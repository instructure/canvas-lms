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

describe DataFixup::BackfillAnonymousGradingData do
  before(:once) do
    @root_account = account_model
    course_factory(account: @root_account)
    assignment_model(course: @course)
  end

  def do_backfill
    DataFixup::BackfillAnonymousGradingData.run(@course.id, @course.id+1)
  end
  private :do_backfill

  let(:assignment_anonymously_graded) { @course.assignments.first.anonymous_grading }

  context "when a course has Anonymous Grading disabled" do
    before(:once) do
      @course.disable_feature!(:anonymous_grading)
    end

    it "does not enable Anonymous Marking" do
      do_backfill
      expect(@course).not_to be_feature_enabled(:anonymous_marking)
    end

    it "does not set assignments to be anonymously graded" do
      do_backfill
      expect(assignment_anonymously_graded).to be false
    end
  end

  context "when a course has Anonymous Grading enabled" do
    before(:once) do
      @course.enable_feature!(:anonymous_grading)
    end

    context "when the base Anonymous Moderated Marking flag is off" do
      before(:once) do
        @root_account.disable_feature!(:anonymous_moderated_marking)
      end

      it "does not cause Anonymous Marking for the course to register as enabled" do
        # Note that technically this *does* flip on the Anonymous Marking
        # feature flag for the course, but because it depends on the base
        # AMM flag, any check for whether it's enabled while that flag is
        # off will return false. This is confusing but is the "correct"
        # behavior for these purposes.
        do_backfill
        expect(@course).not_to be_feature_enabled(:anonymous_marking)
      end

      it "sets assignments to be anonymously graded" do
        do_backfill
        expect(assignment_anonymously_graded).to be true
      end
    end

    context "when the base Anonymous Moderated Marking flag is on" do
      before(:once) do
        @root_account.enable_feature!(:anonymous_moderated_marking)
      end

      it "enables Anonymous Marking for the course" do
        do_backfill
        expect(@course).to be_feature_enabled(:anonymous_marking)
      end

      it "sets assignments to be anonymously graded" do
        do_backfill
        expect(assignment_anonymously_graded).to be true
      end
    end
  end
end

