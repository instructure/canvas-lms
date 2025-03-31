# frozen_string_literal: true

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

describe ContextModulesController do
  describe "GET 'index'" do
    subject { get :index, params: { course_id: @course.id } }

    render_views

    before do
      course_with_teacher_logged_in(active_all: true)
      @course.context_modules.create!(name: "Test Module")
    end

    context "when modules_perf enabled" do
      before do
        @course.account.enable_feature!(:modules_perf)
      end

      it "exports proper environment variable with the flag ON" do
        subject
        expect(assigns[:js_env][:FEATURE_MODULES_PERF]).to be_truthy
      end
    end

    context "when modules_perf disabled" do
      before do
        @course.account.disable_feature!(:modules_perf)
      end

      it "exports proper environment variable with the flag OFF" do
        subject
        expect(assigns[:js_env][:FEATURE_MODULES_PERF]).to be_falsey
      end
    end
  end

  describe "GET 'items_html'" do
    subject { get "items_html", params: { course_id: @course.id, context_module_id: context_module.id } }

    render_views

    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
    end

    let(:context_module) { @course.context_modules.create! }

    context "when modules_perf enabled" do
      before do
        @course.account.enable_feature!(:modules_perf)
      end

      context "when there is no user session" do
        it "redirect to login page" do
          subject
          assert_unauthorized
        end
      end

      context "when there is a user session" do
        before do
          user_session(@user)
        end

        it "renders the template" do
          subject
          assert_status(200)
          expect(response.body).to include("<ul class=\"ig-list items context_module_items\">")
        end
      end
    end

    context "when modules_perf disabled" do
      before do
        @course.account.disable_feature!(:modules_perf)
      end

      it "renders 404" do
        subject
        assert_status(404)
      end
    end
  end
end
