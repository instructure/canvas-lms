<%@ Application Language="VB" %>

<script runat="server">

	Sub Application_BeginRequest(ByVal sender As Object, ByVal e As EventArgs)
		'/* Fix for the Flash Player Cookie bug in Non-IE browsers.
		' * Since Flash Player always sends the IE cookies even in FireFox
		' * we have to bypass the cookies by sending the values as part of the POST or GET
		' * and overwrite the cookies with the passed in values.
		' * 
		' * The theory is that at this point (BeginRequest) the cookies have not been read by
		' * the Session and Authentication logic and if we update the cookies here we'll get our
		' * Session and Authentication restored correctly
		' */

		Try
			Dim session_param_name As String = "ASPSESSID"
			Dim session_cookie_name As String = "ASP.NET_SESSIONID"

			If Not HttpContext.Current.Request.Form(session_param_name) Is Nothing Then
				UpdateCookie(session_cookie_name, HttpContext.Current.Request.Form(session_param_name))
			ElseIf Not HttpContext.Current.Request.QueryString(session_param_name) Is Nothing Then
				UpdateCookie(session_cookie_name, HttpContext.Current.Request.QueryString(session_param_name))
			End If
		Catch ex As Exception
			Response.StatusCode = 500
			Response.Write("Error Initializing Session")
	
		End Try
		
		Try
			Dim auth_param_name As String = "AUTHID"
			Dim auth_cookie_name As String = FormsAuthentication.FormsCookieName

			If Not HttpContext.Current.Request.Form(auth_param_name) Is Nothing Then
				UpdateCookie(auth_cookie_name, HttpContext.Current.Request.Form(auth_param_name))
			ElseIf Not HttpContext.Current.Request.QueryString(auth_param_name) Is Nothing Then
				UpdateCookie(auth_cookie_name, HttpContext.Current.Request.QueryString(auth_param_name))
			End If

		Catch ex As Exception
			Response.StatusCode = 500
			Response.Write("Error Initializing Forms Authentication")
		End Try
		
	End Sub
	
	Sub UpdateCookie(ByVal cookie_name As String, ByVal cookie_value As String)
		Dim cookie As System.Web.HttpCookie = HttpContext.Current.Request.Cookies.Get(cookie_name)
		If cookie Is Nothing Then
			cookie = New HttpCookie(cookie_name)
			HttpContext.Current.Request.Cookies.Add(cookie)
		End If
		cookie.Value = cookie_value
		HttpContext.Current.Request.Cookies.Set(cookie)
	End Sub
       
</script>