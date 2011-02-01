Imports Microsoft.VisualBasic

Public Class Thumbnail
	Private _id As String
	Private _data As Byte()

	Public Sub New(ByVal id As String, ByVal data As Byte())
		Me._id = id
		Me._data = data
	End Sub

	Public Property ID() As String
		Get
			Return Me._id
		End Get
		Set(ByVal value As String)
			Me._id = value
		End Set
	End Property
	Public Property Data() As Byte()
		Get
			Return Me._data
		End Get
		Set(ByVal value As Byte())
			Me._data = value
		End Set
	End Property

End Class
