# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../../spec_helper"

describe SupportHelpers::AssetProcessorNoticeResubmission do
  let(:course) { course_model }
  let(:submission) { submission_model(course:) }
  let(:asset_processor) { lti_asset_processor_model(assignment: submission.assignment) }

  describe "#resubmit_notice" do
    it "notifies the asset processor of a resubmission in course context" do
      fixer = SupportHelpers::AssetProcessorNoticeResubmission.new("email", nil, course)
      expect(Lti::AssetProcessorNotifier).to receive(:notify_asset_processors).with(submission, nil, nil)
      fixer.fix
    end

    it "notifies the asset processor of a resubmission in assignment context" do
      fixer = SupportHelpers::AssetProcessorNoticeResubmission.new("email", nil, submission.assignment)
      expect(Lti::AssetProcessorNotifier).to receive(:notify_asset_processors).with(submission, nil, nil)
      fixer.fix
    end
  end
end
