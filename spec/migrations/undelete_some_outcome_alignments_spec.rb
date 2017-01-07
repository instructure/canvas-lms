#
# Copyright (C) 2013 Instructure, Inc.
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

describe DataFixup::UndeleteSomeOutcomeAlignments do
  before do
    course_with_teacher(:active_all => true)
    outcome_with_rubric
    @rubric_association_object = @course.assignments.create!(:title => 'blah')
    @rubric_association = @rubric.rubric_associations.create!({
      :association_object => @rubric_association_object,
      :context => @course,
      :purpose => 'grading'
    })
  end

  it "should undelete tags on rubrics that should still exist, and their corresponding assignments" do
    align = @rubric.learning_outcome_alignments.first
    align2 = @rubric_association_object.learning_outcome_alignments.first

    data = @rubric.data.map{|h| h.with_indifferent_access}
    Rubric.where(:id => @rubric.id).update_all(:data => data.to_yaml)

    ContentTag.where(:id => [align, align2]).update_all(:workflow_state => 'deleted')
    expect(align.reload).to be_deleted
    expect(align2.reload).to be_deleted

    DataFixup::UndeleteSomeOutcomeAlignments.run
    expect(align.reload).not_to be_deleted
    expect(align2.reload).not_to be_deleted
  end

  it "should not undelete assignments tags that aren't linked to rubrics already undeleted" do
    align = @rubric_association_object.learning_outcome_alignments.first

    ContentTag.where(:id => align).update_all(:workflow_state => 'deleted')
    expect(align.reload).to be_deleted

    DataFixup::UndeleteSomeOutcomeAlignments.run
    expect(align.reload).to be_deleted
  end
end
