<%@ Page Language="VB" AutoEventWireup="true" CodeFile="Login.aspx.vb" Inherits="Login" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
<title>SWFUpload Revision v2.1.0 Application Demo (ASP.Net VB.Net 2.0)</title>
<link href="../css/default.css" rel="stylesheet" type="text/css" />
</head>
<body>
<form id="form1" runat="server">
	<div id="header">
		<h1 id="logo"><a href="../">SWFUpload</a></h1>
		<div id="version">v2.1.0</div>
	</div>
	<h2>Application Demo (ASP.Net 2.0)</h2>
	<div class="content">
		<table>
			<tr>
				<td><label for="txtUserName">User Name:</label></td>
				<td><asp:TextBox ID="txtUserName" runat="server" Text="demo" /></td>
			</tr>
			<tr>
				<td><label for="txtPassword">Password:</label></td>
				<td><asp:TextBox ID="txtPassword" runat="server" Text="demo" /></td>
			</tr>
		</table>
		<asp:Button ID="btnLogin" runat="server" Text="Login" />
	</div>
</form>
</body>
</html>
