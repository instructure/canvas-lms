#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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
Mime::Type.register 'application/vnd.ims.lis.v2.lineitem+json', :lineitem
Mime::Type.register 'application/vnd.ims.lis.v1.score+json', :score
Mime::Type.register 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', :docx
Mime::Type.register 'application/vnd.openxmlformats-officedocument.presentationml.presentation', :pptx
Mime::Type.register 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', :xlsx
Mime::Type.register_alias 'text/html', :fbml unless defined? Mime::FBML

# Custom LTI Advantage MIME types
standard_json_parser = lambda { |body| JSON.parse(body) }
ActionDispatch::Request.parameter_parsers[:lineitem] = standard_json_parser
ActionDispatch::Request.parameter_parsers[:score] = standard_json_parser
