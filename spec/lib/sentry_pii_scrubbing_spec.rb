#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../spec_helper"

# Inline PII scrubbing for Sentry events (for FERPA compliance purposes).
# Mirrors PlatformSdk::Sentry::PiiScrubber but uses Rails 5-compatible
# ActionDispatch::Http::ParameterFilter as strongmind-platform-sdk
# requires Rails >= 7.1.
describe "Sentry PII Scrubbing" do
  let(:pii_fields) do
    [
      :email, /\Aname\z/i, :first_name, :last_name, :student_name,
      :username, :phone, :phone_number, :address, :street, :city,
      :zip, :postal_code, :ssn, :social_security, :date_of_birth,
      :dob, :birthday, :ip_address, /\Aip\z/i, :remote_ip,
      :password, :password_confirmation, :token, :secret, :api_key,
      :authorization
    ]
  end

  let(:pii_filter) do
    ActionDispatch::Http::ParameterFilter.new(pii_fields)
  end

  let(:pii_email_regex) do
    /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/
  end

  let(:filtered) { '[FILTERED]' }

  describe "ParameterFilter field scrubbing" do
    it "scrubs email fields" do
      result = pii_filter.filter(
        email: "student@example.com", id: "abc-123"
      )
      expect(result[:email]).to eq(filtered)
      expect(result[:id]).to eq("abc-123")
    end

    it "scrubs name fields via regex anchor" do
      result = pii_filter.filter(name: "Jane Doe", role: "student")
      expect(result[:name]).to eq(filtered)
      expect(result[:role]).to eq("student")
    end

    it "does not scrub partial name matches like username" do
      result = pii_filter.filter(
        username: "jdoe", display_name: "Jane"
      )
      expect(result[:username]).to eq(filtered)
      expect(result[:display_name]).to eq("Jane")
    end

    it "scrubs first_name and last_name" do
      result = pii_filter.filter(
        first_name: "Victor", last_name: "Smith", grade: "A"
      )
      expect(result[:first_name]).to eq(filtered)
      expect(result[:last_name]).to eq(filtered)
      expect(result[:grade]).to eq("A")
    end

    it "scrubs student_name" do
      result = pii_filter.filter(
        student_name: "Violet Jones", course: "Math 101"
      )
      expect(result[:student_name]).to eq(filtered)
      expect(result[:course]).to eq("Math 101")
    end

    it "scrubs contact fields" do
      result = pii_filter.filter(
        phone: "555-1234", address: "123 Main St",
        city: "Phoenix", zip: "85001"
      )
      expect(result[:phone]).to eq(filtered)
      expect(result[:address]).to eq(filtered)
      expect(result[:city]).to eq(filtered)
      expect(result[:zip]).to eq(filtered)
    end

    it "scrubs sensitive identifiers" do
      result = pii_filter.filter(
        ssn: "123-45-6789", date_of_birth: "2010-05-15",
        ip_address: "192.168.1.1"
      )
      expect(result[:ssn]).to eq(filtered)
      expect(result[:date_of_birth]).to eq(filtered)
      expect(result[:ip_address]).to eq(filtered)
    end

    it "scrubs auth-related fields" do
      result = pii_filter.filter(
        password: "s3cret", token: "abc123",
        api_key: "key-456", authorization: "Bearer xyz"
      )
      expect(result[:password]).to eq(filtered)
      expect(result[:token]).to eq(filtered)
      expect(result[:api_key]).to eq(filtered)
      expect(result[:authorization]).to eq(filtered)
    end

    it "handles string keys the same as symbol keys" do
      result = pii_filter.filter(
        "email" => "student@example.com", "id" => "abc-123"
      )
      expect(result["email"]).to eq(filtered)
      expect(result["id"]).to eq("abc-123")
    end
  end

  describe "user hash scrubbing" do
    it "preserves symbol id while scrubbing email" do
      user_hash = { id: "user-42", email: "student@school.edu" }
      scrubbed = pii_filter.filter(user_hash)
      scrubbed[:id] = user_hash[:id]
      expect(scrubbed[:id]).to eq("user-42")
      expect(scrubbed[:email]).to eq(filtered)
    end

    it "preserves string id while scrubbing email" do
      user_hash = { 'id' => "user-42", 'email' => "s@school.edu" }
      scrubbed = pii_filter.filter(user_hash)
      scrubbed['id'] = user_hash['id']
      expect(scrubbed['id']).to eq("user-42")
      expect(scrubbed['email']).to eq(filtered)
    end
  end

  describe "email regex scrubbing in free text" do
    it "scrubs email addresses from messages" do
      message = "User john.doe@school.edu failed to submit"
      scrubbed = message.gsub(pii_email_regex, filtered)
      expect(scrubbed).to eq("User #{filtered} failed to submit")
    end

    it "scrubs multiple email addresses" do
      message = "From a@b.com to c@d.org regarding enrollment"
      scrubbed = message.gsub(pii_email_regex, filtered)
      expect(scrubbed).to eq(
        "From #{filtered} to #{filtered} regarding enrollment"
      )
    end

    it "does not scrub non-email text" do
      message = "Assignment submitted at 3pm for course 101"
      scrubbed = message.gsub(pii_email_regex, filtered)
      expect(scrubbed).to eq(message)
    end
  end

  describe "non-hash input handling" do
    it "returns empty hash for nil input" do
      result = nil.is_a?(Hash) ? pii_filter.filter(nil) : {}
      expect(result).to eq({})
    end

    it "returns empty hash for string input" do
      result = "not a hash".is_a?(Hash) ? pii_filter.filter("x") : {}
      expect(result).to eq({})
    end
  end
end
