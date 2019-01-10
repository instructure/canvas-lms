#
# Copyright (C) 2016 - present Instructure, Inc.
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

module InstFS
  class << self
    def enabled?
      # true if plugin is enabled AND all settings values are set
      Canvas::Plugin.find('inst_fs').enabled? && !!app_host && !!jwt_secret
    end

    def login_pixel(user, session, oauth_host)
      return if session[:oauth2] # don't stomp an existing oauth flow in progress
      return if session[:pending_otp]
      if !session[:shown_instfs_pixel] && user && enabled?
        session[:shown_instfs_pixel] = true
        pixel_url = login_pixel_url(token: session_jwt(user, oauth_host))
        %Q(<img src="#{pixel_url}" alt="" role="presentation" />).html_safe
      end
    end

    def logout(user)
      return unless user && enabled?
      CanvasHttp.delete(logout_url(user))
    rescue CanvasHttp::Error => e
      Canvas::Errors.capture_exception(:page_view, e)
    end

    def authenticated_url(attachment, options={})
      query_params = { token: access_jwt(access_path(attachment, attachment.filename), options) }
      query_params[:download] = 1 if options[:download]
      access_url(attachment, query_params)
    end

    def logout_url(user)
      query_params = { token: logout_jwt(user) }
      service_url("/session", query_params)
    end

    def authenticated_thumbnail_url(attachment, options={})
      query_params = { token: access_jwt(thumbnail_path(attachment), options) }
      query_params[:geometry] = options[:geometry] if options[:geometry]
      thumbnail_url(attachment, query_params)
    end

    def export_references_url
      query_params = { token: export_references_jwt}
      service_url("/references", query_params)
    end

    def app_host
      setting("app-host")
    end

    def jwt_secret
      secret = setting("secret")
      if secret
        Base64.decode64(secret)
      end
    end

    def upload_preflight_json(context:, root_account:, user:, acting_as:, access_token:, folder:, filename:,
                              content_type:, quota_exempt:, on_duplicate:, capture_url:, target_url: nil,
                              progress_json: nil, include_param: nil, additional_capture_params: {})
      raise ArgumentError unless !!target_url == !!progress_json # these params must both be present or both absent

      token = upload_jwt(
        user: user,
        acting_as: acting_as,
        access_token: access_token,
        root_account: root_account,
        capture_url: capture_url,
        capture_params: additional_capture_params.merge(
          context_type: context.class.to_s,
          context_id: context.global_id.to_s,
          user_id: acting_as.global_id.to_s,
          folder_id: folder&.global_id&.to_s,
          root_account_id: root_account.global_id.to_s,
          quota_exempt: !!quota_exempt,
          on_duplicate: on_duplicate,
          progress_id: progress_json && progress_json[:id],
          include: include_param
        )
      )

      upload_params = {
        filename: filename,
        content_type: content_type
      }
      if target_url
        upload_params[:target_url] = target_url
      end

      {
        file_param: target_url ? nil : 'file',
        progress: progress_json,
        upload_url: upload_url(token),
        upload_params: upload_params
      }
    end

    def direct_upload(file_name:, file_object:)
      # example of a call to direct_upload:
      # > res = InstFS.direct_upload(
      # >   file_name: "a.png",
      # >   file_object: File.open("public/images/a.png")
      # > )

      token = direct_upload_jwt
      url = "#{app_host}/files?token=#{token}"

      data = {}
      data[file_name] = file_object

      response = CanvasHttp.post(url, form_data: data, multipart: true, streaming: true)
      if response.class == Net::HTTPCreated
        json_response = JSON.parse(response.body)
        return json_response["instfs_uuid"] if json_response.key?("instfs_uuid")

        raise InstFS::DirectUploadError, "upload succeeded, but response did not containe an \"instfs_uuid\" key"
      end
      raise InstFS::DirectUploadError, "received code \"#{response.code}\" from service"
    end

    private
    def setting(key)
      Canvas::DynamicSettings.find(service: "inst-fs", default_ttl: 5.minutes)[key]
    rescue Imperium::TimeoutError => e
      Canvas::Errors.capture_exception(:inst_fs, e)
      nil
    end

    def service_url(path, query_params=nil)
      url = "#{app_host}#{path}"
      url += "?#{query_params.to_query}" if query_params
      url
    end

    def login_pixel_url(query_params)
      service_url("/session/ensure", query_params)
    end

    def access_url(attachment, query_params)
      service_url(access_path(attachment, attachment.filename), query_params)
    end

    def thumbnail_url(attachment, query_params)
      service_url(thumbnail_path(attachment), query_params)
    end

    def upload_url(token=nil)
      query_string = { token: token } if token
      service_url("/files", query_string)
    end

    def access_path(attachment, custom_name)
      res = "/files/#{attachment.instfs_uuid}"
      if custom_name
        res += "/#{custom_name}"
      end
      res
    end

    def thumbnail_path(attachment)
      "/thumbnails/#{attachment.instfs_uuid}"
    end

    def service_jwt(claims, expires_in)
      Canvas::Security.create_jwt(claims, expires_in.from_now, self.jwt_secret, :HS512)
    end

    def access_jwt(resource, options={})
      expires_in = Setting.get('instfs.access_jwt.expiration_hours', '24').to_i.hours
      expires_in = options[:expires_in] || expires_in
      claims = {
        iat: Time.now.utc.to_i,
        user_id: options[:user]&.global_id&.to_s,
        resource: resource,
        host: options[:oauth_host]
      }
      if options[:acting_as] && options[:acting_as] != options[:user]
        claims[:acting_as_user_id] = options[:acting_as].global_id.to_s
      end
      amend_claims_for_access_token(claims, options[:access_token], options[:root_account])
      service_jwt(claims, expires_in)
    end

    def upload_jwt(user:, acting_as:, access_token:, root_account:, capture_url:, capture_params:)
      expires_in = Setting.get('instfs.upload_jwt.expiration_minutes', '10').to_i.minutes
      claims = {
        iat: Time.now.utc.to_i,
        user_id: user.global_id.to_s,
        resource: "/files",
        capture_url: capture_url,
        capture_params: capture_params
      }
      unless acting_as == user
        claims[:acting_as_user_id] = acting_as.global_id.to_s
      end
      amend_claims_for_access_token(claims, access_token, root_account)
      service_jwt(claims, expires_in)
    end

    def direct_upload_jwt
      expires_in = Setting.get('instfs.upload_jwt.expiration_minutes', '10').to_i.minutes
      service_jwt({
        iat: Time.now.utc.to_i,
        user_id: nil,
        host: "canvas",
        resource: "/files",
      }, expires_in)
    end

    def session_jwt(user, host)
      expires_in = Setting.get('instfs.session_jwt.expiration_minutes', '5').to_i.minutes
      service_jwt({
        iat: Time.now.utc.to_i,
        user_id: user.global_id&.to_s,
        host: host,
        resource: '/session/ensure'
      }, expires_in)
    end

    def logout_jwt(user)
      expires_in = Setting.get('instfs.logout_jwt.expiration_minutes', '5').to_i.minutes
      service_jwt({
        iat: Time.now.utc.to_i,
        user_id: user.global_id&.to_s,
        resource: '/session'
      }, expires_in)
    end

    def export_references_jwt
      expires_in = Setting.get('instfs.logout_jwt.expiration_minutes', '5').to_i.minutes
      service_jwt({
        iat: Time.now.utc.to_i,
        resource: '/references'
      }, expires_in)
    end

    def amend_claims_for_access_token(claims, access_token, root_account)
      return unless access_token
      if whitelisted_access_token?(access_token)
        # temporary workaround for legacy API consumers
        claims[:legacy_api_developer_key_id] = access_token.global_developer_key_id.to_s
        claims[:legacy_api_root_account_id] = root_account.global_id.to_s
      else
        # TODO: long term solution for updated API consumers goes here
      end
    end

    def whitelisted_access_token?(access_token)
      if access_token.nil?
        false
      elsif Setting.get('instfs.whitelist_all_developer_keys', 'false') == 'true'
        true
      else
        whitelist = Setting.get('instfs.whitelisted_developer_key_global_ids', '')
        whitelist = whitelist.split(',').map(&:to_i)
        whitelist.include?(access_token.global_developer_key_id)
      end
    end
  end

  class DirectUploadError < StandardError; end
end
