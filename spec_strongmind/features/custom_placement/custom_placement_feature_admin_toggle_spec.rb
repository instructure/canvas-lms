
require_relative '../../rails_helper'

RSpec.describe 'Custom placement admin feature toggle', type: :feature, js: true do
  include_context 'stubbed_network'

  before do
    account_admin_user
    user_session(@admin)
  end

  context "when setting service not set" do
    it "shows feature NOT being checked (OFF)" do
      allow(SettingsService).to receive(:get_settings).with(object: :school, id: 1).and_return({})

      visit account_settings_path(@admin.account)

      expect(page).to have_selector('label', text: 'Enable student custom placement')
      expect(page).not_to have_checked_field('account_settings_enable_custom_placement')
    end
  end

  context "when setting service set to false" do
    it "shows feature NOT being checked (OFF)" do
      allow(SettingsService).to receive(:get_settings).with(object: :school, id: 1).and_return('enable_custom_placement' => false)

      visit account_settings_path(@admin.account)

      expect(page).to have_selector('label', text: 'Enable student custom placement')
      expect(page).not_to have_checked_field('account_settings_enable_custom_placement')
    end
  end


  context "when setting service set to true" do
    it "shows feature being checked (ON)" do
      allow(SettingsService).to receive(:get_settings).with(object: :school, id: 1).and_return('enable_custom_placement' => true)

      visit account_settings_path(@admin.account)

      expect(page).to have_selector('label', text: 'Enable student custom placement')
      expect(page).to have_checked_field('account_settings_enable_custom_placement')
    end
  end
end
