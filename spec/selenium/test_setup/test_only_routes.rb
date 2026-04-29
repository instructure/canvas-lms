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

module SeleniumDriverSetup
  module TestOnlyRoutes
    def self.create_routes(app)
      app.routes.append do
        post "/test/mock_lti/ui", to: "test/mock_lti#ui"
        post "/test/mock_lti/login", to: "test/mock_lti#login"
        get "/test/mock_lti/jwks", to: "test/mock_lti#jwks"
        post "/test/mock_lti/subscription_handler", to: "test/mock_lti#subscription_handler"
      end
    end
  end
end
