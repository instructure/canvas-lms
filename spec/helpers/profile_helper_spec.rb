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

require_relative "../spec_helper"

describe ProfileHelper do
  let(:dummy_class) { Class.new { include ProfileHelper } }
  let(:dummy_instance) { dummy_class.new }
  let(:user) { double("User") }
  let(:current_pseudonym) { double("Pseudonym") }
  let(:mfa_settings) { :optional }

  before do
    dummy_instance.instance_variable_set(:@user, user)
    dummy_instance.instance_variable_set(:@current_pseudonym, current_pseudonym)
    allow(user).to receive(:mfa_settings).with(pseudonym_hint: current_pseudonym).and_return(mfa_settings)
  end

  describe "#current_mfa_settings" do
    context "when @current_mfa_settings is not set" do
      it "calls mfa_settings on the user and memoizes the result" do
        expect(user).to receive(:mfa_settings).with(pseudonym_hint: current_pseudonym).and_return(mfa_settings)
        expect(dummy_instance.current_mfa_settings).to eq(mfa_settings)
        expect(dummy_instance.instance_variable_get(:@current_mfa_settings)).to eq(mfa_settings)
      end
    end

    context "when @current_mfa_settings is already set" do
      before do
        dummy_instance.instance_variable_set(:@current_mfa_settings, mfa_settings)
      end

      it "returns the memoized value without calling mfa_settings on the user" do
        expect(user).not_to receive(:mfa_settings)
        expect(dummy_instance.current_mfa_settings).to eq(mfa_settings)
      end
    end
  end
end
