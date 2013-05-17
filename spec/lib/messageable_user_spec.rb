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
  describe ".build_select" do
    it "should ignore common_course_column without common_role_column" do
      MessageableUser.build_select(:common_course_column => 'ignored_column').
        should match(/NULL AS common_courses/)
    end

    it "should require common_course_column with common_role_column" do
      lambda{ MessageableUser.build_select(:common_role_column => 'role_column') }.
        should raise_error(ArgumentError)
    end

    it "should combine common_course_column and common_role_column in common_courses" do
      course_with_student(:active_all => true)
      messageable_user = MessageableUser.
        select(MessageableUser.build_select(
          :common_course_column => "'course_column'",
          :common_role_column => "'role_column'")).
        where(:id => @student).
        group(MessageableUser.connection.group_by(*MessageableUser::COLUMNS)).
        first
      messageable_user.send(:read_attribute, :common_courses).
        should == "course_column:role_column"
    end

    it "should combine multiple (course,role) pairs in common_courses" do
      course_with_ta(:active_all => true)
      multiple_student_enrollment(@ta, @course.course_sections.create!)
      messageable_user = MessageableUser.
        select(MessageableUser.build_select(
          :common_course_column => "'course'",
          :common_role_column => 'enrollments.type')).
        joins('INNER JOIN enrollments ON enrollments.user_id=users.id').
        where(:id => @ta.id).
        group(MessageableUser.connection.group_by(*MessageableUser::COLUMNS)).
        first
      messageable_user.send(:read_attribute, :common_courses).split(/,/).sort.
        should == ["course:StudentEnrollment", "course:TaEnrollment"]
    end

    it "should combine multiple common_group_column values in common_groups" do
      group1 = group_with_user(:active_all => true).group
      group2 = group_with_user(:user => @user, :active_all => true).group
      messageable_user = MessageableUser.
        select(MessageableUser.build_select(:common_group_column => "group_memberships.group_id")).
        joins('INNER JOIN group_memberships ON group_memberships.user_id=users.id').
        where(:id => @user).
        group(MessageableUser.connection.group_by(*MessageableUser::COLUMNS)).
        first
      messageable_user.send(:read_attribute, :common_groups).split(/,/).map(&:to_i).sort.
        should == [group1.id, group2.id].sort
    end
  end

  describe ".prepped" do
    it "should group by id" do
      MessageableUser.prepped().scope(:find, :group).
        should match(MessageableUser::COLUMNS.first)
    end

    it "should include column-based common_course_column in group by" do
      MessageableUser.prepped(:common_course_column => 'course_column').scope(:find, :group).
        should match('course_column')
    end

    it "should include column-based common_group_column in group by" do
      MessageableUser.prepped(:common_group_column => 'group_column').scope(:find, :group).
        should match('group_column')
    end

    it "should not include literal common_course_column value in group by" do
      MessageableUser.prepped(:common_course_column => 5).scope(:find, :group).
        should_not match('5')
    end

    it "should not include literal common_group_column value in group by" do
      MessageableUser.prepped(:common_group_column => 5).scope(:find, :group).
        should_not match('5')
    end

    it "should order by short_name before name or id" do
      user1 = user(:active_all => 1, :short_name => 'Bob', :name => 'Yellow Bob')
      user2 = user(:active_all => 1, :short_name => 'Alice', :name => 'Zebra Alice')
      MessageableUser.prepped().first.id.should == user2.id
    end

    it "should ignore case when ordering by short_name" do
      user1 = user(:active_all => 1, :short_name => 'bob')
      user2 = user(:active_all => 1, :short_name => 'ALICE')
      MessageableUser.prepped().first.id.should == user2.id
    end

    it "should order by name before id" do
      user1 = user(:active_all => 1, :name => 'Bob')
      user2 = user(:active_all => 1, :name => 'Alice')
      MessageableUser.prepped().first.id.should == user2.id
    end

    it "should ignore case when ordering by name" do
      user1 = user(:active_all => 1, :name => 'bob')
      user2 = user(:active_all => 1, :name => 'ALICE')
      MessageableUser.prepped().first.id.should == user2.id
    end

    it "should order by id as tiebreaker" do
      user1 = user(:active_all => 1, :short_name => 'Alice')
      user2 = user(:active_all => 1, :short_name => 'Alice')
      MessageableUser.prepped().first.id.should == user1.id
    end

    it "should exclude creation_pending students with strict_checks true" do
      user(:user_state => 'creation_pending')
      MessageableUser.prepped(:strict_checks => true).length.should == 0
    end

    it "should include creation_pending students with strict_checks false" do
      user(:user_state => 'creation_pending')
      MessageableUser.prepped(:strict_checks => false).length.should == 1
    end

    it "should exclude deleted students with include_deleted true but strict_checks true" do
      user(:user_state => 'deleted')
      MessageableUser.prepped(:strict_checks => true, :include_deleted => true).length.should == 0
    end

    it "should exclude deleted students with with strict_checks false but include_deleted false" do
      user(:user_state => 'deleted')
      MessageableUser.prepped(:strict_checks => false, :include_deleted => false).length.should == 0
    end

    it "should include deleted students with strict_checks false and include_deleted true" do
      user(:user_state => 'deleted')
      MessageableUser.prepped(:strict_checks => false, :include_deleted => true).length.should == 1
    end

    it "should default strict_checks to true" do
      user(:user_state => 'creation_pending')
      MessageableUser.prepped().length.should == 0
    end

    it "should default include_delete to false" do
      user(:user_state => 'deleted')
      MessageableUser.prepped(:strict_checks => false).length.should == 0
    end
  end

  describe "#common_courses" do
    before do
      user(:active_all => 1)
    end

    it "should be empty with no common_courses selected" do
      MessageableUser.prepped().first.common_courses.
        should == {}
    end

    it "should populate from non-null common_courses" do
      user = MessageableUser.prepped(:common_course_column => 1, :common_role_column => "'StudentEnrollment'").first
      user.common_courses.should == {1 => ['StudentEnrollment']}
    end

    describe "sharding" do
      specs_require_sharding

      it "should translate keys to the current shard" do
        user = MessageableUser.prepped(:common_course_column => @shard2.relative_id_for(1), :common_role_column => "'StudentEnrollment'").first
        [Shard.default, @shard1, @shard2].each do |shard|
          shard.activate do
            user.common_courses.should == {@shard2.relative_id_for(1) => ['StudentEnrollment']}
          end
        end
      end
    end
  end

  describe "#common_groups" do
    before do
      user(:active_all => 1)
    end

    it "should be empty with no common_groups selected" do
      MessageableUser.prepped().first.common_groups.
        should == {}
    end

    it "should populate from non-null common_groups with 'Member' roles" do
      user = MessageableUser.prepped(:common_group_column => 1).first
      user.common_groups.should == {1 => ['Member']}
    end

    describe "sharding" do
      specs_require_sharding

      it "should translate keys to the current shard" do
        user = MessageableUser.prepped(:common_group_column => @shard2.relative_id_for(1)).first
        [Shard.default, @shard1, @shard2].each do |shard|
          shard.activate do
            user.common_groups.should == {@shard2.relative_id_for(1) => ['Member']}
          end
        end
      end
    end
  end
end
