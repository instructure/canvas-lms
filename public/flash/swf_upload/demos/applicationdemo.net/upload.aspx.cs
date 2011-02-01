using System;
using System.Data;
using System.Configuration;
using System.Collections;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Web.UI.HtmlControls;
using System.IO;
using System.Collections.Generic;

public partial class upload : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
		
		System.Drawing.Image thumbnail_image = null;
		System.Drawing.Image original_image = null;
		System.Drawing.Bitmap final_image = null;
		System.Drawing.Graphics graphic = null;
		MemoryStream ms = null;

		try
		{
			// Get the data
			HttpPostedFile jpeg_image_upload = Request.Files["Filedata"];

			// Retrieve the uploaded image
			original_image = System.Drawing.Image.FromStream(jpeg_image_upload.InputStream);

			// Calculate the new width and height
			int width = original_image.Width;
			int height = original_image.Height;
			int target_width = 100;
			int target_height = 100;
			int new_width, new_height;

			float target_ratio = (float)target_width / (float)target_height;
			float image_ratio = (float)width / (float)height;

			if (target_ratio > image_ratio)
			{
				new_height = target_height;
				new_width = (int)Math.Floor(image_ratio * (float)target_height);
			}
			else
			{
				new_height = (int)Math.Floor((float)target_width / image_ratio);
				new_width = target_width;
			}

			new_width = new_width > target_width ? target_width : new_width;
			new_height = new_height > target_height ? target_height : new_height;
			
			
			// Create the thumbnail
			
			// Old way
			//thumbnail_image = original_image.GetThumbnailImage(new_width, new_height, null, System.IntPtr.Zero);
				// We don't have to create a Thumbnail since the DrawImage method will resize, but the GetThumbnailImage looks better
				// I've read about a problem with GetThumbnailImage. If a jpeg has an embedded thumbnail it will use and resize it which
				//  can result in a tiny 40x40 thumbnail being stretch up to our target size

			
			final_image = new System.Drawing.Bitmap(target_width, target_height);
			graphic = System.Drawing.Graphics.FromImage(final_image);
			graphic.FillRectangle(new System.Drawing.SolidBrush(System.Drawing.Color.Black), new System.Drawing.Rectangle(0, 0, target_width, target_height));
			int paste_x = (target_width - new_width) / 2;
			int paste_y = (target_height - new_height) / 2;
			graphic.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic; /* new way */
			//graphic.DrawImage(thumbnail_image, paste_x, paste_y, new_width, new_height);
			graphic.DrawImage(original_image, paste_x, paste_y, new_width, new_height);
			
			// Store the thumbnail in the session (Note: this is bad, it will take a lot of memory, but this is just a demo)
			ms = new MemoryStream();
			final_image.Save(ms, System.Drawing.Imaging.ImageFormat.Jpeg);

			// Store the data in my custom Thumbnail object
			string thumbnail_id = DateTime.Now.ToString("yyyyMMddHHmmssfff");
			Thumbnail thumb = new Thumbnail(thumbnail_id, ms.GetBuffer());

			// Put it all in the Session (initialize the session if necessary)			
			List<Thumbnail> thumbnails = Session["file_info"] as List<Thumbnail>;
			if (thumbnails == null)
			{
				thumbnails = new List<Thumbnail>();
				Session["file_info"] = thumbnails;
			}
			thumbnails.Add(thumb);

			Response.StatusCode = 200;
			Response.Write(thumbnail_id);
		}
		catch
		{
			// If any kind of error occurs return a 500 Internal Server error
			Response.StatusCode = 500;
			Response.Write("An error occured");
			Response.End();
		}
		finally
		{
			// Clean up
			if (final_image != null) final_image.Dispose();
			if (graphic != null) graphic.Dispose();
			if (original_image != null) original_image.Dispose();
			if (thumbnail_image!= null )thumbnail_image.Dispose();
			if (ms != null) ms.Close();
			Response.End();
		}
	
	}
}
