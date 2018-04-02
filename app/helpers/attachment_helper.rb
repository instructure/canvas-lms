#
# Copyright (C) 2012 - present Instructure, Inc.
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
#

module AttachmentHelper
  # returns a string of html attributes suitable for use with $.loadDocPreview
  def doc_preview_attributes(attachment, attrs={})
    url_opts = {
      moderated_grading_whitelist: attrs[:moderated_grading_whitelist],
      enable_annotations: attrs.delete(:enable_annotations)
    }
    if attachment.crocodoc_available?
      begin
        attrs[:crocodoc_session_url] = attachment.crocodoc_url(@current_user, url_opts)
      rescue => e
        Canvas::Errors.capture_exception(:crocodoc, e)
      end
    elsif attachment.canvadocable?
      attrs[:canvadoc_session_url] = attachment.canvadoc_url(@current_user, url_opts)
    end
    attrs[:attachment_id] = attachment.id
    attrs[:mimetype] = attachment.mimetype
    context_name = url_helper_context_from_object(attachment.context)
    url_helper = "#{context_name}_file_inline_view_url"
    if self.respond_to?(url_helper)
      attrs[:attachment_view_inline_ping_url] = self.send(url_helper, attachment.context, attachment.id)
    end
    if attachment.pending_upload? || attachment.processing?
      attrs[:attachment_preview_processing] = true
    end
    attrs.map { |attr,val|
      %|data-#{attr}="#{ERB::Util.html_escape(val)}"|
    }.join(" ").html_safe
  end

  def media_preview_attributes(attachment, attrs={})
    attrs[:type] = attachment.content_type.match(/video/) ? 'video' : 'audio'
    attrs[:download_url] = context_url(attachment.context, :context_file_download_url, attachment.id)
    attrs[:media_entry_id] = attachment.media_entry_id if attachment.media_entry_id
    attrs.inject("") { |s,(attr,val)| s << "data-#{attr}=#{val} " }
  end

  def doc_preview_json(attachment, user)
    {
      canvadoc_session_url: attachment.canvadoc_url(@current_user),
      crocodoc_session_url: attachment.crocodoc_url(@current_user),
    }
  end

  def render_or_redirect_to_stored_file(attachment:, verifier: nil, inline: false)
    set_cache_header(attachment, inline)
    if safer_domain_available?
      redirect_to safe_domain_file_url(attachment, @safer_domain_host, verifier, !inline)
    elsif attachment.stored_locally?
      @headers = false if @files_domain
      send_file(attachment.full_filename, :type => attachment.content_type_with_encoding, :disposition => (inline ? 'inline' : 'attachment'), :filename => attachment.display_name)
    elsif inline && attachment.can_be_proxied?
      send_file_headers!( :length=> attachment.s3object.content_length, :filename=>attachment.filename, :disposition => 'inline', :type => attachment.content_type_with_encoding)
      render body: attachment.s3object.get.body.read
    elsif inline
      redirect_to authenticated_inline_url(attachment)
    else
      redirect_to authenticated_download_url(attachment)
    end
  end

  # checks if for the current root account there's a 'files' domain
  # defined and tried to use that.  This way any files that we stream through
  # a canvas URL are at least on a separate subdomain and the javascript
  # won't be able to access or update data with AJAX requests.
  def safer_domain_available?
    if !@files_domain && request.host_with_port != HostUrl.file_host(@domain_root_account, request.host_with_port)
      @safer_domain_host = HostUrl.file_host_with_shard(@domain_root_account, request.host_with_port)
    end
    !!@safer_domain_host
  end

  def set_cache_header(attachment, inline)
    # TODO [RECNVS-73]
    # instfs JWTs cannot be shared across users, so we cannot cache them across
    # users. while most browsers will only service one user and caching
    # independent of user would not be detrimental, we cannot guarantee that.
    # so we can't let the browser cache the instfs redirect. we should still
    # investigate opportunities to reuse JWTs when the same user requests the
    # same file within a reasonable window of time, so that the URL redirected
    # too can still take advantage of browser caching.
    unless attachment.instfs_hosted? || attachment.content_type.match(/\Atext/) || attachment.extension == '.html' || attachment.extension == '.htm'
      cancel_cache_buster
      # set cache to expire whenever the s3 url does (or one day if local or inline proxy), max-age take seconds, and Expires takes a date
      ttl = attachment.stored_locally? || (inline && attachment.can_be_proxied?) ? 1.day : attachment.url_ttl
      response.headers["Cache-Control"] = "private, max-age=#{ttl.seconds.to_s}"
      response.headers["Expires"] = ttl.from_now.httpdate
    end
  end

end
