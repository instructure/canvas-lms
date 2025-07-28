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
#

describe Canvas::Security::PasswordPolicyAccountSettingValidator do
  subject { dummy_account_class.new }

  let(:dummy_account_class) do
    Class.new do
      include Canvas::Security::PasswordPolicyAccountSettingValidator
      include ActiveModel::Validations

      def initialize
        @errors = ActiveModel::Errors.new(self)
      end

      def t(message, options = {})
        message % options
      end
    end
  end

  describe "#validate_password_policy_for" do
    context "when setting value is an integer" do
      it "does not add an error" do
        subject.validate_password_policy_for("minimum_character_length", "10")
        expect(subject.errors).to be_empty
      end
    end

    context "when setting value is not an integer" do
      it "adds an error" do
        subject.validate_password_policy_for("minimum_character_length", "ten")
        expect(subject.errors).not_to be_empty
        expect(subject.errors.first.message).to include("An integer value is required")
      end
    end

    context "when setting value is negative" do
      it "adds an error" do
        subject.validate_password_policy_for("minimum_character_length", "-1")
        expect(subject.errors).not_to be_empty
        expect(subject.errors.first.message).to include("Value must be positive")
      end
    end
  end

  describe "validating specific settings" do
    context "when setting is minimum_character_length" do
      it "validates minimum" do
        subject.errors.clear
        subject.validate_password_policy_for("minimum_character_length", "4")
        expect(subject.errors).not_to be_empty
        expect(subject.errors.first.message).to include("Must be at least")
      end

      it "validates maximum" do
        subject.errors.clear
        subject.validate_password_policy_for("minimum_character_length", "365")
        expect(subject.errors).not_to be_empty
        expect(subject.errors.first.message).to include("Must not exceed")
      end
    end

    context "when setting is maximum_login_attempts" do
      it "validates minimum" do
        subject.errors.clear
        subject.validate_password_policy_for("maximum_login_attempts", "2")
        expect(subject.errors).not_to be_empty
        expect(subject.errors.first.message).to include("Must be at least")
      end

      it "validates maximum" do
        subject.errors.clear
        subject.validate_password_policy_for("maximum_login_attempts", "21")
        expect(subject.errors).not_to be_empty
        expect(subject.errors.first.message).to include("Must not exceed")
      end
    end
  end
end
