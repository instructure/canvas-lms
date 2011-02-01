
Partial Class upload
    Inherits System.Web.UI.Page

	Public Sub Page_Load(ByVal Sender As Object, ByVal E As EventArgs)
		Dim thumbnail_image As System.Drawing.Image = Nothing
		Dim original_image As System.Drawing.Image = Nothing
		Dim final_image As System.Drawing.Bitmap = Nothing
		Dim graphic As System.Drawing.Graphics = Nothing

		Dim ms As System.IO.MemoryStream = Nothing

		Try
			Dim jpeg_image_upload As HttpPostedFile = Request.Files("Filedata")
			original_image = System.Drawing.Image.FromStream(jpeg_image_upload.InputStream)

			Dim width As Integer = original_image.Width
			Dim height As Integer = original_image.Height
			Dim target_width As Integer = 100
			Dim target_height As Integer = 100
			Dim new_width, new_height As Integer

			Dim target_ratio As Double = target_width / target_height
			Dim image_ratio As Double = width / height

			If target_ratio > image_ratio Then
				new_height = target_height
				new_width = Math.Floor(image_ratio * target_height)
			Else
				new_height = Math.Floor(target_width / image_ratio)
				new_width = target_width
			End If

			final_image = New System.Drawing.Bitmap(target_width, target_height)
			graphic = System.Drawing.Graphics.FromImage(final_image)
			graphic.FillRectangle(New System.Drawing.SolidBrush(System.Drawing.Color.Black), New System.Drawing.Rectangle(0, 0, target_width, target_height))
			Dim paste_x As Integer = (target_width - new_width) / 2
			Dim paste_y As Integer = (target_height - new_height) / 2
			graphic.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic  '/* new way */
			'//graphic.DrawImage(thumbnail_image, paste_x, paste_y, new_width, new_height)
			graphic.DrawImage(original_image, paste_x, paste_y, new_width, new_height)

			' // Store the thumbnail in the session (Note: this is bad, it will take a lot of memory, but this is just a demo)
			ms = New System.IO.MemoryStream()
			final_image.Save(ms, System.Drawing.Imaging.ImageFormat.Jpeg)

			' // Store the data in my custom Thumbnail object
			Dim thumbnail_id As String = DateTime.Now.ToString("yyyyMMddHHmmssfff")
			Dim thumb As Thumbnail = New Thumbnail(thumbnail_id, ms.GetBuffer())

			' // Put it all in the Session (initialize the session if necessary)			
			Dim thumbnails As System.Collections.Generic.List(Of Thumbnail) = Session("file_info")
			If thumbnails Is Nothing Then
				thumbnails = New System.Collections.Generic.List(Of Thumbnail)()
				Session("file_info") = thumbnails
			End If
			thumbnails.Add(thumb)

			Response.StatusCode = 200
			Response.Write(thumbnail_id)

		Catch ex As Exception
			' // If any kind of error occurs return a 500 Internal Server error
			Response.StatusCode = 500
			Response.Write("An error occured")
			Response.End()
		Finally
			' // Clean up
			If Not final_image Is Nothing Then
				final_image.Dispose()
			End If
			If Not graphic Is Nothing Then
				graphic.Dispose()
			End If
			If Not original_image Is Nothing Then
				original_image.Dispose()
			End If
			If Not thumbnail_image Is Nothing Then
				thumbnail_image.Dispose()
			End If

			If Not ms Is Nothing Then
				ms.Close()
			End If

			Response.End()
		End Try

	End Sub
End Class
