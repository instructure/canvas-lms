# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe ObserverPairingCode do
  before :once do
    @student = user_model
  end

  it "can pass validations" do
    code = ObserverPairingCode.create(user: @student, expires_at: 1.day.from_now, code: SecureRandom.hex(3))
    expect(code.valid?).to be true
  end

  it "can be generated from a user" do
    code = @student.generate_observer_pairing_code
    expect(code).not_to be_nil
  end

  it "can generate more than one code" do
    code = @student.generate_observer_pairing_code
    code2 = @student.generate_observer_pairing_code
    expect(code2.id).not_to eq code.id
  end

  it "ignores expired codes" do
    ObserverPairingCode.create(user: @student, expires_at: 1.day.ago, code: SecureRandom.hex(3))
    codes = @student.observer_pairing_codes
    expect(codes.length).to eq 0
  end
end
