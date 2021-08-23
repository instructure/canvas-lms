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

require 'spec_helper'
require_relative '../../helpers/k5_common'

describe K5Mode do
  include K5Common

  controller(AssignmentsController) do
    def index
      respond_to do |format|
        format.html do
          render :new_index
        end
      end
    end
  end

  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    account_admin_user(account: @course.account)
    toggle_k5_setting(@course.account)
  end

  describe 'set_k5_mode' do
    shared_examples_for ':show_left_side' do
      it 'should not set :show_left_side in non-k5 contexts' do
        toggle_k5_setting(@course.account, false)
        get :index, params: { course_id: @course.id }
        expect(assigns(:show_left_side)).to be_nil
      end
    end

    context 'teacher' do
      before :each do
        user_session(@teacher)
      end

      it_behaves_like ':show_left_side'

      it 'should set k5 variables' do
        get :index, params: { course_id: @course.id }
        expect(assigns(:k5_details_view)).to eq(false)
        expect(assigns(:show_left_side)).to eq(true)
        expect(assigns(:css_bundles).flatten).to include(:k5_theme)
        expect(assigns(:js_bundles).flatten).to include(:k5_theme)
      end

      context 'that is also a student' do
        before :each do
          @course.enroll_user(@teacher, 'StudentEnrollment', enrollment_state: 'active')
        end

        it_behaves_like ':show_left_side'

        it 'should set k5 variables' do
          get :index, params: { course_id: @course.id }
          expect(assigns(:k5_details_view)).to eq(false)
          expect(assigns(:show_left_side)).to eq(true)
          expect(assigns(:css_bundles).flatten).to include(:k5_theme)
          expect(assigns(:js_bundles).flatten).to include(:k5_theme)
        end
      end
    end

    context 'admin' do
      before :each do
        user_session(@admin)
      end

      it_behaves_like ':show_left_side'

      it 'should set k5 variables' do
        get :index, params: { course_id: @course.id }
        expect(assigns(:k5_details_view)).to eq(false)
        expect(assigns(:show_left_side)).to eq(true)
        expect(assigns(:css_bundles).flatten).to include(:k5_theme)
        expect(assigns(:js_bundles).flatten).to include(:k5_theme)
      end
    end

    context 'student' do
      before :each do
        user_session(@student)
      end

      it_behaves_like ':show_left_side'

      it 'should set k5 variables' do
        get :index, params: { course_id: @course.id }
        expect(assigns(:k5_details_view)).to eq(true)
        expect(assigns(:show_left_side)).to eq(false)
        expect(assigns(:css_bundles).flatten).to include(:k5_theme)
        expect(assigns(:js_bundles).flatten).to include(:k5_theme)
      end
    end

    it 'should use K5 theme for homeroom courses' do
      @course.homeroom_course = true
      user_session(@teacher)
      get :index, params: { course_id: @course.id }
      expect(assigns(:css_bundles).flatten).to include(:k5_theme)
      expect(assigns(:js_bundles).flatten).to include(:k5_theme)
    end

    it 'should prefer the K5 theme to the old elementary theme if both apply' do
      @course.enable_feature!(:canvas_k6_theme)
      user_session(@teacher)
      get :index, params: { course_id: @course.id }
      expect(assigns(:css_bundles).flatten).to include(:k5_theme)
      expect(assigns(:js_bundles).flatten).to include(:k5_theme)
      expect(assigns(:js_bundles).flatten).not_to include(:k6_theme)
    end

    it 'should use the old elementary theme if the flag is on and K5 mode is off' do
      @course.enable_feature!(:canvas_k6_theme)
      @course.account.settings[:enable_as_k5_account] = { value: false }
      @course.account.save!
      user_session(@teacher)
      get :index, params: { course_id: @course.id }
      expect(assigns(:css_bundles).flatten).to include(:k6_theme)
    end
  end
end
