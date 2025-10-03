# frozen_string_literal: true

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
describe TermsOfService do
  before :once do
    @ac = account_model
    @terms_of_service_content = TermsOfServiceContent.create!(content: "default content")
    @terms_of_service = TermsOfService.create!(terms_type: "default",
                                               terms_of_service_content: @terms_of_service_content,
                                               account: @ac)
  end

  describe "::terms_of_service_workflow_state" do
    it "returns 'deleted' for deleted terms of service" do
      @terms_of_service.destroy!
      expect(@terms_of_service.workflow_state).to eq "deleted"
    end

    it "returns 'active' for Terms of Service Content even if its terms has been deleted" do
      expect(@terms_of_service_content.workflow_state).to eq "active"
    end
  end

  it "creates a Terms of Service defaulting passive to true" do
    ac2 = account_model
    tos = TermsOfService.create!(terms_type: "default",
                                 terms_of_service_content: @terms_of_service_content,
                                 account: ac2)
    expect(tos.passive).to be true
  end

  it "creates a Terms of Service defaulting sets correct options" do
    ac2 = account_model
    expect(TermsOfService.type_dropdown_options_for_account(ac2)[0][1]).to eq "default"
  end

  describe "#ensure_terms_for_account" do
    before do
      TermsOfService.skip_automatic_terms_creation = false
    end

    it "creates a default terms_of_service on root account creation" do
      ac2 = account_model
      expect(ac2.terms_of_service.terms_type).to eq TermsOfService.term_options_for_account(ac2)[:terms_type]
      sub = ac2.sub_accounts.create!
      expect(sub.terms_of_service).to be_nil
    end
  end

  describe ".external_url" do
    before do
      # required by some plugin gems
      Setting.set("terms_of_service_content_default_v2_global_id", @terms_of_service_content.global_id.to_s)
      Setting.set("terms_of_service_content_internet2_global_id", @terms_of_service_content.global_id.to_s)
    end

    it "returns nil in test environment even if there's a setting" do
      @terms_of_service.update!(terms_type: "built_in:default_v2")
      Setting.set("external_aup_url_for_default_v2", "https://example.com/terms")
      expect(TermsOfService.external_url(@ac)).to be_nil
    end

    describe "in non-test environment" do
      before do
        allow(Rails.env).to receive(:test?).and_return(false)
      end

      it "returns nil when no setting exists" do
        ac2 = Account.new
        expect(TermsOfService.external_url(ac2)).to be_nil
      end

      it "returns nil when terms_type doesn't fit the 'built_in:' pattern" do
        @terms_of_service.update!(terms_type: "deffo-not-built-in")
        expect(TermsOfService.external_url(@ac)).to be_nil
      end

      it "returns setting value when a match is found" do
        @terms_of_service.update!(terms_type: "built_in:internet2")
        Setting.set("external_aup_url_for_internet2", "https://example.com/internet2")
        expect(TermsOfService.external_url(@ac)).to eq "https://example.com/internet2"
      end

      it "returns nil when a setting exists but doesn't match" do
        @terms_of_service.update!(terms_type: "built_in:default_v2")
        Setting.set("external_aup_url_for_default_v2", nil)
        expect(TermsOfService.external_url(@ac)).to be_nil
      end
    end
  end
end
