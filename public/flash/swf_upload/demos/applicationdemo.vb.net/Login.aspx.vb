
Partial Class Login
    Inherits System.Web.UI.Page

	Protected Sub btnLogin_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnLogin.Click
		If FormsAuthentication.Authenticate(Me.txtUserName.Text, Me.txtPassword.Text) Then
			FormsAuthentication.RedirectFromLoginPage(Me.txtUserName.Text, True)
		End If
	End Sub
End Class
