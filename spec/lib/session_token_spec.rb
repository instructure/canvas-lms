#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../spec_helper'

describe SessionToken do
  it "should be valid after serialization and parsing" do
    token = SessionToken.new(1)
    token_string = token.to_s
    new_token = SessionToken.parse(token_string)
    expect(new_token).to be_valid

    # there was an error with the padding of the base64 encoding for a different sized token
    token = SessionToken.new(1145874)
    token_string = token.to_s
    new_token = SessionToken.parse(token_string)
    expect(new_token).to be_valid
  end

  it "should preserve pseudonym_id" do
    token = SessionToken.new(1)
    expect(SessionToken.parse(token.to_s).pseudonym_id).to eq token.pseudonym_id
  end

  it "should preserve nil current_user_id" do
    token = SessionToken.new(1)
    expect(SessionToken.parse(token.to_s).current_user_id).to be_nil
  end

  it "should preserve non-nil current_user_id" do
    token = SessionToken.new(1, current_user_id: 2)
    expect(SessionToken.parse(token.to_s).current_user_id).to eq token.current_user_id
  end

  it "should preserve nil used_remember_me_token" do
    token = SessionToken.new(1)
    expect(SessionToken.parse(token.to_s).used_remember_me_token).to be_nil
  end

  it "should preserve non-nil used_remember_me_token" do
    token = SessionToken.new(1, used_remember_me_token: true)
    expect(SessionToken.parse(token.to_s).used_remember_me_token).to eq token.used_remember_me_token
  end

  it "should not be valid after tampering" do
    token = SessionToken.new(1)
    token.pseudonym_id = 2
    expect(SessionToken.parse(token.to_s)).not_to be_valid
  end

  it "should not be valid with out of bounds created_at" do
    token = SessionToken.new(1)

    token.created_at -= (SessionToken::VALIDITY_PERIOD + 5).seconds
    token.signature = Canvas::Security.hmac_sha1(token.signature_string)
    expect(SessionToken.parse(token.to_s)).not_to be_valid

    token.created_at += (2 * SessionToken::VALIDITY_PERIOD + 10).seconds
    token.signature = Canvas::Security.hmac_sha1(token.signature_string)
    expect(SessionToken.parse(token.to_s)).not_to be_valid

    token.created_at -= (SessionToken::VALIDITY_PERIOD + 5).seconds
    token.signature = Canvas::Security.hmac_sha1(token.signature_string)
    expect(SessionToken.parse(token.to_s)).to be_valid
  end

  it "should not parse with invalid syntax or contents" do
    # bad base64
    expect(SessionToken.parse("{}")).to be_nil

    # good base64, bad json
    bad_token = Base64.encode64("[[]").tr('+/', '-_').gsub(/=|\n/, '')
    expect(SessionToken.parse(bad_token)).to be_nil

    # good json, wrong data structure
    expect(SessionToken.parse(JSONToken.encode([]))).to be_nil

    # good json, extra field
    token = SessionToken.new(1)
    data = token.as_json.merge(:extra => 1)
    expect(SessionToken.parse(JSONToken.encode(data))).to be_nil

    # good json, missing field
    data = token.as_json.slice(:created_at, :pseudonym_id, :current_user_id, :signature)
    expect(SessionToken.parse(JSONToken.encode(data))).to be_nil

    # good json, wrong data types
    data = token.as_json.merge(:created_at => 'invalid')
    expect(SessionToken.parse(JSONToken.encode(data))).to be_nil

    data = token.as_json.merge(:pseudonym_id => 'invalid')
    expect(SessionToken.parse(JSONToken.encode(data))).to be_nil

    data = token.as_json.merge(:current_user_id => 'invalid')
    expect(SessionToken.parse(JSONToken.encode(data))).to be_nil

    data = token.as_json.merge(:used_remember_me_token => 'invalid')
    expect(SessionToken.parse(JSONToken.encode(data))).to be_nil

    data = token.as_json.merge(:signature => 1)
    expect(SessionToken.parse(JSONToken.encode(data))).to be_nil
  end
end
