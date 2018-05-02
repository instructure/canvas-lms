#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative '../../spec_helper'

RSpec.describe Submissions::AbstractSubmissionForShow do
  let(:course) { Account.default.courses.create! }
  let(:assignment) { course.assignments.create! }

  describe '#assignment' do
    subject(:abstract_submission_for_show) do
      Submissions::AbstractSubmissionForShow.new(context: course, assignment_id: assignment.id)
    end

    it 'finds the active assignment' do
      expect(abstract_submission_for_show.assignment).to eql assignment
    end

    it 'raises an error when assignment is not active' do
      assignment.destroy!
      expect { abstract_submission_for_show.assignment }.to raise_error ActiveRecord::RecordNotFound
    end

    it 'raises an error when assignment is not in the course' do
      other_assignment = Account.default.courses.create!.assignments.create!
      abstract_submission_for_show =
        Submissions::AbstractSubmissionForShow.new(context: course, assignment_id: other_assignment.id)
      expect { abstract_submission_for_show.assignment }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
