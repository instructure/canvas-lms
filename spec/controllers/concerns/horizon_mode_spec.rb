# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe HorizonMode do
  controller(CoursesController) do
    def show
      render json: {}
    end
  end

  before :once do
    @course = course_factory(active_all: true)
    course_with_student(active_all: true)
    account = @course.root_account
    account.settings[:horizon_domain] = "test.canvasforcareer.com"
    account.save!
  end

  before do
    @context = Course.find(@course.id)
    controller.instance_variable_set(:@context, @context)
  end

  context "when course is not a Horizon course" do
    it "does not redirect" do
      get :show, params: { id: @course.id }
      expect(response).to have_http_status :ok
    end
  end

  context "when course is a Horizon course" do
    before :once do
      Account.site_admin.enable_feature!(:horizon_course_setting)
      @course.update!(horizon_course: true)
    end

    it "does not redirect if user is not student" do
      user_session(@teacher)
      get :show, params: { id: @course.id }
      expect(response).to have_http_status :ok
    end

    it "does not redirect if user is account admin" do
      admin = account_admin_user(account: @course.account)
      user_session(admin)
      get :show, params: { id: @course.id }
      expect(response).to have_http_status :ok
    end

    it "redirects to horizon if user is student" do
      user_session(@student)
      get :show, params: { id: @course.id }
      expect(response).to redirect_to("https://test.canvasforcareer.com/redirect?canvas_url=%2Fcourses%2F#{@course.id}&preview=false&reauthenticate=false")
    end

    it "does not redirect if horizon domain is not set, even if student" do
      @course.account.settings[:horizon_domain] = nil
      @course.account.save!
      user_session(@student)
      get :show, params: { id: @course.id }
      expect(response).to have_http_status :ok
    end
  end
end
