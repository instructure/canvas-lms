#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TermsController do
  it "should only touch courses once when setting overrides" do
    a = Account.default
    u = user_factory(active_all: true)
    a.account_users.create!(user: u)
    user_session(@user)

    term = a.default_enrollment_term
    term.any_instantiation.expects(:touch_all_courses).once

    put 'update', :account_id => a.id, :id => term.id, :enrollment_term => {:start_at => 1.day.ago, :end_at => 1.day.from_now,
        :overrides => {
          :student_enrollment => { :start_at => 1.day.ago, :end_at => 1.day.from_now},
          :teacher_enrollment => { :start_at => 1.day.ago, :end_at => 1.day.from_now},
          :ta_enrollment => { :start_at => 1.day.ago, :end_at => 1.day.from_now},
      }}
  end

  it "should not be able to delete a default term" do
    account_model
    account_admin_user(:account => @account)
    user_session(@user)

    delete 'destroy', :account_id => @account.id, :id => @account.default_enrollment_term.id

    expect(response).to_not be_success
    error = json_parse(response.body)["errors"]["workflow_state"].first["message"]
    expect(error).to eq "Cannot delete the default term"
  end

  it "should not be able to delete an enrollment term with active courses" do
    account_model
    account_admin_user(:account => @account)
    user_session(@user)

    @term = @account.enrollment_terms.create!
    course_factory account: @account
    @course.enrollment_term = @term
    @course.save!

    delete 'destroy', :account_id => @account.id, :id => @term.id

    expect(response).to_not be_success
    error = json_parse(response.body)["errors"]["workflow_state"].first["message"]
    expect(error).to eq "Cannot delete a term with active courses"

    @course.destroy

    delete 'destroy', :account_id => @account.id, :id => @term.id

    expect(response).to be_success

    @term.reload
    expect(@term).to be_deleted
  end
end
