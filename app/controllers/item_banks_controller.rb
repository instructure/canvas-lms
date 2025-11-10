# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class ItemBanksController < ApplicationController
  before_action :require_context

  add_crumb(proc { t("#crumbs.item_banks", "Item Banks") }) { |c| c.send :named_context_url, c.instance_variable_get(:@context), :context_item_banks_url }
  before_action { |c| c.active_tab = "item_banks" }

  def show
    return render status: :not_found, template: "shared/errors/404_message" unless ams_integration_enabled?

    js_env(context_url: context_url(@context, :context_item_banks_url))
    remote_env(ams:
      {
        launch_url: Services::Ams.item_management_launch_url,
        api_url: Services::Ams.api_url
      })

    @body_classes << "full-width padless-content"
    render html: '<div id="ams_container"></div>'.html_safe, layout: true
  end

  def ams_integration_enabled?
    @context.root_account.feature_enabled?(:ams_root_account_integration) &&
      @context.is_a?(Course) &&
      @context.feature_enabled?(:ams_course_integration)
  end
end
