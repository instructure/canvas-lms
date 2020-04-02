#
# Copyright (C) 2020 - present Instructure, Inc.
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

  describe "fullstory" do
    include FullStoryHelper

    before :each do
      @site_admin_account = Account.site_admin
      @session = {}
    end

    context "with feature enabled" do
      before :each do
        @site_admin_account.enable_feature!(:enable_fullstory)
      end

      it 'is enabled if login is sampled' do
        allow(FullStoryHelper).to receive(:rand).and_return(0.5)
        override_dynamic_settings(config: {canvas: { fullstory: {sampling_rate: 1, app_key: '12345'} } }) do
          fullstory_init(@site_admin_account, @session)
          expect(fullstory_app_key).to eql('12345')
          expect(@session[:fullstory_enabled]).to be_truthy
          expect(fullstory_enabled_for_session?(@session)).to be_truthy
        end
      end

      it 'is disabled if login is not sampled' do
        allow(FullStoryHelper).to receive(:rand).and_return(0.5)
        override_dynamic_settings(config: {canvas: { fullstory: {sampling_rate: 0, app_key: '12345'} } }) do
          fullstory_init(@site_admin_account, @session)
          expect(fullstory_app_key).to eql('12345')
          expect(@session[:fullstory_enabled]).to be_falsey
          expect(fullstory_enabled_for_session?(@session)).to be_falsey
        end
      end

      it "doesn't explode if the dynamic settings are missing" do
        allow(FullStoryHelper).to receive(:rand).and_return(0.5)
        override_dynamic_settings(config: {canvas: { fullstory: nil } }) do
          fullstory_init(@site_admin_account, @session)
          expect(fullstory_app_key).to be_nil
          expect(@session[:fullstory_enabled]).to be_falsey
          expect(fullstory_enabled_for_session?(@session)).to be_falsey
        end
      end
    end

    context "with feature disabled" do
      before :each do
        @site_admin_account.disable_feature!(:enable_fullstory)
      end

      it 'is disabled' do
        allow(FullStoryHelper).to receive(:rand).and_return(0.5)
        override_dynamic_settings(config: {canvas: { fullstory: {sampling_rate: 1, app_key: '12345'} } }) do
          fullstory_init(@site_admin_account, @session)
          expect(fullstory_app_key).to eql('12345')
          expect(@session[:fullstory_enabled]).to be_falsey
          expect(fullstory_enabled_for_session?(@session)).to be_falsey
        end
      end
    end
  end