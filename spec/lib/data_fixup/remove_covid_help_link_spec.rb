# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe DataFixup::RemoveCovidHelpLink do
  let(:covid_link) do
    {
      available_to: %w[user student teacher admin observer unenrolled],
      text: "COVID-19 Canvas Resources",
      subtext: "Stay connected.",
      url: "https://community.canvaslms.com/t5/Contingency-Resources/ct-p/contingency",
      type: "default",
      id: :covid,
      is_featured: false,
      is_new: false,
      feature_headline: ""
    }
  end

  let(:guides_link) do
    {
      available_to: %w[user student teacher admin observer unenrolled],
      text: "Search the Canvas Guides",
      subtext: "Find answers to common questions.",
      url: "https://community.canvaslms.com/t5/Canvas/ct-p/canvas",
      type: "default",
      id: :search_the_canvas_guides,
      is_featured: false,
      is_new: false,
      feature_headline: ""
    }
  end

  let(:custom_link) do
    {
      available_to: %w[user student teacher admin],
      text: "Our Help Desk",
      subtext: "Contact us for help.",
      url: "https://example.com/help",
      type: "custom",
      id: :custom_1,
      is_featured: false,
      is_new: false,
      feature_headline: ""
    }
  end

  before(:once) do
    @account = Account.create!(root_account_id: nil)
  end

  context "the account does not have custom_help_links" do
    before do
      @account.settings[:custom_help_links] = nil
      @account.save!
    end

    it "does nothing" do
      expect do
        DataFixup::RemoveCovidHelpLink.run
      end.not_to change { @account.reload.settings[:custom_help_links] }
    end
  end

  context "the account has custom_help_links without a covid link" do
    before do
      @account.settings[:custom_help_links] = [guides_link, custom_link]
      @account.save!
    end

    it "does nothing" do
      expect do
        DataFixup::RemoveCovidHelpLink.run
      end.not_to change { @account.reload.settings[:custom_help_links] }
    end
  end

  context "the account has a non-featured covid link" do
    before do
      @account.settings[:custom_help_links] = [guides_link.merge(is_featured: true), covid_link, custom_link]
      @account.save!
    end

    it "removes the covid link" do
      DataFixup::RemoveCovidHelpLink.run
      links = @account.reload.settings[:custom_help_links]
      expect(links.pluck(:id)).to match_array([:search_the_canvas_guides, :custom_1])
    end

    it "does not change the featured status of other links" do
      DataFixup::RemoveCovidHelpLink.run
      links = @account.reload.settings[:custom_help_links]
      guides = links.find { |l| l[:id] == :search_the_canvas_guides }
      expect(guides[:is_featured]).to be true
    end
  end

  context "the account has a featured covid link" do
    before do
      @account.settings[:custom_help_links] = [guides_link, covid_link.merge(is_featured: true), custom_link]
      @account.save!
    end

    it "removes the covid link" do
      DataFixup::RemoveCovidHelpLink.run
      links = @account.reload.settings[:custom_help_links]
      expect(links.pluck(:id)).to match_array([:search_the_canvas_guides, :custom_1])
    end

    it "sets search_the_canvas_guides as featured" do
      DataFixup::RemoveCovidHelpLink.run
      links = @account.reload.settings[:custom_help_links]
      guides = links.find { |l| l[:id] == :search_the_canvas_guides }
      expect(guides[:is_featured]).to be true
    end
  end

  context "the account has a featured covid link but no search_the_canvas_guides link" do
    before do
      @account.settings[:custom_help_links] = [covid_link.merge(is_featured: true), custom_link]
      @account.save!
    end

    it "removes the covid link without error" do
      DataFixup::RemoveCovidHelpLink.run
      links = @account.reload.settings[:custom_help_links]
      expect(links.pluck(:id)).to eq([:custom_1])
    end
  end
end
