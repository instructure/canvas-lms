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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe 'Models' do

  context "config/initializers/active_record.rb" do

    it "should return the first descendant of ActiveRecord::Base when calling base_ar_class" do
      Account.base_ar_class.should == Account
      Group.base_ar_class.should == Group
      CourseAssignedGroup.base_ar_class.should == Group
      TeacherEnrollment.base_ar_class.should == Enrollment
    end
  end
end
