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
    def generate_lti_launch(opts = {})
      lti_launch = Lti::Launch.new
      lti_launch.resource_url = opts[:launch_url]
      lti_launch
    end

    def self.default_lti_params(context, domain_root_account, user = nil)
      lti_helper = Lti::SubstitutionsHelper.new(context, domain_root_account, user)

      params = {
        context_id: Lti::Asset.opaque_identifier_for(context),
        tool_consumer_instance_guid: domain_root_account.lti_guid,
        roles: lti_helper.current_lis_roles,
        launch_presentation_locale: I18n.locale || I18n.default_locale.to_s,
        launch_presentation_document_target: 'iframe',
        ext_roles: lti_helper.all_roles,
      }

      params.merge!(user_id: Lti::Asset.opaque_identifier_for(user)) if user
      params
    end
  end
end
