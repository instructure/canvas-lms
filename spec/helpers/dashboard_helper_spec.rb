#
# Copyright (C) 2012 Instructure, Inc.
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

describe DashboardHelper do
  include DashboardHelper
  
  context "show_welcome_message?" do
    it "should be true if the user has no current enrollments" do
      user_model
      @current_user = @user
      expect(show_welcome_message?()).to be_truthy
    end

    it "should be false otherwise" do
      course_with_student(:active_all => true)
      @current_user = @student
      expect(show_welcome_message?()).to be_falsey
    end
  end
end
