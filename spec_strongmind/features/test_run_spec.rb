require_relative '../rails_helper'

RSpec.describe 'This app boots', type: :feature, js: true do
  describe 'getting a login page' do
    it "renders successfully (note: no branding present)" do
      visit '/'

      expect(page).to have_selector('body')
    end
  end
end