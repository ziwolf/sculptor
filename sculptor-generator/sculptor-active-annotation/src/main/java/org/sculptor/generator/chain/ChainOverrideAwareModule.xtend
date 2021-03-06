/*
 * Copyright 2013 The Sculptor Project Team, including the original 
 * author or authors.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.sculptor.generator.chain

import com.google.inject.AbstractModule
import java.io.IOException
import java.io.InputStream
import java.lang.reflect.Array
import java.util.HashSet
import java.util.List
import java.util.MissingResourceException
import java.util.Stack
import javax.inject.Inject
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import java.util.Properties

/**
 * Binds specified class(es) to instanc(es) with support for creating
 * chains from override or extension classes.      
 */
class ChainOverrideAwareModule extends AbstractModule {

	private static final Logger LOG = LoggerFactory::getLogger(typeof(ChainOverrideAwareModule))

	//
	// Properties support for reading 'cartridges' property
	// TODO: Move this and loadProperties into separate class shared with PropertiesBase?
	//
	public static final String PROPERTIES_LOCATION_PROPERTY = "sculptor.generatorPropertiesLocation"
	public static final String COMMON_PROPERTIES_LOCATION_PROPERTY = "sculptor.commonGeneratorPropertiesLocation"
	public static final String DEFAULT_PROPERTIES_LOCATION_PROPERTY = "sculptor.defaultGeneratorPropertiesLocation"

	private static final String PROPERTIES_RESOURCE = System.getProperty(PROPERTIES_LOCATION_PROPERTY,
			"generator/sculptor-generator.properties")
	private static final String COMMON_PROPERTIES_RESOURCE = System.getProperty(COMMON_PROPERTIES_LOCATION_PROPERTY,
			"common-sculptor-generator.properties")
	private static final String DEFAULT_PROPERTIES_RESOURCE = System.getProperty(DEFAULT_PROPERTIES_LOCATION_PROPERTY,
			"default-sculptor-generator.properties")

	// Package where override packages will be looked for
	var String defaultOverridesPackage = "generator";
	
	private val List<? extends Class<?>> startClasses

	public new(Class<?> startClassOn) {
		startClasses = #[startClassOn]
		setProperties
	}

	public new(List<? extends Class<?>> startClassesOn) {
		startClasses = startClassesOn
		setProperties
	}

	def protected setProperties() {
		val defaultOverridesPkgProp = System::getProperty("sculptor.defaultOverridesPackage")
		if (defaultOverridesPkgProp != null) {
			defaultOverridesPackage = defaultOverridesPkgProp
		}
		if (LOG.debugEnabled) {
			LOG.debug("Enabled cartridges: {}", cartridgeNames.toList)
		}
	}

	override protected configure() {
		buildChainForClasses(<Class<?>>newHashSet(), startClasses)
	}

	def void buildChainForClasses(HashSet<Class<?>> mapped, List<? extends Class<?>> newClasses) {
		val onlyNew = newClasses.filter[c|!mapped.contains(c)].toList
		mapped.addAll(onlyNew)
		val HashSet<Class<?>> discovered = newHashSet()
		onlyNew.forEach[clazz|buildChainForClass(discovered, clazz)]
		if (discovered.size > 0) {
			buildChainForClasses(mapped, discovered.toList)
		}
	}

