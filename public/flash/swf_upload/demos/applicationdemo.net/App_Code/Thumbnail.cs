using System;
using System.Data;
using System.Configuration;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Web.UI.HtmlControls;

/// <summary>
/// Summary description for Thumbnail
/// </summary>
public class Thumbnail
{
	public Thumbnail(string id, byte[] data)
	{
		this.ID = id;
		this.Data = data;
	}


	private string id;
	public string ID
	{
		get
		{
			return this.id;
		}
		set
		{
			this.id = value;
		}
	}

	private byte[] thumbnail_data;
	public byte[] Data
	{
		get
		{
			return this.thumbnail_data;
		}
		set
		{
			this.thumbnail_data = value;
		}
	}
	
	
}
