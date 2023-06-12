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

require "nokogiri"

describe "student interactions links" do
  before do
    username = "nobody@example.com"
    password = "asdfasdf"
    u = user_with_pseudonym(active_user: true,
                            username:,
                            password:)
    u.save!
    @e = course_with_teacher active_course: true,
                             user: u,
                             active_enrollment: true
    @e.save!
    @teacher = u

    user_model
    @student = @user
    @course.enroll_student(@student).accept

    user_model
    @student2 = @user
    @course.enroll_student(@student2).accept

    user_model
    @ta = @user
    @course.enroll_ta(@ta).accept
  end

  context "as a user without permissions to view grades" do
    before do
      ["view_all_grades", "manage_grades"].each do |permission|
        RoleOverride.create!(permission:, enabled: false, context: @course.account, role: ta_role)
      end

      user_session(@ta)
    end

    it "does not show the student link on the student's page" do
      get "/courses/#{@course.id}/users/#{@student.id}"
      expect(response).to be_successful
      expect(response.body).not_to match(/Interactions Report/)
      expect(response.body).not_to match(/Student Interactions Report/)
    end

    it "does not show the teacher link on the teacher's page" do
      get "/courses/#{@course.id}/users/#{@teacher.id}"
      expect(response).to be_successful
      expect(response.body).not_to match(/Student Interactions Report/)
    end
  end

  context "as a user with permissions to view grades" do
    before do
      user_session(@teacher)
    end

    it "only shows the student link on the student's page" do
      get "/courses/#{@course.id}/users/#{@student.id}"
      expect(response).to be_successful
      expect(response.body).to match(/Interactions Report/)
      expect(response.body).not_to match(/Student Interactions Report/)
    end

    it "shows the teacher link on the teacher's page" do
      get "/courses/#{@course.id}/users/#{@teacher.id}"
      expect(response).to be_successful
      expect(response.body).to match(/Student Interactions Report/)
    end

    it "shows mail link for teachers" do
      get "/users/#{@teacher.id}/teacher_activity/course/#{@course.id}"
      expect(response).to be_successful
      html = Nokogiri::HTML5(response.body)
      expect(html.css(".message_student_link")).not_to be_nil
    end

    it "does not show mail link for admins" do
      user_model
      Account.site_admin.account_users.create!(user: @user)
      user_session(@user)
      get "/users/#{@teacher.id}/teacher_activity/course/#{@course.id}"
      expect(response).to be_successful
      html = Nokogiri::HTML5(response.body)
      expect(html.css(".message_student_link")).to be_empty
    end
  end
end
