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
require_dependency 'speed_grader/submission'

describe SpeedGrader::Submission do
  let(:submission) do
    instance_double(Submission,
      assignment: assignment,
      submission_comments: submission_comments,
      all_submission_comments: all_submission_comments
    )
  end
  let(:current_user) { instance_double(User) }
  let(:assignment) do
    instance_double(Assignment, grades_published?: false, grade_as_group?: false, can_view_other_grader_comments?: true)
  end
  let(:provisional_grade) do
    instance_double(ModeratedGrading::ProvisionalGrade, submission_comments: provisional_grade_submission_comments)
  end
  let(:submission_comments) { double('submission_comments', for_groups: submission_comments_group_comments) }
  let(:all_submission_comments) { double('all_submission_comments', for_groups: all_submission_comments_group_comments) }
  let(:submission_comments_group_comments) { double('submission_comments_group_comments') }
  let(:all_submission_comments_group_comments) { double('all_submission_comments_group_comments') }
  let(:provisional_grade_submission_comments) do
    double('provisional_grade_submission_comments', for_groups: provisional_grade_submission_comments_group_comments)
  end
  let(:provisional_grade_submission_comments_group_comments) { double('provisional_grade_submission_comments_group_comments') }

  describe '#comments' do
    subject do
      SpeedGrader::Submission.new(
        submission: submission,
        current_user: current_user,
        provisional_grade: provisional_grade
      ).comments
    end

    context 'given grades are published' do
      before { allow(assignment).to receive(:grades_published?).and_return(true) }

      it 'returns submission comments' do
        is_expected.to eql submission_comments
      end

      context 'given a group assignment' do
        before { allow(assignment).to receive(:grade_as_group?).and_return(true) }

        it 'returns submission comments filtered by for_groups scope' do
          is_expected.to eql submission_comments_group_comments
        end
      end
    end

    context 'given grader comments are hidden' do
      before { allow(assignment).to receive(:can_view_other_grader_comments?).and_return(false) }

      it 'returns provisional submission comments' do
        is_expected.to eql provisional_grade_submission_comments
      end

      context 'given a group assignment' do
        before { allow(assignment).to receive(:grade_as_group?).and_return(true) }

        it 'returns provisional grade submission comments filtered by for_groups scope' do
          is_expected.to eql provisional_grade_submission_comments_group_comments
        end
      end

      context 'given no provisional grade' do
        let(:provisional_grade) { nil }

        it 'returns submission comments' do
          is_expected.to eql submission_comments
        end

        context 'given a group assignment' do
          before { allow(assignment).to receive(:grade_as_group?).and_return(true) }

          it 'returns submission comments filtered by for_groups scope' do
            is_expected.to eql submission_comments_group_comments
          end
        end
      end
    end

    context 'given grades are not published and grader comments are not hidden' do
      it 'returns all submission comments' do
        is_expected.to eql all_submission_comments
      end

      context 'given a group assignment' do
        before { allow(assignment).to receive(:grade_as_group?).and_return(true) }

        it 'returns all submission comments filtered by for_groups scope' do
          is_expected.to eql all_submission_comments_group_comments
        end
      end
    end
  end
end
