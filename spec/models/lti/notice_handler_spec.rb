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
  let(:notice_type) { "notice_type" }
  let(:url) { "http://example.com" }

  describe "create" do
    context "without account" do
      it "fails" do
        expect { Lti::NoticeHandler.create!(notice_type:, url:, context_external_tool: tool) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "without notice_type" do
      it "fails" do
        expect { Lti::NoticeHandler.create!(account:, url:, context_external_tool: tool) }.to raise_error(ActiveRecord::NotNullViolation)
      end
    end

    context "without url" do
      it "fails" do
        expect { Lti::NoticeHandler.create!(account:, notice_type:, context_external_tool: tool) }.to raise_error(ActiveRecord::NotNullViolation)
      end
    end

    context "without context_external_tool" do
      it "fails" do
        expect { Lti::NoticeHandler.create!(account:, notice_type:, url:) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "with all valid attributes" do
      it "succeeds" do
        expect { Lti::NoticeHandler.create!(account:, notice_type:, url:, context_external_tool: tool) }.not_to raise_error
      end
    end
  end
end
