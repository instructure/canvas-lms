
Partial Class ShowThumbnail
	Inherits System.Web.UI.Page

	Public Sub Page_Load(ByVal Sender As Object, ByVal E As EventArgs)
		Dim id As String = Request.QueryString("id")
		Dim thumbnails As System.Collections.Generic.List(Of Thumbnail) = Session("file_info")

		If id Is Nothing OrElse thumbnails Is Nothing Then
			Response.StatusCode = 404
			Response.Write("Not Found")
			Response.End()
			Return
		End If

		For Each thumb As Thumbnail In thumbnails
			If thumb.ID = id Then
				Response.ContentType = "image/jpeg"
				Response.BinaryWrite(thumb.Data)
				Response.End()
				Return
			End If
		Next

		Response.StatusCode = 404
		Response.Write("Not Found")
		Response.End()
	End Sub

End Class
