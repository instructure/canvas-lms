# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

require 'spec_helper'

describe SupportHelpers::CrocodocController do
  describe 'require_site_admin' do
    it 'should redirect to root url if current user is not a site admin' do
      account_admin_user
      user_session(@user)
      get :shard
      assert_unauthorized
    end

    it 'should redirect to login if current user is not logged in' do
      get :shard
      assert_unauthorized
    end

    it 'should render 200 if current user is a site admin' do
      site_admin_user
      user_session(@user)
      get :shard
      assert_status(200)
    end
  end

  describe 'helper action' do
    before do
      site_admin_user
      user_session(@user)
    end

    context 'shard' do
      it "should create a new ShardFixer" do
        fixer = SupportHelpers::Crocodoc::ShardFixer.new(@user.email)
        expect(SupportHelpers::Crocodoc::ShardFixer).to receive(:new).with(@user.email, nil).and_return(fixer)
        expect(fixer).to receive(:monitor_and_fix)
        get :shard
        expect(response.body).to eq("Enqueued Crocodoc ShardFixer ##{fixer.job_id}...")
      end

      it "should create a new ShardFixer with after_time" do
        fixer = SupportHelpers::Crocodoc::ShardFixer.new(@user.email, '2016-05-01')
        expect(SupportHelpers::Crocodoc::ShardFixer).to receive(:new).
          with(@user.email, Time.zone.parse('2016-05-01')).and_return(fixer)
        expect(fixer).to receive(:monitor_and_fix)
        get :shard, params: {after_time: '2016-05-01'}
        expect(response.body).to eq("Enqueued Crocodoc ShardFixer ##{fixer.job_id}...")
      end
    end

    context 'submission' do
      it "should create a new SubmissionFixer" do
        fixer = SupportHelpers::Crocodoc::SubmissionFixer.new(@user.email, nil, 1234, 5678)
        expect(SupportHelpers::Crocodoc::SubmissionFixer).to receive(:new).
          with(@user.email, nil, 1234, 5678).and_return(fixer)
        expect(fixer).to receive(:monitor_and_fix)
        get :submission, params: {assignment_id: 1234, user_id: 5678}
        expect(response.body).to eq("Enqueued Crocodoc SubmissionFixer ##{fixer.job_id}...")
      end
    end
  end
end
