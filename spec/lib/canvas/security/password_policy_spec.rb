# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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
class CorruptedDownload < StandardError; end

describe Canvas::Security::PasswordPolicy do
  specs_require_cache(:redis_cache_store)

  let(:account) { Account.default }
  let(:policy) { { common_passwords_attachment_id: 1 } }
  let(:attachment) do
    double("Attachment",
           size: 500.kilobytes,
           open: StringIO.new("password1\npassword2\npassword3"),
           root_account: account)
  end
  let(:redis) { Canvas.redis }
  let(:cache_key) { "common_passwords:{#{account.global_id}}/#{policy[:common_passwords_attachment_id]}" }

  before do
    account.enable_feature!(:password_complexity)
    allow(Attachment).to receive(:not_deleted).and_return(double(find_by: attachment))
  end

  describe "validations" do
    def pseudonym_with_policy(policy)
      account.settings[:password_policy] = policy
      account.save
      @pseudonym = Pseudonym.new
      @pseudonym.user = user_factory
      @pseudonym.account = account
      @pseudonym.unique_id = "foo"
    end

    it "only enforces minimum length by default" do
      pseudonym_with_policy({})
      @pseudonym.password = @pseudonym.password_confirmation = "aaaaa"
      expect(@pseudonym).not_to be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "aaaaaaaa"
      expect(@pseudonym).to be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "abcdefgh"
      expect(@pseudonym).to be_valid
    end

    it "does not validate against new policies if :password_complexity is disabled" do
      pseudonym_with_policy({ require_number_characters: "true", require_symbol_characters: "true" })
      @pseudonym.account.disable_feature!(:password_complexity)

      @pseudonym.password = @pseudonym.password_confirmation = "2short"
      expect(@pseudonym).not_to be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "herearesomenumbers1234"
      expect(@pseudonym).to be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "idontneednumbers"
      expect(@pseudonym).to be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "idontneedsymbols"
      expect(@pseudonym).to be_valid
    end

    it "validates confirmation matches" do
      pseudonym_with_policy({})

      @pseudonym.password = "abcdefgh"
      expect(@pseudonym).not_to be_valid
    end

    it "enforces minimum length" do
      pseudonym_with_policy(minimum_character_length: 10)
      @pseudonym.password = @pseudonym.password_confirmation = "asdfg"
      expect(@pseudonym).not_to be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "asdfghijklm"
      expect(@pseudonym).to be_valid

      @pseudonym.account.disable_feature!(:password_complexity)
      @pseudonym.password = @pseudonym.password_confirmation = "asdfghijk"
      expect(@pseudonym).to be_valid
    end

    it "enforces repeated character limits" do
      pseudonym_with_policy(max_repeats: 4)
      @pseudonym.password = @pseudonym.password_confirmation = "aaaaabbbb"
      expect(@pseudonym).not_to be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "aaaabbbb"
      expect(@pseudonym).to be_valid
    end

    it "enforces sequence limits" do
      pseudonym_with_policy(max_sequence: 4)
      @pseudonym.password = @pseudonym.password_confirmation = "edcba1234"
      expect(@pseudonym).not_to be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "dcba1234"
      expect(@pseudonym).to be_valid
    end

    it "does not raise or error when password is shorter than or equal to max_sequence" do
      pseudonym_with_policy(max_sequence: 4)
      @pseudonym.password = @pseudonym.password_confirmation = "abc"
      expect { @pseudonym.valid? }.not_to raise_error
      expect(@pseudonym.errors[:password]).not_to include("sequence")
      @pseudonym.password = @pseudonym.password_confirmation = "abcd"
      expect { @pseudonym.valid? }.not_to raise_error
      expect(@pseudonym.errors[:password]).not_to include("sequence")
    end

    it "rejects passwords longer than 255 characters" do
      pseudonym_with_policy({})
      @pseudonym.password = @pseudonym.password_confirmation = "a" * 255
      expect(@pseudonym).to be_valid
      @pseudonym.password = @pseudonym.password_confirmation = "a" * 256
      expect(@pseudonym).not_to be_valid
    end

    context "when requiring at least one number" do
      before { pseudonym_with_policy({ require_number_characters: "true" }) }

      it "is invalid without a number" do
        @pseudonym.password = @pseudonym.password_confirmation = "Password"
        expect(@pseudonym).not_to be_valid
      end

      it "is valid with at least one number" do
        @pseudonym.password = @pseudonym.password_confirmation = "Password1"
        expect(@pseudonym).to be_valid
      end
    end

    context "when requiring at least one symbol" do
      before { pseudonym_with_policy({ require_symbol_characters: "true" }) }

      it "is invalid without a symbol" do
        @pseudonym.password = @pseudonym.password_confirmation = "Password"
        expect(@pseudonym).not_to be_valid
      end

      it "is valid with at least one symbol" do
        @pseudonym.password = @pseudonym.password_confirmation = "Password!"
        expect(@pseudonym).to be_valid
      end
    end

    context "when validating against a common password dictionary" do
      it "is valid with a password not listed in the provided dictionary" do
        pseudonym_with_policy(policy)
        @pseudonym.password = @pseudonym.password_confirmation = "Password!"
        expect(@pseudonym).to be_valid
      end

      it "is invalid when the password is a member of the provided dictionary" do
        pseudonym_with_policy(policy)
        @pseudonym.password = @pseudonym.password_confirmation = "password1"
        expect(@pseudonym).not_to be_valid
      end

      it "is invalid when the password dictionary member check returns nil" do
        allow(described_class).to receive(:check_password_membership).and_return(nil)
        pseudonym_with_policy(policy)
        @pseudonym.password = @pseudonym.password_confirmation = "Password!"
        expect(@pseudonym).not_to be_valid
      end

      it "falls back to default common password dictionary when password complexity feature is disabled" do
        account.disable_feature!(:password_complexity)
        pseudonym_with_policy(disallow_common_passwords: true)
        @pseudonym.password = @pseudonym.password_confirmation = "Password!"
        expect(@pseudonym).to be_valid
      end

      it "falls back to default common password dictionary when common_passwords_attachment_id is not present" do
        pseudonym_with_policy(disallow_common_passwords: true)
        @pseudonym.password = @pseudonym.password_confirmation = "Password!"
        expect(@pseudonym).to be_valid
      end

      it "falls back to default common password dictionary when attachment is not found" do
        allow(Attachment).to receive(:not_deleted).and_return(double(find_by: nil))
        pseudonym_with_policy(disallow_common_passwords: true)
        @pseudonym.password = @pseudonym.password_confirmation = "Password!"
        expect(@pseudonym).to be_valid
      end

      it "falls back to default common password dictionary when attachment is too large" do
        allow(attachment).to receive(:size).and_return(2.megabytes)
        pseudonym_with_policy(disallow_common_passwords: true)
        @pseudonym.password = @pseudonym.password_confirmation = "Password!"
        expect(@pseudonym).to be_valid
      end

      it "falls back to default common password dictionary when attachment is corrupted" do
        allow(attachment).to receive(:open).and_raise(CorruptedDownload)
        pseudonym_with_policy(disallow_common_passwords: true)
        @pseudonym.password = @pseudonym.password_confirmation = "Password!"
        expect(@pseudonym).to be_valid
      end

      it "falls back to default common password dictionary and still invalidates" do
        pseudonym_with_policy(disallow_common_passwords: true)
        @pseudonym.password = @pseudonym.password_confirmation = "football"
        expect(@pseudonym).not_to be_valid
      end
    end
  end

  describe ".load_common_passwords_file_data" do
    context "when attachment is found and valid" do
      it "loads and returns the common passwords" do
        passwords = described_class.load_common_passwords_file_data(policy)
        expect(passwords).to eq(%w[password1 password2 password3])
      end
    end

    context "when attachment is not found" do
      before do
        allow(Attachment).to receive(:not_deleted).and_return(double(find_by: nil))
      end

      it "returns false" do
        expect(described_class.load_common_passwords_file_data(policy)).to be_falsey
      end
    end

    context "when attachment size is too large" do
      before do
        allow(attachment).to receive(:size).and_return(2.megabytes)
      end

      it "returns false" do
        expect(described_class.load_common_passwords_file_data(policy)).to be_falsey
      end
    end

    context "when attachment is corrupted" do
      before do
        allow(attachment).to receive(:open).and_raise(CorruptedDownload)
      end

      it "logs an error and returns false" do
        expect(Rails.logger).to receive(:error).with(/Corrupted download for common passwords attachment/)
        expect(described_class.load_common_passwords_file_data(policy)).to be_falsey
      end
    end
  end

  describe ".add_password_membership" do
    it "adds passwords to the Redis set" do
      passwords = %w[password1 password2 password3]
      described_class.add_password_membership(cache_key, passwords)

      passwords.each do |password|
        expect(redis.sismember(cache_key, password)).to be_truthy
      end
    end
  end

  describe ".check_password_membership" do
    before do
      passwords = %w[password1 password2 password3]
      described_class.add_password_membership(cache_key, passwords)
    end

    it "returns true if the password is in the Redis set" do
      expect(described_class.check_password_membership(cache_key, "password1", policy)).to be_truthy
    end

    it "returns false if the password is not in the Redis set" do
      expect(described_class.check_password_membership(cache_key, "password4", policy)).to be_falsey
    end

    it "recreates the Redis set if the key gets invalidated by a new attachment_id" do
      new_cache_key = "common_passwords_set_2"
      passwords = %w[password4 password5 password6]
      described_class.add_password_membership(new_cache_key, passwords)

      passwords.each do |password|
        expect(redis.sismember(cache_key, password)).to be_falsey
        expect(redis.sismember(new_cache_key, password)).to be_truthy
      end
    end

    it "returns nil when an error occurs" do
      allow(redis).to receive(:srandmember).with(cache_key).and_raise(Redis::BaseConnectionError)
      expect(described_class.check_password_membership(cache_key, "password1", policy)).to be_nil
    end

    it "returns nil when a Redis::Distributed::CannotDistribute error occurs" do
      allow(redis).to receive(:sismember).with(cache_key, "password1").and_raise(
        Redis::Distributed::CannotDistribute.new(:sismember)
      )
      expect(described_class.check_password_membership(cache_key, "password1", policy)).to be_nil
    end
  end
end
