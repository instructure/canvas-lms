#
# Copyright (C) 2012 Instructure, Inc.
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
require 'db/migrate/20130523162832_unify_active_assignment_workflow_states'

describe 'UnifyActiveAssignmentWorkflowStates' do
  it "should update the right assignments" do
    course_with_teacher(:active_all => true)
    a1 = @course.assignments.create!(:name => 'hi')
    expect(a1.workflow_state).to eq "published"

    a2 = @course.assignments.create!(:name => 'hi')
    Assignment.where(:id => a2.id).update_all(:workflow_state => "available")
    expect(a2.reload.workflow_state).to eq "available"

    a3 = @course.assignments.create!(:name => 'hi')
    a3.destroy
    expect(a3.workflow_state).to eq "deleted"

    UnifyActiveAssignmentWorkflowStates.up

    expect(a1.reload.workflow_state).to eq "published"
    expect(a2.reload.workflow_state).to eq "published"
    expect(a3.reload.workflow_state).to eq "deleted"
  end
end
