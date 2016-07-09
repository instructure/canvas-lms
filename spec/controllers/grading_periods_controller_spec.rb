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

  let(:group_helper)  { Factories::GradingPeriodGroupHelper.new }
  let(:period_helper) { Factories::GradingPeriodHelper.new }

  let(:root_account) { Account.default }
  let(:sub_account)  { root_account.sub_accounts.create! }

  let(:course) { sub_account.courses.create! }

  before do
    account_admin_user(account: root_account)
    user_session(@admin)
    root_account.enable_feature!(:multiple_grading_periods)
    request.accept = 'application/json'
  end

  describe 'GET index' do
    let(:get_index!) { get :index, { course_id: course.id } }
    let(:json) { json_parse }

    context 'with course grading periods' do
      before do
        period_helper.create_with_group_for_course(course)
      end

      it 'contains grading periods owned by the course' do
        get_index!
        expect(json['grading_periods'].count).to eql(1)
      end

      it 'paginates' do
        get_index!
        expect(json).to have_key('meta')
        expect(json['meta']).to have_key('pagination')
        expect(json['meta']['primaryCollection']).to eql('grading_periods')
      end

      it 'is ordered by start_date' do
        get_index!
        expect(json['grading_periods']).to be_sorted_by('start_date')
      end

      it "sets 'grading_periods_read_only' to false" do
        get_index!
        expect(json['grading_periods_read_only']).to eql(false)
      end
    end

    context 'with no grading periods' do
      it "sets 'grading_periods_read_only' to false" do
        get_index!
        expect(json['grading_periods_read_only']).to eql(false)
      end
    end

    context 'with account grading periods' do
      it "sets 'grading_periods_read_only' to true" do
        group = group_helper.create_for_account(root_account)
        course.enrollment_term.update_attribute(:grading_period_group_id, group)
        period_helper.create_for_group(group)
        get_index!
        expect(json['grading_periods_read_only']).to eql(true)
      end
    end

    context 'with root account admins' do
      before do
        period_helper.create_with_group_for_course(course)
      end

      it 'disallows creating grading periods' do
        root_account.enable_feature!(:multiple_grading_periods)
        get_index!
        expect(json['can_create_grading_periods']).to eql(false)
      end

      it 'allows toggling grading periods when multiple grading periods are enabled' do
        root_account.enable_feature!(:multiple_grading_periods)
        get_index!
        expect(json['can_toggle_grading_periods']).to eql(true)
      end

      it "returns 'not found' when multiple grading periods are allowed" do
        root_account.allow_feature!(:multiple_grading_periods)
        get_index!
        expect(response).to be_not_found
      end

      it "returns 'not found' when multiple grading periods are disabled" do
        root_account.disable_feature!(:multiple_grading_periods)
        get_index!
        expect(response).to be_not_found
      end
    end

    context 'with sub account admins' do
      let(:sub_account_admin) { account_admin_user(account: sub_account) }

      before do
        period_helper.create_with_group_for_course(course)
      end

      it 'disallows creating grading periods' do
        root_account.enable_feature!(:multiple_grading_periods)
        user_session(sub_account_admin)
        get_index!
        expect(json['can_create_grading_periods']).to eql(false)
      end

      it 'disallows toggling grading periods when multiple grading periods are root account enabled' do
        root_account.enable_feature!(:multiple_grading_periods)
        user_session(sub_account_admin)
        get_index!
        expect(json['can_toggle_grading_periods']).to eql(false)
      end

      it "returns 'not found' when multiple grading periods are root account disabled" do
        root_account.disable_feature!(:multiple_grading_periods)
        user_session(sub_account_admin)
        get_index!
        expect(response).to be_not_found
      end

      it "returns 'not found' when multiple grading periods are allowed" do
        root_account.allow_feature!(:multiple_grading_periods)
        user_session(sub_account_admin)
        get_index!
        expect(response).to be_not_found
      end

      it "returns 'not found' when multiple grading periods are sub account disabled" do
        root_account.allow_feature!(:multiple_grading_periods)
        sub_account.disable_feature!(:multiple_grading_periods)
        user_session(sub_account_admin)
        get_index!
        expect(response).to be_not_found
      end
    end
  end

  describe 'GET show' do
    it 'contains grading periods owned by the course' do
      grading_period = period_helper.create_with_group_for_course(course)
      get :show, { course_id: course.id, id: grading_period.id }
      json = json_parse
      expect(json['grading_periods'].count).to eql(1)
      period = json['grading_periods'].first
      expect(period['id']).to eql(grading_period.id.to_s)
    end
  end

  describe "PATCH batch_update for a grading period set" do
    let(:period_1_params) do
      {
        title: 'First Grading Period',
        start_date: 2.days.ago(now).to_s,
        end_date: 2.days.from_now(now).to_s
      }
    end
    let(:period_2_params) do
      {
        title: 'Second Grading Period',
        start_date: 2.days.from_now(now).to_s,
        end_date: 4.days.from_now(now).to_s
      }
    end
    let(:term) { root_account.enrollment_terms.create! }
    let(:group) { group_helper.create_for_enrollment_term(term) }
    let(:period_1) { group.grading_periods.create!(period_1_params) }
    let(:period_2) { group.grading_periods.create!(period_2_params) }

    context 'given two consecutive persisted periods' do
      it "compares the in memory periods' dates for overlapping" do
        patch :batch_update, {
          set_id: group.id,
          grading_periods: [
            period_1_params.merge(id: period_1.id, end_date: 3.days.from_now(now)),
            period_2_params.merge(id: period_2.id, start_date: 3.days.from_now(now))
          ]
        }
        expect(period_1.reload.end_date).to eql(3.days.from_now(now))
        expect(period_2.reload.start_date).to eql(3.days.from_now(now))
      end

      it "does not paginate" do
        period_params = (1..11).map do|i|
          {
            title: "Period #{i}",
            start_date: i.days.from_now(now),
            end_date: (i+1).days.from_now(now)
          }
        end
        patch :batch_update, {
          set_id: group.id,
          grading_periods: period_params
        }
        json = JSON.parse(response.body)
        expect(json).not_to have_key('meta')
        expect(json.fetch('grading_periods').count).to eql 11
      end
    end

    context "as a user associated with the root account" do
      before do
        user = User.create!
        root_account.account_users.create!(:user => user)
        user_session(user)
      end

      it "can create a single grading period" do
        expect do
          patch :batch_update, { set_id: group.id, grading_periods: [period_1_params] }
        end.to change { group.grading_periods.count }.by 1
      end

      it "can create multiple grading periods" do
        expect do
          patch :batch_update, {
            set_id: group.id,
            grading_periods: [period_1_params, period_2_params]
          }
        end.to change { group.grading_periods.count }.by 2
      end

      it "can update a single grading period" do
        patch :batch_update, { set_id: group.id, grading_periods: [
          period_1_params.merge(id: period_1.id, title: 'Updated Title')
        ] }
        expect(group.reload.grading_periods.find(period_1.id).title).to eq 'Updated Title'
      end

      it "can update multiple grading periods" do
        patch :batch_update, { set_id: group.id, grading_periods: [
          period_1_params.merge(id: period_1.id, title: 'Original Title'),
          period_2_params.merge(id: period_2.id, title: 'Updated Title')
        ] }
        expect(group.reload.grading_periods.find(period_1.id).title).to eql('Original Title')
        expect(group.reload.grading_periods.find(period_2.id).title).to eql('Updated Title')
      end

      it "can create and update multiple grading periods" do
        period_1 = group.grading_periods.create!(period_1_params)
        expect do
          patch :batch_update, { set_id: group.id, grading_periods: [
            period_1_params.merge(id: period_1.id, title: 'A Different Title'),
            period_2_params
          ] }
        end.to change { group.grading_periods.count }.by 1
        expect(group.reload.grading_periods.find(period_1.id).title).to eql('A Different Title')
      end
    end
  end

  describe "PATCH batch_update for course grading periods" do
    let(:period_1_params) do
      {
        title: 'First Grading Period',
        start_date: 2.days.ago(now).to_s,
        end_date: 2.days.from_now(now).to_s
      }
    end
    let(:period_2_params) do
      {
        title: 'Second Grading Period',
        start_date: 2.days.from_now(now).to_s,
        end_date: 4.days.from_now(now).to_s
      }
    end
    let(:group) { group_helper.create_for_course(course) }
    let(:period_1) { group.grading_periods.create!(period_1_params) }
    let(:period_2) { group.grading_periods.create!(period_2_params) }

    context 'given two consecutive persisted periods' do
      it "compares the in memory periods' dates for overlapping" do
        patch :batch_update, {
          course_id: course.id,
          grading_periods: [
            period_1_params.merge(id: period_1.id, end_date: 3.days.from_now(now)),
            period_2_params.merge(id: period_2.id, start_date: 3.days.from_now(now))
          ]
        }
        expect(period_1.reload.end_date).to eql(3.days.from_now(now))
        expect(period_2.reload.start_date).to eql(3.days.from_now(now))
      end
    end

    context "as a user associated with the root account" do
      before do
        user = User.create!
        root_account.account_users.create!(:user => user)
        user_session(user)
      end

      it "cannot create a single grading period" do
        expect do
          patch :batch_update, { course_id: course.id, grading_periods: [period_1_params] }
        end.not_to change { course.grading_periods.count }
        expect(response.status).to eql(Rack::Utils.status_code(:unauthorized))
      end

      it "cannot create multiple grading periods" do
        expect do
          patch :batch_update, {
            course_id: course.id,
            grading_periods: [period_1_params, period_2_params]
          }
        end.not_to change { course.grading_periods.count }
      end

      it "can update a single grading period" do
        patch :batch_update, { course_id: course.id, grading_periods: [
          period_1_params.merge(id: period_1.id, title: 'Original Title')
        ] }
        expect(course.grading_periods.find(period_1.id).title).to eql('Original Title')
      end

      it "can update multiple grading periods" do
        patch :batch_update, { course_id: course.id, grading_periods: [
          period_1_params.merge(id: period_1.id, title: 'Original Title'),
          period_2_params.merge(id: period_2.id, title: 'Updated Title')
        ] }
        expect(course.grading_periods.find(period_1.id).title).to eql('Original Title')
        expect(course.grading_periods.find(period_2.id).title).to eql('Updated Title')
      end

      it "cannot create and update multiple grading periods" do
        period_1 = group.grading_periods.create!(period_1_params)
        expect do
          patch :batch_update, { course_id: course.id, grading_periods: [
            period_1_params.merge(id: period_1.id, title: 'Original Title'),
            period_2_params
          ] }
        end.not_to change { course.grading_periods.count }
        expect(course.grading_periods.find(period_1.id).title).not_to eql('Original Title')
      end
    end

    context "as a user associated with a sub account" do
      before do
        user = User.create!
        sub_account.account_users.create!(:user => user)
        user_session(user)
      end

      it "cannot create a single grading period" do
        expect do
          patch :batch_update, { course_id: course.id, grading_periods: [period_1_params] }
        end.not_to change { course.grading_periods.count }
        expect(response.status).to eql(Rack::Utils.status_code(:unauthorized))
      end

      it "cannot create multiple grading periods" do
        expect do
          patch :batch_update, {
            course_id: course.id,
            grading_periods: [period_1_params, period_2_params]
          }
        end.not_to change { course.grading_periods.count }
      end

      it "can update a single grading period" do
        patch :batch_update, { course_id: course.id, grading_periods: [
          period_1_params.merge(id: period_1.id, title: 'Original Title')
        ] }
        expect(course.grading_periods.find(period_1.id).title).to eql('Original Title')
      end

      it "can update multiple grading periods" do
        patch :batch_update, { course_id: course.id, grading_periods: [
          period_1_params.merge(id: period_1.id, title: 'Original Title'),
          period_2_params.merge(id: period_2.id, title: 'Updated Title')
        ] }
        expect(course.grading_periods.find(period_1.id).title).to eql('Original Title')
        expect(course.grading_periods.find(period_2.id).title).to eql('Updated Title')
      end

      it "cannot create and update multiple grading periods" do
        period_1 = group.grading_periods.create!(period_1_params)
        expect do
          patch :batch_update, { course_id: course.id, grading_periods: [
            period_1_params.merge(id: period_1.id, title: 'Original Title'),
            period_2_params
          ] }
        end.not_to change { course.grading_periods.count }
        expect(course.grading_periods.find(period_1.id).title).not_to eql('Original Title')
      end
    end

    it "responds with json upon success" do
      patch :batch_update, { course_id: course.id, grading_periods: [] }
      expect(response).to be_ok
      json = JSON.parse(response.body)
      expect(json['grading_periods']).to be_empty
      expect(json).not_to includes('errors')
    end

    it "responds with json upon failure" do
      period = period_helper.create_with_group_for_course(course)
      patch :batch_update, { course_id: course.id, grading_periods: [{id: period.id, title: ''}] }
      expect(response).not_to be_ok
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
      expect(json).not_to have_key('grading_periods')
    end
  end

  describe "PATCH batch_update with a course for account-level grading periods" do
    let(:period_1_params) do
      {
        title: 'Original Title',
        start_date: 2.days.ago(now).to_s,
        end_date: 2.days.from_now(now).to_s
      }
    end
    let(:group) { group_helper.create_for_account(root_account) }
    let(:period_1) { group.grading_periods.create!(period_1_params) }

    before(:each) do
      user = User.create!
      root_account.account_users.create!(:user => user)
      user_session(user)
      course.enrollment_term.update_attribute(:grading_period_group_id, group)
    end

    it "cannot update any grading periods" do
      patch :batch_update, { course_id: course.id, grading_periods: [
        period_1_params.merge(id: period_1.id, title: 'Updated Title')
      ] }
      expect(period_1.reload.title).to eql('Original Title')
      expect(GradingPeriod.for(course).find(period_1.id).title).to eql('Original Title')
    end

    it "responds with json upon failure" do
      patch :batch_update, { course_id: course.id, grading_periods: [
        period_1_params.merge(id: period_1.id, title: 'Updated Title')
      ] }
      expect(response.status).to eql(Rack::Utils.status_code(:unauthorized))
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
      expect(json).not_to have_key('grading_periods')
    end
  end

  describe "DELETE destroy with a course for course-level grading periods" do
    it "can destroy any grading periods" do
      user = User.create!
      root_account.account_users.create!(:user => user)
      user_session(user)

      group = group_helper.legacy_create_for_course(course)
      period = period_helper.create_for_group(group)
      course.enrollment_term.update_attribute(:grading_period_group_id, group)

      delete :destroy, { course_id: course.id, id: period.to_param }
      expect(period.reload).to be_deleted
    end
  end

  describe "DELETE destroy with a course for account-level grading periods" do
    let(:group) { group_helper.create_for_account(root_account) }
    let(:period) { period_helper.create_for_group(group) }

    before(:each) do
      user = User.create!
      root_account.account_users.create!(:user => user)
      user_session(user)
      course.enrollment_term.update_attribute(:grading_period_group_id, group)
    end

    it "cannot destroy any grading periods" do
      delete :destroy, { course_id: course.id, id: period.to_param }
      expect(period.reload).not_to be_deleted
      expect(GradingPeriod.for(course).find(period.id).title).to eql('Example Grading Period')
    end

    it "responds with json upon failure" do
      delete :destroy, { course_id: course.id, id: period.to_param }
      expect(response.status).to eql(Rack::Utils.status_code(:unauthorized))
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
      expect(json).not_to have_key('grading_periods')
    end
  end
end
