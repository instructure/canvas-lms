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

describe DataFixup::FixOutOfSyncOutcomeAlignments do
  before do
    course_with_teacher_logged_in(:active_all => true)
    outcome_with_rubric
    @rubric_association_object = @course.assignments.create!(:title => 'blah')
    @rubric_association = @rubric.rubric_associations.create!({
      :association_object => @rubric_association_object,
      :context => @course,
      :purpose => 'grading'
    })
  end

  it "should not delete active alignments" do
    align1 = @rubric_association_object.learning_outcome_alignments.first
    align2 = @rubric.learning_outcome_alignments.first

    expect(align1.reload).not_to be_deleted
    expect(align2.reload).not_to be_deleted

    DataFixup::FixOutOfSyncOutcomeAlignments.run

    expect(align1.reload).not_to be_deleted
    expect(align2.reload).not_to be_deleted
  end

  it "should delete alignments to deleted rubrics" do
    align = @rubric.learning_outcome_alignments.first
    Rubric.where(:id => @rubric.id).update_all(:workflow_state => 'deleted')

    expect(align.reload).not_to be_deleted
    DataFixup::FixOutOfSyncOutcomeAlignments.run
    expect(align.reload).to be_deleted
  end

  it "should delete alignments to rubrics that no longer should be aligned" do
    align = @rubric.learning_outcome_alignments.first
    data = @rubric.data
    data.first.delete(:learning_outcome_id)
    Rubric.where(:id => @rubric.id).update_all(:data => data.to_yaml)

    expect(align.reload).not_to be_deleted
    DataFixup::FixOutOfSyncOutcomeAlignments.run
    expect(align.reload).to be_deleted
  end

  it "should delete alignments to assignments without rubrics" do
    align = @rubric_association_object.learning_outcome_alignments.first
    RubricAssociation.where(:rubric_id => @rubric.id).delete_all

    expect(align.reload).not_to be_deleted
    DataFixup::FixOutOfSyncOutcomeAlignments.run
    expect(align.reload).to be_deleted
  end

  it "should delete alignments to assignments with rubrics without matching alignments" do
    align = @rubric_association_object.learning_outcome_alignments.first
    lo = LearningOutcome.create!(short_description: 's')
    @rubric.learning_outcome_alignments.update_all(:learning_outcome_id => lo)

    expect(align.reload).not_to be_deleted
    DataFixup::FixOutOfSyncOutcomeAlignments.run
    expect(align.reload).to be_deleted
  end
end
