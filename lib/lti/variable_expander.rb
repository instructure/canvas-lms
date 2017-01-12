#
# Copyright (C) 2015 Instructure, Inc.
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

module Lti
  class VariableExpander

    SUBSTRING_REGEX = /(?<=\${).*?(?=})/.freeze #matches only the stuff inside `${}`

    attr_reader :context, :root_account, :controller, :current_user

    attr_accessor :current_pseudonym, :content_tag, :assignment,
                  :tool_setting_link_id, :tool_setting_binding_id, :tool_setting_proxy_id, :tool, :attachment,
                  :collaboration

    def self.register_expansion(name, permission_groups, expansion_proc, *guards)
      @expansions ||= {}
      @expansions["$#{name}".to_sym] = VariableExpansion.new(name, permission_groups, expansion_proc, *guards)
    end

    def self.expansions
      @expansions || {}
    end

    CONTROLLER_GUARD = -> { !!@controller }
    COURSE_GUARD = -> { @context.is_a? Course }
    TERM_START_DATE_GUARD = -> { @context.is_a?(Course) && @context.enrollment_term &&
                                 @context.enrollment_term.start_at }
    USER_GUARD = -> { @current_user }
    SIS_USER_GUARD = -> { @current_user && @current_user.pseudonym && @current_user.pseudonym.sis_user_id }
    PSEUDONYM_GUARD = -> { sis_pseudonym }
    ENROLLMENT_GUARD = -> { @current_user && @context.is_a?(Course) }
    ROLES_GUARD = -> { @current_user && (@context.is_a?(Course) || @context.is_a?(Account)) }
    CONTENT_TAG_GUARD = -> { @content_tag }
    ASSIGNMENT_GUARD = -> { @assignment }
    COLLABORATION_GUARD = -> { @collaboration }
    MEDIA_OBJECT_GUARD = -> { @attachment && @attachment.media_object}
    USAGE_RIGHTS_GUARD = -> { @attachment && @attachment.usage_rights}
    MEDIA_OBJECT_ID_GUARD = -> {@attachment && (@attachment.media_object || @attachment.media_entry_id )}
    LTI1_GUARD = -> { @tool.is_a?(ContextExternalTool) }
    MASQUERADING_GUARD = -> { !!@controller && @controller.logged_in_user != @current_user }

    def initialize(root_account, context, controller, opts = {})
      @root_account = root_account
      @context = context
      @controller = controller
      @request = controller.request if controller
      opts.each { |opt, val| instance_variable_set("@#{opt}", val) }
    end

    def lti_helper
      @lti_helper ||= Lti::SubstitutionsHelper.new(@context, @root_account, @current_user)
    end

    def current_user=(current_user)
      @lti_helper = nil
      @current_user = current_user
    end

    def [](key)
      k = (key[0] == '$' && key) || "$#{key}"
      if (expansion = self.class.expansions[k.respond_to?(:to_sym) && k.to_sym])
        expansion.expand(self)
      end
    end

    def expand_variables!(var_hash)
      var_hash.update(var_hash) do |_, v|
        if (expansion = v.respond_to?(:to_sym) && self.class.expansions[v.to_sym])
          expansion.expand(self)
        elsif v.respond_to?(:to_s) && v.to_s =~ SUBSTRING_REGEX
          expand_substring_variables(v)
        else
          v
        end
      end
    end

    # returns the canvas domain for the current context.
    # @example
    #   ```
    #   canvas.instructure.com
    #   ```
    register_expansion 'Canvas.api.domain', [],
                       -> { HostUrl.context_host(@root_account, @request.host) },
                       CONTROLLER_GUARD

    # returns the api url for the members of the collaboration
    # @example
    #  ```
    #  https://canvas.instructure.com/api/v1/collaborations/1/members
    #  ```
    register_expansion 'Canvas.api.collaborationMembers.url', [],
                       -> { @controller.api_v1_collaboration_members_url(@collaboration) },
                       CONTROLLER_GUARD,
                       COLLABORATION_GUARD
    # returns the base URL for the current context.
    # @example
    #   ```
    #   https://canvas.instructure.com
    #   ```
    register_expansion 'Canvas.api.baseUrl', [],
                       -> { "#{@request.scheme}://#{HostUrl.context_host(@root_account, @request.host)}" },
                       CONTROLLER_GUARD

    # returns the URL for the membership service associated with the current context
    # @example
    #   ```
    #   https://canvas.instructure.com/api/lti/courses/1/membership_service
    #   ```
    register_expansion 'ToolProxyBinding.memberships.url', [],
                       -> { @controller.polymorphic_url([@context, :membership_service]) },
                       CONTROLLER_GUARD,
                       -> { @context.is_a?(Course) || @context.is_a?(Group) }

    # returns the account id for the current context.
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion 'Canvas.account.id', [],
                       -> { lti_helper.account.id }

    # returns the account name for the current context.
    # @example
    #   ```
    #   School Name
    #   ```
    register_expansion 'Canvas.account.name', [],
                       -> { lti_helper.account.name }

    # returns the account's sis source id for the current context. Only available if sis_account_id is specified.
    # @example
    #   ```
    #   sis_account_id_1234
    #   ```
    register_expansion 'Canvas.account.sisSourceId', [],
                       -> { lti_helper.account.sis_source_id }

    # returns the Root Account ID for the current context.
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion 'Canvas.rootAccount.id', [],
                       -> { @root_account.id }

    # returns the root account's sis source id for the current context. Only available if sis_account_id is specified.
    # @example
    #   ```
    #   sis_account_id_1234
    #   ```
    register_expansion 'Canvas.rootAccount.sisSourceId', [],
                       -> { @root_account.sis_source_id }

    # returns the API URL for the external tool that was launched. Only available for LTI 1.
    # @example
    #   ```
    #   http://example.url/path
    #   ```
    register_expansion 'Canvas.externalTool.url', [],
                       -> { @controller.named_context_url(@tool.context, :api_v1_context_external_tools_update_url,
                                                          @tool.id, include_host:true) },
                       CONTROLLER_GUARD,
                       LTI1_GUARD

    # returns the URL for the common css file. Should always be available.
    # @example
    #   ```
    #   http://example.url/path.css
    #   ```
    register_expansion 'Canvas.css.common', [],
                       -> { URI.parse(@request.url)
                               .merge(@controller.view_context.stylesheet_path(@controller.css_url_for(:common))).to_s },
                       CONTROLLER_GUARD

    # returns the shard id for the current context.
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion 'Canvas.shard.id', [],
                       -> { Shard.current.id }

    # returns the root account's global id for the current context.
    # @example
    #   ```
    #   123400000000123
    #   ```
    register_expansion 'Canvas.root_account.global_id', [],
                       -> { @root_account.global_id }

    # returns the root account id for the current context.
    # @deprecated
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion 'Canvas.root_account.id', [],
                       -> { @root_account.id }

    # returns the root account sis source id for the current context.
    # @deprecated
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion 'Canvas.root_account.sisSourceId', [],
                       -> { @root_account.sis_source_id }

    # returns the current course id.
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion 'Canvas.course.id', [],
                       -> { @context.id },
                       COURSE_GUARD

    # returns the current course sis source id.
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion 'Canvas.course.sisSourceId', [],
                       -> { @context.sis_source_id },
                       COURSE_GUARD

    # returns the current course start date.
    # @example
    #   ```
    #   YYY-MM-DD HH:MM:SS -0700
    #   ```
    register_expansion 'Canvas.course.startAt', [],
                       -> { @context.start_at },
                       COURSE_GUARD

    # returns the current course workflow state. Workflow states of "claimed" or "created"
    # indicate an unpublished course.
    # @example
    #   ```
    #   active
    #   ```
    register_expansion 'Canvas.course.workflowState', [],
                       -> { @context.workflow_state },
                       COURSE_GUARD

    # returns the current course's term start date.
    # @example
    #   ```
    #   YYY-MM-DD HH:MM:SS -0700
    #   ```
    register_expansion 'Canvas.term.startAt', [],
                       -> { @context.enrollment_term.start_at },
                       TERM_START_DATE_GUARD

    # returns the current course sis source id
    # to return the section source id use Canvas.course.sectionIds
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion 'CourseSection.sourcedId', [],
                       -> { @context.sis_source_id },
                       COURSE_GUARD

    # returns the current course enrollment state
    # @example
    #   ```
    #   active
    #   ```
    register_expansion 'Canvas.enrollment.enrollmentState', [],
                       -> { lti_helper.enrollment_state },
                       COURSE_GUARD

    # returns the current course membership roles
    # @example
    #   ```
    #   StudentEnrollment
    #   ```
    register_expansion 'Canvas.membership.roles', [],
                       -> { lti_helper.current_canvas_roles },
                       ROLES_GUARD

    # This is a list of IMS LIS roles should have a different key
    # @example
    #   ```
    #   urn:lti:sysrole:ims/lis/None
    #   ```
    register_expansion 'Canvas.membership.concludedRoles', [],
                       -> { lti_helper.concluded_lis_roles },
                       COURSE_GUARD

    # Returns the context ids from the course that the current course was copied from.
    # Only available when launched in a course that was copied (excludes cartridge imports).
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion 'Canvas.course.previousContextIds', [],
                       -> { lti_helper.previous_lti_context_ids },
                       COURSE_GUARD

    # Returns the course ids of the course that the current course was copied from.
    # Only available when launched in a course that was copied (excludes cartridge imports).
    # @example
    #   ```
    #   1234
    #   ```
    register_expansion 'Canvas.course.previousCourseIds', [],
                       -> { lti_helper.previous_course_ids },
                       COURSE_GUARD

    # Returns the full name of the launching user. Only available when launched by a logged in user.
    # @example
    #   ```
    #   John Doe
    #   ```
    register_expansion 'Person.name.full', [],
                       -> { @current_user.name },
                       USER_GUARD

    # Returns the last name of the launching user. Only available when launched by a logged in user.
    # @example
    #   ```
    #   Doe
    #   ```
    register_expansion 'Person.name.family', [],
                       -> { @current_user.last_name },
                       USER_GUARD

    # Returns the first name of the launching user. Only available when launched by a logged in user.
    # @example
    #   ```
    #   John
    #   ```
    register_expansion 'Person.name.given', [],
                       -> { @current_user.first_name },
                       USER_GUARD

    # Returns the primary email of the launching user. Only available when launched by a logged in user.
    # @example
    #   ```
    #   john.doe@example.com
    #   ```
    register_expansion 'Person.email.primary', [],
                       -> { @current_user.email },
                       USER_GUARD


    # Returns the institution assigned email of the launching user. Only available when launched by a logged in user that was added via SIS.
    # @example
    #   ```
    #   john.doe@example.com
    #   ```
    register_expansion 'vnd.Canvas.Person.email.sis', [],
                       -> { @current_user.communication_channels.joins(
                         "INNER JOIN #{Pseudonym.quoted_table_name}
                          ON communication_channels.id=pseudonyms.sis_communication_channel_id")
                              .limit(1).pluck(:path).first }, SIS_USER_GUARD

    # Returns the name of the timezone of the launching user. Only available when launched by a logged in user.
    # @example
    #   ```
    #   America/Denver
    #   ```
    register_expansion 'Person.address.timezone', [],
                       -> { Time.zone.tzinfo.name },
                       USER_GUARD

    # Returns the profile picture URL of the launching user. Only available when launched by a logged in user.
    # @example
    #   ```
    #   https://example.com/picture.jpg
    #   ```
    register_expansion 'User.image', [],
                       -> { @current_user.avatar_url },
                       USER_GUARD

    # Returns the Canvas user_id of the launching user. Only available when launched by a logged in user.
    # @example
    #   ```
    #   420000000000042
    #   ```
    register_expansion 'User.id', [],
                       -> { @current_user.id },
                       USER_GUARD

    # Returns the Canvas user_id of the launching user. Only available when launched by a logged in user.
    # @example
    #   ```
    #   420000000000042
    #   ```
    register_expansion 'Canvas.user.id', [],
                       -> { @current_user.id },
                       USER_GUARD

    # Returns the users preference for high contrast colors (an accessibility feature). Only available when launched by a logged in user.
    # @example
    #   ```
    #   false
    #   ```
    register_expansion 'Canvas.user.prefersHighContrast', [],
                       -> { @current_user.prefers_high_contrast? ? 'true' : 'false' },
                       USER_GUARD

    # returns the context ids for the groups the user belongs to in the course.
    # @example
    #   ```
    #   1c16f0de65a080803785ecb3097da99872616f0d,d4d8d6ae1611e2c7581ce1b2f5c58019d928b79d,...
    #   ```
    register_expansion 'Canvas.group.contextIds', [],
                       -> { @current_user.groups.active.where(context_type: 'Course', context_id: @context.id).map do |g|
                              Lti::Asset.opaque_identifier_for(g)
                            end.join(',') },
                       -> { @current_user && @context.is_a?(Course) }

    # Returns the <a href="https://www.imsglobal.org/specs/ltimemv1p0/specification-3">IMS LTI membership service</a> roles for filtering via query parameters.
    # Only available when launched by a logged in user.
    # @example
    #   ```
    #   http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator
    #   ```
    register_expansion 'Membership.role', [],
                       -> { lti_helper.all_roles('lis2') },
                       USER_GUARD

    # Returns list of <a href="https://www.imsglobal.org/specs/ltiv1p0/implementation-guide#toc-16" target ="_blank">LIS role full URNs</a>.
    # Should always be available.
    # @example
    #   ```
    #   http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator
    #   ```
    register_expansion 'Canvas.xuser.allRoles', [],
                       -> { lti_helper.all_roles }

    # Returns the Canvas user_id of the launching user. Only available when launched by a logged in user.
    # @example
    #   ```
    #   420000000000042
    #   ```
    register_expansion 'Canvas.user.globalId', [],
                       -> { @current_user.global_id},
                       USER_GUARD

    # Returns true for root account admins and false for all other roles. Only available when launched by a logged in user.
    # @example
    #   ```
    #   true
    #   ```
   register_expansion 'Canvas.user.isRootAccountAdmin', [],
                      -> { @current_user.roles(@root_account).include? 'root_admin' },
                      USER_GUARD

    # Returns the username/Login ID for the primary pseudonym for the user for the account
    # This may not be the pseudonym the user is actually logged in with. Only available when pseudonym is in use.
    #   ```
    #   jdoe
    #   ```
    register_expansion 'User.username', [],
                       -> { sis_pseudonym.unique_id },
                       PSEUDONYM_GUARD

    # Returns the username/Login ID for the primary pseudonym for the user for the account
    # This may not be the pseudonym the user is actually logged in with. Only available when pseudonym is in use.
    #   ```
    #   jdoe
    #   ```
    register_expansion 'Canvas.user.loginId', [],
                       -> { sis_pseudonym.unique_id },
                       PSEUDONYM_GUARD

    # Returns the sis source id for the primary pseudonym for the user for the account
    # This may not be the pseudonym the user is actually logged in with. Only available when pseudonym is in use.
    #   ```
    #   sis_user_42
    #   ```
    register_expansion 'Canvas.user.sisSourceId', [],
                       -> { sis_pseudonym.sis_user_id },
                       PSEUDONYM_GUARD

    # Returns the integration id for the primary pseudonym for the user for the account
    # This may not be the pseudonym the user is actually logged in with. Only available when pseudonym is in use.
    #   ```
    #   integration_user_42
    #   ```
    register_expansion 'Canvas.user.sisIntegrationId', [],
                       -> { sis_pseudonym.integration_id },
                       PSEUDONYM_GUARD

    # Returns the sis source id for the primary pseudonym for the user for the account
    # This may not be the pseudonym the user is actually logged in with. Only available when pseudonym is in use.
    #   ```
    #   sis_user_42
    #   ```
    register_expansion 'Person.sourcedId', [],
                       -> { sis_pseudonym.sis_user_id },
                       PSEUDONYM_GUARD

    # Returns the logout service url for the user.
    # This is the pseudonym the user is actually logged in as.
    # It may not hold all the sis info needed in other launch substitutions.
    #   ```
    #   https://<domain>.instructure.com/api/lti/v1/logout_service/<external_tool_id>-<user_id>-<current_unix_timestamp>-<opaque_id>
    #   ```
    register_expansion 'Canvas.logoutService.url', [],
                       -> { @controller.lti_logout_service_url(Lti::LogoutService.create_token(@tool, @current_pseudonym)) },
                       CONTROLLER_GUARD,
                       -> { @current_pseudonym && @tool }

    # Returns the Canvas user_id for the masquerading user.
    # This is the pseudonym the user is actually logged in as.
    # It may not hold all the sis info needed in other launch substitutions.
    # Only available when the user is being masqueraded.
    #   ```
    #   420000000000042
    #   ```
    register_expansion 'Canvas.masqueradingUser.id', [],
                       -> { @controller.logged_in_user.id },
                       MASQUERADING_GUARD

    # Returns the 40 character opaque user_id for masquerading user.
    # This is the pseudonym the user is actually logged in as.
    # It may not hold all the sis info needed in other launch substitutions.
    # Only available when the user is being masqueraded.
    #   ```
    #   da12345678cb37ba1e522fc7c5ef086b7704eff9
    #   ```
    register_expansion 'Canvas.masqueradingUser.userId', [],
                       -> { @tool.opaque_identifier_for(@controller.logged_in_user) },
                       MASQUERADING_GUARD

    # Returns the xapi url for the user.
    #   ```
    #   https://<domain>.instructure.com/api/lti/v1/xapi/<external_tool_id>-<user_id>-<course_id>-<current_unix_timestamp>-<opaque_id>
    #   ```
    register_expansion 'Canvas.xapi.url', [],
                       -> { @controller.lti_xapi_url(Lti::AnalyticsService.create_token(@tool, @current_user, @context)) },
                       -> { @current_user && @context.is_a?(Course) && @tool }

    # Returns the caliper url for the user.
    #   ```
    #   https://<domain>.instructure.com/api/lti/v1/caliper/<external_tool_id>-<user_id>-<course_id>-<current_unix_timestamp>-<opaque_id>
    #   ```
    register_expansion 'Caliper.url', [],
                       -> { @controller.lti_caliper_url(Lti::AnalyticsService.create_token(@tool, @current_user, @context)) },
                       CONTROLLER_GUARD,
                       -> { @current_user && @context.is_a?(Course) && @tool }

    # Returns a comma separated list of section_id's that the user is enrolled in.
    # Only available when launched from a course as an enrolled user.
    #   ```
    #   42, 43
    #   ```
    register_expansion 'Canvas.course.sectionIds', [],
                       -> { lti_helper.section_ids },
                       ENROLLMENT_GUARD

    # Returns a comma separated list of section sis_id's that the user is enrolled in.
    # Only available when launched from a course as an enrolled user.
    #   ```
    #   section_sis_id_1, section_sis_id_2
    #   ```
    register_expansion 'Canvas.course.sectionSisSourceIds', [],
                       -> { lti_helper.section_sis_ids },
                       ENROLLMENT_GUARD

    # Returns the module_id that the module item was launched from.
    # Only available when content tag is present.
    #   ```
    #   1234
    #   ```
    register_expansion 'Canvas.module.id', [],
                       -> {
                         @content_tag.context_module_id
                       },
                       CONTENT_TAG_GUARD

    # Returns the module_item_id of the module item that was launched.
    # Only available when content tag is present.
    #   ```
    #   1234
    #   ```
    register_expansion 'Canvas.moduleItem.id', [],
                       -> {
                         @content_tag.id
                       },
                       CONTENT_TAG_GUARD

    # Returns the assignment_id of the assignment that was launched.
    # Only available when launched as an assignment.
    #   ```
    #   1234
    #   ```
    register_expansion 'Canvas.assignment.id', [],
                       -> { @assignment.id },
                       ASSIGNMENT_GUARD

    # Returns the title of the assignment that was launched.
    # Only available when launched as an assignment.
    #   ```
    #   Deep thought experiment
    #   ```
    register_expansion 'Canvas.assignment.title', [],
                       -> { @assignment.title },
                       ASSIGNMENT_GUARD

    # Returns the points possible of the assignment that was launched.
    # Only available when launched as an assignment.
    #   ```
    #   100
    #   ```
    register_expansion 'Canvas.assignment.pointsPossible', [],
                       -> { TextHelper.round_if_whole(@assignment.points_possible) },
                       ASSIGNMENT_GUARD

    # @deprecated in favor of ISO8601
    register_expansion 'Canvas.assignment.unlockAt', [],
                       -> { @assignment.unlock_at },
                       ASSIGNMENT_GUARD

    # @deprecated in favor of ISO8601
    register_expansion 'Canvas.assignment.lockAt', [],
                       -> { @assignment.lock_at },
                       ASSIGNMENT_GUARD

    # @deprecated in favor of ISO8601
    register_expansion 'Canvas.assignment.dueAt', [],
                       -> { @assignment.due_at },
                       ASSIGNMENT_GUARD

    # Returns the unlock_at date of the assignment that was launched.
    # Only available when launched as an assignment.
    #   ```
    #   YYYY-MM-DDT07:00:00Z
    #   ```
    register_expansion 'Canvas.assignment.unlockAt.iso8601', [],
                       -> { @assignment.unlock_at.utc.iso8601 },
                       -> {@assignment && @assignment.unlock_at.present?}

    # Returns the lock_at date of the assignment that was launched.
    # Only available when launched as an assignment.
    #   ```
    #   YYYY-MM-DDT07:00:00Z
    #   ```
    register_expansion 'Canvas.assignment.lockAt.iso8601', [],
                       -> { @assignment.lock_at.utc.iso8601 },
                       -> {@assignment && @assignment.lock_at.present?}

    # Returns the due_at date of the assignment that was launched.
    # Only available when launched as an assignment.
    #   ```
    #   YYYY-MM-DDT07:00:00Z
    #   ```
    register_expansion 'Canvas.assignment.dueAt.iso8601', [],
                       -> { @assignment.due_at.utc.iso8601 },
                       -> {@assignment && @assignment.due_at.present?}

    # Returns the true if the assignment that was launched is published.
    # Only available when launched as an assignment.
    #   ```
    #   true
    #   ```
    register_expansion 'Canvas.assignment.published', [],
                       -> { @assignment.workflow_state == 'published' },
                       ASSIGNMENT_GUARD

    # Returns the endpoint url for accessing link-level tool settings
    # Only available for LTI 2.0
    #   ```
    #   https://<domain>.instructure.com/api/lti/tool_settings/<link_id>
    #   ```
    register_expansion 'LtiLink.custom.url', [],
                       -> { @controller.show_lti_tool_settings_url(@tool_setting_link_id) },
                       CONTROLLER_GUARD,
                       -> { @tool_setting_link_id }

    # Returns the endpoint url for accessing context-level tool settings
    # Only available for LTI 2.0
    #   ```
    #   https://<domain>.instructure.com/api/lti/tool_settings/<binding_id>
    #   ```
    register_expansion 'ToolProxyBinding.custom.url', [],
                       -> { @controller.show_lti_tool_settings_url(@tool_setting_binding_id) },
                       CONTROLLER_GUARD,
                       -> { @tool_setting_binding_id }

    # Returns the endpoint url for accessing system-wide tool settings
    # Only available for LTI 2.0
    #   ```
    #   https://<domain>.instructure.com/api/lti/tool_settings/<proxy_id>
    #   ```
    register_expansion 'ToolProxy.custom.url', [],
                       -> { @controller.show_lti_tool_settings_url(@tool_setting_proxy_id) },
                       -> { !!@controller && @tool_setting_proxy_id }

    # Returns the <a href="https://www.imsglobal.org/specs/ltiv2p0/implementation-guide#toc-46" target="_blank">Tool Consumer Profile</a> url for the tool.
    # Only available for LTI 2.0
    #   ```
    #   https://<domain>.instructure.com/api/lti/courses/<course_id>/tool_consumer_profile/<opaque_id>
    #   https://<domain>.instructure.com/api/lti/accounts/<account_id>/tool_consumer_profile/<opaque_id>
    #   ```
    register_expansion 'ToolConsumerProfile.url', [],
                       -> { @controller.polymorphic_url([@tool.context, :tool_consumer_profile], tool_consumer_profile_id: Lti::ToolConsumerProfileCreator::TCP_UUID)},
                       CONTROLLER_GUARD,
                       -> { @tool && @tool.is_a?(Lti::ToolProxy) }

    register_expansion 'Canvas.file.media.id', [],
                       -> { (@attachment.media_object && @attachment.media_object.media_id) || @attachment.media_entry_id },
                       MEDIA_OBJECT_ID_GUARD

    register_expansion 'Canvas.file.media.type', [],
                       -> {@attachment.media_object.media_type},
                       MEDIA_OBJECT_GUARD

    register_expansion 'Canvas.file.media.duration', [],
                       -> {@attachment.media_object.duration},
                       MEDIA_OBJECT_GUARD

    register_expansion 'Canvas.file.media.size', [],
                       -> {@attachment.media_object.total_size},
                       MEDIA_OBJECT_GUARD

    register_expansion 'Canvas.file.media.title', [],
                       -> {@attachment.media_object.user_entered_title || @attachment.media_object.title},
                       MEDIA_OBJECT_GUARD

    register_expansion 'Canvas.file.usageRights.name', [],
                       -> {@attachment.usage_rights.license_name},
                       USAGE_RIGHTS_GUARD

    register_expansion 'Canvas.file.usageRights.url', [],
                       -> {@attachment.usage_rights.license_url},
                       USAGE_RIGHTS_GUARD

    register_expansion 'Canvas.file.usageRights.copyrightText', [],
                       -> {@attachment.usage_rights.legal_copyright},
                       USAGE_RIGHTS_GUARD

    private

    def sis_pseudonym
      @sis_pseudonym ||= @current_user.find_pseudonym_for_account(@root_account) if @current_user
    end

    def expand_substring_variables(value)
      value.to_s.scan(SUBSTRING_REGEX).inject(value) do |v, match|
        substring = "${#{match}}"
        v.gsub(substring, (self[match] || substring).to_s)
      end
    end
  end
end
