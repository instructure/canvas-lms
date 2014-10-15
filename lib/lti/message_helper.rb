#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
  module MessageHelper

    def common_variable_substitutions
      lti_helper = Lti::SubstitutionsHelper.new(@context, @domain_root_account, @current_user)
      account = lti_helper.account

      substitutions = {
          '$Canvas.api.domain' => -> { HostUrl.context_host(@domain_root_account, request.host) },
          '$Canvas.api.baseUrl' => -> { "#{request.scheme}://#{HostUrl.context_host(@domain_root_account, request.host)}"},
          '$Canvas.account.id' => account.id,
          '$Canvas.account.name' => account.name,
          '$Canvas.account.sisSourceId' => account.sis_source_id,
          '$Canvas.rootAccount.id' => @domain_root_account.id,
          '$Canvas.rootAccount.sisSourceId' => @domain_root_account.sis_source_id
      }

      #Depricated substitutions
      substitutions.merge!(
          '$Canvas.root_account.id' => @domain_root_account.id,
          '$Canvas.root_account.sisSourceId' => @domain_root_account.sis_source_id,
      )


      if @context.is_a? Course
        substitutions.merge!(
          {
            '$Canvas.course.id' => @context.id,
            '$Canvas.course.sisSourceId' => @context.sis_source_id,
            '$Canvas.enrollment.enrollmentState' => -> { lti_helper.enrollment_state },
            '$Canvas.membership.roles' => -> { lti_helper.current_canvas_roles },
            #This is a list of IMS LIS roles should have a different key
            '$Canvas.membership.concludedRoles' => -> { lti_helper.concluded_lis_roles },
          }
        )
      end

      if @current_user
        pseudonym = @current_user.find_pseudonym_for_account(@domain_root_account)
        substitutions.merge!(
            {
                '$Person.name.full' => @current_user.name,
                '$Person.name.family' => @current_user.last_name,
                '$Person.name.given' => @current_user.first_name,
                '$Person.email.primary' => @current_user.email,
                '$Person.address.timezone' => Time.zone.tzinfo.name,
                '$User.image' => -> { @current_user.avatar_url },
                '$User.id' => @current_user.id,
                '$Canvas.user.id' => @current_user.id,
                '$Canvas.user.prefersHighContrast' => -> { @current_user.prefers_high_contrast? ? 'true' : 'false' },
            }
        )
        if pseudonym
          substitutions.merge!(
              {
                  '$User.username' => pseudonym.unique_id,
                  '$Canvas.user.loginId' => pseudonym.unique_id,
                  '$Canvas.user.sisSourceId' => pseudonym.sis_user_id,
                  '$Canvas.logoutService.url' => -> { lti_logout_service_url(Lti::LogoutService.create_token(@tool, pseudonym)) },
              }
          )
        end

        substitutions.merge!( '$Canvas.masqueradingUser.id' => logged_in_user.id ) if logged_in_user != @current_user
      end

      if @current_user && @context.is_a?(Course)
        substitutions.merge!(
              {
                 '$Canvas.xapi.url' => -> { lti_xapi_url(Lti::XapiService.create_token(@tool, @current_user, @context)) }
              }
        )
      end

      substitutions
    end

    def default_lti_params
      lti_helper = Lti::SubstitutionsHelper.new(@context, @domain_root_account, @current_user)

      params = {
          context_id: Lti::Asset.opaque_identifier_for(@context),
          tool_consumer_instance_guid: @domain_root_account.lti_guid,
          roles: lti_helper.current_lis_roles,
          launch_presentation_locale: I18n.locale || I18n.default_locale.to_s,
          launch_presentation_document_target: 'iframe',
          ext_roles: lti_helper.all_roles,
          # launch_presentation_width:,
          # launch_presentation_height:,
          # launch_presentation_return_url: return_url,
      }

      params.merge!(user_id: Lti::Asset.opaque_identifier_for(@current_user)) if @current_user
      params
    end
  end
end
