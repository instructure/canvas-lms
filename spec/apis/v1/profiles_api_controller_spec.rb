#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')


def call_setting(opts)
  status_assertion = opts[:assert_unauthorized] ? {:expected_status => 401} : {}
  api_call_as_user(opts[:as_user], :get,
    "/api/v1/users/#{opts[:for_user].id}/profile.json",
    { :controller => 'profile', :action => 'settings',
      :format => 'json', :user_id => opts[:for_user].id },{},{}, status_assertion)
end

describe 'ProfileController', type: :request do
  context "setting permissions" do
    context "admin" do
      it "should show all profiles" do
        admin = account_admin_user
        user = user_with_pseudonym

        json = call_setting(as_user: admin, for_user: user)
        expect(json["short_name"]).to eq("User")
      end
    end

    context "teacher" do
      it "should show profiles for their students" do
        course_with_teacher(:active_all => true)
        e = course_with_user("StudentEnrollment", course: @course, active_all: true)
        user = e.user

        json = call_setting(as_user: @teacher, for_user: user)
        expect(json["short_name"]).to eq("User")
      end
      it "should return unauthorized profiles for other students" do
        course_with_teacher(:active_all => true)
        user = user_with_pseudonym

        json = call_setting(as_user: @teacher, for_user: user, assert_unauthorized: true)
      end
    end

    context "student" do
      it "should show a profile if it is theirs" do
        user = user_with_pseudonym(:active_user => true)

        json = call_setting(as_user: user, for_user: user)
        expect(json["short_name"]).to eq("User")
      end
      it "should return unauthorized when attempting to access another students profile" do
        user_one = user_with_pseudonym(:active_user => true)
        user_two = user_with_pseudonym(:active_user => true, :user => user)

        json = call_setting(as_user: user_one, for_user: user_two, assert_unauthorized: true)
      end
    end
  end
end
