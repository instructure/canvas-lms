#
# Copyright (C) 2015 Instructure, Inc.
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

describe GradeSummaryAssignmentPresenter do
  let(:summary) {
    GradeSummaryPresenter.new :first, :second, :third
  }

  let(:assignment) {
    Assignment.new
  }

  let(:presenter) {
    GradeSummaryAssignmentPresenter.new(summary,
                                        :current_user,
                                        assignment,
                                        :submission)
  }

  context "#grade_distribution" do
    context "when a summary's assignment_stats is empty" do
      before { summary.stubs(:assignment_stats).returns({}) }

      it "does not raise an error " do
        expect { presenter.grade_distribution }.to_not raise_error
      end

      it "returns nil when a summary's assignment_stats is empty" do
        expect(presenter.grade_distribution).to be_nil
      end
    end
  end
end