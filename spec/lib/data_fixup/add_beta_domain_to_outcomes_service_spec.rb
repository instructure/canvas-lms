# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe DataFixup::AddBetaDomainToOutcomesService do
  before do
    @account = Account.create!
  end

  it "does not set beta_domain in settings of a non-provisioned account" do
    expect(@account.settings[:provision]).to be_nil
    DataFixup::AddBetaDomainToOutcomesService.run
    expect(Account.find(@account.id).settings[:provision]).to be_nil
  end

  describe "provisioned accounts" do
    it "sets beta_domain in settings of a provisioned account" do
      @account.settings[:provision] = { "outcomes" => {
        domain: "test.outcomes-iad-prod.instructure.com",
        consumer_key: "blah",
        jwt_secret: "woo"
      } }
      @account.save!
      allow(ApplicationController).to receive(:test_cluster_name).and_return("beta")
      expect(@account.settings[:provision]["outcomes"][:beta_domain]).to be_nil
      DataFixup::AddBetaDomainToOutcomesService.run
      expect(Account.find(@account.id).settings[:provision]["outcomes"][:beta_domain]).to eq("test.outcomes-iad-beta.instructure.com")
    end

    it "replace only the end of the url for beta domain" do
      @account.settings[:provision] = { "outcomes" => {
        domain: "test-prod.instructure.com.outcomes-iad-prod.instructure.com",
        consumer_key: "blah",
        jwt_secret: "woo"
      } }
      @account.save!
      allow(ApplicationController).to receive(:test_cluster_name).and_return("beta")
      expect(@account.settings[:provision]["outcomes"][:beta_domain]).to be_nil
      DataFixup::AddBetaDomainToOutcomesService.run
      expect(Account.find(@account.id).settings[:provision]["outcomes"][:beta_domain]).to eq("test-prod.instructure.com.outcomes-iad-beta.instructure.com")
    end

    it "does not set beta_domain if outcomes is not in provision settings" do
      @account.settings[:provision] = {}
      @account.save!
      allow(ApplicationController).to receive(:test_cluster_name).and_return("beta")
      expect(@account.settings[:provision]["outcomes"]).to be_nil
      DataFixup::AddBetaDomainToOutcomesService.run
      expect(Account.find(@account.id).settings[:provision]["outcomes"]).to be_nil
    end
  end
end
