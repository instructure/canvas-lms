#
# Copyright (C) 2015 Instructure, Inc.
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
require_relative '../spec_helper'

describe GradingPeriodsController do
  let(:now) { Time.zone.now.change(usec: 0) }

  let(:root_account) { Account.default }
  let(:sub_account) { root_account.sub_accounts.create! }

  let(:create_grading_periods) do
    ->(context, start) do
      group = context.grading_period_groups.create!
      group.grading_periods.create!(
        weight: 1,
        title: 'an title',
        start_date: start,
        end_date: (10.days.from_now(now))
      )
    end
  end

  let(:remove_while) { ->(string) { string.sub(%r{^while\(1\);}, '') } }

  before do
    root_account.allow_feature!(:multiple_grading_periods)
    root_account.enable_feature!(:multiple_grading_periods)
  end

  context 'given a root account with a grading period and a sub account with a grading period' do
    before do
      account_admin_user(account: root_account)
      user_session(@admin)

      create_grading_periods.call(root_account, 3.days.ago)
      create_grading_periods.call(sub_account, Time.zone.now)
    end

    describe 'GET index' do
      let(:sub_account_admin) { account_admin_user(account: sub_account) }
      context "can_create_grading_periods" do
        it "is a key returned with the collection" do
          get :index, account_id: root_account.id
          expect(json_parse).to have_key 'can_create_grading_periods'
        end

        it "returns true if the context is a root account " \
        "and the user is a root account admin" do
          get :index, account_id: root_account.id
          expect(json_parse['can_create_grading_periods']).to eq true
        end

        it "returns false if the context is not a root account, " \
        "even if the user is a root account admin" do
          get :index, account_id: sub_account.id
          expect(json_parse['can_create_grading_periods']).to eq false
        end
      end

      context "can_toggle_grading_periods" do
        it "is a key returned with the collection" do
          get :index, account_id: root_account.id
          expect(json_parse).to have_key 'can_toggle_grading_periods'
        end

        it "returns true if the user is a root account admin" do
          get :index, account_id: root_account.id
          expect(json_parse['can_toggle_grading_periods']).to eq true
        end

        it "returns false if the user is not a root account admin and the multiple grading "\
        "periods feature flag is not in an 'allowed' state" do
          user_session(sub_account_admin)
          get :index, account_id: sub_account.id
          expect(json_parse['can_toggle_grading_periods']).to eq false
        end

        it "returns true if the user is not a root account admin and the multiple grading "\
        "periods feature flag is in an 'allowed' state" do
          root_account.allow_feature!(:multiple_grading_periods)
          user_session(sub_account_admin)
          get :index, account_id: sub_account.id
          expect(json_parse['can_toggle_grading_periods']).to eq true
        end
      end

      context 'when context is a sub account' do
        before do
          get :index, { account_id: sub_account.id }
          @json = json_parse
        end

        it 'contains one grading periods' do
          expect(@json['grading_periods'].count).to eql 1
        end

        it 'paginates' do
          expect(@json).to have_key('meta')
          expect(@json['meta']).to have_key('pagination')
          expect(@json['meta']['primaryCollection']).to eq 'grading_periods'
        end

        it 'is ordered by start_date' do
          expect(@json['grading_periods']).to be_sorted_by('start_date')
        end
      end

      context 'when context is a course' do
        before do
          course = Course.create!(account: sub_account)

          create_grading_periods.call(course, 5.days.ago)

          get :index, { course_id: course.id }
          @json = JSON.parse(remove_while.call(response.body))
        end

        it 'contains three grading periods' do
          expect(@json['grading_periods'].count).to eql 1
        end
      end
    end

    describe 'GET show' do

      context 'when context is a sub account' do
        it 'contains one grading periods' do
          get :show, { account_id: sub_account.id, id: sub_account.grading_periods.first.id }
          @json = JSON.parse(remove_while.call(response.body))
          expect(@json['grading_periods'].count).to eql 1
        end
      end

      context 'when context is a course' do
        let(:course) { Course.create!(account: sub_account) }
        let(:grading_period) { create_grading_periods.call(course, 5.days.ago) }
        let(:root_grading_period) { root_account.grading_periods.first }

        it 'does not match ids' do
          get :show, { course_id: course.id, id: grading_period.id }
          json = JSON.parse(remove_while.call(response.body))
          period = json['grading_periods'].first
          expect(period['id']).not_to eq root_grading_period.id.to_s
        end
      end
    end
  end

  describe "PUT batch_update" do
    let(:first_period_params) do
      {
        title: 'First Grading Period',
        start_date: 2.days.ago(now).to_s,
        end_date: 2.days.from_now(now).to_s
      }
    end

    let(:second_period_params) do
      {
        title: 'Second Grading Period',
        start_date: 2.days.from_now(now).to_s,
        end_date: 4.days.from_now(now).to_s
      }
    end

    context 'given two consecutive persisted periods' do
      before do
        account_admin_user(account: root_account)
        user_session(@admin)
      end

      let(:group) { root_account.grading_period_groups.create! }
      let!(:first_persisted_period) do
        group.grading_periods.create!(first_period_params)
      end

      let!(:second_persisted_period) do
        group.grading_periods.create!(second_period_params)
      end

      let(:first_changed_params) do
        first_period_params.merge(
          id: first_persisted_period.id,
          end_date: 3.days.from_now(now)
        )
      end

      let(:second_changed_params) do
        second_period_params.merge(
          id: second_persisted_period.id,
          start_date: 3.days.from_now(now)
        )
      end

      it "compares the in memory periods' dates for overlapping" do
        put :batch_update, {
          account_id: root_account.id,
          course_id: nil,
          grading_periods: [
            first_changed_params,
            second_changed_params
          ]
        }
        expect(first_persisted_period.reload.end_date).to    eq 3.days.from_now(now)
        expect(second_persisted_period.reload.start_date).to eq 3.days.from_now(now)
      end
    end

    shared_examples 'batch create and update' do
      let(:first_period) { group.grading_periods.create!(first_period_params) }
      let(:second_period) { group.grading_periods.create!(second_period_params) }

      it "can create a single grading period" do
        expect {
          put :batch_update, { account_id: account_id, course_id: course_id, grading_periods: [first_period_params] }
        }.to change { context.grading_periods.count }.by 1
      end

      it "can create multiple grading periods" do
        expect {
          put :batch_update, {
            account_id: account_id,
            course_id: course_id,
            grading_periods: [first_period_params, second_period_params]
          }
        }.to change { context.grading_periods.count }.by 2
      end

      it "can update a single grading period" do
        put :batch_update, { account_id: account_id, course_id: course_id, grading_periods: [
          first_period_params.merge(id: first_period.id, title: 'An Different Title')
        ] }
        expect(context.grading_periods.find(first_period.id).title).to eq 'An Different Title'
      end

      it "can update multiple grading periods" do
        put :batch_update, { account_id: account_id, course_id: course_id, grading_periods: [
          first_period_params.merge(id: first_period.id,  title: 'An Different Title'),
          second_period_params.merge(id: second_period.id, title: 'Another Different Title')
        ] }
        expect(context.grading_periods.find(first_period.id).title).to  eq 'An Different Title'
        expect(context.grading_periods.find(second_period.id).title).to eq 'Another Different Title'
      end

      it "can create and update multiple grading periods" do
        # first period is being created here because otherwise expect would create the
        # period in the block
        first_period = group.grading_periods.create!(first_period_params)

        expect {
          put :batch_update, { account_id: account_id, course_id: course_id, grading_periods: [
            first_period_params.merge(id: first_period.id,  title: 'An Different Title'),
            second_period_params
          ] }
        }.to change { context.grading_periods.count }.by 1
        expect(context.grading_periods.find(first_period.id).title).to  eq 'An Different Title'
      end
    end

    context "as a user associated with the root account" do
      include_examples "batch create and update" do
        let(:group) { root_account.grading_period_groups.create! }
        let!(:login_and_enable_multiple_grading_periods) do
          user =  User.create!
          root_account.account_users.create!(:user => user)
          user_session(user)

          root_account.allow_feature!(:multiple_grading_periods)
          root_account.enable_feature!(:multiple_grading_periods)
        end

        let(:context)    { root_account }
        let(:account_id) { root_account.id }
        let(:course_id)  { nil }
      end
    end

    context "as a user associated with a sub account" do
      include_examples "batch create and update" do
        let(:sub_account) { root_account.sub_accounts.create! }
        let(:group) { sub_account.grading_period_groups.create! }
        let!(:login_and_enable_multiple_grading_periods) do
          user =  User.create!
          sub_account.account_users.create!(:user => user)
          user_session(user)

          root_account.allow_feature!(:multiple_grading_periods)
          root_account.enable_feature!(:multiple_grading_periods)
        end

        let(:context)    { sub_account }
        let(:account_id) { sub_account.id }
        let(:course_id)  { nil }
      end
    end

    context "as a user associated with a course" do
      include_examples "batch create and update" do
        let(:sub_account) { root_account.sub_accounts.create! }
        let(:course) { sub_account.courses.create! }
        let(:group) { course.grading_period_groups.create! }
        let!(:login_and_enable_multiple_grading_periods) do
          user =  User.create!
          sub_account.account_users.create!(:user => user)
          user_session(user)

          root_account.allow_feature!(:multiple_grading_periods)
          root_account.enable_feature!(:multiple_grading_periods)
        end

        let(:context)    { course }
        let(:account_id) { nil }
        let(:course_id)  { course.id }
      end
    end
  end

  context "it responds with json" do
    before do
      user =  User.create!
      root_account.account_users.create!(:user => user)
      user_session(user)
    end

    it "when success" do
      put :batch_update, { account_id: root_account.id, course_id: nil, grading_periods: [] }
      expect(response).to be_ok
      json = JSON.parse(response.body)
      expect(json['grading_periods']).to be_empty
      expect(json).to_not includes 'errors'
    end

    it "when failure" do
      put :batch_update, { account_id: root_account.id, course_id: nil, grading_periods: [{title: ''}] }
      expect(response).not_to be_ok
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
      expect(json).to_not have_key 'grading_periods'
    end
  end
end
