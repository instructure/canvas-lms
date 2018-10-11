#
# Copyright (C) 2011 - present Instructure, Inc.
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
  class LtiAppsController < ApplicationController
    before_action :require_context
    before_action :require_user, except: [:launch_definitions]

    def index
      if authorized_action(@context, @current_user, :read_as_admin)
        app_collator = AppCollator.new(@context, method(:reregistration_url_builder))
        collection = app_collator.bookmarked_collection

        respond_to do |format|
          app_defs = Api.paginate(collection, self, named_context_url(@context, :api_v1_context_app_definitions_url, include_host: true))

          mc_status = setup_master_course_restrictions(app_defs.select{|o| o.is_a?(ContextExternalTool)}, @context)
          format.json {render json: app_collator.app_definitions(app_defs, :master_course_status => mc_status)}
        end
      end
    end

    def launch_definitions
      placements = params['placements'] || []
      if authorized_for_launch_definitions(@context, @current_user, placements)
        # only_visible requires that specific placements are requested.  If a user is not read_admin, and they request only_visible
        # without placements, an empty array will be returned.
        if placements == ['global_navigation']
          # We allow global_navigation to pull all the launch_definitions, even if they are not explicitly visible to user.
          collection = AppLaunchCollator.bookmarked_collection(@context, placements, {current_user: @current_user, session: session, only_visible: false})
        else
          collection = AppLaunchCollator.bookmarked_collection(@context, placements, {current_user: @current_user, session: session, only_visible: true})
        end
        pagination_args = {max_per_page: 100}
        respond_to do |format|
          launch_defs = Api.paginate(
            collection,
            self,
            named_context_url(@context, :api_v1_context_launch_definitions_url, include_host: true),
            pagination_args
          )
          format.json { render :json => AppLaunchCollator.launch_definitions(launch_defs, placements) }
        end
      end
    end


    private

    def reregistration_url_builder(context, tool_proxy_id)
        polymorphic_url([context, :tool_proxy_reregistration], tool_proxy_id: tool_proxy_id)
    end

    def authorized_for_launch_definitions(context, user, placements)
      # This is a special case to allow any user (students especially) to access the
      # launch definitions for global navigation specifically. This is requested in
      # the context of an account, not a course, so a student would normally not
      # have any account-level permissions. So instead, just ensure that the user
      # is associated with the current account (not sure how it could be otherwise?)
      return true if context.is_a?(Account) && \
        placements == ['global_navigation'] && \
        user_in_account?(user, context)

      authorized_action(context, user, :read)
    end

    def user_in_account?(user, account)
      user.associated_accounts.include? account
    end
  end
end
