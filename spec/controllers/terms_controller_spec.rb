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

describe TermsController do
  it "only touches courses once when setting overrides" do
    a = Account.default
    u = user_factory(active_all: true)
    a.account_users.create!(user: u)
    user_session(@user)

    term = a.default_enrollment_term
    expect_any_instantiation_of(term).to receive(:touch_all_courses).once

    put "update", params: { account_id: a.id,
                            id: term.id,
                            enrollment_term: { start_at: 1.day.ago,
                                               end_at: 1.day.from_now,
                                               overrides: {
                                                 student_enrollment: { start_at: 1.day.ago, end_at: 1.day.from_now },
                                                 teacher_enrollment: { start_at: 1.day.ago, end_at: 1.day.from_now },
                                                 ta_enrollment: { start_at: 1.day.ago, end_at: 1.day.from_now },
                                               } } }
  end

  it "is not able to change the name for a default term" do
    account_model
    account_admin_user(account: @account)
    user_session(@user)

    put "update", params: { account_id: @account.id, id: @account.default_enrollment_term.id, enrollment_term: { name: "new name lol" } }

    expect(response).to_not be_successful
    error = json_parse(response.body)["errors"]["name"].first["message"]
    expect(error).to eq "Cannot change the default term name"
  end

  it "doesn't overwrite stuck sis fields" do
    account = Account.default
    user = user_factory(active_all: true)
    account.account_users.create!(user:)
    user_session(@user)

    term = account.default_enrollment_term
    start_at = 5.days.ago
    term.update_attribute(:start_at, start_at)

    put "update", params: { account_id: account.id, id: term.id, override_sis_stickiness: false, enrollment_term: { start_at: 1.day.ago } }

    term.reload

    expect(response).to be_successful
    expect(term.start_at).to eq start_at
  end

  it "is not able to delete a default term" do
    account_model
    account_admin_user(account: @account)
    user_session(@user)

    delete "destroy", params: { account_id: @account.id, id: @account.default_enrollment_term.id }

    expect(response).to_not be_successful
    error = json_parse(response.body)["errors"]["workflow_state"].first["message"]
    expect(error).to eq "Cannot delete the default term"
  end

  it "is not able to delete an enrollment term with active courses" do
    account_model
    account_admin_user(account: @account)
    user_session(@user)

    @term = @account.enrollment_terms.create!
    course_factory account: @account
    @course.enrollment_term = @term
    @course.save!

    delete "destroy", params: { account_id: @account.id, id: @term.id }

    expect(response).to_not be_successful
    error = json_parse(response.body)["errors"]["workflow_state"].first["message"]
    expect(error).to eq "Cannot delete a term with active courses"

    @course.destroy

    delete "destroy", params: { account_id: @account.id, id: @term.id }

    expect(response).to be_successful

    @term.reload
    expect(@term).to be_deleted
  end

  context "course paces" do
    before do
      account_model
      course_model(account: @account)
      account_admin_user(account: @account)
      @course.account.enable_feature!(:course_paces)
      @course.enable_course_paces = true
      @course.save!
      @course_pace = course_pace_model(course: @course)
    end

    it "republishes course paces when the term is updated" do
      user_session(@user)

      put "update", params: { account_id: @account.id, id: @account.default_enrollment_term.id, enrollment_term: { start_at: 1.day.from_now } }
      expect(Progress.find_by(context: @course_pace)).to be_queued
    end
  end
end
