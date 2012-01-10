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

describe LearningOutcomeGroup do
  
  before do
    course
    @root = LearningOutcomeGroup.default_for(@course)
  end
  
  it "should not create multiple default groups" do
    group = LearningOutcomeGroup.default_for(@course)
    group.should == @root
  end
  
  it "should not add itself as a child" do
    @root.content_tags.count.should == 0
    @root.add_item(LearningOutcomeGroup.find(@root.id))
    @root.content_tags.count.should == 0
  end
  
  it "should not let add_item cause disgusting ancestral relations" do
    group = @course.learning_outcome_groups.create!(:title => 'groupage')
    group2 = @course.learning_outcome_groups.create!(:title => 'groupage2')
    @root.add_item(group)
    @root.add_item(group2)
    
    group.add_item(group2)
    group.content_tags.count.should == 1
    @root.content_tags.count.should == 1

    # shouldn't work because group is already group2's parent
    group2.add_item(group)
    group2.content_tags.count.should == 0
    group.content_tags.count.should == 1
    @root.content_tags.count.should == 1
  end
  
  it "should not let reorder_content cause disgusting ancestral relations" do
    group = @course.learning_outcome_groups.create!(:title => 'groupage')
    group2 = @course.learning_outcome_groups.create!(:title => 'groupage2')
    @root.add_item(group)
    @root.add_item(group2)
    @root.content_tags.count.should == 2
    
    # this is trying to rearrange itself into itself
    group.reorder_content({"learning_outcome_group_#{group.id}"=>"0"})
    group.reload
    group.content_tags.count.should == 0

    # this is okay
    group.reorder_content({"learning_outcome_group_#{group2.id}"=>"0"})
    group.reload
    group.content_tags.count.should == 1

    # this should not work because group is an ancestor of group2
    group2.reorder_content({"learning_outcome_group_#{group.id}"=>"0"})
    group2.reload
    group2.content_tags.count.should == 0
    group.content_tags.count.should == 1
  end
  
  it "should return valid sorted content even if disgusting ancestral relations exist" do
    group = @course.learning_outcome_groups.create!(:title => 'groupage')
    group2 = @course.learning_outcome_groups.create!(:title => 'groupage2')
    group3 = @course.learning_outcome_groups.create!(:title => 'groupage3')
    @root.add_item(group)
    @root.add_item(group2)
    group2.add_item(group3)

    add_group_to_group(group, group, 1)
    add_group_to_group(group2, group, 2)
    add_group_to_group(group, group2, 2)
    add_group_to_group(group2, group2, 3)
    add_group_to_group(group, group3, 1)
    
    @root.sorted_content.map(&:id).should == [group.id, group2.id]
    group.sorted_content.map(&:id).should == []
    group2.sorted_content.map(&:id).should == [group3.id, group.id]
    group3.sorted_content.map(&:id).should == []
  end
  
  
  # used to emulate bad group relations previously created by LearningOutcomeGroup#reorder_content
  # groups could be their own parent/ancestor which isn't possible anymore.
  def add_group_to_group(child, parent, position)
    tag = ContentTag.create(:context => parent.context)
    tag.content = child
    tag.associated_asset = parent
    tag.title = child.title
    tag.tag_type = 'learning_outcome_association'
    tag.position = position
    tag.save!
  end
  
end
