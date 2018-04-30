#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe SupportHelpers::DueDateCacheController do
  describe 'require_site_admin' do
    it 'should redirect to root url if current user is not a site admin' do
      account_admin_user
      user_session(@user)
      get :course
      assert_unauthorized
    end

    it 'should redirect to login if current user is not logged in' do
      get :course
      assert_unauthorized
    end

    it 'should render 400 if current user is a site admin and there is no course_id' do
      site_admin_user
      user_session(@user)
      get :course
      assert_status(400)
    end

    describe 'helper action' do
      before do
        site_admin_user
        user_session(@user)
      end

      context 'course' do
        it "should create a new CourseFixer" do
          fixer = SupportHelpers::DueDateCache::CourseFixer.new(@user.email, nil, 1234)
          expect(SupportHelpers::DueDateCache::CourseFixer).to receive(:new).
            with(@user.email, nil, 1234).and_return(fixer)
          expect(fixer).to receive(:monitor_and_fix)
          get :course, params: { course_id: 1234 }
          expect(response.body).to eq("Enqueued CourseFixer ##{fixer.job_id}...")
        end
      end
    end
  end
end
