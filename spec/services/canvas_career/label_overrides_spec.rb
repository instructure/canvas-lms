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
#

require "spec_helper"

RSpec.describe CanvasCareer::LabelOverrides do
  describe ".permission_label_overrides" do
    context "when context is in career mode" do
      let(:account) { instance_double(Account, is_a?: true, horizon_account?: true) }

      before do
        allow(CanvasCareer::Constants::Overrides).to receive(:permission_label_overrides)
          .and_return({ "manage_students" => "Manage Learners" })
      end

      it "returns the permission label overrides from Constants::Overrides" do
        result = described_class.permission_label_overrides(account)
        expect(result).to eq({ "manage_students" => "Manage Learners" })
      end

      it "calls Constants::Overrides.permission_label_overrides" do
        expect(CanvasCareer::Constants::Overrides).to receive(:permission_label_overrides)
        described_class.permission_label_overrides(account)
      end
    end

    context "when context is not in career mode" do
      let(:regular_account) { instance_double(Account, is_a?: true, horizon_account?: false) }

      it "returns an empty hash for non-horizon account" do
        result = described_class.permission_label_overrides(regular_account)
        expect(result).to eq({})
      end

      it "returns an empty hash for non-Account context" do
        non_account_context = instance_double(Course, is_a?: false)
        result = described_class.permission_label_overrides(non_account_context)
        expect(result).to eq({})
      end

      it "returns an empty hash when context is nil" do
        result = described_class.permission_label_overrides(nil)
        expect(result).to eq({})
      end

      it "does not call Constants::Overrides.permission_label_overrides" do
        expect(CanvasCareer::Constants::Overrides).not_to receive(:permission_label_overrides)
        described_class.permission_label_overrides(regular_account)
      end
    end
  end

  describe ".enrollment_type_overrides" do
    context "when context is in career mode" do
      let(:account) { instance_double(Account, is_a?: true, horizon_account?: true) }

      before do
        allow(CanvasCareer::Constants::Overrides).to receive(:enrollment_type_overrides)
          .and_return({ "StudentEnrollment" => "LearnerEnrollment" })
      end

      it "returns the enrollment type overrides from Constants::Overrides" do
        result = described_class.enrollment_type_overrides(account)
        expect(result).to eq({ "StudentEnrollment" => "LearnerEnrollment" })
      end

      it "calls Constants::Overrides.enrollment_type_overrides" do
        expect(CanvasCareer::Constants::Overrides).to receive(:enrollment_type_overrides)
        described_class.enrollment_type_overrides(account)
      end
    end

    context "when context is not in career mode" do
      let(:regular_account) { instance_double(Account, is_a?: true, horizon_account?: false) }

      it "returns an empty hash for non-horizon account" do
        result = described_class.enrollment_type_overrides(regular_account)
        expect(result).to eq({})
      end

      it "returns an empty hash for non-Account context" do
        non_account_context = instance_double(Course, is_a?: false)
        result = described_class.enrollment_type_overrides(non_account_context)
        expect(result).to eq({})
      end

      it "returns an empty hash when context is nil" do
        result = described_class.enrollment_type_overrides(nil)
        expect(result).to eq({})
      end

      it "does not call Constants::Overrides.enrollment_type_overrides" do
        expect(CanvasCareer::Constants::Overrides).not_to receive(:enrollment_type_overrides)
        described_class.enrollment_type_overrides(regular_account)
      end
    end
  end

  describe ".career_mode?" do
    context "when context is an Account" do
      it "returns true for horizon account" do
        account = instance_double(Account, is_a?: true, horizon_account?: true)
        expect(described_class.career_mode?(account)).to be true
      end

      it "returns false for non-horizon account" do
        account = instance_double(Account, is_a?: true, horizon_account?: false)
        expect(described_class.career_mode?(account)).to be false
      end

      it "caches the result using instance variables" do
        account = instance_double(Account, is_a?: true, horizon_account?: true)

        # First call should call horizon_account?
        expect(account).to receive(:horizon_account?).once.and_return(true)
        expect(account).to receive(:instance_variable_get).with(:@_career_mode).and_return(nil)
        expect(account).to receive(:instance_variable_set).with(:@_career_mode, true).and_return(true)

        result1 = described_class.career_mode?(account)
        expect(result1).to be true
      end

      it "returns cached result on subsequent calls" do
        account = instance_double(Account, is_a?: true)

        # Set up the account to return cached value
        allow(account).to receive(:instance_variable_get).with(:@_career_mode).and_return(true)

        # Should not call horizon_account? since we have cached value
        expect(account).not_to receive(:horizon_account?)

        result = described_class.career_mode?(account)
        expect(result).to be true
      end

      it "handles nil cache values correctly" do
        account = instance_double(Account, is_a?: true, horizon_account?: false)

        # First call: cache is nil, should call horizon_account?
        expect(account).to receive(:instance_variable_get).with(:@_career_mode).and_return(nil)
        expect(account).to receive(:instance_variable_set).with(:@_career_mode, false).and_return(false)

        result = described_class.career_mode?(account)
        expect(result).to be false
      end

      it "distinguishes between nil and false cache values" do
        account = instance_double(Account, is_a?: true)

        # Cache contains false (not nil), should return cached value
        expect(account).to receive(:instance_variable_get).with(:@_career_mode).and_return(false)
        expect(account).not_to receive(:horizon_account?) # Should not be called

        result = described_class.career_mode?(account)
        expect(result).to be false
      end
    end

    context "when context is not an Account" do
      it "returns false for Course context" do
        course = instance_double(Course, is_a?: false)
        expect(described_class.career_mode?(course)).to be false
      end

      it "returns false for User context" do
        user = instance_double(User, is_a?: false)
        expect(described_class.career_mode?(user)).to be false
      end

      it "returns false for nil context" do
        expect(described_class.career_mode?(nil)).to be false
      end

      it "returns false for string context" do
        expect(described_class.career_mode?("not an account")).to be false
      end
    end
  end

  describe "integration scenarios" do
    let(:horizon_account) { instance_double(Account, is_a?: true, horizon_account?: true) }
    let(:regular_account) { instance_double(Account, is_a?: true, horizon_account?: false) }

    before do
      allow(CanvasCareer::Constants::Overrides).to receive_messages(permission_label_overrides: { "manage_students" => "Manage Learners" }, enrollment_type_overrides: { "StudentEnrollment" => "LearnerEnrollment" })
    end

    it "returns consistent results for horizon account across all methods" do
      expect(described_class.career_mode?(horizon_account)).to be true
      expect(described_class.permission_label_overrides(horizon_account)).not_to be_empty
      expect(described_class.enrollment_type_overrides(horizon_account)).not_to be_empty
    end

    it "returns consistent results for regular account across all methods" do
      expect(described_class.career_mode?(regular_account)).to be false
      expect(described_class.permission_label_overrides(regular_account)).to be_empty
      expect(described_class.enrollment_type_overrides(regular_account)).to be_empty
    end
  end
end
