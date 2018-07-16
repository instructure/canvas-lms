#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe InfoController do

  describe "GET 'health_check'" do
    it "should work" do
      get 'health_check'
      expect(response).to be_successful
      expect(response.body).to eq 'canvas ok'
    end

    it "should respond_to json" do
      request.accept = "application/json"
      allow(Canvas).to receive(:revision).and_return("Test Proc")
      allow(Canvas::Cdn::RevManifest).to receive(:gulp_manifest).and_return({test_key: "mock_revved_url"})
      get "health_check"
      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json).to have_key('installation_uuid')
      json.delete('installation_uuid')
      expect(json).to eq({
        "status" => "canvas ok",
        "revision" => "Test Proc",
        "asset_urls" => {
          "common_css" => "/dist/brandable_css/new_styles_normal_contrast/bundles/common-#{BrandableCSS.cache_for('bundles/common', 'new_styles_normal_contrast')[:combinedChecksum]}.css",
          "common_js" => ActionController::Base.helpers.javascript_url("#{ENV['USE_OPTIMIZED_JS'] == 'true' ? '/dist/webpack-production' : '/dist/webpack-dev'}/common"),
          "revved_url" => "mock_revved_url"
        }
      })
    end
  end

  describe "GET 'help_links'" do
    it "should work" do
      get 'help_links'
      expect(response).to be_successful
    end

    it "should set the locale for translated help link text from the current user" do
      user = User.create!(locale: 'es')
      user_session(user)
      # create and save account instance so that we don't invoke I18n's
      # localizer lambda in a request filter prior to loading necessary
      # users, accounts, context etc.
      Account.default
      get 'help_links'
      expect(I18n.locale.to_s).to eq 'es'
    end

    it "should filter the links based on the current user's role" do
      account = Account.create!
      allow(Account::HelpLinks).to receive(:default_links).and_return([
        {
          :available_to => ['student'],
          :text => 'Ask Your Instructor a Question',
          :subtext => 'Questions are submitted to your instructor',
          :url => '#teacher_feedback',
          :is_default => 'true'
        },
        {
          :available_to => ['user', 'student', 'teacher', 'admin', 'observer', 'unenrolled'],
          :text => 'Search the Canvas Guides',
          :subtext => 'Find answers to common questions',
          :url => 'http://community.canvaslms.com/community/answers/guides',
          :is_default => 'true'
        },
        {
          :available_to => ['user', 'student', 'teacher', 'admin', 'observer', 'unenrolled'],
          :text => 'Report a Problem',
          :subtext => 'If Canvas misbehaves, tell us about it',
          :url => '#create_ticket',
          :is_default => 'true'
        }
      ])
      allow(LoadAccount).to receive(:default_domain_root_account).and_return(account)
      admin = account_admin_user active_all: true
      user_session(admin)

      get 'help_links'
      links = json_parse(response.body)
      expect(links.select {|link| link[:text] == 'Ask Your Instructor a Question'}.size).to eq 0
    end
  end
end
