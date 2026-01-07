# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe Accessibility::Concerns::CourseStatisticsQueueable do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new do
      include Accessibility::Concerns::CourseStatisticsQueueable
    end
  end

  let(:test_instance) { test_class.new }
  let(:course) { course_model }

  describe "#queue_course_statistics" do
    context "when a11y_checker_account_statistics feature flag is enabled" do
      before do
        Account.site_admin.enable_feature!(:a11y_checker_account_statistics)
      end

      it "queues course statistics calculation" do
        expect(Accessibility::CourseStatisticCalculatorService).to receive(:queue_calculation).with(course)
        test_instance.queue_course_statistics(course)
      end
    end

    context "when a11y_checker_account_statistics feature flag is disabled" do
      it "does not queue course statistics calculation" do
        expect(Accessibility::CourseStatisticCalculatorService).not_to receive(:queue_calculation)
        test_instance.queue_course_statistics(course)
      end
    end
  end
end
