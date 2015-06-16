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
  
  before :each do
    course
    @root = @course.root_outcome_group
  end
  
  it "should not create multiple default groups" do
    group = @course.root_outcome_group
    expect(group).to eq @root
  end
  
  it "should not add itself as a child" do
    expect(@root.child_outcome_groups.count).to eq 0
    @root.adopt_outcome_group(LearningOutcomeGroup.find(@root.id))
    expect(@root.child_outcome_groups.count).to eq 0
  end
  
  it "should not let adopt_outcome_group cause disgusting ancestral relations" do
    group = @course.learning_outcome_groups.create!(:title => 'groupage')
    group2 = @course.learning_outcome_groups.create!(:title => 'groupage2')
    @root.adopt_outcome_group(group)
    @root.adopt_outcome_group(group2)
    
    group.adopt_outcome_group(group2)
    expect(group.child_outcome_groups.count).to eq 1
    expect(@root.child_outcome_groups.count).to eq 1

    # shouldn't work because group is already group2's parent
    group2.adopt_outcome_group(group)
    expect(group2.child_outcome_groups.count).to eq 0
    expect(group.child_outcome_groups.count).to eq 1
    expect(@root.child_outcome_groups.count).to eq 1
  end

  it "should allowing touching the context to be skipped" do
    group = @course.learning_outcome_groups.create!(:title => 'groupage')
    group.add_outcome @course.created_learning_outcomes.create!(:title => 'o1')
    group.add_outcome @course.created_learning_outcomes.create!(:title => 'o2')
    group.add_outcome @course.created_learning_outcomes.create!(:title => 'o3')

    time = 1.hour.ago
    Course.where(:id => @course).update_all(:updated_at => time)

    group.skip_tag_touch = true
    group.destroy

    expect(@course.reload.updated_at.to_i).to eq time.to_i
  end
end
