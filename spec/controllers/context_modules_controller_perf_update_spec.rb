# frozen_string_literal: true

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

describe ContextModulesController do
  context "with site_admin modules_perf feature flag" do
    render_views

    before :once do
      Account.site_admin.allow_feature!(:modules_perf)
    end

    describe "GET 'index'" do
      before do
        course_with_teacher_logged_in(active_all: true)
        @course.context_modules.create!(name: "Test Module")
      end

      it "exports proper environment variable with the flag ON" do
        @course.account.enable_feature!(:modules_perf)
        get :index, params: { course_id: @course.id }
        expect(assigns[:js_env][:FEATURE_MODULES_PERF]).to be_truthy
      end

      it "exports proper environment variable with the flag OFF" do
        @course.account.disable_feature!(:modules_perf)
        get :index, params: { course_id: @course.id }
        expect(assigns[:js_env][:FEATURE_MODULES_PERF]).to be_falsey
      end
    end
  end
end
