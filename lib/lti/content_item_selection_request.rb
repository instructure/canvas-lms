#
# Copyright (C) 2017 Instructure, Inc.
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

module Lti
  class ContentItemSelectionRequest
    include ActionDispatch::Routing::PolymorphicRoutes
    include Rails.application.routes.url_helpers

    def initialize(context:, domain_root_account:, base_url:, tool:, user: nil, secure_params: nil)
      @context = context
      @domain_root_account = domain_root_account
      @user = user
      @base_url = URI.parse(base_url)
      @tool = tool
      @secure_params = secure_params
    end

    def generate_lti_launch(placement:, opts: {}, expanded_variables: {})
      lti_launch = Lti::Launch.new(opts)
      lti_launch.resource_url = opts[:launch_url] || @tool.extension_setting(placement, :url)
      lti_launch.link_text = @tool.label_for(placement.to_sym, I18n.locale)
      lti_launch.analytics_id = @tool.tool_id
      lti_launch.params = launch_params(
        lti_launch.resource_url,
        placement,
        expanded_variables,
        opts[:content_item_id],
        opts[:assignment]
      )

      lti_launch
    end

    def self.default_lti_params(context, domain_root_account, user = nil)
      lti_helper = Lti::SubstitutionsHelper.new(context, domain_root_account, user)

      params = {
        context_id: Lti::Asset.opaque_identifier_for(context),
        tool_consumer_instance_guid: domain_root_account.lti_guid,
        roles: lti_helper.current_lis_roles,
        launch_presentation_locale: I18n.locale.to_s || I18n.default_locale.to_s,
        launch_presentation_document_target: 'iframe',
        ext_roles: lti_helper.all_roles,
        oauth_callback: 'about:blank'
      }

      params[:user_id] = Lti::Asset.opaque_identifier_for(user) if user
      params
    end

    private

    def launch_params(resource_url, placement, expanded_variables, content_item_id = nil, assignment = nil)
      content_item_return_url = return_url(content_item_id)

      params = ContentItemSelectionRequest.default_lti_params(@context, @domain_root_account, @user).
        merge(message_params(content_item_return_url)).
        merge(data: data_hash_jwt(resource_url, content_item_id)).
        merge(placement_params(placement, assignment: assignment)).
        merge(expanded_variables)

      params[:ext_lti_assignment_id] = lti_assignment_id(assignment: assignment)

      Lti::Security.signed_post_params(
        params,
        resource_url,
        @tool.consumer_key,
        @tool.shared_secret,
        @context.root_account.feature_enabled?(:disable_lti_post_only) || @tool.extension_setting(:oauth_compliant)
      )
    end

    def lti_assignment_id(assignment: nil)
      assignment.try(:lti_context_id) || Lti::Security.decoded_lti_assignment_id(@secure_params)
    end

    def message_params(content_item_return_url)
      {
        # required params
        lti_message_type: 'ContentItemSelectionRequest',
        lti_version: 'LTI-1p0',
        content_item_return_url: content_item_return_url,
        context_title: @context.name,
        # optional params
        accept_multiple: false
      }
    end

    def data_hash_jwt(resource_url, content_item_id = nil)
      data_hash = {default_launch_url: resource_url}
      if content_item_id
        data_hash[:content_item_id] = content_item_id
        data_hash[:oauth_consumer_key] = @tool.consumer_key
      end

      Canvas::Security.create_jwt(data_hash)
    end

    def return_url(content_item_id)
      return_url_opts = {
        service: 'external_tool_dialog',
        host: @base_url.host,
        protocol: @base_url.scheme,
        port: @base_url.port
      }

      if content_item_id
        return_url_opts[:id] = content_item_id
        polymorphic_url([@context, :external_content_update], return_url_opts)
      else
        polymorphic_url([@context, :external_content_success], return_url_opts)
      end
    end

    def placement_params(placement, assignment: nil)
      case placement
      when 'migration_selection'
        migration_selection_params
      when 'editor_button'
        editor_button_params
      when 'resource_selection', 'link_selection', 'assignment_selection'
        lti_launch_selection_params
      when 'collaboration'
        collaboration_params
      when 'homework_submission'
        homework_submission_params(assignment)
      else
        # TODO: we _could_, if configured, have any other placements return to the content migration page...
        raise "Content-Item not supported at this placement"
      end
    end

    def migration_selection_params
      accept_media_types = %w(
        application/vnd.ims.imsccv1p1
        application/vnd.ims.imsccv1p2
        application/vnd.ims.imsccv1p3
        application/zip
        application/xml
      )

      {
        accept_media_types: accept_media_types.join(','),
        accept_presentation_document_targets: 'download',
        accept_copy_advice: true,
        ext_content_file_extensions: %w(zip imscc mbz xml).join(','),
        accept_unsigned: true,
        auto_create: false
      }
    end

    def editor_button_params
      {
        accept_media_types: %w(image/* text/html application/vnd.ims.lti.v1.ltilink */*).join(','),
        accept_presentation_document_targets: %w(embed frame iframe window).join(','),
        accept_unsigned: true,
        auto_create: false
      }
    end

    def lti_launch_selection_params
      {
        accept_media_types: 'application/vnd.ims.lti.v1.ltilink',
        accept_presentation_document_targets: %w(frame window).join(','),
        accept_unsigned: true,
        auto_create: false
      }
    end

    def collaboration_params
      {
        accept_media_types: 'application/vnd.ims.lti.v1.ltilink',
        accept_presentation_document_targets: 'window',
        accept_unsigned: false,
        auto_create: true,
      }
    end

    def homework_submission_params(assignment)
      params = {}
      params[:accept_media_types] = '*/*'
      accept_presentation_document_targets = []
      accept_presentation_document_targets << 'window' if assignment.submission_types.include?('online_url')
      accept_presentation_document_targets << 'none' if assignment.submission_types.include?('online_upload')
      params[:accept_presentation_document_targets] = accept_presentation_document_targets.join(',')
      params[:accept_copy_advice] = !!assignment.submission_types.include?('online_upload')
      if assignment.submission_types.strip == 'online_upload' && assignment.allowed_extensions.present?
        params[:ext_content_file_extensions] = assignment.allowed_extensions.compact.join(',')
        params[:accept_media_types] = assignment.allowed_extensions.map do |ext|
          MimetypeFu::EXTENSIONS[ext]
        end.compact.join(',')
      end
      params
    end
  end
end
