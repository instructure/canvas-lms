<%@ Application Language="C#" %>

<script runat="server">

	void Application_BeginRequest(object sender, EventArgs e)
	{
		/* Fix for the Flash Player Cookie bug in Non-IE browsers.
		 * Since Flash Player always sends the IE cookies even in FireFox
		 * we have to bypass the cookies by sending the values as part of the POST or GET
		 * and overwrite the cookies with the passed in values.
		 * 
		 * The theory is that at this point (BeginRequest) the cookies have not been read by
		 * the Session and Authentication logic and if we update the cookies here we'll get our
		 * Session and Authentication restored correctly
		 */

		try
		{
			string session_param_name = "ASPSESSID";
			string session_cookie_name = "ASP.NET_SESSIONID";

			if (HttpContext.Current.Request.Form[session_param_name] != null)
			{
				UpdateCookie(session_cookie_name, HttpContext.Current.Request.Form[session_param_name]);
			}
			else if (HttpContext.Current.Request.QueryString[session_param_name] != null)
			{
				UpdateCookie(session_cookie_name, HttpContext.Current.Request.QueryString[session_param_name]);
			}
		}
		catch (Exception)
		{
			Response.StatusCode = 500;
			Response.Write("Error Initializing Session");
		}

		try
		{
			string auth_param_name = "AUTHID";
			string auth_cookie_name = FormsAuthentication.FormsCookieName;

			if (HttpContext.Current.Request.Form[auth_param_name] != null)
			{
				UpdateCookie(auth_cookie_name, HttpContext.Current.Request.Form[auth_param_name]);
			}
			else if (HttpContext.Current.Request.QueryString[auth_param_name] != null)
			{
				UpdateCookie(auth_cookie_name, HttpContext.Current.Request.QueryString[auth_param_name]);
			}

		}
		catch (Exception)
		{
			Response.StatusCode = 500;
			Response.Write("Error Initializing Forms Authentication");
		}
	}
	void UpdateCookie(string cookie_name, string cookie_value)
	{
		HttpCookie cookie = HttpContext.Current.Request.Cookies.Get(cookie_name);
		if (cookie == null)
		{
			cookie = new HttpCookie(cookie_name);
			HttpContext.Current.Request.Cookies.Add(cookie);
		}
		cookie.Value = cookie_value;
		HttpContext.Current.Request.Cookies.Set(cookie);
	}
		   
</script>
