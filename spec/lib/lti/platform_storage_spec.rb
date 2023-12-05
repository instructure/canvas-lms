# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe Lti::PlatformStorage do
  describe "::signing_secret" do
    subject { Lti::PlatformStorage.signing_secret }

    let(:signing_secret) { "sekret" }

    before do
      allow(Rails).to receive(:application).and_return(instance_double("Rails::Application", credentials: {})) unless Rails.application.present?
      allow(Rails.application.credentials).to receive(:dig).with(:lti_platform_storage, :signing_secret).and_return(signing_secret)
    end

    it "should return value from vault" do
      expect(subject).to eq signing_secret
    end
  end

  describe "::FORWARDING_TARGET" do
    subject { Lti::PlatformStorage::FORWARDING_TARGET }

    it { is_expected.to be_a String }
    it { is_expected.to_not be_empty }
  end
end
