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

require File.expand_path(File.dirname(__FILE__) + '/common')

describe "layout" do
  include_context "in-process server selenium tests"

  before (:each) do
    course_with_student_logged_in
    @user.update_attribute(:name, "</script><b>evil html & name</b>")
    get "/"
  end

  it "should have ENV available to the JavaScript from js_env" do
    expect(driver.execute_script("return ENV.current_user_id")).to eq @user.id.to_s
  end

  it "should escape JSON injected directly into the view" do
    expect(driver.execute_script("return ENV.current_user.display_name")).to eq  "</script><b>evil html & name</b>"
  end
end
