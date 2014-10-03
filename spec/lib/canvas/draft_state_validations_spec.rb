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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

shared_examples_for "Canvas::DraftStateValidations" do
  describe ":validate_draft_state_change" do
    it "should work" do
      subject.workflow_state = 'unpublished'
      subject.stubs(has_student_submissions?: true)
      subject.stubs(workflow_state_changed?: true)
      subject.stubs({
        changes: { 'workflow_state' => [ 'published', 'unpublished' ] }
      })
      subject.save

      subject.errors[:workflow_state].should be_present
      subject.errors[:workflow_state][0].to_s.should match(
        %r{can't unpublish if there are student submissions}i
      )
    end
  end
end
