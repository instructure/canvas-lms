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

describe "heap_helper" do
  include HeapHelper

  before do
    @session = {}
    Account.site_admin.enable_feature!(:send_usage_metrics)
    @domain_root_account = Account.new
    @domain_root_account.settings[:enable_usage_metrics] = true
    @domain_root_account.save!
  end

  context "with feature enabled" do
    it "is enabled if login is sampled" do
      allow(HeapHelper).to receive(:rand).and_return(0.5)
      allow_any_instance_of(HeapHelper).to receive(:find_heap_application_id).and_return("12345")

      override_dynamic_settings(config: { canvas: { fullstory: { sampling_rate: 1 } } }) do
        expect(load_heap?).to be_truthy
      end
    end

    it "is disabled if login is not sampled" do
      allow(HeapHelper).to receive(:rand).and_return(0.5)
      allow_any_instance_of(HeapHelper).to receive(:find_heap_application_id).and_return("12345")

      override_dynamic_settings(config: { canvas: { fullstory: { sampling_rate: 0 } } }) do
        expect(load_heap?).to be_falsey
      end
    end

    it "retursn true if session is previously set to true" do
      session[:heap_enabled] = true
      allow_any_instance_of(HeapHelper).to receive(:find_heap_application_id).and_return("12345")

      expect(load_heap?).to be_truthy
    end

    it "returns false if session is previously set to false" do
      session[:heap_enabled] = false
      allow_any_instance_of(HeapHelper).to receive(:find_heap_application_id).and_return("12345")

      expect(load_heap?).to be_falsey
    end

    it "returns false if there is no heap id" do
      allow_any_instance_of(HeapHelper).to receive(:find_heap_application_id).and_return(nil)

      expect(load_heap?).to be_falsey
    end

    it "reutrns false if the feature is not eanbled" do
      Account.site_admin.disable_feature!(:send_usage_metrics)

      expect(load_heap?).to be_falsey
    end

    it "is disabled if the dynamic settings are missing" do
      allow(HeapHelper).to receive(:rand).and_return(0.5)
      allow_any_instance_of(HeapHelper).to receive(:find_heap_application_id).and_return(nil)

      override_dynamic_settings(config: { canvas: nil }) do
        expect(load_heap?).to be_falsey
      end
    end
  end
end
