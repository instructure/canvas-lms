# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

# Serves the Ada chatbot popup host page. User metadata is never passed via URL
# params — it arrives through a same-origin postMessage from the Canvas page
# that opened this popup, then forwarded to the Ada Embed2 SDK.
class AdaChatPopupController < ApplicationController
  def show
    not_found unless @domain_root_account&.feature_enabled?(:ada_chatbot)

    # Deny iframe embedding — this page is only valid as a popup window.
    response.headers["X-Frame-Options"] = "DENY"
    render layout: false
  end
end
