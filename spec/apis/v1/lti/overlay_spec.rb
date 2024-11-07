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

require_relative "../../api_spec_helper"

describe Api::V1::Lti::Overlay do
  let(:tester) { Class.new { include Api::V1::Lti::Overlay }.new }

  let(:user) { user_model }
  let(:data) { { title: "Test" } }
  let(:account) { account_model }
  let(:registration) { lti_registration_model(account:) }
  let(:overlay) { lti_overlay_model(account:, registration:, updated_by: user, data:) }

  before do
    overlay
  end

  describe "#lti_overlay_json" do
    subject { tester.lti_overlay_json(overlay, user, {}, account) }

    it "includes all expected base attributes" do
      expect(subject).to include({
                                   id: overlay.id,
                                   account_id: overlay.account_id,
                                   registration_id: overlay.registration_id,
                                   workflow_state: overlay.workflow_state,
                                   created_at: overlay.created_at,
                                   updated_at: overlay.updated_at,
                                   root_account_id: overlay.root_account_id,
                                   data:
                                 })
    end

    it "includes a basic user object for updated_by" do
      expect(subject[:updated_by]).to include({
                                                id: overlay.updated_by.id,
                                              })
    end
  end

  describe ".find_in_site_admin" do
    subject { Lti::Overlay.find_in_site_admin(registration) }

    let(:account) { Account.site_admin }

    it "returns overlay" do
      expect(subject).to eq(overlay)
    end

    context "with caching" do
      specs_require_cache(:redis_cache_store)

      it "caches the result" do
        allow(Lti::Overlay).to receive(:find_by).and_call_original
        subject
        # call it again
        Lti::Overlay.find_in_site_admin(registration)
        expect(Lti::Overlay).to have_received(:find_by).once
      end
    end
  end

  describe ".find_all_in_site_admin" do
    subject { Lti::Overlay.find_all_in_site_admin(registrations) }

    let(:account) { Account.site_admin }
    let(:registrations) { [registration1, registration2] }
    let(:registration1) { lti_registration_model(account:, name: "first") }
    let(:registration2) { lti_registration_model(account:, name: "second") }
    let(:overlay1) { lti_overlay_model(account:, registration: registration1, updated_by: user, data:) }
    let(:overlay2) { lti_overlay_model(account:, registration: registration2, updated_by: user, data:) }

    context "with no registrations" do
      let(:registrations) { [] }

      it "returns empty array" do
        expect(subject).to eq([])
      end
    end

    context "with non-site admin registrations" do
      let(:extra_overlay) { lti_overlay_model(account: account_model, registration: extra_registration) }
      let(:extra_registration) { lti_registration_model(account: account_model) }
      let(:registrations) { [extra_registration] }

      before do
        extra_overlay
      end

      it "filters them out" do
        expect(subject).to eq([])
      end
    end

    it "returns all overlays for all registrations" do
      expect(subject).to include(overlay1, overlay2)
    end

    context "with caching" do
      specs_require_cache(:redis_cache_store)

      let(:list_cache_key) { Lti::Overlay.site_admin_list_cache_key(registrations) }

      it "caches the result" do
        subject
        expect(MultiCache.fetch(list_cache_key, nil)).to eq([overlay1, overlay2])
      end

      it "caches the pointer" do
        subject
        registrations.each do |registration|
          expect(MultiCache.fetch(Lti::Overlay.pointer_to_list_key(registration), nil)).to eq(list_cache_key)
        end
      end
    end
  end

  describe "#clear_cache_if_site_admin" do
    subject { overlay.update!(data: { hello: "world" }) }

    let(:cache_key) { Lti::Overlay.site_admin_cache_key(overlay.registration) }
    let(:list_cache_key) { Lti::Overlay.site_admin_list_cache_key([overlay.registration]) }

    context "with mocks" do
      before do
        allow(MultiCache).to receive(:delete).and_return(true)
        allow(MultiCache).to receive(:fetch).and_call_original
        allow(MultiCache).to receive(:fetch).with(Lti::Overlay.pointer_to_list_key(overlay.registration), nil).and_return(list_cache_key)
      end

      context "when account is site admin" do
        let(:account) { Account.site_admin }

        it "clears the cache" do
          subject
          expect(MultiCache).to have_received(:delete).with(cache_key)
          expect(MultiCache).to have_received(:delete).with(list_cache_key)
        end
      end

      context "when account is not site admin" do
        let(:account) { account_model }

        it "does not clear the cache" do
          subject
          expect(MultiCache).not_to have_received(:delete).with(cache_key)
          expect(MultiCache).not_to have_received(:delete).with(list_cache_key)
        end
      end
    end

    context "with caching" do
      specs_require_cache(:redis_cache_store)

      let(:account) { Account.site_admin }

      before do
        Lti::Overlay.find_in_site_admin(overlay.registration)
        Lti::Overlay.find_all_in_site_admin([overlay.registration])
      end

      it "clears the cache" do
        expect(MultiCache.fetch(cache_key, nil)).to eq(overlay)
        expect(MultiCache.fetch(list_cache_key, nil)).to eq([overlay])

        subject

        expect(MultiCache.fetch(cache_key, nil)).to be_nil
        expect(MultiCache.fetch(list_cache_key, nil)).to be_nil
      end
    end
  end
end