	/**
	 * Instantiate and build chain for clazz if it supports overriding/chaining.
	 * In either case, bind the newly created instance.
	 * Add any injected classes found in clazz to discovered.  These will later be evaluated for chain processing as well.
	 * Instantiate clazz first, then work backwards looking for cartridges or app override class that override clazz
	 */
	def <T> buildChainForClass(HashSet<Class<?>> discovered, Class<T> clazz) {
		LOG.debug("Building chain for class '{}'", clazz)

		// Instantiate template - try overrideable version first
		val T template = try {
			clazz.getConstructor(clazz).newInstance(null as T)
		} catch (Throwable t) {
			// fall-back to non-overrideable class constructor
			clazz.newInstance
		}

		// Add all classes injected into template to discovered  
		template.^class.discoverInjectedFields(discovered)

		// If template is overridable/chainable then try to prepare whole chain, with the overridable class being the last element in chain
		// chain ends up being the head of the chain or the template itself if not overridable/chainable.
		var T chain
		if (template instanceof ChainLink<?>) {
			val methodsDispatchHead = (template as ChainLink<?>)._getOverridesDispatchArray as T[]

			// Prepare list of class names to add to chain if they exist
			val needsToBeChained = new Stack<String>()
			needsToBeChained.push(clazz.overrideClassName)
			cartridgeNames.forEach[cartridgeName|needsToBeChained.push(clazz.getTemplateClassName(cartridgeName))]
			if (LOG.debugEnabled) {
				LOG.debug("Classes to check to add to chain: {}", needsToBeChained.join(", "))
			}

			// Create the override chain for needsToBeChained, removing elements off the stack as it goes
			chain = template.buildChainForInstance(template.^class, discovered, needsToBeChained, methodsDispatchHead)
			
			// Finally set methodsDispatchHead into each chain member
			chain.updateChainWithMethodsDispatchHead(methodsDispatchHead)
		} else {
			chain = template
		}

		// Bind loaded chain to class
		bind(clazz).toInstance(chain)
	}

	/**
	 * Iterates through the whole chain and sets the methodsDispatchHead of each chain member.
	 */
	private def <T> updateChainWithMethodsDispatchHead(T chain, T[] methodsDispatchHead) {
		var chainLink = chain as ChainLink<?>
		while (chainLink != null) {
			chainLink.setMethodsDispatchHead(methodsDispatchHead)
			chainLink = chainLink.next
		}
	}

	/**
	 * Build out the override chain for needsToBeChained recursively, removing elements off the stack as it goes.
	 * @param object current head of chain.  New ChainLink instance will be made to point to object
	 * @param templateClass Original template class
	 * @param discovered Classes discovered so far that are to be injected into ChainLink classes
	 * @param needsToBeChained Classes that still need to be chained
	 */
	def <T> T buildChainForInstance(T object, Class<?> templateClass, HashSet<Class<?>> discovered, Stack<String> needsToBeChained,
		T[] methodsDispatchHead
	) {
		if (needsToBeChained.isEmpty) {
			return object
		}

		var result = object
		val className = needsToBeChained.pop
		try {
			val chainedClass = Class::forName(className)
			if (typeof(ChainLink).isAssignableFrom(chainedClass)) {
				LOG.debug("    chaining with class '{}'", chainedClass)

				// Create an instance of MethodDispatch class for the given templateClass and the current head of chain object
				val nextDispatchObj = methodsDispatchHead.createNextDispatchObjFromHead(templateClass, object)

				// Create chain instance via chaining constructor added by ChainOverride annotation
				val constructor = chainedClass.getConstructor(templateClass, methodsDispatchHead.class)
				result = (constructor.newInstance(nextDispatchObj, null) as T)

				// Update methodsDispatchHead with dispatch array returned by chainLink of newly created chained instance
				methodsDispatchHead.updateFromObjDispatchArray(result)
				
				// Inject fields and methods into given object
				requestInjection(object)

				// Discover the classes of injected fields and add them to the given list
				chainedClass.discoverInjectedFields(discovered)
			} else {
				LOG.debug("    found class {} but not assignable to ChainLink.  skipping.", className)
			}
		} catch (ClassNotFoundException ex) {
			if (LOG.traceEnabled) {
				LOG.trace("Could not find class extension or override class {}", className)
			}

			// No such class - continue with popping from stack using same base object
		}
		// Recursive
		buildChainForInstance(result, templateClass, discovered, needsToBeChained, methodsDispatchHead);
	}

	/**
	 * Creates an instance of MethodDispatch class for the given templateClass and methodsDispatchHead.
	 */
	private def <T> createNextDispatchObjFromHead(T[] methodsDispatchHead, Class<?> templateClass, T object) {
		val methodsDispatchNext = methodsDispatchHead.copyMethodsDispatchHead(templateClass)

		val methodDispatchClass = Class::forName(templateClass.dispatchClassName)
		val methodDispatchConst = methodDispatchClass.getConstructor(templateClass, methodsDispatchNext.class)
		methodDispatchConst.newInstance(object, methodsDispatchNext as Object) as T
	}

