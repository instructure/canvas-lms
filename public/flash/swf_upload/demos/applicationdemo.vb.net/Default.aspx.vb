
Partial Class _Default
    Inherits System.Web.UI.Page

	Protected AuthCookie As String

	Public Sub Page_Load(ByVal Sender As Object, ByVal E As EventArgs)
		Session.Clear()

		Dim auth_cookie As HttpCookie = Request.Cookies(FormsAuthentication.FormsCookieName)
		If Not auth_cookie Is Nothing Then
			AuthCookie = auth_cookie.Value
		End If

	End Sub

	Protected Sub btnLogout_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnLogout.Click
		FormsAuthentication.SignOut()
		FormsAuthentication.RedirectToLoginPage()
	End Sub
End Class
