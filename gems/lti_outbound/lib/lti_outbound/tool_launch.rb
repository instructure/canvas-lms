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

require 'oauth'

module LtiOutbound
  class ToolLaunch
    attr_reader :url, :tool, :user, :context, :link_code, :return_url, :account,
                :resource_type, :consumer_instance, :hash, :assignment,
                :outgoing_email_address, :selected_html, :variable_expander,
                :post_only

    def initialize(options)
      @url = options[:url] || raise('URL required for generating LTI content')
      @tool = options[:tool] || raise('Tool required for generating LTI content')
      @user = options[:user] || LTIUser.new #|| raise('User required for generating LTI content')
      @account = options[:account] || raise('Account required for generating LTI content')
      @context = options[:context] || raise('Context required for generating LTI content')
      @link_code = options[:link_code] || raise('Link Code required for generating LTI content')
      @return_url = options[:return_url] || raise('Return URL required for generating LTI content')
      @resource_type = options[:resource_type]
      @outgoing_email_address = options[:outgoing_email_address]
      @selected_html = options[:selected_html]
      @consumer_instance = context.consumer_instance || raise('Consumer instance required for generating LTI content')

      @variable_expander = options[:variable_expander] || raise('VariableExpander is required for generating LTI content')

      @hash = {}
    end

    def for_assignment!(assignment, outcome_service_url, legacy_outcome_service_url, lti_turnitin_outcomes_placement_url)
      @assignment = assignment
      hash['lis_result_sourcedid'] = assignment.source_id if user.learner?
      hash['lis_outcome_service_url'] = outcome_service_url
      hash['ext_ims_lis_basic_outcome_url'] = legacy_outcome_service_url
      hash['ext_outcome_data_values_accepted'] = assignment.return_types.join(',')
      hash['ext_outcome_result_total_score_accepted'] = true
      hash['ext_outcomes_tool_placement_url'] = lti_turnitin_outcomes_placement_url

      add_assignment_substitutions!(assignment)
    end

    def for_homework_submission!(assignment)
      @assignment = assignment
      @resource_type = 'homework_submission'

      hash['ext_content_return_types'] = assignment.return_types.join(',')
      hash['ext_content_file_extensions'] = assignment.allowed_extensions.join(',') if assignment.allowed_extensions

      add_assignment_substitutions!(assignment)
    end

    def generate(overrides={})
      hash['lti_message_type'] = 'basic-lti-launch-request'
      hash['lti_version'] = 'LTI-1p0'
      hash['resource_link_id'] = link_code
      hash['resource_link_title'] = overrides['resource_link_title'] || tool.name
      hash['user_id'] = user.opaque_identifier
      hash['text'] = CGI::escape(selected_html) if selected_html

      hash['roles'] = user.current_role_types # AccountAdmin, Student, Faculty or Observer
      hash['ext_roles'] = '$Canvas.xuser.allRoles'

      hash['custom_canvas_enrollment_state'] = '$Canvas.enrollment.enrollmentState'

      if tool.include_name?
        hash['lis_person_name_given'] = user.first_name
        hash['lis_person_name_family'] = user.last_name
        hash['lis_person_name_full'] = user.name
      end
      if tool.include_email?
        hash['lis_person_contact_email_primary'] = user.email
      end
      if tool.public?
        hash['user_image'] = user.avatar_url
        hash['custom_canvas_user_id'] = '$Canvas.user.id'
        hash['lis_person_sourcedid'] = '$Person.sourcedId' if user.sis_source_id
        hash['custom_canvas_user_login_id'] = '$Canvas.user.loginId'
        if context.is_a?(LTICourse)
          hash['custom_canvas_course_id'] = '$Canvas.course.id'
          hash['lis_course_offering_sourcedid'] = '$CourseSection.sourcedId' if context.sis_source_id
        elsif context.is_a?(LTIAccount) || context.is_a?(LTIUser)
          hash['custom_canvas_account_id'] = '$Canvas.account.id'
          hash['custom_canvas_account_sis_id'] = '$Canvas.account.sisSourceId'
        end
        hash['custom_canvas_api_domain'] = '$Canvas.api.domain'
      end

      # need to set the locale here (instead of waiting for the first call to
      # I18n.t like we usually do), because otherwise we'll have the wrong code
      # for the launch_presentation_locale.
      I18n.set_locale_with_localizer

      hash['context_id'] = context.opaque_identifier
      hash['context_title'] = context.name
      hash['context_label'] = context.course_code if context.respond_to?(:course_code)
      hash['launch_presentation_locale'] = I18n.locale || I18n.default_locale.to_s
      hash['launch_presentation_document_target'] = 'iframe'
      if resource_type
        hash['launch_presentation_width'] = tool.selection_width(resource_type)
        hash['launch_presentation_height'] = tool.selection_height(resource_type)
      end
      hash['launch_presentation_return_url'] = return_url
      hash['tool_consumer_instance_guid'] = consumer_instance.lti_guid
      hash['tool_consumer_instance_name'] = consumer_instance.name
      hash['tool_consumer_instance_contact_email'] = outgoing_email_address # TODO: find a better email address to use here
      hash['tool_consumer_info_product_family_code'] = 'canvas'
      hash['tool_consumer_info_version'] = 'cloud'
      tool.set_custom_fields(hash, resource_type)
      set_resource_type_keys()
      hash['oauth_callback'] = 'about:blank'

      @variable_expander.expand_variables!(hash)
      hash
    end

    private

    def add_assignment_substitutions!(assignment)
      if tool.public?
        hash['custom_canvas_assignment_id'] = '$Canvas.assignment.id'
      end

      hash['custom_canvas_assignment_title'] = '$Canvas.assignment.title'
      hash['custom_canvas_assignment_points_possible'] = '$Canvas.assignment.pointsPossible'
    end

    def set_resource_type_keys
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
      elsif resource_type == 'migration_selection'
        hash['ext_content_intended_use'] = 'content_package'
        hash['ext_content_return_types'] = 'file'
        hash['ext_content_file_extensions'] = 'zip,imscc'
        hash['ext_content_return_url'] = return_url
      end
    end

  end
end
