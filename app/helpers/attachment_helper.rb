# frozen_string_literal: true

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
  def doc_preview_attributes(attachment, attrs = {})
    url_opts = {
      anonymous_instructor_annotations: attrs.delete(:anonymous_instructor_annotations),
      enable_annotations: attrs.delete(:enable_annotations),
      moderated_grading_allow_list: attrs[:moderated_grading_allow_list],
      submission_id: attrs.delete(:submission_id)
    }
    url_opts[:enrollment_type] = attrs.delete(:enrollment_type) if url_opts[:enable_annotations]

    if attachment.crocodoc_available?
      begin
        attrs[:crocodoc_session_url] = attachment.crocodoc_url(@current_user, url_opts)
      rescue => e
        Canvas::Errors.capture_exception(:crocodoc, e)
      end
    elsif attachment.canvadocable?
      attrs[:canvadoc_session_url] = attachment.canvadoc_url(@current_user, url_opts, access_token: params[:access_token])
    end
    attrs[:attachment_id] = attachment.id
    attrs[:mimetype] = attachment.mimetype
    context_name = url_helper_context_from_object(attachment.context)
    url_helper = "#{context_name}_file_inline_view_url"
    if respond_to?(url_helper)
      attrs[:attachment_view_inline_ping_url] = send(
        url_helper,
        attachment.context,
        attachment.id,
        {
          access_token: params[:access_token],
          verifier: params[:verifier],
          location: params[:location]
        }
      )
    end
    if attachment.pending_upload? || attachment.processing?
      attrs[:attachment_preview_processing] = true
    end
    attrs.map do |attr, val|
      %(data-#{attr}="#{ERB::Util.html_escape(val)}")
    end.join(" ").html_safe
  end

  def media_preview_attributes(attachment, attrs = {})
    attrs[:attachment_id] = attachment.id
    attrs[:bp_locked_attachment] = attachment_locked? attachment
    attrs[:type] = attachment.content_type&.include?("video") ? "video" : "audio"
    attrs[:download_url] = context_url(attachment.context, :context_file_download_url, attachment.id)
    attrs[:media_entry_id] = attachment.media_entry_id if attachment.media_entry_id
    attrs.inject(+"") { |s, (attr, val)| s << "data-#{attr}=#{val} " }
  end

  def jwt_resource_match(attachment)
    # If we're getting a JWT token from New Quizzes, the file might be in a an item
    # bank, which can be used in multiple contexts, and we need to give access to
    # it in all of them, even if the user doesn't have access to the context the file
    # original comes from.
    # And also used in Lti Asset Processor Asset service to accept DeveloperKeys::AccessVerifier
    @jwt_resource_match ||= if params[:sf_verifier]
                              jwt_payload = Canvas::Security.decode_jwt(params[:sf_verifier], ignore_expiration: true)
                              jwt_payload["permission"] == "download" && jwt_payload["attachment_id"] == attachment.global_id.to_s
                            end
    @jwt_resource_match ||= ensure_token_resource_link(@token, attachment)
  end

  def ensure_token_resource_link(token, attachment)
    return false unless token.respond_to?(:jwt_payload)
    return false unless (resource = token.jwt_payload[:resource])
    return false unless (tenant_auth = token.jwt_payload[:tenant_auth])
    return false unless InstFS.enabled?
    return false unless params[:instfs_id]

    parsed_file_url = Rails.application.routes.recognize_path(resource)
    file_id = parsed_file_url[:attachment_id] || parsed_file_url[:file_id] || parsed_file_url[:id]
    return false unless file_id == (params[:attachment_id] || params[:file_id] || params[:id])

    attachment.instfs_uuid = params[:instfs_id] if params[:instfs_id]
    attachment.instfs_tenant_auth = tenant_auth
    # TODO: One day it would be good if InstFS owned the Canvadoc/Studio file previews and we could use the
    # preview URL without having to ask InstFS if the file is linked to the tenant_auth location, but for now,
    # we need to ask InstFS before we show a file preview.
    metadata = InstFS.get_file_metadata(attachment)
    @attachment_authorization = { attachment:, permission: :download } if metadata.present?
    metadata.present?
  rescue ActionController::RoutingError, InstFS::MetadataError
    false
  end

  def attachment_locked?(attachment)
    cct = MasterCourses::ChildContentTag.where(content_type: "Attachment", content_id: attachment.id).first
    return false unless cct

    mct = MasterCourses::MasterContentTag.where(migration_id: cct.migration_id).first
    return false unless mct # This *should* never happen, but you never know...

    !!mct.restrictions[:content] || !!mct.restrictions[:all]
  end

  def doc_preview_json(attachment, locked_for_user: false, access_token: nil)
    # Don't add canvadoc session URL if the file is locked to the user
    return {} if locked_for_user

    {
      canvadoc_session_url: attachment.canvadoc_url(@current_user, access_token:),
      crocodoc_session_url: attachment.crocodoc_url(@current_user),
    }
  end

  def load_media_object
    if params[:attachment_id].present?
      @attachment = Attachment.find_by(id: params[:attachment_id])
      @attachment = @attachment.context.attachments.find(params[:attachment_id]) if @attachment&.deleted?
      return render_unauthorized_action if @attachment&.deleted? && !(@instfs_verified_token ||= ensure_token_resource_link(@token, @attachment))
      return render_unauthorized_action unless @attachment&.media_entry_id

      # Look on active shard
      @media_object = MediaObject.by_media_id(@attachment&.media_entry_id).take
      # Look on attachment's shard
      @media_object ||= @attachment&.media_object_by_media_id
      # Look on attachment's root account and user shards
      @media_object ||= Shard.shard_for(@attachment.root_account).activate { MediaObject.by_media_id(@attachment.media_entry_id).take }
      @media_object ||= Shard.shard_for(@attachment.user).activate { MediaObject.by_media_id(@attachment.media_entry_id).take }
      @media_object.current_attachment = @attachment unless @media_object.nil?
      @media_id = @media_object&.id
    elsif params[:media_object_id].present?
      @media_id = params[:media_object_id]
      @media_object = MediaObject.by_media_id(@media_id).take
    end
  end

  def check_media_permissions(access_type: :download)
    if @attachment.present?
      access_allowed(attachment: @attachment, user: @current_user, access_type:)
    else
      media_object_exists = @media_object.present?
      render_unauthorized_action unless media_object_exists
      media_object_exists
    end
  end

  def access_allowed(
    attachment:,
    user:,
    access_type:,
    no_error_on_failure: false,
    check_submissions: true
  )
    return true if jwt_resource_match(attachment) || access_via_location?(attachment, user, access_type)

    if params[:verifier]
      verifier_checker = Attachments::Verification.new(attachment)
      return true if verifier_checker.valid_verifier_for_permission?(params[:verifier], access_type, @domain_root_account, session)
    end

    if check_submissions
      submissions = attachment.attachment_associations.where(context_type: "Submission").preload(:context)
                              .filter_map(&:context)
      return true if submissions.any? { |submission| submission.grants_right?(user, session, access_type) }
    end

    if access_type == :update && attachment.editing_restricted?(:content)
      return no_error_on_failure ? false : render_unauthorized_action
    end

    if params[:sf_token]
      return true if check_safe_files_token(attachment, params[:sf_token])
    end

    no_error_on_failure ? attachment.grants_right?(user, session, access_type) : authorized_action(attachment, user, access_type)
  end

  def access_via_location?(attachment, user, access_type)
    if params[:location] && [:read, :download].include?(access_type)
      return AttachmentAssociation.verify_access(params[:location], attachment, user, session)
    end

    false
  end

  def check_safe_files_token(attachment, sf_token)
    return false unless Account.site_admin.feature_enabled?(:safe_files_token) && sf_token && !safer_domain_available?

    sf_token_key = "sf_token:#{sf_token}"
    sf_token_data = Rails.cache.read(sf_token_key)
    return false unless sf_token_data

    if sf_token_data[:full_path] == attachment.full_path
      # access is checked twice so delete token after second check
      if sf_token_data[:used]
        Rails.cache.delete(sf_token_key)
      else
        sf_token_data[:used] = true
        Rails.cache.write(sf_token_key, sf_token_data, expires_in: 5.minutes)
      end
      true
    else
      false
    end
  end

  def render_or_redirect_to_stored_file(attachment:, verifier: nil, inline: false)
    can_proxy = inline && attachment.can_be_proxied?
    must_proxy = inline && csp_enforced? && attachment.mime_class == "html"
    direct = attachment.stored_locally? || can_proxy || must_proxy

    # up here to preempt files domain redirect
    if attachment.instfs_hosted? && file_location_mode? && !direct
      url = if inline
              authenticated_inline_url(attachment)
            else
              authenticated_download_url(attachment)
            end
      render_file_location(url)
      return
    end

    set_cache_header(attachment, direct)
    if safer_domain_available?
      redirect_to safe_domain_file_url(attachment,
                                       host_and_shard: @safer_domain_host,
                                       verifier:,
                                       download: !inline,
                                       authorization: @attachment_authorization)
    elsif attachment.stored_locally?
      @headers = false if @files_domain
      send_file(attachment.full_filename, type: attachment.content_type_with_encoding, disposition: (inline ? "inline" : "attachment"), filename: attachment.display_name)
    elsif can_proxy
      body = attachment.open.read
      add_csp_for_file if attachment.mime_class == "html"
      send_file_headers!(length: body.length, filename: attachment.filename, disposition: "inline", type: attachment.content_type_with_encoding)
      render body:
    elsif must_proxy
      render 400, text: I18n.t("It's not allowed to redirect to HTML files that can't be proxied while Content-Security-Policy is being enforced")
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

  def set_cache_header(attachment, direct)
    # TODO: [RECNVS-73]
    # instfs JWTs cannot be shared across users, so we cannot cache them across
    # users. while most browsers will only service one user and caching
    # independent of user would not be detrimental, we cannot guarantee that.
    # so we can't let the browser cache the instfs redirect. we should still
    # investigate opportunities to reuse JWTs when the same user requests the
    # same file within a reasonable window of time, so that the URL redirected
    # too can still take advantage of browser caching.
    unless (attachment.instfs_hosted? && !direct) || attachment.content_type&.start_with?("text") || attachment.extension == ".html" || attachment.extension == ".htm"
      cancel_cache_buster
      # set cache to expire whenever the s3 url does (or one day if local or inline proxy), max-age take seconds, and Expires takes a date
      ttl = direct ? 1.day : attachment.url_ttl
      response.headers["Cache-Control"] = "private, max-age=#{ttl.seconds}"
      response.headers["Expires"] = ttl.from_now.httpdate
    end
  end

  def file_index_scope(context_or_folder, current_user, params)
    params[:sort] ||= params[:sort_by]
    params[:include] = Array(params[:include])
    params[:include] << "user" if params[:sort] == "user"

    scope = Attachments::ScopedToUser.new(context_or_folder, current_user).scope
    scope = scope.preload(:user) if params[:include].include?("user") && params[:sort] != "user"
    scope = scope.preload(:usage_rights) if params[:include].include?("usage_rights")

    scope = Attachment.search_by_attribute(scope, :display_name, params[:search_term], normalize_unicode: true)
    scope = scope.by_content_types(Array(params[:content_types])) if params[:content_types].present?
    scope = scope.by_exclude_content_types(Array(params[:exclude_content_types])) if params[:exclude_content_types].present?
    scope = scope.for_category(params[:category]) if params[:category].present?
    scope
  end
end
