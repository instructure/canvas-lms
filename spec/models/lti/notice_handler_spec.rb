# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

RSpec.describe Lti::NoticeHandler, type: :model do
  let(:account) { account_model }
  let(:tool) { external_tool_1_3_model }
  let(:notice_type) { "LtiAssetProcessorSubmissionNotice" }
  let(:url) { tool.url + "/handler" }

  describe "validations" do
    subject do
      Lti::NoticeHandler.new(account:, notice_type:, url:, context_external_tool: tool)
    end

    it { is_expected.to validate_presence_of(:account) }
    it { is_expected.to validate_presence_of(:notice_type) }
    it { is_expected.to validate_inclusion_of(:notice_type).in_array(Lti::Pns::NoticeTypes::ALL) }
    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_presence_of(:context_external_tool) }

    it do
      expect(subject).to \
        validate_numericality_of(:max_batch_size)
        .is_greater_than_or_equal_to(10).allow_nil
    end

    it { is_expected.to be_valid }

    it "validates url matches tool" do
      subject.url = "http://definitely-not-the-tool-url.com/"
      expect(subject).not_to be_valid
    end

    it "allows deletion of handlers with bad urls, max_batch_size, or notice_type" do
      subject.save!
      subject.update_column(:url, "http://definitely-not-the-tool-url.com/")
      subject.update_column(:max_batch_size, 1)
      subject.update_column(:notice_type, "not_a_notice_type")
      subject.destroy!
      expect(subject.workflow_state).to eq("deleted")
    end
  end
end
