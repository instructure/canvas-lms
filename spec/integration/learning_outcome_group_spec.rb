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

describe LearningOutcomeGroup do
  it "should not loop infinitely with bad ancestral relations" do
    course_with_teacher_logged_in(:active_all => true)
    root = LearningOutcomeGroup.default_for(@course)
    group = @course.learning_outcome_groups.create!(:title => 'groupage')
    root.add_item(group)
    
    #make the group point to itself:
    tag = ContentTag.create(:context => @course, :content => group, :tag_type => 'learning_outcome_association')
    tag.associated_asset = group
    tag.save!

    res = timeout(5) do
      get "/courses/#{@course.id}/outcomes"
    end
    res.should be_true
    response.should be_success
    response.body.should_not =~ %r{<code>execution expired</code>}
  end
end