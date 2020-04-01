#
# Copyright (C) 2019 - present Instructure, Inc.
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

require 'spec_helper'

describe DataFixup::BackfillNewDefaultHelpLink do
  let(:new_default_link) do
    {
      :available_to => ['student'],
      :text => -> { I18n.t('#help_dialog.stuff', 'Stuff') },
      :subtext => -> { I18n.t('#help_dialog.things', 'Things') },
      :url => '#teacher_feedback',
      :type => 'default',
      :id => :covid
    }.freeze
  end

  let(:existing_default_link) do
    {
      :available_to => ['student'],
      :text => -> { I18n.t('#help_dialog.hi', 'Hi') },
      :subtext => -> { I18n.t('#help_dialog.hello', 'Hello') },
      :url => '#teacher_feedback',
      :type => 'default',
      :id => :hi_and_hello
    }.freeze
  end

  let(:help_links_builder_double) { double(:help_links_builder) }

  before(:once) do
    @account = Account.create!(root_account_id: nil)
    @account.settings[:custom_help_links] = @account.help_links_builder.instantiate_links([existing_default_link])
    @account.save!
    @original_help_links_builder = @account.help_links_builder
  end

  before(:each) do
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(Account).to receive(:help_links_builder).and_return(help_links_builder_double)
    # rubocop:enable RSpec/AnyInstance
    allow(help_links_builder_double).to receive(:default_links).and_return([])
    allow(help_links_builder_double).to receive(:instantiate_links) { |links| @original_help_links_builder.instantiate_links(links) }
  end

  context "the account does not have a custom_help_links hash" do
    before do
      @account.settings[:custom_help_links] = nil
      @account.save!
    end

    it "does nothing" do
      expect do
        DataFixup::BackfillNewDefaultHelpLink.run(:covid)
      end.to_not change { @account.reload.settings[:custom_help_links] }
    end
  end

  context "the specified help_link_id is not in the default_links for the account" do
    before do
      allow(help_links_builder_double).to receive(:default_links).and_return([existing_default_link])
    end

    it "does nothing" do
      expect do
        DataFixup::BackfillNewDefaultHelpLink.run(:covid)
      end.to_not change { @account.reload.settings[:custom_help_links] }
    end
  end

  context "the specified help_link_id is already in the custom_help_links for the account" do
    before do
      allow(help_links_builder_double).to receive(:default_links).and_return([existing_default_link, new_default_link])
      @account.settings[:custom_help_links] = @original_help_links_builder.instantiate_links([new_default_link])
      @account.save!
    end

    it "does nothing" do
      expect do
        DataFixup::BackfillNewDefaultHelpLink.run(:covid)
      end.to_not change { @account.reload.settings[:custom_help_links] }
    end
  end

  context "the specified help_link_id is not already in the custom_help_links for the account" do
    before do
      allow(help_links_builder_double).to receive(:default_links).and_return([existing_default_link, new_default_link])
    end

    it "adds the help link to custom_help_links" do
      DataFixup::BackfillNewDefaultHelpLink.run(:covid)
      expect(@account.reload.settings[:custom_help_links].map { |hl| hl[:id] }).to match_array([existing_default_link[:id], new_default_link[:id]])
    end
  end
end
