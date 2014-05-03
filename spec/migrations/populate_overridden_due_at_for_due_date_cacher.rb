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
require 'lib/data_fixup/populate_overridden_due_at_for_due_date_cacher.rb'

describe DataFixup::PopulateOverriddenDueAtForDueDateCacher do
  before do
    course_with_student(:active_all => true)
    @assignment1 = assignment_model(:course => @course)
    assignment_model(:course => @course)
    @section = @course.course_sections.create!
    student_in_section(@section, :course => @course)

    # Create an override
    @due_at = @assignment.due_at - 1.day
    assignment_override_model(:assignment => @assignment, :set => @section)
    @override.override_due_at(@due_at)
    @override.save!

    # Delete Submissions simulating current data state.
    @assignment.submissions.destroy_all
    @assignment1.submissions.destroy_all
  end

  it "should recompute cached date dues for overridden assignments" do
    DueDateCacher.expects(:recompute_batch).once.with([@assignment.id])

    DataFixup::PopulateOverriddenDueAtForDueDateCacher.run
  end

  it "should create submission for overridden assignments" do
    DataFixup::PopulateOverriddenDueAtForDueDateCacher.run

    @assignment1.reload
    @assignment1.submissions.size.should eql(0)

    @assignment.reload
    @assignment.submissions.size.should eql(1)
    @submission = @assignment.submissions.first

    @submission.user.should == @user
    @submission.assignment.should == @assignment
    @submission.cached_due_date.should == @due_at
  end
end
