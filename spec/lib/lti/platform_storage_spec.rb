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
  describe "::flag_enabled?" do
    subject { Lti::PlatformStorage.flag_enabled? }

    context "when flag is disabled" do
      before do
        Account.site_admin.disable_feature! :lti_platform_storage
      end

      it { is_expected.to be false }
    end

    context "when flag is enabled" do
      before do
        Account.site_admin.enable_feature! :lti_platform_storage
      end

      it { is_expected.to be true }
    end
  end

  describe "::lti_storage_target" do
    subject { Lti::PlatformStorage.lti_storage_target }

    before do
      allow(Lti::PlatformStorage).to receive(:flag_enabled?).and_return(flag_enabled)
    end

    context "when flag is disabled" do
      let(:flag_enabled) { false }

      it "returns default target" do
        expect(subject).to eq Lti::PlatformStorage::DEFAULT_TARGET
      end
    end

    context "when flag is enabled" do
      let(:flag_enabled) { true }

      it "returns forwarding target" do
        expect(subject).to eq Lti::PlatformStorage::FORWARDING_TARGET
      end
    end
  end

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
end
