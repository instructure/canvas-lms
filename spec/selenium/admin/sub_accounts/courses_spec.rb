#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../common')

describe "sub account courses" do
  include_context "in-process server selenium tests"
    let(:account) { Account.create(:name => 'sub account from default account', :parent_account => Account.default) }
    let(:url) { "/accounts/#{account.id}" }

    before (:each) do
      course_with_admin_logged_in
    end

    it "should add a new course", priority: "1", test_id: 263241 do
      course_name = 'course 1'
      course_code = '12345'
      get url

      f(".add_course_link").click
      wait_for_ajaximations
      f("#add_course_form #course_name").send_keys(course_name)
      f("#course_course_code").send_keys(course_code)
      submit_dialog_form("#add_course_form")
      refresh_page # we need to refresh the page so the course shows up
      course = Course.where(name: course_name).first
      expect(course).to be_present
      expect(course.course_code).to eq course_code
      expect(f("#course_#{course.id}")).to be_displayed
      expect(f("#course_#{course.id}")).to include_text(course_name)
    end
  end
