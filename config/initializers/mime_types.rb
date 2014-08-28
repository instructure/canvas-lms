# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone

Mime::Type.register "application/msword", :doc
Mime::Type.register "application/vnd.ms-powerpoint", :ppt
Mime::Type.register "application/vnd.ms-excel", :xls
Mime::Type.register "application/postscript", :ps
Mime::Type.register "application/rtf", :rtf
Mime::Type.register "text/plaintext", :log
Mime::Type.register 'application/vnd.api+json', :jsonapi
Mime::Type.register 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', :docx
Mime::Type.register 'application/vnd.openxmlformats-officedocument.presentationml.presentation', :pptx
Mime::Type.register 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', :xlsx
Mime::Type.register_alias 'text/html', :fbml unless defined? Mime::FBML
