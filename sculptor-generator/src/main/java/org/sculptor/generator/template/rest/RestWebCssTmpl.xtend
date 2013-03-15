package org.sculptor.generator.template.rest

import org.sculptor.generator.ext.GeneratorFactory

import org.sculptor.generator.util.OutputSlot
import sculptormetamodel.Application

import org.sculptor.generator.ext.Helper

class RestWebCssTmpl {
	extension Helper helper = GeneratorFactory::helper


def String css(Application it) {
	fileOutput("stylesheets/main.css", OutputSlot::TO_WEBROOT, '''
/* main elements */

	body,div,td {
	font-family: Arial, Helvetica, sans-serif;
	font-size: 12px;
	color: #000;
	}

	body {
	background-color: #fff;
	background-position: top center;
	background-repeat: no-repeat;
	text-align: center;
	min-width: 800px;
	margin-top: 60px;
	margin-left: auto;
	margin-right: auto;
	}

	.formContainer {
	height:400px;
	}
	label {
	width:100px;
	float:left;
	margin-left: 5px;
	margin-top: 0px;
	}

	input {
	height:16px;
	}

	submit {
	height:25px;
	}

	div {
	text-align: left;
	}

	div .box {
	display:block;
	margin-left:105px;
	}

/* header and footer elements */

	#wrap {
	margin:0 auto;
			position:relative;
			float:center;  	
			top: 0px;
			left:0px;
			width:750px;
			text-align:left;  	

	}
	#main {
			margin:0 auto;
			position:relative;
			float:right;  	
			top: 35px;
			left:0px;
			width:700px;
			height:700px; 
			text-align:left;
	}




	.footer {
	background:#fff;
	border:none;
	margin-top:20px;
	border-top:1px solid #999999;
	width:100%;
	}

	.footer td {color:#999999;}

	.footer a:link {color: #7db223;}

/* menu elements*/

	a.menu, a.menu:link, a.menu:visited {display:block; width:150px; height:25px;} 
	
/* text styles */

	h1,h2,h3 {
	font-family: Helvetica, sans-serif;
	color: #ae8658;
	}

	h1 {
	font-size: 20px;
	line-height: 26px;
	}

	h2 {
	font-size: 18px;
	line-height: 20px;
	}

	h3 {
	font-size: 15px;
	line-height: 21px;
	color:#555;
	}

	h4 {
	font-size: 14px;
	line-height: 20px;
	}

	.errors {
	color: red;
	font-weight: bold;
	display: block;
	margin-left: 105px;
	}

	a {
	text-decoration: underline;
	font-size: 13px;
	}

	a:link {
	color: #ae8658;
	}

	a:hover {
	color: #456314;
	}

	a:active {
	color: #ae8658;
	}

	a:visited {
	color: #ae8658;
	}

	ul {
	list-style: disc url(../images/bullet-arrow.png);
	}

	li {
	padding-top: 5px;
	text-align: left;
	}

	li ul {
	list-style: square url(images/sub-bullet.gif);
	}

	li ul li ul {
	list-style: circle none;
	}

/* table elements */

	table {
	background: #EEEEEE;
	margin: 2px 0 0 0;
	border: 1px solid #BBBBBB;
	border-collapse: collapse;
	}

	table table {
	margin: -5px 0;
	border: 0px solid #e0e7d3;
	width: 100%;
	}

	table td,table th {
	padding: 5px;
	}

	table th {
	font-size: 11px;
	text-align: left;
	font-weight: bold;
	color: #FFFFFF;
	}

	table thead {
	font-weight: bold;
	font-style: italic;
	background-color: #BBBBBB;
	}

	table a:link {color: #303030;}

	caption {
	caption-side: top;
	width: auto;
	text-align: left;
	font-size: 12px;
	color: #848f73;
	padding-bottom: 4px;
	}

	fieldset {
	background: #e0e7d3;
	padding: 8px;
	padding-bottom: 22px;
	border: none;
	width: 560px;
	}

	fieldset label {
	width: 70px;
	float: left;
	margin-top: 1.7em;
	margin-left: 20px;
	}

	fieldset textfield {
	margin: 3px;
	height: 20px;
	background: #e0e7d3;
	}

	fieldset textarea {
	margin: 3px;
	height: 165px;
	background: #e0e7d3;
	}

	fieldset input {
	margin: 3px;
	height: 20px;
	background: #e0e7d3;
	}

	fieldset table {
	width: 100%;
	}

	fieldset th {
	padding-left: 25px;
	}

	.table-buttons {
	background-color:#fff;
	border:none;
	}

	.table-buttons td {
	border:none;
	}

	.submit input {
	border: 1px solid #BBBBBB;
	color:#777777;
	padding:2px 7px;
	font-size:11px;
	text-transform:uppercase;
	font-weight:bold;
	height:24px;
	}

	.updated {
	background:#ecf1e5;
	font-size:11px;
	margin-left:2px;
	border:4px solid #ecf1e5;
	}

	.updated td {
	padding:2px 8px;
	font-size:11px;
	color:#888888;
	}




	#menu {
		background: #eee;
			position:relative;
			float:left;  	
			top: 35px;
			left:0px;
			width:200px;
	}

	#menu ul{
	list-style: none;
	margin: 0;
	padding: 0;
	}

	#menu ul li{
	padding: 0px;
	}


	#menu a, #menu h2 {
	display: block;
	margin: 0;
	padding: 2px 6px;
	color:#FFFFFF;
	}

	#menu h2 {
	color: #fff;
	background: #648C1D;
	text-transform: uppercase;
	font-weight:bold;
	font-size: 1em;
	}

	#menu a {
	color: #666666;
	background: #efefef;
	text-decoration: none;
	padding: 2px 12px;
	}

	#menu a:hover {
	color: #648C1D;
	background: #fff;
	}
	'''
	)
}

}
