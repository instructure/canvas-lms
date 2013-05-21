#
# Copyright (C) 2012 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under the
# terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

module AttachmentHelper
  # returns a string of html attributes suitable for use with $.loadDocPreview
  def doc_preview_attributes(attachment, attrs={})
    if attachment.crocodoc_available?
      begin
        crocodoc = attachment.crocodoc_document
        session_url = crocodoc.session_url(:user => @current_user)
        attrs[:crocodoc_session_url] = session_url
      rescue => e
        ErrorReport.log_exception('crocodoc', e)
      end
    elsif attachment.scribdable? && scribd_doc = attachment.scribd_doc
      begin
        attrs[:scribd_doc_id] = scribd_doc.doc_id
        attrs[:scribd_access_key] = scribd_doc.access_key
        attrs[:public_url] = attachment.authenticated_s3_url
      rescue => e
        ErrorReport.log_exception('scribd', e)
      end
    end
    attrs[:attachment_id] = attachment.id
    attrs[:mimetype] = attachment.mimetype
    attrs[:attachment_view_inline_ping_url] = context_url(self.context, :context_file_inline_view_url, self.id)
    attrs.inject("") { |s,(attr,val)| s << "data-#{attr}=#{val} " }
  end
end
