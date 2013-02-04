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

describe "MessageableUser" do
  describe "#common_courses" do
    it "should be empty with no common_course_id selected"
    it "should populate values from comma-delimited common_roles"

    describe "sharding" do
      it_should_behave_like "sharding"
      it "should translate keys to the current shard"
    end
  end

  describe "#common_groups" do
    it "should be empty with no common_group_id selected"
    it "should populate values with 'Member'"

    describe "sharding" do
      it_should_behave_like "sharding"
      it "should translate keys to the current shard"
    end
  end
end
