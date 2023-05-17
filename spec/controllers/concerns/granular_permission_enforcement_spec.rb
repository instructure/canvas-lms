# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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
require "spec_helper"

describe GranularPermissionEnforcement do
  controller(ApplicationController) do
    include GranularPermissionEnforcement
    before_action :authorize_action

    def index
      respond_to do |format|
        format.html do
          head :ok
        end
      end
    end

    def new
      respond_to do |format|
        format.html do
          head :ok
        end
      end
    end

    def authorize_action
      @context = api_find(Course, params[:course])
      enforce_granular_permissions(
        @context,
        overrides: [:manage_content],
        actions: {
          index: RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS,
          show: [:manage_course_content_add],
        }
      )
    end
  end

  describe "enforce_granular_permissions" do
    before :once do
      course_with_teacher(active_all: true)
      course_with_student(active_all: true)
    end

    shared_examples_for "when authorizing" do
      it "is not authorized" do
        user_session(@student)
        get :index, params: { course: @course }
        expect(response).to have_http_status :unauthorized
      end

      it "is authorized" do
        user_session(@teacher)
        get :index, params: { course: @course }
        expect(response).to have_http_status :ok
      end

      it "raises error if current controller action is missing from provided actions" do
        user_session(@teacher)
        expect_any_instance_of(GranularPermissionEnforcement)
          .to receive(:enforce_granular_permissions)
          .and_throw(/Missing current controller action/)
        get :new, params: { course: @course }
      end
    end

    context "with :granular_permissions_manage_course_content feature preview disable" do
      before do
        @course.root_account.disable_feature!(:granular_permissions_manage_course_content)
      end

      it_behaves_like "when authorizing"
    end

    context "with :granular_permissions_manage_course_content feature preview enabled" do
      before do
        @course.root_account.enable_feature!(:granular_permissions_manage_course_content)
      end

      it_behaves_like "when authorizing"
    end
  end
end
