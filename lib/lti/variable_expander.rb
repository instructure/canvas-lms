# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
# NOTE: To update the VariableExpansion docs run `script/generate_lti_variable_substitution_markdown`

module Lti
  class VariableExpander
    SUBSTRING_REGEX = /(?<=\${).*?(?=})/ # matches only the stuff inside `${}`
    PARAMETERS_REGEX = /^(\$.+)<(.+)>$/ # matches key and argument

    attr_reader :context, :root_account, :controller, :current_user

    attr_accessor :current_pseudonym,
                  :content_tag,
                  :assignment,
                  :tool_setting_link_id,
                  :tool_setting_binding_id,
                  :tool_setting_proxy_id,
                  :tool,
                  :attachment,
                  :collaboration,
                  :variable_whitelist,
                  :variable_blacklist

    def self.register_expansion(name, permission_groups, expansion_proc, *guards, **kwargs)
      @expansions ||= {}
      @expansions[:"$#{name}"] = VariableExpansion.new(
        name,
        permission_groups,
        expansion_proc,
        *([-> { Lti::AppUtil.allowed?(name, @variable_whitelist, @variable_blacklist) }] + guards),
        **kwargs
      )
    end

    def self.deregister_expansion(name)
      @expansions.delete :"$#{name}"
    end

    def self.expansions
      @expansions || {}
    end

    def self.expansion_keys
      expansions.keys.map { |c| c.to_s[1..] }
    end

    def self.default_name_expansions
      expansions.values.select { |v| v.default_name.present? }.map(&:name)
    end

    def self.find_expansion(key)
      return unless key.respond_to?(:to_sym)

      if (md = key.to_s.match(PARAMETERS_REGEX))
        real_key = md[1] + "<>"
        if (expansion = expansions[real_key.to_sym])
          [expansion, md[2]]
        end
      else
        expansions[key.to_sym]
      end
    end

    CONTROLLER_GUARD = -> { !!@controller }
    COURSE_GUARD = -> { @context.is_a? Course }
    TERM_START_DATE_GUARD = lambda do
      @context.is_a?(Course) && @context.enrollment_term &&
        @context.enrollment_term.start_at
    end
    TERM_END_DATE_GUARD = lambda do
      @context.is_a?(Course) && @context.enrollment_term &&
        @context.enrollment_term.end_at
    end
    TERM_NAME_GUARD = -> { @context.is_a?(Course) && @context.enrollment_term&.name }
    TERM_ID_GUARD = -> { @context.is_a?(Course) && @context.enrollment_term_id }
    USER_GUARD = -> { @current_user }
    SIS_USER_GUARD = -> { sis_pseudonym&.sis_user_id }
    PSEUDONYM_GUARD = -> { sis_pseudonym }
    ENROLLMENT_GUARD = -> { @current_user && @context.is_a?(Course) }
    ROLES_GUARD = -> { @current_user && (@context.is_a?(Course) || @context.is_a?(Account)) }
    CONTENT_TAG_GUARD = -> { @content_tag }
    ASSIGNMENT_GUARD = -> { @assignment }
    FILE_UPLOAD_GUARD = -> { !!@assignment && @assignment.submission_types.split(",").include?("online_upload") }
    COLLABORATION_GUARD = -> { @collaboration }
    MEDIA_OBJECT_GUARD = -> { @attachment&.media_object }
    USAGE_RIGHTS_GUARD = -> { @attachment&.usage_rights }
    MEDIA_OBJECT_ID_GUARD = -> { @attachment && (@attachment.media_object || @attachment.media_entry_id) }
    LTI1_GUARD = -> { @tool.is_a?(ContextExternalTool) }
    INTERNAL_TOOL_GUARD = -> { @tool.internal_service?(@launch_url) }
    MASQUERADING_GUARD = -> { !!@controller && @controller.logged_in_user != @current_user }
    MESSAGE_TOKEN_GUARD = -> { @post_message_token.present? || @launch.instance_of?(Lti::Launch) }
    ORIGINALITY_REPORT_GUARD = -> { @originality_report.present? }
    ORIGINALITY_REPORT_ATTACHMENT_GUARD = -> { @originality_report&.attachment.present? }
    LTI_ASSIGN_ID = -> { @assignment.present? || @originality_report.present? || @secure_params.present? }
    LTI_ASSIGN_DESCRIPTION = -> { @assignment.present? || @originality_report.present? || @secure_params.present? }
    EDITOR_GUARD = -> { @editor_contents.present? }
    STUDENT_ASSIGNMENT_GUARD = -> { @context.is_a?(Course) && @context.user_is_student?(@current_user) && @assignment }

    def initialize(root_account, context, controller, opts = {})
      @root_account = root_account
      @context = context
      @controller = controller
      @request = controller.request if controller
      opts.each { |opt, val| instance_variable_set(:"@#{opt}", val) }

      # This will provide the most accurate version of the actual launch
      # url used, whether directly provided from a resource link or
      # calculated from the tool/placement combo. @tool can be an Lti::ToolProxy
      # or a ContextExternalTool, and this only cares about the latter.
      if @tool.respond_to? :launch_url
        @launch_url ||= @tool.launch_url(extension_type: @placement)
      end
    end

    def lti_helper
      @lti_helper ||= Lti::SubstitutionsHelper.new(@context, @root_account, @current_user, @tool)
    end

    def current_user=(current_user)
      @lti_helper = nil
      @current_user = current_user
    end

    def [](key)
      k = (key[0] == "$" && key) || "$#{key}"
      expansion, args = self.class.find_expansion(k)
      expansion&.expand(self, *args)
    end

    def expand_variables!(var_hash)
      var_hash.update(var_hash) do |_, v|
        expansion, args = self.class.find_expansion(v)
        output = if expansion
                   expansion.expand(self, *args)
                 elsif v.respond_to?(:to_s) && v.to_s =~ SUBSTRING_REGEX
                   expand_substring_variables(v)
                 else
                   v
                 end

        if @tool.is_a?(ContextExternalTool) && @tool.use_1_3? && output.is_a?(Numeric)
          output&.to_s
        else
          output
        end
      end
    end

    def enabled_capability_params(enabled_capabilities)
      enabled_capabilities.each_with_object({}) do |capability, hash|
        if (expansion = capability.respond_to?(:to_sym) && self.class.expansions[:"$#{capability}"])
          value = expansion.expand(self)
          hash[expansion.default_name] = value if expansion.default_name.present? && value != "$#{capability}"
        end
      end
    end

    def resource_link_id
      @resource_link_id ||= if @assignment&.submission_types == "external_tool" && @assignment&.line_items.present?
                              if @root_account&.feature_enabled?(:resource_link_uuid_in_custom_substitution)
                                @assignment.line_items.first&.resource_link&.resource_link_uuid
                              else
                                @assignment.line_items.first&.resource_id
                              end
                            elsif @resource_link
                              @resource_link.resource_link_uuid
                            elsif @content_tag&.associated_asset.present?
                              resource_link = @content_tag.associated_asset
                              if resource_link.respond_to?(:resource_link_uuid)
                                resource_link.resource_link_uuid
                              end
                            end
    end

    # This method should be removed when resource_link_uuid_in_custom_substitution is turned on for all
    def resource_link_id_is_present
      @resource_link_id_is_present ||=
        if @assignment&.submission_types == "external_tool"
          if @root_account&.feature_enabled?(:resource_link_uuid_in_custom_substitution)
            resource_link_id.present?
          else
            @assignment&.line_items.present?
          end
        else
          resource_link_id.present?
        end
    end

    # LTI - Custom parameter substitution: ResourceLink.id
    # Returns the LTI value for the resource_link.id property
    # Returns "$ResourceLink.id" otherwise
    register_expansion "ResourceLink.id",
                       [],
                       -> { resource_link_id },
                       -> { resource_link_id_is_present },
                       default_name: "resourcelink_id"

    # LTI - Custom parameter substitution: ResourceLink.description
    # Returns the LTI value for the resource_link.description property
    # Returns "$ResourceLink.description" otherwise
    register_expansion "ResourceLink.description",
                       [],
                       -> { @assignment.description },
                       -> { @assignment && @assignment.description.present? },
                       default_name: "resourcelink_description"

    # LTI - Custom parameter substitution: ResourceLink.title
    # Returns the LTI value for the resource_link.title property
    # Returns "$ResourceLink.title" otherwise
    register_expansion "ResourceLink.title",
                       [],
                       -> { @resource_link&.title || @assignment&.title || lti_helper.tag_from_resource_link(@resource_link)&.title || @context.name },
                       -> { @resource_link || (@assignment && @assignment.title.present?) },
                       default_name: "resourcelink_title"

    # LTI - Custom parameter substitution: ResourceLink.available.startDateTime
    # Returns the ISO 8601 date and time when this resource is available for learners to access
    # Returns "$ResourceLink.available.startDateTime" otherwise
    register_expansion "ResourceLink.available.startDateTime",
                       [],
                       -> { @assignment.unlock_at.iso8601(3) },
                       -> { @assignment && @assignment.unlock_at.present? },
                       default_name: "resourcelink_available_startdatetime"

    # LTI - Custom parameter substitution: ResourceLink.available.endDateTime
    # Returns the ISO 8601 date and time when this resource ceases to be available for learners to access
    # Returns "$ResourceLink.available.endDateTime" otherwise
    register_expansion "ResourceLink.available.endDateTime",
                       [],
                       -> { @assignment.lock_at.iso8601(3) },
                       -> { @assignment && @assignment.lock_at.present? },
                       default_name: "resourcelink_available_enddatetime"

    # LTI - Custom parameter substitution: ResourceLink.submission.endDateTime
    # Returns the ISO 8601 date and time when this resource stops accepting submissions.
    # Returns "$ResourceLink.submission.endDateTime" otherwise
    register_expansion "ResourceLink.submission.endDateTime",
                       [],
                       -> { @assignment.due_at.iso8601(3) },
                       -> { @assignment && @assignment.due_at.present? },
                       default_name: "resourcelink_submission_enddatetime"

    # If the current user is an observer in the launch
    # context, this substitution returns a comma-separated
    # list of user IDs linked to the current user for
    # observing. For LTI 1.3 tools, the user IDs will
    # correspond to the "sub" claim made in LTI 1.3 launches
    # (a UUIDv4), while for all other tools, the user IDs will
    # be the user's typical LTI ID.
    #
    # Returns an empty string otherwise.
    #
    # @launch_parameter com_instructure_user_observees
    # @example
    #   ```
    #    LTI 1.3: "a6e2e413-4afb-4b60-90d1-8b0344df3e91",
    #    All Others: "c0ddd6c90cbe1ef0f32fbce5c3bf654204be186c"
    #   ```
    register_expansion "com.instructure.User.observees",
                       [],
                       lambda {
                         observed_users =
                           ObserverEnrollment.observed_students(@context, @current_user)
                                             .keys
                         if @tool.use_1_3?
                           observed_users.map { |u| u.lookup_lti_id(@context) }.join(",")
                         else
                           observed_users.map { |u| Lti::Asset.opaque_identifier_for(u) }.join(",")
                         end
                       },
                       COURSE_GUARD,
                       default_name: "com_instructure_user_observees"

    # Returns an array of the section names in a JSON-escaped format that the user is enrolled in, if the
    # context of the tool launch is within a course. The names are sorted by the course_section_id, so that
    # they are useful in conjunction with the Canvas.course.sectionIds substitution.
    #
    # @example
    #   ```
    #   [\"Section 1, M-T\", \"Section 2, W-Th\", \"TA Section\"]
    #   ```
    register_expansion "com.instructure.User.sectionNames",
                       [],
                       -> { @context.enrollments.active.joins(:course_section).where(user_id: @current_user.id).order(:course_section_id).pluck(:name)&.to_json },
                       ENROLLMENT_GUARD,
                       default_name: "com_instructure_user_section_names"

    # Returns the host of the rich content service for the current region
    #
    # @example
    #   ```
    #   "rich-content-iad.inscloudgate.net"
    #   ```
    register_expansion "com.instructure.RCS.app_host",
                       [],
                       lambda {
                         Services::RichContent.env_for[:RICH_CONTENT_APP_HOST]
                       },
                       default_name: "com_instructure_rcs_app_host"

    # Returns true if the user is launching from student view.
    #
    # @example
    #   ```
    #   "true"
    #   "false"
    #   ```
    register_expansion "com.instructure.User.student_view",
                       [],
                       -> { @current_user.fake_student? || false },
                       USER_GUARD,
                       default_name: "com_instructure_user_student_view"

    # Returns the RCS Service JWT for the current user
    #
    # @internal
    # @example
    #   ```
    #   "base64-encoded-service-jwt"
    #   ```
    register_expansion "com.instructure.RCS.service_jwt",
                       [],
                       lambda {
                         return "" if @request.nil?

                         @controller.rce_js_env_base[:JWT]
                       },
                       INTERNAL_TOOL_GUARD,
                       default_name: "com_instructure_rcs_service_jwt"

    # Returns instui_nav release flag state
    #
    # @internal
    # @example
    #   ```
    #   "true"
    #   "false"
    #   ```
    register_expansion "com.instructure.instui_nav",
                       [],
                       -> { @root_account.feature_enabled?(:instui_nav) },
                       INTERNAL_TOOL_GUARD,
                       default_name: "com_instructure_instui_nav"

    # returns all observee ids linked to this observer as an String separated by `,`
    # @launch_parameter com_instructure_observee_ids
    # @example
    #   ```
    #   "A123,B456,..."
    #   ```
    register_expansion "com.instructure.Observee.sisIds",
                       [],
                       lambda {
                         observed_users = ObserverEnrollment.observed_students(@context, @current_user).keys
                         observed_users&.filter_map { |user| find_sis_user_id_for(user) }&.join(",")
                       },
                       COURSE_GUARD,
                       default_name: "com_instructure_observee_sis_ids"

    # The title of the context
    # @launch_parameter context_title
    # @example
    #   ```
    #   "Example Course"
    #   ```
    register_expansion "Context.title",
                       [],
                       -> { @context.name },
                       default_name: "context_title"

    # The contents of the text editor associated with the content item launch.
    # @launch_parameter com_instructure_editor_contents
    # @example
    #   ```
    #   "This text was in the editor"
    #   ```
    register_expansion "com.instructure.Editor.contents",
                       [],
                       -> { @editor_contents },
                       EDITOR_GUARD,
                       default_name: "com_instructure_editor_contents"

    # The contents the user has selected in the text editor associated
    # with the content item launch.
    # @launch_parameter com_instructure_editor_selection
    # @example
    #   ```
    #   "this text was selected by the user"
    #   ```
    register_expansion "com.instructure.Editor.selection",
                       [],
                       -> { @editor_selection },
                       EDITOR_GUARD,
                       default_name: "com_instructure_editor_selection"

    # A token that can be used for frontend communication between an LTI tool
    # and Canvas via the Window.postMessage API
    # @launch_parameter com_instructure_post_message_token
    # @example
    #   ```
    #   "9ae4170c-6b64-444d-9246-0b7dedd5f560"
    #   ```
    register_expansion "com.instructure.PostMessageToken",
                       [],
                       -> { @post_message_token || @launch.post_message_token },
                       MESSAGE_TOKEN_GUARD,
                       default_name: "com_instructure_post_message_token"

    # The LTI assignment id of an assignment. This value corresponds with
    # the `ext_lti_assignment_id` send in various launches and webhooks.
    # @launch_parameter com_instructure_assignment_lti_id
    # @example
    #   ```
    #   "9ae4170c-6b64-444d-9246-0b7dedd5f560"
    #   ```
    register_expansion "com.instructure.Assignment.lti.id",
                       [],
                       lambda {
                         if @assignment
                           @assignment.lti_context_id
                         elsif @originality_report
                           @originality_report.submission.assignment.lti_context_id
                         elsif @secure_params.present?
                           Lti::Security.decoded_lti_assignment_id(@secure_params)
                         end
                       },
                       LTI_ASSIGN_ID,
                       default_name: "com_instructure_assignment_lti_id"

    # The LTI assignment description of an assignment.
    # @launch_parameter com_instructure_assignment_lti_description
    # @example
    #   ```
    #   "Example Description"
    #   ```
    register_expansion "com.instructure.Assignment.description",
                       [],
                       lambda {
                         if @assignment
                           @assignment.lti_safe_description
                         elsif @originality_report
                           @originality_report.submission.assignment.lti_safe_description
                         elsif @secure_params.present?
                           Lti::Security.decoded_lti_assignment_description(@secure_params)
                         end
                       },
                       LTI_ASSIGN_DESCRIPTION,
                       default_name: "com_instructure_assignment_description"

    # A comma separated list of the file extensions that are allowed for submitting to this
    # assignment. If there are no limits on what files can be uploaded, an empty string will be
    # returned. If the assignment does not allow file uploads as a submission type, then no
    # substitution will be performed.
    #
    # @launch_parameter com_instructure_originality_report_id
    # @example
    #   ```
    #   "docx,pdf,txt"
    #   ```
    register_expansion "com.instructure.Assignment.allowedFileExtensions",
                       [],
                       -> { @assignment.allowed_extensions.join(",") },
                       FILE_UPLOAD_GUARD,
                       default_name: "com_instructure_assignment_allowed_file_extensions"

    # The Canvas id of the Originality Report associated
    # with the launch.
    # @launch_parameter com_instructure_originality_report_id
    # @example
    #   ```
    #   23
    #   ```
    register_expansion "com.instructure.OriginalityReport.id",
                       [],
                       lambda {
                         @originality_report.id
                       },
                       ORIGINALITY_REPORT_GUARD,
                       default_name: "com_instructure_originality_report_id"

    # The Canvas id of the submission associated with the
    # launch.
    # @launch_parameter com_instructure_submission_id
    # @example
    #   ```
    #   23
    #   ```
    register_expansion "com.instructure.Submission.id",
                       [],
                       -> { @originality_report.submission.id },
                       ORIGINALITY_REPORT_GUARD,
                       default_name: "com_instructure_submission_id"

    # The Canvas id of the file associated with the submission
    # in the launch.
    # @launch_parameter com_instructure_file_id
    # @example
    #   ```
    #   23
    #   ```
    register_expansion "com.instructure.File.id",
                       [],
                       -> { @originality_report.attachment.id },
                       ORIGINALITY_REPORT_ATTACHMENT_GUARD,
                       default_name: "com_instructure_file_id"

    # the LIS identifier for the course offering
    # @launch_parameter lis_course_offering_sourcedid
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion "CourseOffering.sourcedId",
                       [],
                       -> { @context.sis_source_id },
                       COURSE_GUARD,
                       default_name: "lis_course_offering_sourcedid"

    # an opaque identifier that uniquely identifies the context of the tool launch
    # @launch_parameter context_id
    # @example
    #   ```
    #   "cdca1fe2c392a208bd8a657f8865ddb9ca359534"
    #   ```
    register_expansion "Context.id",
                       [],
                       -> { Lti::Asset.opaque_identifier_for(@context) },
                       default_name: "context_id"

    # The Canvas global identifier for the launch context
    # @example
    #   ```
    #   10000000000070
    #   ```
    register_expansion "com.instructure.Context.globalId",
                       [],
                       -> { @context&.global_id }

    # The Canvas UUID for the launch context
    # @example
    #   ```
    #   4TVeERS266frWLG5RVK0L8BbSC831mUZHaYpK4KP
    #   ```
    register_expansion "com.instructure.Context.uuid",
                       [],
                       -> { @context.uuid },
                       -> { @context&.respond_to?(:uuid) }

    # If the context is a Course, returns sourced Id of the context
    # @example
    #   ```
    #   1234
    #   ```
    #
    # If the placement is :user_navigation, it works like $Person.sourcedId: returns the sis source id for the primary
    # pseudonym for the user for the account
    # This may not be the pseudonym the user is actually logged in with.
    # @duplicates Person.sourcedId
    # @example
    #   ```
    #   "sis_user_42"
    #   ```
    register_expansion "Context.sourcedId",
                       [],
                       lambda {
                         if @context.is_a? User
                           sis_pseudonym.sis_user_id
                         else
                           @context.sis_source_id
                         end
                       },
                       -> { @context.is_a?(Course) || (@placement == :user_navigation && @context.is_a?(User) && sis_pseudonym) }

    # Returns a string with a comma-separated list of the context ids of the
    # courses in reverse chronological order from which content has been copied.
    # Will show a limit of 1000 context ids.  When the number passes 1000,
    # 'truncated' will show at the end of the list.
    # @example
    #   ```
    #   "789,456,123"
    #   ```
    register_expansion "Context.id.history",
                       [],
                       -> { lti_helper.recursively_fetch_previous_lti_context_ids },
                       COURSE_GUARD

    # communicates the kind of browser window/frame where the Canvas has launched a tool
    # @launch_parameter launch_presentation_document_target
    # @example
    #   ```
    #   "iframe"
    #   ```
    register_expansion "Message.documentTarget",
                       [],
                       -> { ::IMS::LTI::Models::Messages::Message::LAUNCH_TARGET_IFRAME },
                       default_name: "launch_presentation_document_target"

    # returns the current locale
    # @launch_parameter launch_presentation_locale
    # @example
    #   ```
    #   "de"
    #   ```
    register_expansion "Message.locale",
                       [],
                       -> { I18n.locale || I18n.default_locale },
                       default_name: "launch_presentation_locale"

    # returns a unique identifier for the Tool Consumer (Canvas)
    # @launch_parameter tool_consumer_instance_guid
    # @example
    #   ```
    #   "0dWtgJjjFWRNT41WdQMvrleejGgv7AynCVm3lmZ2:canvas-lms"
    #   ```
    register_expansion "ToolConsumerInstance.guid",
                       [],
                       -> { @root_account.lti_guid },
                       default_name: "tool_consumer_instance_guid"

    # returns the canvas domain for the current context.
    # @example
    #   ```
    #   "canvas.instructure.com"
    #   ```
    register_expansion "Canvas.api.domain",
                       [],
                       -> { HostUrl.context_host(@root_account, @request.host) },
                       CONTROLLER_GUARD

    # returns the api url for the members of the collaboration
    # @example
    #  ```
    #  "https://canvas.instructure.com/api/v1/collaborations/1/members"
    #  ```
    register_expansion "Canvas.api.collaborationMembers.url",
                       [],
                       -> { @controller.api_v1_collaboration_members_url(@collaboration) },
                       CONTROLLER_GUARD,
                       COLLABORATION_GUARD
    # returns the base URL for the current context.
    # @example
    #   ```
    #   "https://canvas.instructure.com"
    #   ```
    register_expansion "Canvas.api.baseUrl",
                       [],
                       -> { "#{@request.scheme}://#{HostUrl.context_host(@root_account, @request.host)}" },
                       CONTROLLER_GUARD

    # returns the URL for the membership service associated with the current context.
    #
    # This variable is for future use only. Complete support for the IMS Membership Service has not been added to Canvas. This will be updated when we fully support and certify the IMS Membership Service.
    # @example
    #   ```
    #   "https://canvas.instructure.com/api/lti/courses/1/membership_service"
    #   ```
    register_expansion "ToolProxyBinding.memberships.url",
                       [],
                       -> { @controller.polymorphic_url([@context, :membership_service]) },
                       CONTROLLER_GUARD,
                       -> { @context.is_a?(Course) || @context.is_a?(Group) }

    # returns the account id for the current context.
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion "Canvas.account.id",
                       [],
                       -> { lti_helper.account.id }

    # returns the account name for the current context.
    # @example
    #   ```
    #   "School Name"
    #   ```
    register_expansion "Canvas.account.name",
                       [],
                       -> { lti_helper.account.name }

    # returns the account's sis source id for the current context.
    # @example
    #   ```
    #   "sis_account_id_1234"
    #   ```
    register_expansion "Canvas.account.sisSourceId",
                       [],
                       -> { lti_helper.account.sis_source_id }

    # returns the Root Account ID for the current context.
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion "Canvas.rootAccount.id",
                       [],
                       -> { @root_account.id }

    # returns the root account's sis source id for the current context.
    # @example
    #   ```
    #   "sis_account_id_1234"
    #   ```
    register_expansion "Canvas.rootAccount.sisSourceId",
                       [],
                       -> { @root_account.sis_source_id }

    # returns the global ID for the external tool that was launched. Only available for LTI 1.
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion "Canvas.externalTool.global_id",
                       [],
                       -> { @tool.global_id },
                       CONTROLLER_GUARD,
                       LTI1_GUARD

    # returns the URL for the external tool that was launched. Only available for LTI 1.
    # @example
    #   ```
    #   "http://example.url/path"
    #   ```
    register_expansion "Canvas.externalTool.url",
                       [],
                       lambda {
                         @controller.named_context_url(@tool.context,
                                                       :api_v1_context_external_tools_update_url,
                                                       @tool.id,
                                                       include_host: true)
                       },
                       CONTROLLER_GUARD,
                       LTI1_GUARD

    # returns the URL to retrieve the brand config JSON for the launching context.
    # @example
    #   ```
    #   "http://example.url/path.json"
    #   ```
    register_expansion "com.instructure.brandConfigJSON.url",
                       [],
                       -> { @controller.active_brand_config_url("json") },
                       CONTROLLER_GUARD

    # returns the brand config JSON itself for the launching context.
    # @example
    #   ```
    #   {"ic-brand-primary-darkened-5":"#0087D7"}
    #   ```
    register_expansion "com.instructure.brandConfigJSON",
                       [],
                       -> { @controller.active_brand_config.try(:to_json) },
                       CONTROLLER_GUARD

    # returns the URL to retrieve the brand config javascript for the launching context.
    # This URL should be used as the src attribute for a script tag on the external tool
    # provider's web page. It is configured to be used with the [instructure-ui node module](https://github.com/instructure/instructure-ui).
    # More information on on how to use instructure ui react components can be found [here](http://instructure.github.io/instructure-ui/).
    # @example
    #   ```
    #   "http://example.url/path.js"
    #   ```
    register_expansion "com.instructure.brandConfigJS.url",
                       [],
                       -> { @controller.active_brand_config_url("js") },
                       CONTROLLER_GUARD

    # returns the URL for the common css file.
    # @example
    #   ```
    #   "http://example.url/path.css"
    #   ```
    register_expansion "Canvas.css.common",
                       [],
                       lambda {
                         URI.parse(@request.url)
                            .merge(@controller.view_context.stylesheet_path(@controller.css_url_for(:common))).to_s
                       },
                       CONTROLLER_GUARD

    # returns the shard id for the current context.
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion "Canvas.shard.id",
                       [],
                       -> { Shard.current.id }

    # returns the root account's global id for the current context.
    # @duplicates Canvas.user.globalId
    # @example
    #   ```
    #   123400000000123
    #   ```
    register_expansion "Canvas.root_account.global_id",
                       [],
                       -> { @root_account.global_id }

    # returns the root account id for the current context.
    # @deprecated
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion "Canvas.root_account.id",
                       [],
                       -> { @root_account.id }

    # returns the account uuid for the current context.
    # @example
    #   ```
    #   "Ioe3sJPt0KZp9Pw6xAvcHuLCl0z4TvPKP0iIOLbo"
    #   ```
    register_expansion "vnd.Canvas.root_account.uuid",
                       [],
                       -> { @root_account.uuid },
                       default_name: "vnd_canvas_root_account_uuid"

    # returns the root account sis source id for the current context.
    # @deprecated
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion "Canvas.root_account.sisSourceId",
                       [],
                       -> { @root_account.sis_source_id }

    # returns the current course id.
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion "Canvas.course.id",
                       [],
                       -> { @context.id },
                       COURSE_GUARD

    # returns the current course uuid.
    # @example
    #   ```
    #   "S3vhRY2pBzG8iPdZ3OBPsPrEnqn5sdRoJOLXGbwc"
    #   ```
    register_expansion "vnd.instructure.Course.uuid",
                       [],
                       -> { @context.uuid },
                       COURSE_GUARD

    # returns the current course name.
    # @example
    #   ```
    #   "Course Name"
    #   ```
    register_expansion "Canvas.course.name",
                       [],
                       -> { @context.name },
                       COURSE_GUARD

    # returns the current course sis source id.
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion "Canvas.course.sisSourceId",
                       [],
                       -> { @context.sis_source_id },
                       COURSE_GUARD

    # returns the current course integration id.
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion "com.instructure.Course.integrationId",
                       [],
                       -> { @context.integration_id },
                       COURSE_GUARD

    # returns the current course start date.
    # @example
    #   ```
    #   2018-01-15 00:00:00 -0700
    #   ```
    register_expansion "Canvas.course.startAt",
                       [],
                       -> { @context.start_at },
                       COURSE_GUARD

    # returns the current course end date.
    # @example
    #   ```
    #   2018-05-01 00:00:00 -0700
    #   ```
    register_expansion "Canvas.course.endAt",
                       [],
                       -> { @context.end_at },
                       COURSE_GUARD

    # returns the current course workflow state. Workflow states of "claimed" or "created"
    # indicate an unpublished course.
    # @example
    #   ```
    #   "active"
    #   ```
    register_expansion "Canvas.course.workflowState",
                       [],
                       -> { @context.workflow_state },
                       COURSE_GUARD

    # returns true if the current course has the setting "Hide grade distribution graphs from students" enabled
    # @internal
    register_expansion "Canvas.course.hideDistributionGraphs",
                       [],
                       -> { @context.hide_distribution_graphs? },
                       COURSE_GUARD

    # returns grade passback setting for the course.
    # @internal
    register_expansion "Canvas.course.gradePassbackSetting",
                       [],
                       -> { @context.grade_passback_setting },
                       COURSE_GUARD

    # returns the current course's term start date.
    # @example
    #   ```
    #   2018-01-12 00:00:00 -0700
    #   ```
    register_expansion "Canvas.term.startAt",
                       [],
                       -> { @context.enrollment_term.start_at },
                       TERM_START_DATE_GUARD

    # returns the current course's term end date.
    # @example
    #   ```
    #   2018-01-12 00:00:00 -0700
    #   ```
    register_expansion "Canvas.term.endAt",
                       [],
                       -> { @context.enrollment_term.end_at },
                       TERM_END_DATE_GUARD

    # returns the current course's term name.
    # @example
    #   ```
    #   "W1 2017"
    #   ```
    register_expansion "Canvas.term.name",
                       [],
                       -> { @context.enrollment_term.name },
                       TERM_NAME_GUARD,
                       default_name: "canvas_term_name"

    # returns the current course's term numerical id.
    # @example
    #   ```
    #   123
    #   ```
    register_expansion "Canvas.term.id",
                       [],
                       -> { @context.enrollment_term_id },
                       TERM_ID_GUARD,
                       default_name: "canvas_term_id"

    # returns the current course sis source id
    # to return the section source id use Canvas.course.sectionIds
    # @launch_parameter lis_course_section_sourcedid
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion "CourseSection.sourcedId",
                       [],
                       -> { @context.sis_source_id },
                       COURSE_GUARD,
                       default_name: "lis_course_section_sourcedid"

    # returns the current course enrollment state
    # @example
    #   ```
    #   "active"
    #   ```
    register_expansion "Canvas.enrollment.enrollmentState",
                       [],
                       -> { lti_helper.enrollment_state },
                       COURSE_GUARD

    # returns true if the assignment has anonymous grading
    # enabled.
    # @example
    #   ```
    #   true
    #   ```
    register_expansion "com.instructure.Assignment.anonymous_grading",
                       [],
                       -> { @assignment.anonymous_grading },
                       ASSIGNMENT_GUARD,
                       default_name: "com_instructure_assignment_anonymous_grading"

    # returns true if the assignment restricts quantitative data.
    # Assignment types: points, percentage, gpa_scale are all considered quantitative.
    # @example
    #   ```
    #   true
    #   ```
    register_expansion "com.instructure.Assignment.restrict_quantitative_data",
                       [],
                       -> { @assignment.restrict_quantitative_data?(@current_user)&.to_s },
                       ASSIGNMENT_GUARD,
                       default_name: "com_instructure_assignment_restrict_quantitative_data"

    # returns the grading scheme data for the course
    # it is an array of objects of grade levels
    # @example
    #  ```
    #  [
    #    {name: "A", value: 94.0},
    #    {name: "A-", value: 90.0},
    #    {name: "B+", value: 87.0},
    #  ]
    #  ```
    register_expansion "com.instructure.Course.gradingScheme",
                       [],
                       -> { @context.grading_standard_or_default.data.map { |grading_standard_data_row| { name: grading_standard_data_row[0], value: grading_standard_data_row[1] } }.to_json },
                       COURSE_GUARD,
                       default_name: "com_instructure_course_grading_scheme"

    # returns the current course membership roles
    # using the LIS v2 vocabulary.
    # @example
    #   ```
    #   "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Student"
    #   ```
    register_expansion "com.Instructure.membership.roles",
                       [],
                       -> { lti_helper.current_canvas_roles_lis_v2(lti_1_3? ? "lti1_3" : "lis2") },
                       ROLES_GUARD,
                       default_name: "com_instructure_membership_roles"

    # returns the current course membership roles
    # @example
    #   ```
    #   "StudentEnrollment"
    #   ```
    register_expansion "Canvas.membership.roles",
                       [],
                       -> { lti_helper.current_canvas_roles },
                       ROLES_GUARD,
                       default_name: "canvas_membership_roles"

    # This is a list of IMS LIS roles should have a different key
    # @example
    #   ```
    #   "urn:lti:sysrole:ims/lis/None"
    #   ```
    register_expansion "Canvas.membership.concludedRoles",
                       [],
                       -> { lti_helper.concluded_lis_roles },
                       COURSE_GUARD

    # Returns a comma-separated list of permissions granted to the user in the current context,
    # given a comma-separated set to check using the format
    # $Canvas.membership.permissions<example_permission,example_permission2,..>
    # @internal
    # @example
    #   ```
    #   "example_permission_1,example_permission_2"
    #   ```
    register_expansion "Canvas.membership.permissions<>",
                       [],
                       ->(permissions_str) { lti_helper.granted_permissions(permissions_str.split(",")) },
                       ROLES_GUARD

    # With respect to the current course, returns the context ids of the courses from which content has been copied (excludes cartridge imports).
    #
    # @example
    #   ```
    #   "1234,4567"
    #   ```
    register_expansion "Canvas.course.previousContextIds",
                       [],
                       -> { lti_helper.previous_lti_context_ids },
                       COURSE_GUARD

    # With respect to the current course, recursively returns the context ids of the courses from which content has been copied (excludes cartridge imports).
    # Will show a limit of 1000 context ids.  When the number passes 1000, 'truncated' will show at the end of the list.
    #
    # @example
    #   ```
    #   "1234,4567"
    #   ```
    register_expansion "Canvas.course.previousContextIds.recursive",
                       [],
                       -> { lti_helper.recursively_fetch_previous_lti_context_ids },
                       COURSE_GUARD

    # With respect to the current course, returns the course ids of the courses from which content has been copied (excludes cartridge imports).
    #
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion "Canvas.course.previousCourseIds",
                       [],
                       -> { lti_helper.previous_course_ids },
                       COURSE_GUARD

    # Returns the full name of the launching user.
    # @launch_parameter lis_person_name_full
    # @example
    #   ```
    #   "John Doe"
    #   ```
    register_expansion "Person.name.full",
                       [],
                       -> { @current_user.name },
                       USER_GUARD,
                       default_name: "lis_person_name_full"

    # Returns the display name of the launching user.
    # @launch_parameter lis_person_name_full
    # @example
    #   ```
    #   "John Doe"
    #   ```
    register_expansion "Person.name.display",
                       [],
                       -> { @current_user.short_name },
                       USER_GUARD,
                       default_name: "person_name_display"

    # Returns the last name of the launching user.
    # @launch_parameter lis_person_name_family
    # @example
    #   ```
    #   "Doe"
    #   ```
    register_expansion "Person.name.family",
                       [],
                       -> { @current_user.last_name },
                       USER_GUARD,
                       default_name: "lis_person_name_family"

    # Returns the first name of the launching user.
    # @launch_parameter lis_person_name_given
    # @example
    #   ```
    #   "John"
    #   ```
    register_expansion "Person.name.given",
                       [],
                       -> { @current_user.first_name },
                       USER_GUARD,
                       default_name: "lis_person_name_given"

    # Returns the sortable name of the launching user.
    # @launch_parameter com_instructure_person_name_sortable
    # @example
    #   ```
    #   "Doe, John"
    #   ```
    register_expansion "com.instructure.Person.name_sortable",
                       [],
                       -> { @current_user.sortable_name },
                       USER_GUARD,
                       default_name: "com_instructure_person_name_sortable"

    # Returns the primary email of the launching user.
    # @launch_parameter lis_person_contact_email_primary
    # @example
    #   ```
    #   "john.doe@example.com"
    #   ```
    register_expansion "Person.email.primary",
                       [],
                       -> { lti_helper.email },
                       USER_GUARD,
                       default_name: "lis_person_contact_email_primary"

    # Returns pronouns for the current user
    # @example
    #   ```
    #   "She/Her"
    #   ```
    register_expansion "com.instructure.Person.pronouns",
                       [],
                       -> { @current_user.pronouns },
                       USER_GUARD,
                       default_name: "com_instructure_person_pronouns"

    # Returns the institution assigned email of the launching user.
    # @example
    #   ```
    #   "john.doe@example.com"
    #   ```
    register_expansion "vnd.Canvas.Person.email.sis",
                       [],
                       -> { lti_helper.sis_email },
                       SIS_USER_GUARD

    # Returns the name of the timezone of the launching user.
    # @example
    #   ```
    #   "America/Denver"
    #   ```
    register_expansion "Person.address.timezone",
                       [],
                       -> { Time.zone.tzinfo.name },
                       USER_GUARD

    # Returns the profile picture URL of the launching user.
    # @launch_parameter user_image
    # @example
    #   ```
    #   "https://example.com/picture.jpg"
    #   ```
    register_expansion "User.image",
                       [],
                       -> { @current_user.avatar_url },
                       USER_GUARD,
                       default_name: "user_image"

    # Returns the Canvas user_id of the launching user.
    # @duplicates Canvas.user.id
    # @launch_parameter user_id
    # @example
    #   ```
    #   420000000000042
    #   ```
    register_expansion "User.id",
                       [],
                       -> { @current_user.id },
                       USER_GUARD,
                       default_name: "user_id"

    # Returns the Canvas user_id of the launching user.
    # @duplicates User.id
    # @example
    #   ```
    #   420000000000042
    #   ```
    register_expansion "Canvas.user.id",
                       [],
                       -> { @current_user.id },
                       USER_GUARD

    # Returns the Canvas user_uuid of the launching user for the context.
    # @duplicates User.uuid
    # @example
    #   ```
    #   "N2ST123dQ9zyhurykTkBfXFa3Vn1RVyaw9Os6vu3"
    #   ```
    register_expansion "vnd.instructure.User.uuid",
                       [],
                       -> { UserPastLtiId.uuid_for_user_in_context(@current_user, @context) },
                       USER_GUARD

    # Returns the current Canvas user_uuid of the launching user.
    # @duplicates User.uuid
    # @example
    #   ```
    #   "N2ST123dQ9zyhurykTkBfXFa3Vn1RVyaw9Os6vu3"
    #   ```
    register_expansion "vnd.instructure.User.current_uuid",
                       [],
                       -> { @current_user.uuid },
                       USER_GUARD

    # Returns the users preference for high contrast colors (an accessibility feature).
    # @example
    #   ```
    #   false
    #   ```
    register_expansion "Canvas.user.prefersHighContrast",
                       [],
                       -> { @current_user.prefers_high_contrast? ? "true" : "false" },
                       USER_GUARD

    # returns the Canvas ids of all active groups in the current course.
    # @example
    #   ```
    #   "23,24,..."
    #   ```
    register_expansion "com.instructure.Course.groupIds",
                       [],
                       -> { @context.groups.active.pluck(:id).join(",") },
                       COURSE_GUARD,
                       default_name: "com_instructure_course_groupids"

    # returns the context ids for the groups the user belongs to in the course.
    # @example
    #   ```
    #   "1c16f0de65a080803785ecb3097da99872616f0d,d4d8d6ae1611e2c7581ce1b2f5c58019d928b79d,..."
    #   ```
    register_expansion "Canvas.group.contextIds",
                       [],
                       lambda {
                         @current_user.groups.active.where(context_type: "Course", context_id: @context.id).map do |g|
                           Lti::Asset.opaque_identifier_for(g)
                         end.join(",")
                       },
                       -> { @current_user && @context.is_a?(Course) }

    # Returns the [IMS LTI membership service](https://www.imsglobal.org/specs/ltimemv1p0/specification-3) roles for filtering via query parameters.
    # Or, for LTI 1.3 tools, returns the [IMS LTI Names and Role Provisioning Service](https://www.imsglobal.org/spec/lti-nrps/v2p0) roles for filtering via query parameters.
    # @launch_parameter roles
    # @example
    #   ```
    #   "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator"
    #   ```
    register_expansion "Membership.role",
                       [],
                       -> { lti_helper.all_roles(lti_1_3? ? "lti1_3" : "lis2") },
                       USER_GUARD,
                       default_name: "roles"

    # Returns list of [LIS role full URNs](https://www.imsglobal.org/specs/ltiv1p0/implementation-guide#toc-16).
    # Note that this will include all roles the user has.
    # There are 3 different levels of roles defined: Context, Institution, System.
    # Context role urns start with "urn:lti:ims" and include roles for the context where the launch occurred.
    # Institution role urns start with "urn:lti:instrole" and include roles the user has in the institution. This
    # will include roles they have in other courses or at the account level. Note that there is not a TA role at the
    # Institution level. Instead Users with a TA enrollment will have an institution role of Instructor.
    # System role urns start with "urn:lti:sysrole" and include roles for the entire system.
    # @duplicates ext_roles which is sent by default
    # @example
    #   ```
    #   "urn:lti:instrole:ims/lis/Administrator,urn:lti:instrole:ims/lis/Instructor,urn:lti:sysrole:ims/lis/SysAdmin,urn:lti:sysrole:ims/lis/User"
    #   ```
    register_expansion "Canvas.xuser.allRoles",
                       [],
                       -> { lti_helper.all_roles }

    # Same as "Canvas.xuser.allRoles", but uses roles formatted for LTI Advantage
    # @example
    #   ```
    #    "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Student",
    #    "http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor",
    #    "http://purl.imsglobal.org/vocab/lis/v2/system/person#User"
    #   ```
    register_expansion "com.instructure.User.allRoles",
                       [],
                       -> { lti_helper.all_roles("lti1_3") }

    # Returns the Canvas global user_id of the launching user.
    # @duplicates Canvas.root_account.global_id
    # @example
    #   ```
    #   420000000000042
    #   ```
    register_expansion "Canvas.user.globalId",
                       [],
                       -> { @current_user.global_id },
                       USER_GUARD

    # Returns true for root account admins and false for all other roles.
    # @example
    #   ```
    #   true
    #   ```
    register_expansion "Canvas.user.isRootAccountAdmin",
                       [],
                       -> { @current_user.roles(@root_account).include? "root_admin" },
                       USER_GUARD

    # Returns a string with a comma-separated list of the (local) account IDs
    # that a user has admin rights in, which fall under the root account that
    # the tool was launched under. This list includes the IDs of
    # all subaccounts of these accounts (and their subaccounts, etc.), since
    # the admin privileges carry from an account to all its subaccounts.
    #
    # Will show a limit of 40000 characters. If the account IDs list is too big
    # to fit into 40000 characters, 'truncated' will show at the end of the
    # list.
    #
    # @example
    #   ```
    #   123,456,798
    #   123,456,789,1234,truncated
    #   ```
    register_expansion "Canvas.user.adminableAccounts",
                       [],
                       -> { lti_helper.adminable_account_ids_recursive_truncated },
                       USER_GUARD

    # Username/Login ID for the primary pseudonym for the user for the account.
    # This may not be the pseudonym the user is actually logged in with.
    # @duplicates Canvas.user.loginId
    # @example
    #   ```
    #   "jdoe"
    #   ```
    register_expansion "User.username",
                       [],
                       -> { sis_pseudonym.unique_id },
                       PSEUDONYM_GUARD

    # Username/Login ID for the primary pseudonym for the user for the account.
    # This may not be the pseudonym the user is actually logged in with.
    # @duplicates User.username
    # @example
    #   ```
    #   "jdoe"
    #   ```
    register_expansion "Canvas.user.loginId",
                       [],
                       -> { sis_pseudonym.unique_id },
                       PSEUDONYM_GUARD

    # Returns the sis source id for the primary pseudonym for the user for the account
    # This may not be the pseudonym the user is actually logged in with.
    # @duplicates Person.sourcedId
    # @example
    #   ```
    #   "sis_user_42"
    #   ```
    register_expansion "Canvas.user.sisSourceId",
                       [],
                       -> { sis_pseudonym.sis_user_id },
                       PSEUDONYM_GUARD

    # Returns the integration id for the primary pseudonym for the user for the account
    # This may not be the pseudonym the user is actually logged in with.
    # @example
    #   ```
    #   "integration_user_42"
    #   ```
    register_expansion "Canvas.user.sisIntegrationId",
                       [],
                       -> { sis_pseudonym.integration_id },
                       PSEUDONYM_GUARD

    # Returns the sis source id for the primary pseudonym for the user for the account
    # This may not be the pseudonym the user is actually logged in with.
    # @duplicates Canvas.user.sisSourceId
    # @example
    #   ```
    #   "sis_user_42"
    #   ```
    register_expansion "Person.sourcedId",
                       [],
                       -> { sis_pseudonym.sis_user_id },
                       PSEUDONYM_GUARD,
                       default_name: "lis_person_sourcedid"

    # Returns the logout service url for the user.
    # This is the pseudonym the user is actually logged in as.
    # It may not hold all the sis info needed in other launch substitutions.
    # @example
    #   ```
    #   "https://<domain>.instructure.com/api/lti/v1/logout_service/<external_tool_id>-<user_id>-<current_unix_timestamp>-<opaque_string>"
    #   ```
    register_expansion "Canvas.logoutService.url",
                       [],
                       -> { @controller.lti_logout_service_url(Lti::LogoutService.create_token(@tool, @current_pseudonym)) },
                       CONTROLLER_GUARD,
                       -> { @current_pseudonym && @tool }

    # Returns the Canvas user_id for the masquerading user.
    # This is the pseudonym the user is actually logged in as.
    # It may not hold all the sis info needed in other launch substitutions.
    #
    # @example
    #   ```
    #   420000000000042
    #   ```
    register_expansion "Canvas.masqueradingUser.id",
                       [],
                       -> { @controller.logged_in_user.id },
                       MASQUERADING_GUARD

    # Returns the opaque user_id for the masquerading user. This is the
    # pseudonym the user is actually logged in as. It may not hold all the sis
    # info needed in other launch substitutions.
    #
    # For LTI 1.3 tools, the opaque user IDs are UUIDv4 values (also used in
    # the "sub" claim in LTI 1.3 launches), while for other LTI versions, the
    # user ID will be the user's 40 character opaque LTI id.
    #
    # @example
    #   ```
    #    LTI 1.3: "8b9f8327-aa32-fa90-9ea2-2fa8ef79e0f9",
    #    All Others: "da12345678cb37ba1e522fc7c5ef086b7704eff9"
    #   ```
    register_expansion "Canvas.masqueradingUser.userId",
                       [],
                       lambda {
                         u = @controller.logged_in_user
                         if lti_1_3?
                           u.lookup_lti_id(@context)
                         else
                           @tool.opaque_identifier_for(u, context: @context)
                         end
                       },
                       MASQUERADING_GUARD

    # Returns the xapi url for the user.
    # @example
    #   ```
    #   "https://<domain>.instructure.com/api/lti/v1/xapi/<external_tool_id>-<user_id>-<course_id>-<current_unix_timestamp>-<opaque_id>"
    #   ```
    register_expansion "Canvas.xapi.url",
                       [],
                       -> { @controller.lti_xapi_url(Lti::AnalyticsService.create_token(@tool, @current_user, @context)) },
                       -> { @current_user && @context.is_a?(Course) && @tool }

    # Returns the caliper url for the user.
    # @example
    #   ```
    #   "https://<domain>.instructure.com/api/lti/v1/caliper/<external_tool_id>-<user_id>-<course_id>-<current_unix_timestamp>-<opaque_id>"
    #   ```
    register_expansion "Caliper.url",
                       [],
                       -> { @controller.lti_caliper_url(Lti::AnalyticsService.create_token(@tool, @current_user, @context)) },
                       CONTROLLER_GUARD,
                       -> { @current_user && @context.is_a?(Course) && @tool }

    # Returns a comma separated list of section_id's that the user is enrolled in.
    #
    # @example
    #   ```
    #   "42, 43"
    #   ```
    register_expansion "Canvas.course.sectionIds",
                       [],
                       -> { lti_helper.section_ids },
                       ENROLLMENT_GUARD

    # Returns true if the user can only view and interact with users in their own sections
    #
    # @example
    #   ```
    #   true
    #   ```
    register_expansion "Canvas.course.sectionRestricted",
                       [],
                       -> { lti_helper.section_restricted },
                       ENROLLMENT_GUARD

    # Returns a comma separated list of section sis_id's that the user is enrolled in.
    #
    # @example
    #   ```
    #   "section_sis_id_1, section_sis_id_2"
    #   ```
    register_expansion "Canvas.course.sectionSisSourceIds",
                       [],
                       -> { lti_helper.section_sis_ids },
                       ENROLLMENT_GUARD

    # Returns the course code
    #
    # @example
    #   ```
    #   "CS 124"
    #   ```
    register_expansion "com.instructure.contextLabel",
                       [],
                       -> { @context.course_code },
                       COURSE_GUARD,
                       default_name: "context_label"

    # Returns the module_id that the module item was launched from.
    #
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion "Canvas.module.id",
                       [],
                       lambda {
                         @content_tag.context_module_id
                       },
                       CONTENT_TAG_GUARD

    # Returns the module_item_id of the module item that was launched.
    #
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion "Canvas.moduleItem.id",
                       [],
                       lambda {
                         @content_tag.id
                       },
                       CONTENT_TAG_GUARD

    # Returns the assignment_id of the assignment that was launched.
    #
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion "Canvas.assignment.id",
                       [],
                       -> { @assignment.id },
                       ASSIGNMENT_GUARD

    # Returns the assignment_description of the assignment that was launched.
    #
    # @example
    #   ```
    #   "Example Description"
    #   ```
    register_expansion "Canvas.assignment.description",
                       [],
                       -> { @assignment.lti_safe_description },
                       ASSIGNMENT_GUARD

    # Returns the Canvas id of the group the current user is in if launching
    # from a group assignment.
    #
    # @example
    #   ```
    #   481
    #   ```
    register_expansion "com.instructure.Group.id",
                       [],
                       -> { @assignment.group_category && (@assignment.group_category.groups & @current_user.groups).first&.id },
                       USER_GUARD,
                       ASSIGNMENT_GUARD,
                       default_name: "vnd_canvas_group_id"

    # Returns the name of the group the current user is in if launching
    # from a group assignment.
    #
    # @example
    #   ```
    #   "Group One"
    #   ```
    register_expansion "com.instructure.Group.name",
                       [],
                       -> { @assignment.group_category && (@assignment.group_category.groups & @current_user.groups).first&.name },
                       USER_GUARD,
                       ASSIGNMENT_GUARD,
                       default_name: "vnd_canvas_group_name"

    # Returns the title of the assignment that was launched.
    #
    # @example
    #   ```
    #   "Deep thought experiment"
    #   ```
    register_expansion "Canvas.assignment.title",
                       [],
                       -> { @assignment.title },
                       ASSIGNMENT_GUARD

    # Returns the points possible of the assignment that was launched.
    #
    # @example
    #   ```
    #   100
    #   ```
    register_expansion "Canvas.assignment.pointsPossible",
                       [],
                       -> { TextHelper.round_if_whole(@assignment.points_possible) },
                       ASSIGNMENT_GUARD

    # @deprecated in favor of ISO8601
    register_expansion "Canvas.assignment.unlockAt",
                       [],
                       -> { @assignment.unlock_at },
                       ASSIGNMENT_GUARD

    # @deprecated in favor of ISO8601
    register_expansion "Canvas.assignment.lockAt",
                       [],
                       -> { @assignment.lock_at },
                       ASSIGNMENT_GUARD

    # @deprecated in favor of ISO8601
    register_expansion "Canvas.assignment.dueAt",
                       [],
                       -> { @assignment.due_at },
                       ASSIGNMENT_GUARD

    # Returns the `unlock_at` date of the assignment that was launched.
    # Only available when launched as an assignment with an `unlock_at` set.
    # @example
    #   ```
    #   2018-02-18T00:00:00Z
    #   ```
    register_expansion "Canvas.assignment.unlockAt.iso8601",
                       [],
                       -> { @assignment.unlock_at.utc.iso8601 },
                       -> { @assignment && @assignment.unlock_at.present? }

    # Returns the `lock_at` date of the assignment that was launched.
    # Only available when launched as an assignment with a `lock_at` set.
    #
    # @example
    #   ```
    #   2018-02-20:00:00Z
    #   ```
    register_expansion "Canvas.assignment.lockAt.iso8601",
                       [],
                       -> { @assignment.lock_at.utc.iso8601 },
                       -> { @assignment && @assignment.lock_at.present? }

    # Returns the `due_at` date of the assignment that was launched. Only
    # available when launched as an assignment with a `due_at` set. If the tool
    # is launched as a student, this will be the date that assignment is due
    # for that student (or unexpanded -- "$Canvas.assignment.dueAt.iso8601" --
    # if there is no due date for the student). If the tool is launched as an
    # instructor and there are multiple possible due dates (i.e., there are
    # multiple sections and at least one has a due date override), this will be
    # the LATEST effective due date of any section or student (or unexpanded if
    # there is at least one section or student with no effective due date).
    #
    # @example
    #   ```
    #   2018-02-19:00:00Z
    #   ```
    register_expansion "Canvas.assignment.dueAt.iso8601",
                       [],
                       -> { @assignment.due_at.utc.iso8601 },
                       -> { @assignment && @assignment.due_at.present? }

    # Returns the `due_at` date of the assignment that was launched.
    # If the tool is launched as a student, this will be the date that
    # assignment is due for that student (or an empty string if there is no due
    # date for the student). If the tool is launched as an instructor and different
    # students are assigned multiple due dates (i.e., there are students in sections
    # with overrides / different effective due dates), this will be the
    # EARLIEST due date of any enrollment (or an empty string if there are no
    # enrollments with due dates). Note than like allDueAts, but unlike the dueAt
    # expansion, there must be at least one enrollment in a section for its due
    # date to be considered.
    #
    # @example
    #   ```
    #   2018-02-19:00:00Z
    #   ```
    register_expansion "Canvas.assignment.earliestEnrollmentDueAt.iso8601",
                       [],
                       -> { earliest_due_at&.utc&.iso8601.to_s },
                       ASSIGNMENT_GUARD

    # In Canvas, users, sections and groups can have distinct due dates for the same assignment.
    # This returns all possible `due_at` dates of the assignment that was launched.
    # If the assignment is assigned to anyone without a due date, an empty string
    # will be present in the list (hence the ",," in the example)
    #
    # Only available when launched as an assignment.
    #
    # @example
    #   ```
    #   2018-02-19:00:00Z,,2018-02-20:00:00Z
    #   ```
    register_expansion "Canvas.assignment.allDueAts.iso8601",
                       [],
                       -> { unique_submission_dates.map { |d| d.present? ? d.utc.iso8601 : "" }.join(",") },
                       ASSIGNMENT_GUARD

    # Returns true if the assignment that was launched is published.
    # Only available when launched as an assignment.
    # @example
    #   ```
    #   true
    #   ```
    register_expansion "Canvas.assignment.published",
                       [],
                       -> { @assignment.workflow_state == "published" },
                       ASSIGNMENT_GUARD

    # Returns true if the assignment is LDB enabled.
    # Only available when launched as an assignment.
    # @example
    #   ```
    #   true
    #   ```
    register_expansion "Canvas.assignment.lockdownEnabled",
                       [],
                       -> { !!@controller && @current_user == @controller.logged_in_user && (@assignment.settings&.dig("lockdown_browser", "require_lockdown_browser") || false) },
                       ASSIGNMENT_GUARD

    # Returns the allowed number of submission attempts.
    #
    # @example
    #   ```
    #   5
    #   ```
    register_expansion "Canvas.assignment.allowedAttempts",
                       [],
                       -> { @assignment.allowed_attempts },
                       ASSIGNMENT_GUARD

    # Returns the number of submission attempts which the student did.
    #
    # @example
    #   ```
    #   2
    #   ```
    register_expansion "Canvas.assignment.submission.studentAttempts",
                       [],
                       -> { @assignment.submissions&.find_by(user: @current_user)&.attempt },
                       STUDENT_ASSIGNMENT_GUARD

    # Returns the endpoint url for accessing link-level tool settings
    # Only available for LTI 2.0
    # @example
    #   ```
    #   "https://<domain>.instructure.com/api/lti/tool_settings/<link_id>"
    #   ```
    register_expansion "LtiLink.custom.url",
                       [],
                       -> { @controller.show_lti_tool_settings_url(@tool_setting_link_id) },
                       CONTROLLER_GUARD,
                       -> { @tool_setting_link_id }

    # Returns the endpoint url for accessing context-level tool settings
    # Only available for LTI 2.0
    # @example
    #   ```
    #   "https://<domain>.instructure.com/api/lti/tool_settings/<binding_id>"
    #   ```
    register_expansion "ToolProxyBinding.custom.url",
                       [],
                       -> { @controller.show_lti_tool_settings_url(@tool_setting_binding_id) },
                       CONTROLLER_GUARD,
                       -> { @tool_setting_binding_id }

    # Returns the endpoint url for accessing system-wide tool settings
    # Only available for LTI 2.0
    # @example
    #   ```
    #   "https://<domain>.instructure.com/api/lti/tool_settings/<proxy_id>"
    #   ```
    register_expansion "ToolProxy.custom.url",
                       [],
                       -> { @controller.show_lti_tool_settings_url(@tool_setting_proxy_id) },
                       -> { !!@controller && @tool_setting_proxy_id }

    # Returns the [Tool Consumer Profile](https://www.imsglobal.org/specs/ltiv2p0/implementation-guide#toc-46) url for the tool.
    # Only available for LTI 2.0
    # @example
    #   ```
    #   "https://<domain>.instructure.com/api/lti/courses/<course_id>/tool_consumer_profile/<opaque_id>"
    #   "https://<domain>.instructure.com/api/lti/accounts/<account_id>/tool_consumer_profile/<opaque_id>"
    #   ```
    register_expansion "ToolConsumerProfile.url",
                       [],
                       -> { @controller.polymorphic_url([@tool.context, :tool_consumer_profile]) },
                       CONTROLLER_GUARD,
                       -> { @tool && @tool.is_a?(Lti::ToolProxy) }

    # The originality report LTI2 service endpoint
    # @launch_parameter vnd_canvas_originality_report_url
    # @example
    #   ```
    #   "api/lti/assignments/{assignment_id}/submissions/{submission_id}/originality_report"
    #   ```
    register_expansion "vnd.Canvas.OriginalityReport.url",
                       [],
                       lambda {
                         OriginalityReportsApiController::SERVICE_DEFINITIONS.find do |s|
                           s[:id] == "vnd.Canvas.OriginalityReport"
                         end[:endpoint]
                       },
                       default_name: "vnd_canvas_originality_report_url"

    # The submission LTI2 service endpoint
    # @launch_parameter vnd_canvas_submission_url
    # @example
    #   ```
    #   "api/lti/assignments/{assignment_id}/submissions/{submission_id}"
    #   ```
    register_expansion "vnd.Canvas.submission.url",
                       [],
                       lambda {
                         Lti::SubmissionsApiController::SERVICE_DEFINITIONS.find do |s|
                           s[:id] == "vnd.Canvas.submission"
                         end[:endpoint]
                       },
                       default_name: "vnd_canvas_submission_url"

    # The submission history LTI2 service endpoint
    # @launch_parameter vnd_canvas_submission_history_url
    # @example
    #   ```
    #   "api/lti/assignments/{assignment_id}/submissions/{submission_id}/history"
    #   ```
    register_expansion "vnd.Canvas.submission.history.url",
                       [],
                       lambda {
                         Lti::SubmissionsApiController::SERVICE_DEFINITIONS.find do |s|
                           s[:id] == "vnd.Canvas.submission.history"
                         end[:endpoint]
                       },
                       default_name: "vnd_canvas_submission_history_url"

    register_expansion "Canvas.file.media.id",
                       [],
                       -> { (@attachment.media_object && @attachment.media_object.media_id) || @attachment.media_entry_id },
                       MEDIA_OBJECT_ID_GUARD

    register_expansion "Canvas.file.media.type",
                       [],
                       -> { @attachment.media_object.media_type },
                       MEDIA_OBJECT_GUARD

    register_expansion "Canvas.file.media.duration",
                       [],
                       -> { @attachment.media_object.duration },
                       MEDIA_OBJECT_GUARD

    register_expansion "Canvas.file.media.size",
                       [],
                       -> { @attachment.media_object.total_size },
                       MEDIA_OBJECT_GUARD

    register_expansion "Canvas.file.media.title",
                       [],
                       -> { @attachment.media_object.user_entered_title || @attachment.media_object.title },
                       MEDIA_OBJECT_GUARD

    register_expansion "Canvas.file.usageRights.name",
                       [],
                       -> { @attachment.usage_rights.license_name },
                       USAGE_RIGHTS_GUARD

    register_expansion "Canvas.file.usageRights.url",
                       [],
                       -> { @attachment.usage_rights.license_url },
                       USAGE_RIGHTS_GUARD

    register_expansion "Canvas.file.usageRights.copyrightText",
                       [],
                       -> { @attachment.usage_rights.legal_copyright },
                       USAGE_RIGHTS_GUARD

    # Returns the types of resources that can be imported to the current page, forwarded from the request.
    # Value is a comma-separated array of one or more values of: ["assignment", "assignment_group", "audio",
    # "discussion_topic", "document", "image", "module", "quiz", "page", "video"]
    #
    # Only functional when `com_instructure_course_accept_canvas_resource_types` is included as a query param
    # in Canvas-side GET request that triggers the LTI launch.
    #
    # @example
    #   ```
    #   "page"
    #   "module"
    #   "assignment,discussion_topic,page,quiz,module"
    #   ```
    register_expansion "com.instructure.Course.accept_canvas_resource_types",
                       [],
                       lambda {
                         val = @request.parameters["com_instructure_course_accept_canvas_resource_types"]
                         val.is_a?(Array) ? val.join(",") : val
                       }

    # Returns the target resource type for the current page, forwarded from the request.
    # Value is the largest logical unit of the page. Possible values are: ["assignment", "assignment_group",
    # "audio", "discussion_topic", "document", "image", "module", "quiz", "page", "video"]
    #   on Pages Index -> 'page'
    #   on Modules -> 'module'
    #   and so on.
    #
    # Only functional when `com_instructure_course_canvas_resource_type` is included as a query param
    # in Canvas-side GET request that triggers the LTI launch.
    #
    # @example
    #   ```
    #   page
    #   ```
    register_expansion "com.instructure.Course.canvas_resource_type",
                       [],
                       -> { @request.parameters["com_instructure_course_canvas_resource_type"] }

    # Returns the target resource id for the current page, forwarded from the request. Only functional when
    # `com_instructure_course_canvas_resource_type` is included as a query param. Currently, this is not
    # supported generally, and is only implemented for specific use cases.
    #
    # @example
    #   ```
    #   123123
    #   ```
    register_expansion "com.instructure.Course.canvas_resource_id",
                       [],
                       -> { @request.parameters["com_instructure_course_canvas_resource_id"] }

    # Returns whether a content can be imported into a specific group on the page, forwarded from the request.
    # True for Modules page and Assignment Groups page. False for other content index pages.
    #
    # Only functional when `com_instructure_course_allow_canvas_resource_selection` is included as a query param
    # in Canvas-side GET request that triggers the LTI launch.
    #
    # @example
    #   ```
    #   true
    #   ```
    register_expansion "com.instructure.Course.allow_canvas_resource_selection",
                       [],
                       -> { @request.parameters["com_instructure_course_allow_canvas_resource_selection"] }

    # Returns a JSON-encoded list of content groups which can be selected, providing ID and name of each group,
    # forwarded from the request.
    # Empty value if com.instructure.Course.allow_canvas_resource_selection is false.
    #
    # Only functional when `com_instructure_course_available_canvas_resources` is included as a query param
    # in Canvas-side GET request that triggers the LTI launch.
    #
    # @example
    #   ```
    #   [{"id":"3","name":"First Module"},{"id":"5","name":"Second Module"}]
    #   ```
    register_expansion "com.instructure.Course.available_canvas_resources",
                       [],
                       lambda {
                         val = @request.parameters["com_instructure_course_available_canvas_resources"]
                         val = val.values if val.is_a?(Hash)
                         if val&.count == 1 && (course_id = val.first["course_id"])
                           # replace with the data here because it's too much to pass in via the launch url
                           case val.first["type"]
                           when "module"
                             val = Course.find(course_id).modules_visible_to(@current_user).pluck(:id, :name)
                                         .map { |id, name| { "id" => id, "name" => name } }
                           when "assignment_group"
                             val = Course.find(course_id).assignment_groups.active.pluck(:id, :name)
                                         .map { |id, name| { "id" => id, "name" => name } }
                           end
                         end
                         val&.to_json
                       }

    register_expansion "com.instructure.Account.usage_metrics_enabled",
                       [],
                       lambda {
                         @root_account.feature_enabled?(:send_usage_metrics)
                       }

    private

    def unique_submission_dates
      @assignment.submissions.pluck(:cached_due_date).uniq
    end

    def earliest_due_at
      context = @assignment.context
      # Mirrors logic in AssignmentOverrideApplicator to determine if user is a student or teacher.
      # If a user is a student, we return their due date. Otherwise, in our case here, we return
      # the earliest of all due dates for the assignment.
      if context.user_has_been_admin?(current_user) || (context.user_has_no_enrollments?(current_user) &&
                                               context.grants_any_right?(current_user, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS))
        @assignment.submissions.minimum(:cached_due_date)
      else
        @assignment.due_at
      end
    end

    def sis_pseudonym
      context = @enrollment || @context
      @sis_pseudonym ||= SisPseudonym.for(@current_user, context, type: :trusted, require_sis: false, root_account: @root_account) if @current_user
    end

    def find_sis_user_id_for(user)
      context = @enrollment || @context
      SisPseudonym.for(user, context, type: :trusted, require_sis: false, root_account: @root_account)&.sis_user_id
    end

    def expand_substring_variables(value)
      value.to_s.scan(SUBSTRING_REGEX).inject(value) do |v, match|
        substring = "${#{match}}"
        v.gsub(substring, (self[match] || substring).to_s)
      end
    end

    def lti_1_3?
      @tool.respond_to?(:use_1_3?) && @tool.use_1_3?
    end
  end
end