	/**
	 * Returns a copy of the given methodsDispatchHead for the given overrideableClass.
	 */
	private def <T> T[] copyMethodsDispatchHead(T[] methodsDispatchHead, Class<?> overrideableClass) {
		val T[] methodsDispatchNext = Array::newInstance(overrideableClass, methodsDispatchHead.size) as T[]
		System.arraycopy(methodsDispatchHead, 0, methodsDispatchNext, 0, methodsDispatchHead.length)
		methodsDispatchNext
	}

	/**
	 * Update methodsDispatchHead with dispatch array returned by chainLink.
	 */
	private def <T> updateFromObjDispatchArray(T[] methodsDispatchHead, T chainLink) {
		val cl = chainLink as ChainLink<?>

		val dispatchArray = cl._getOverridesDispatchArray
		if (dispatchArray != null) {
			dispatchArray.forEach [ dispatchObj, i |
				if (dispatchObj != null) {
					methodsDispatchHead.set(i, dispatchObj as T)
				}
			]
		}
	}

	/**
	 * Discover any Inject annotated declared fields in newClass and add the classes to discovered.  Will process newClass base classes too.
	 */
	def void discoverInjectedFields(Class<?> newClass, HashSet<Class<?>> discovered) {
		var cls = newClass;
		do {
			discovered.addAll(
				cls.declaredFields.filter[f|
					f.getAnnotation(typeof(Inject)) != null || f.getAnnotation(typeof(com.google.inject.Inject)) != null].
					map[f|f.type].toList)
			cls = cls.superclass
		} while (cls != typeof(Object))
	}

	//
	// Naming convention generators
	//

	/**
	 * @return Fully qualified name of override class
	 */
	def <T> String getOverrideClassName(Class<T> clazz) {
		defaultOverridesPackage + "." + clazz.simpleName + "Override"
	}

	/**
	 * @return Fully qualified name of template class from given cartridge
	 */
	static def <T> String getTemplateClassName(Class<T> clazz, String cartridgeName) {
		"org.sculptor.generator.cartridge." + cartridgeName + "." + clazz.simpleName + "Extension"
	}

	/**
	 * @return Fully qualified name of method dispatch class
	 */
	static def <T> String getDispatchClassName(Class<T> clazz) {
		clazz.name + "MethodDispatch"
	}

	//
	// System properties support
	//

	private var Properties props

	def getCartridgeNames() {
		if (props == null) {
			
			val defaultProperties = new Properties
			loadProperties(defaultProperties, DEFAULT_PROPERTIES_RESOURCE)
	
			val commonProperties = new Properties(defaultProperties)
			try {
				loadProperties(commonProperties, COMMON_PROPERTIES_RESOURCE)
			} catch (MissingResourceException e) {
				// ignore, it is not mandatory
			}
			props = new Properties(commonProperties)
			try {
				loadProperties(props, PROPERTIES_RESOURCE)
			} catch (MissingResourceException e) {
				// ignore, it is not mandatory
			}
		}

		val cartString = props.getProperty("cartridges")
		if (cartString != null && cartString.length > 0) {
			cartString.split("[,; ]")
		} else {
			<String>newArrayOfSize(0)
		}
	}

	/**
	 * Load properties from resource into properties
	 */
	def protected void loadProperties(Properties properties, String resource) {
		var ClassLoader classLoader = Thread::currentThread().getContextClassLoader()
		if (classLoader == null) {
			classLoader = this.getClass.getClassLoader()
		}
		val InputStream resourceInputStream = classLoader.getResourceAsStream(resource)
		if (resourceInputStream == null) {
			throw new MissingResourceException("Properties resource not available: " + resource, "GeneratorProperties",
				"")
		}
		try {
			properties.load(resourceInputStream)
		} catch (IOException e) {
			throw new MissingResourceException("Can't load properties from: " + resource, "GeneratorProperties", "")
		}
	}

}
