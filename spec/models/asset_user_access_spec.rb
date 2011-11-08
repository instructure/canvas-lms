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

describe AssetUserAccess do
  it "should update existing records that have bad display names" do
    course = Account.default.courses.create!(:name => 'My Course')
    assignment = course.assignments.create!(:title => 'My Assignment')
    u = User.create!
    
    asset = factory_with_protected_attributes(AssetUserAccess, :user => u, :context => course, :asset_code => assignment.asset_string)
    asset.display_name = assignment.asset_string
    asset.save!
    
    asset.display_name.should == "My Assignment"
  end
end
