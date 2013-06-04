#
# Copyright (C) 2013 Instructure, Inc.
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
module BasicLTI
class ToolLaunch < Struct.new(:url, :tool, :user, :context, :link_code, :return_url, :resource_type, :root_account, :hash, :user_data)

    def initialize(options)
      self.url = options[:url]                     || raise("URL required for generating Basic LTI content")
      self.tool = options[:tool]                   || raise("Tool required for generating Basic LTI content")
      self.user = options[:user]                   || raise("User required for generating Basic LTI content")
      self.context = options[:context]             || raise("Context required for generating Basic LTI content")
      self.link_code = options[:link_code]         || raise("Link Code required for generating Basic LTI content")
      self.return_url = options[:return_url]       || raise("Return URL required for generating Basic LTI content")
      self.resource_type = options[:resource_type]
      if self.context.respond_to? :root_account
        self.root_account = context.root_account
      elsif self.tool.context.respond_to? :root_account
        self.root_account = tool.context.root_account
      end
      root_account || raise("Root account required for generating Basic LTI content")

      self.hash = {}
    end

    def for_assignment!(assignment, outcome_service_url, legacy_outcome_service_url)
      hash['lis_result_sourcedid'] = BasicLTI::BasicOutcomes.encode_source_id(tool, context, assignment, user)
      hash['lis_outcome_service_url'] = outcome_service_url
      hash['ext_ims_lis_basic_outcome_url'] = legacy_outcome_service_url
      hash['ext_outcome_data_values_accepted'] = ['url', 'text'].join(',')
      hash['custom_canvas_assignment_title'] = assignment.title
      hash['custom_canvas_assignment_points_possible'] = assignment.points_possible
      if tool.public?
        hash['custom_canvas_assignment_id'] = assignment.id
      end
    end

    def for_homework_submission!(assignment)
      self.resource_type = 'homework_submission'

      return_types_map = {'online_upload' => 'file', 'online_url' => 'url'}
      return_types = []
      assignment.submission_types.split(',').each do |submission_type|
        submission_type.strip!
        return_types << return_types_map[submission_type.strip] if return_types_map.has_key? submission_type
      end
      hash['ext_content_return_types'] = return_types.join(',') unless return_types.blank?
      hash['ext_content_file_extensions'] = assignment.allowed_extensions.join(',') unless assignment.allowed_extensions.blank?

      hash['custom_canvas_assignment_id'] = assignment.id if tool.public?
    end

    def generate
      hash['lti_message_type'] = 'basic-lti-launch-request'
      hash['lti_version'] = 'LTI-1p0'
      hash['resource_link_id'] = link_code
      hash['resource_link_title'] = tool.name
      hash['user_id'] = user.opaque_identifier(:asset_string)
      hash['user_image'] = user.avatar_url
      self.user_data = BasicLTI.user_lti_data(user, context)
      hash['roles'] = self.user_data['role_types'].join(',') # AccountAdmin, Student, Faculty or Observer
      hash['custom_canvas_enrollment_state'] = self.user_data['enrollment_state'] if self.user_data['enrollment_state']

      if tool.include_name?
        hash['lis_person_name_given'] = user.first_name
        hash['lis_person_name_family'] = user.last_name
        hash['lis_person_name_full'] = user.name
      end
      if tool.include_email?
        hash['lis_person_contact_email_primary'] = user.email
      end
      if tool.public?
        hash['custom_canvas_user_id'] = user.id
        pseudo = user.find_pseudonym_for_account(self.root_account)
        if pseudo
          hash['lis_person_sourcedid'] = pseudo.sis_user_id if pseudo.sis_user_id
          hash['custom_canvas_user_login_id'] = pseudo.unique_id
        end
        if context.is_a?(Course)
          hash['custom_canvas_course_id'] = context.id
          hash['lis_course_offering_sourcedid'] = context.sis_source_id if context.sis_source_id
        elsif context.is_a?(Account)
          hash['custom_canvas_account_id'] = context.id
          hash['custom_canvas_account_sis_id'] = context.sis_source_id if context.sis_source_id
        end
        hash['custom_canvas_api_domain'] = root_account.domain
      end

      # need to set the locale here (instead of waiting for the first call to
      # I18n.t like we usually do), because otherwise we'll have the wrong code
      # for the launch_presentation_locale.
      I18n.set_locale_with_localizer

      hash['context_id'] = context.opaque_identifier(:asset_string)
      hash['context_title'] = context.name
      hash['context_label'] = context.course_code if context.respond_to?(:course_code)
      hash['launch_presentation_locale'] = I18n.locale || I18n.default_locale.to_s
      hash['launch_presentation_document_target'] = 'iframe'
      hash['launch_presentation_width'] = tool.extension_setting(resource_type, :selection_width) if resource_type
      hash['launch_presentation_height'] = tool.extension_setting(resource_type, :selection_height) if resource_type
      hash['launch_presentation_return_url'] = return_url
      hash['tool_consumer_instance_guid'] = root_account.lti_guid
      hash['tool_consumer_instance_name'] = root_account.name
      hash['tool_consumer_instance_contact_email'] = HostUrl.outgoing_email_address # TODO: find a better email address to use here
      hash['tool_consumer_info_product_family_code'] = 'canvas'
      hash['tool_consumer_info_version'] = 'cloud'
      tool.set_custom_fields(hash, resource_type)
      if resource_type == 'editor_button'
        hash['selection_directive'] = 'embed_content' #backwards compatibility
        hash['ext_content_intended_use'] = 'embed'
        hash['ext_content_return_types'] = 'oembed,lti_launch_url,url,image_url,iframe'
        hash['ext_content_return_url'] = return_url
      elsif resource_type == 'resource_selection'
        hash['selection_directive'] = 'select_link' #backwards compatibility
        hash['ext_content_intended_use'] = 'navigation'
        hash['ext_content_return_types'] = 'lti_launch_url'
        hash['ext_content_return_url'] = return_url
      elsif resource_type == 'homework_submission'
        hash['ext_content_intended_use'] = 'homework'
        hash['ext_content_return_url'] = return_url
      end
      hash['oauth_callback'] = 'about:blank'

      VariableSubstitutor.new(self).substitute!
      BasicLTI.generate_params(hash, url, tool.consumer_key, tool.shared_secret)
    end
end
end