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

describe AuthenticationProvider::Clever do
  subject(:ap) { AuthenticationProvider::Clever.new(account: Account.default, client_id: "1234") }

  let(:client_id) { "1234" }
  let(:district_id) { "6385008f69df036e83e984a3" }

  # Sample v3.0 API responses based on the upgrade guide
  let(:me_response) do
    {
      "data" => {
        "id" => "63850203bfb8460546071e63",
        "district" => district_id,
        "type" => "user",
        "authorized_by" => "district"
      }
    }
  end

  let(:student_user_data) do
    {
      "data" => {
        "id" => "63850203bfb8460546071e63",
        "district" => district_id,
        "name" => {
          "first" => "John",
          "last" => "Doe"
        },
        "email" => "john.doe@school.edu",
        "roles" => {
          "student" => {
            "sis_id" => "student123",
            "student_number" => "12345",
            "state_id" => "state123",
            "credentials" => {
              "district_username" => "jdoe"
            }
          }
        },
        "demographics" => {
          "home_language" => "English"
        }
      }
    }
  end

  let(:teacher_user_data) do
    {
      "data" => {
        "id" => "63850203bfb8460546071e64",
        "district" => district_id,
        "name" => {
          "first" => "Jane",
          "last" => "Smith"
        },
        "email" => "jane.smith@school.edu",
        "roles" => {
          "teacher" => {
            "sis_id" => "teacher456",
            "teacher_number" => "T001",
            "state_id" => "state456",
            "credentials" => {
              "district_username" => "jsmith"
            }
          }
        },
        "demographics" => {
          "home_language" => "Spanish"
        }
      }
    }
  end

  let(:multi_role_user_data) do
    {
      "data" => {
        "id" => "63850203bfb8460546071e65",
        "district" => district_id,
        "name" => {
          "first" => "Bob",
          "last" => "Wilson"
        },
        "email" => "bob.wilson@school.edu",
        "roles" => {
          "teacher" => {
            "sis_id" => "teacher789",
            "teacher_number" => "T002",
            "credentials" => {
              "district_username" => "bwilson"
            }
          },
          "staff" => {
            "sis_id" => "staff789",
            "credentials" => {
              "district_username" => "bwilson_staff"
            }
          }
        },
        "demographics" => {
          "home_language" => "English"
        }
      }
    }
  end

  def mock_token(user_data, raw_data = me_response)
    me_response_double = double("me_response", parsed: raw_data)
    user_response_double = double("user_response", parsed: user_data)

    token = double("token", options: {})
    allow(token).to receive(:get).with("/v3.0/me").and_return(me_response_double)
    allow(token).to receive(:get).with("/v3.0/users/#{raw_data.dig("data", "id")}").and_return(user_response_double)
    token
  end

  describe "validations" do
    it "validates login_attribute inclusion" do
      ap.login_attribute = "invalid_attribute"
      expect(ap).not_to be_valid
      expect(ap.errors[:login_attribute]).to be_present

      ap.login_attribute = "id"
      expect(ap).to be_valid
    end
  end

  describe "attributes" do
    it "has district_id alias for auth_filter" do
      ap.district_id = "test_district"
      expect(ap.auth_filter).to eq "test_district"
      expect(ap.district_id).to eq "test_district"
    end

    it "defaults login_attribute to 'id'" do
      expect(ap.login_attribute).to eq "id"
    end

    it "allows setting custom login_attribute" do
      ap.login_attribute = "email"
      expect(ap.login_attribute).to eq "email"
    end
  end

  describe "#unique_id" do
    context "with student user" do
      let(:token) { mock_token(student_user_data) }

      it "returns user id when login_attribute is 'id'" do
        ap.login_attribute = "id"
        expect(ap.unique_id(token)).to eq "63850203bfb8460546071e63"
      end

      it "returns email when login_attribute is 'email'" do
        ap.login_attribute = "email"
        expect(ap.unique_id(token)).to eq "john.doe@school.edu"
      end

      it "returns student_number when login_attribute is 'student_number'" do
        ap.login_attribute = "student_number"
        expect(ap.unique_id(token)).to eq "12345"
      end

      it "returns sis_id when login_attribute is 'sis_id'" do
        ap.login_attribute = "sis_id"
        expect(ap.unique_id(token)).to eq "student123"
      end

      it "returns state_id when login_attribute is 'state_id'" do
        ap.login_attribute = "state_id"
        expect(ap.unique_id(token)).to eq "state123"
      end

      it "returns district_username when login_attribute is 'district_username'" do
        ap.login_attribute = "district_username"
        expect(ap.unique_id(token)).to eq "jdoe"
      end
    end

    context "with teacher user" do
      let(:token) { mock_token(teacher_user_data) }

      it "returns teacher_number when login_attribute is 'teacher_number'" do
        ap.login_attribute = "teacher_number"
        expect(ap.unique_id(token)).to eq "T001"
      end

      it "returns sis_id from teacher role when login_attribute is 'sis_id'" do
        ap.login_attribute = "sis_id"
        expect(ap.unique_id(token)).to eq "teacher456"
      end

      it "returns district_username from teacher role when login_attribute is 'district_username'" do
        ap.login_attribute = "district_username"
        expect(ap.unique_id(token)).to eq "jsmith"
      end
    end

    context "with multi-role user" do
      let(:token) { mock_token(multi_role_user_data) }

      it "returns first available sis_id from multiple roles" do
        ap.login_attribute = "sis_id"
        # Should return teacher sis_id since it's checked first in the order
        expect(ap.unique_id(token)).to eq "teacher789"
      end

      it "returns district_username from first available role" do
        ap.login_attribute = "district_username"
        # Should return teacher district_username since teacher is checked before staff
        expect(ap.unique_id(token)).to eq "bwilson"
      end
    end

    context "with district_id filtering" do
      let(:token) { mock_token(student_user_data) }

      it "succeeds when district matches" do
        ap.district_id = district_id
        expect(ap.unique_id(token)).to eq "63850203bfb8460546071e63"
      end

      it "raises error when district doesn't match" do
        ap.district_id = "different_district"
        expect { ap.unique_id(token) }.to raise_error(/Non-matching district/)
      end

      it "succeeds when no district_id is set" do
        ap.district_id = nil
        expect(ap.unique_id(token)).to eq "63850203bfb8460546071e63"
      end
    end

    context "with missing attributes" do
      let(:minimal_user_data) do
        {
          "data" => {
            "id" => "63850203bfb8460546071e63",
            "district" => district_id,
            "name" => {
              "first" => "Test",
              "last" => "User"
            },
            "roles" => {}
          }
        }
      end
      let(:token) { mock_token(minimal_user_data) }

      it "falls back to user data when role-specific attribute is missing" do
        ap.login_attribute = "student_number"
        expect(ap.unique_id(token)).to be_nil
      end

      it "returns top-level attribute when available" do
        minimal_user_data["data"]["email"] = "test@example.com"
        ap.login_attribute = "email"
        expect(ap.unique_id(token)).to eq "test@example.com"
      end
    end
  end

  describe "#provider_attributes" do
    let(:token) { mock_token(student_user_data) }

    it "returns processed user data" do
      attributes = ap.provider_attributes(token)

      expect(attributes["id"]).to eq "63850203bfb8460546071e63"
      expect(attributes["first_name"]).to eq "John"
      expect(attributes["last_name"]).to eq "Doe"
      expect(attributes["email"]).to eq "john.doe@school.edu"
      expect(attributes["home_language"]).to eq "English"
      expect(attributes["district"]).to eq district_id
      expect(attributes["sis_id"]).to eq "student123"
      expect(attributes["student_number"]).to eq "12345"
      expect(attributes["state_id"]).to eq "state123"
      expect(attributes["district_username"]).to eq "jdoe"
    end

    it "only includes recognized federated attributes" do
      attributes = ap.provider_attributes(token)
      expected_keys = AuthenticationProvider::Clever.recognized_federated_attributes + ["district"]
      expect(attributes.keys).to match_array(expected_keys)
    end

    it "caches the result in token options" do
      token = mock_token(student_user_data)
      first_call = ap.provider_attributes(token)
      second_call = ap.provider_attributes(token)

      expect(first_call).to eq(second_call)
      expect(token.options[:me]).to eq(first_call)
    end
  end

  describe "#client_options" do
    it "returns correct Clever API endpoints" do
      options = ap.send(:client_options)
      expect(options[:site]).to eq "https://api.clever.com"
      expect(options[:authorize_url]).to eq "https://clever.com/oauth/authorize"
      expect(options[:token_url]).to eq "https://clever.com/oauth/tokens"
      expect(options[:auth_scheme]).to eq :basic_auth
    end
  end

  describe "#authorize_options" do
    it "includes required scope" do
      options = ap.send(:authorize_options)
      expect(options[:scope]).to eq "read:user_id read:users"
    end

    it "includes district_id when present" do
      ap.district_id = "test_district"
      options = ap.send(:authorize_options)
      expect(options[:district_id]).to eq "test_district"
    end

    it "does not include district_id when nil" do
      ap.district_id = nil
      options = ap.send(:authorize_options)
      expect(options).not_to have_key(:district_id)
    end

    it "does not include district_id when empty" do
      ap.district_id = ""
      options = ap.send(:authorize_options)
      expect(options).not_to have_key(:district_id)
    end
  end

  describe "#scope" do
    it "returns correct v3.0 scopes" do
      expect(ap.send(:scope)).to eq "read:user_id read:users"
    end
  end

  describe "#extract_login_attribute_value" do
    let(:sample_data) do
      {
        "id" => "user123",
        "email" => "user@example.com",
        "roles" => {
          "student" => {
            "sis_id" => "student_sis",
            "student_number" => "S123",
            "state_id" => "state_s123",
            "credentials" => { "district_username" => "student_user" }
          },
          "teacher" => {
            "sis_id" => "teacher_sis",
            "teacher_number" => "T123",
            "state_id" => "state_t123",
            "credentials" => { "district_username" => "teacher_user" }
          },
          "staff" => {
            "sis_id" => "staff_sis",
            "credentials" => { "district_username" => "staff_user" }
          },
          "district_admin" => {
            "sis_id" => "admin_sis",
            "credentials" => { "district_username" => "admin_user" }
          }
        }
      }
    end

    it "extracts district_username from appropriate roles" do
      # Should find student role first
      result = ap.send(:extract_login_attribute_value, sample_data, "district_username")
      expect(result).to eq "student_user"
    end

    it "extracts student_number from student role only" do
      result = ap.send(:extract_login_attribute_value, sample_data, "student_number")
      expect(result).to eq "S123"
    end

    it "extracts teacher_number from teacher role only" do
      result = ap.send(:extract_login_attribute_value, sample_data, "teacher_number")
      expect(result).to eq "T123"
    end

    it "extracts state_id from student or teacher roles" do
      result = ap.send(:extract_login_attribute_value, sample_data, "state_id")
      expect(result).to eq "state_s123" # student comes first in the search order
    end

    it "extracts sis_id from any role" do
      result = ap.send(:extract_login_attribute_value, sample_data, "sis_id")
      expect(result).to eq "student_sis" # student comes first in the search order
    end

    it "extracts top-level attributes directly" do
      result = ap.send(:extract_login_attribute_value, sample_data, "id")
      expect(result).to eq "user123"

      result = ap.send(:extract_login_attribute_value, sample_data, "email")
      expect(result).to eq "user@example.com"
    end

    it "returns nil for missing attributes" do
      result = ap.send(:extract_login_attribute_value, sample_data, "nonexistent")
      expect(result).to be_nil
    end

    it "returns nil for nil attribute" do
      result = ap.send(:extract_login_attribute_value, sample_data, nil)
      expect(result).to be_nil
    end
  end

  describe "#extract_role_attribute" do
    let(:role_data) do
      {
        "roles" => {
          "student" => {
            "sis_id" => "student123",
            "credentials" => { "district_username" => "student_user" }
          },
          "teacher" => {
            "sis_id" => "teacher456",
            "credentials" => { "district_username" => "teacher_user" }
          }
        }
      }
    end

    it "extracts simple attributes from matching roles" do
      result = ap.send(:extract_role_attribute, role_data, %w[student], "sis_id")
      expect(result).to eq "student123"
    end

    it "extracts nested attributes from matching roles" do
      result = ap.send(:extract_role_attribute, role_data, %w[student], "credentials", "district_username")
      expect(result).to eq "student_user"
    end

    it "searches multiple role types in order" do
      result = ap.send(:extract_role_attribute, role_data, %w[teacher student], "sis_id")
      expect(result).to eq "teacher456" # teacher comes first in search order
    end

    it "returns nil when no matching role is found" do
      result = ap.send(:extract_role_attribute, role_data, %w[staff], "sis_id")
      expect(result).to be_nil
    end

    it "returns nil when attribute is not found in any role" do
      result = ap.send(:extract_role_attribute, role_data, %w[student teacher], "nonexistent")
      expect(result).to be_nil
    end

    it "returns first non-empty value found" do
      role_data["roles"]["student"]["sis_id"] = nil
      result = ap.send(:extract_role_attribute, role_data, %w[student teacher], "sis_id")
      expect(result).to eq "teacher456"
    end
  end

  describe "plugin settings" do
    it "accesses client_id from plugin settings" do
      PluginSetting.create!(name: "clever", settings: { client_id: "plugin_id", client_secret: "plugin_secret" })
      ap = AuthenticationProvider::Clever.new
      expect(ap.client_id).to eq "plugin_id"
      expect(ap.client_secret).to eq "plugin_secret"
    end

    it "accesses client_id from itself when not in plugin settings" do
      ap = AuthenticationProvider::Clever.new
      expect(ap.client_id).to be_nil
      expect(ap.client_secret).to be_nil
      ap.client_id = "instance_id"
      ap.client_secret = "instance_secret"
      expect(ap.client_id).to eq "instance_id"
      expect(ap.client_secret).to eq "instance_secret"
    end
  end

  describe "API v3.0 compatibility" do
    context "with API response format changes" do
      let(:token) { mock_token(student_user_data) }

      it "correctly handles consolidated user object" do
        attributes = ap.provider_attributes(token)
        expect(attributes).to include("first_name", "last_name", "email")
        expect(attributes).to include("sis_id", "student_number", "district_username")
      end

      it "processes demographic data" do
        attributes = ap.provider_attributes(token)
        expect(attributes["home_language"]).to eq "English"
      end

      it "extracts role-specific credentials" do
        attributes = ap.provider_attributes(token)
        expect(attributes["district_username"]).to eq "jdoe"
        expect(attributes["student_number"]).to eq "12345"
      end
    end

    context "with multi-role users" do
      let(:token) { mock_token(multi_role_user_data) }

      it "handles users with multiple roles" do
        attributes = ap.provider_attributes(token)
        expect(attributes["sis_id"]).to eq "teacher789" # First available from teacher role
        expect(attributes["district_username"]).to eq "bwilson" # From teacher role
      end
    end
  end
end
