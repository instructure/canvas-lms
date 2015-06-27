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
      context 'when context is a sub account' do
        before do
          get :index, { account_id: sub_account.id }
          @json = JSON.parse(remove_while.call(response.body))
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
    let(:root_account) { Account.default }

    let(:first_period_params) do
      {
        title: 'First Grading Period',
        start_date: 2.days.ago.to_s,
        end_date: 2.days.from_now.to_s
      }
    end

    let(:second_period_params) do
      {
        title: 'Second Grading Period',
        start_date: 2.days.from_now(now).to_s,
        end_date: 4.days.from_now(now).to_s
      }
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

    shared_examples "updating parent periods" do |args|
      describe "updating the #{args[:parent_period]} period" do
        let(:changed_period_params) do
          {
            id:         parent_period.id,
            title:      'A New Title',
            start_date: 1.years.from_now(now),
            end_date:   2.year.from_now(now)
          }
        end

        it "copies the grading period to the #{args[:context]}" do
          expect {
            put :batch_update, {
              account_id: account_id,
              course_id: course_id,
              grading_periods: [changed_period_params]
            }
          }.to change{ scope.grading_periods.count }.by 1
          scoped_period = scope.grading_periods.where(title: changed_period_params[:title]).first
          expect(scoped_period.id).to_not eq parent_period.id
          expect(scoped_period.title).to eq changed_period_params[:title]
          expect(scoped_period.start_date).to eq changed_period_params[:start_date]
          expect(scoped_period.end_date).to eq changed_period_params[:end_date]
        end
      end

      describe "saving the #{args[:parent_period]} account period and creating a new period" do
        let(:unchanged_period_params) do
          {
            id:         parent_period.id,
            title:      parent_period.title,
            start_date: parent_period.start_date,
            end_date:   parent_period.end_date
          }
        end

        let(:new_period_params) do
          {
            title:      'new sub account period',
            start_date: parent_period.start_date + 10.days,
            end_date:   parent_period.end_date   + 10.days
          }
        end

        it "copies the grading period to the #{args[:context]} and creates the new period" do
          # OPTIMIZE: wrapping the `put :batch_update` in a let/let! doesn't seem to
          # cache the action so these specs are collapse into one it block.
          # the result has been a speedup of 2x. If it's possible to cache
          # the `put :batch_update`, please split up these expectations!
          expect {
            put :batch_update, {
              account_id: account_id,
              course_id: course_id,
              grading_periods: [unchanged_period_params, new_period_params]
            }
          }.to change{ scope.grading_periods.count }.by 2

          copied_period = scope.grading_periods.where(title: unchanged_period_params[:title]).first
          expect(copied_period.id).to_not     eq unchanged_period_params[:id]
          expect(copied_period.title).to      eq unchanged_period_params[:title]
          expect(copied_period.start_date).to eq unchanged_period_params[:start_date]
          expect(copied_period.end_date).to   eq unchanged_period_params[:end_date]

          new_period = scope.grading_periods.where(title: new_period_params[:title]).first
          expect(new_period.title).to      eq new_period_params[:title]
          expect(new_period.start_date).to eq new_period_params[:start_date]
          expect(new_period.end_date).to   eq new_period_params[:end_date]
        end
      end
    end

    context "given a root account with one period" do
      let!(:root_period) { root_group.grading_periods.create!(first_period_params) }
      let(:root_group) { root_account.grading_period_groups.create! }

      context "as a user associated with a sub account" do
        let(:sub_account) { root_account.sub_accounts.create! }
        let!(:login_and_enable_multiple_grading_periods) do
          user =  User.create!
          sub_account.account_users.create!(:user => user)
          user_session(user)
        end

        include_examples "updating parent periods", context: 'sub account', parent_period: 'root account' do
          let(:parent_period) { root_period }
          let(:account_id) { sub_account.id }
          let(:course_id)  { nil }
          let(:scope)    { sub_account }
        end
      end

      context "as a user associated with a course" do
        let(:sub_account) { root_account.sub_accounts.create! }
        let(:course) { sub_account.courses.create! }
        let(:group) { root_account.grading_period_groups.create! }
        let!(:login_and_enable_multiple_grading_periods) do
          user =  User.create!
          sub_account.account_users.create!(:user => user)
          user_session(user)
        end

        include_examples "updating parent periods", context: 'course', parent_period: 'root account' do
          let(:parent_period) { root_period }
          let(:account_id) { nil }
          let(:course_id)  { course.id }
          let(:scope)    { course }
        end

      end
    end

    context "given a sub account with one period" do
      let!(:sub_account_period) { sub_account_group.grading_periods.create!(first_period_params) }
      let(:sub_account_group)   { sub_account.grading_period_groups.create! }
      let(:sub_account)         { root_account.sub_accounts.create! }

      context "as a user associated with a course" do
        let(:course) { sub_account.courses.create! }
        let(:group) { root_account.grading_period_groups.create! }
        let!(:login_and_enable_multiple_grading_periods) do
          user =  User.create!
          sub_account.account_users.create!(:user => user)
          user_session(user)
        end

        include_examples "updating parent periods", context: 'course', parent_period: 'sub account' do
          let(:parent_period) { sub_account_period }
          let(:account_id) { nil }
          let(:course_id)  { course.id }
          let(:scope)    { course }
        end
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
      expect(response).to be_success
      json = JSON.parse(response.body)
      expect(json['grading_periods']).to be_empty
      expect(json).to_not includes 'errors'
    end

    it "when failure" do
      put :batch_update, { account_id: root_account.id, course_id: nil, grading_periods: [{title: ''}] }
      expect(response).to be_error
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
      expect(json).to_not have_key 'grading_periods'
    end
  end
end
