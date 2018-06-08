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

require 'spec_helper'

describe DataFixup::BackfillModerationGraders do
  before(:once) do
    @root_account = account_model
    @root_account.enable_feature!(:anonymous_moderated_marking)
    course_factory(account: @root_account)
    @student = User.create!
    @course.enroll_student(@student)
    @teacher = User.create!
    @course.enroll_teacher(@teacher)
    @assignment = @course.assignments.create!(title: 'test')
    @assignment.update_columns(moderated_grading: true, grader_count: 1)
    @assignment.grade_student(@student, grade: 90, provisional: true, grader: @teacher)

    ModerationGrader.delete_all
    @assignment.update_columns(grader_count: 0)
  end

  def do_backfill
    DataFixup::BackfillModerationGraders.run(@assignment.id, @assignment.id+1)
  end
  private :do_backfill

  context "when an assignment has moderated grading disabled" do
    before(:once) do
      @assignment.update_columns(moderated_grading: false)
    end

    it "does not enable Moderated Grading feature flag" do
      do_backfill
      expect(@course).not_to be_feature_enabled(:moderated_grading)
    end

    it "does not set assignments to be anonymously graded" do
      do_backfill
      expect(@assignment.reload.grader_count).to eq 0
    end
  end

  context "when an assignment has moderated grading enabled" do
    it "enables Moderated Grading feature flag for the course" do
      do_backfill
      expect(@course).to be_feature_enabled(:moderated_grading)
    end

    it "creates moderation grader for the assignment" do
      expect { do_backfill }.to change { @assignment.moderation_graders.count }.by(1)
    end

    it "updates grader count" do
      do_backfill
      expect(@assignment.reload.grader_count).to eq 2
    end

    it "creates anonymous id for moderation grader" do
      do_backfill
      expect(@assignment.moderation_graders.first.user_id).to eq @teacher.id
      expect(@assignment.moderation_graders.first.anonymous_id).not_to be_nil
    end

    it "re-running fixup is ok" do
      do_backfill
      expect { do_backfill }.not_to raise_exception
    end
  end
end
