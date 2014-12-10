define [
  'i18n!mimeClass'
], ->

  # this module works together with app/stylesheets/components/_MimeClassIcons.scss
  # so, given the mime-type of a file you can give it a css class name that corresponds to it.
  # eg: somefile.pdf would get the css class .mimeClass-pdf and a little icon with the acrobat logo in it.

  # if there is a file format that is common enough, go ahead and add an entry to one of these:
  # If you need to make a new class, make sure to also make an svg for it in public/images/mimeClassIcons/
  # and a class name in app/stylesheets/components/_MimeClassIcons.scss
  # (and app/stylesheets/components/deprecated/_fancy_links.sass if it is still being used)
  mimeClasses =
    audio:
      displayName: I18n.t('Audio')
      mimeTypes: [
        'audio/x-mpegurl'
        'audio/x-pn-realaudio'
        'audio/x-aiff'
        'audio/3gpp'
        'audio/mid'
        'audio/x-wav'
        'audio/basic'
        'audio/mpeg'
      ]
    code:
      displayName: I18n.t('Source code')
      mimeTypes: [
        'text/xml'
        'text/css'
        'text/x-yaml'
        'application/xml'
        'application/javascript'
        'text/x-csharp'
      ]
    doc:
      displayName: I18n.t('Text document')
      mimeTypes: [
        'application/x-docx'
        'text/rtf'
        'application/msword'
        'application/rtf'
        'application/vnd.oasis.opendocument.text'
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      ]
    flash:
      displayName: I18n.t('Flash')
      mimeTypes: [
        'application/x-shockwave-flash'
      ]
    html:
      displayName: I18n.t('Web page')
      mimeTypes: [
        'text/html'
        'application/xhtml+xml'
      ]
    image:
      displayName: I18n.t('Image')
      mimeTypes: [
        'image/png'
        'image/x-psd'
        'image/gif'
        'image/pjpeg'
        'image/jpeg'
      ]
    ppt:
      displayName: I18n.t('Presentation')
      mimeTypes: [
        'application/vnd.openxmlformats-officedocument.presentationml.presentation'
        'application/vnd.ms-powerpoint'
      ]
    pdf:
      displayName: I18n.t('PDF')
      mimeTypes: [
        'application/pdf'
      ]
    text:
      displayName: I18n.t('Plain text')
      mimeTypes: [
        'text'
        'text/plain'
      ]
    video:
      displayName: I18n.t('Video')
      mimeTypes: [
        'video/mp4'
        'video/x-ms-asf'
        'video/x-msvideo'
        'video/x-sgi-movie'
        'video/mpeg'
        'video/quicktime'
        'video/x-la-asf'
        'video/3gpp'
      ]
    xls:
      displayName: I18n.t('Spreadsheet')
      mimeTypes: [
        'application/vnd.oasis.opendocument.spreadsheet'
        'text/csv'
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        'application/vnd.ms-excel'
      ]
    zip:
      displayName: I18n.t('Archive')
      mimeTypes: [
        'application/x-rar-compressed'
        'application/x-zip-compressed'
        'application/zip'
        'application/x-zip'
        'application/x-rar'
      ]

  mimeClass = (contentType) ->
    mimeClass.mimeClasses[contentType] || 'file'

  mimeClass.displayName = (contentType) ->
    mimeClasses[mimeClass(contentType)]?.displayName || I18n.t('Unknown')

  mimeClass.mimeClasses = {}
  for cls, value of mimeClasses
    for mimeType in value.mimeTypes
      mimeClass.mimeClasses[mimeType] = cls


  return mimeClass