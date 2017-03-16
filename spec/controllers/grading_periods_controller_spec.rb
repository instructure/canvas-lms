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

  def create_course_grading_period(course, opts = {})
    group = group_helper.legacy_create_for_course(course)
    period = period_helper.create_for_group(group, opts)
    course.enrollment_term.update_attribute(:grading_period_group_id, group)
    period
  end

  def create_account_grading_period(account, opts = {})
    group = group_helper.create_for_account(account)
    period = period_helper.create_for_group(group, opts)
    course.enrollment_term.update_attribute(:grading_period_group_id, group)
    period
  end

  def login_admin
    user = User.create!
    root_account.account_users.create!(user: user)
    user_session(user)
  end

  def login_sub_account
    user_session(account_admin_user(account: sub_account))
  end

  def expect_grading_period_id_match(json, period)
    expect(json['grading_periods'].count).to eql(1)
    returned_period = json['grading_periods'].first
    expect(returned_period['id']).to eql(period.id.to_s)
  end

  before do
    account_admin_user(account: root_account)
    user_session(@admin)
    request.accept = 'application/json'
  end

  describe 'GET index' do
    it "paginates" do
      create_course_grading_period(course)
      get :index, { course_id: course.id }
      expect(json_parse).to have_key('meta')
      expect(json_parse['meta']).to have_key('pagination')
      expect(json_parse['meta']['primaryCollection']).to eql('grading_periods')
    end

    describe 'with root account admins' do
      it 'disallows creating grading periods' do
        get :index, { course_id: course.id }
        expect(json_parse['can_create_grading_periods']).to be false
      end
    end

    describe 'with sub account admins' do
      it 'disallows creating grading periods' do
        login_sub_account
        get :index, { course_id: course.id }
        expect(json_parse['can_create_grading_periods']).to be false
      end
    end

    describe 'with course context' do
      it "can get any course associated grading periods with read_only set to false" do
        period = create_course_grading_period(course)
        get :index, { course_id: course.id }
        expect_grading_period_id_match(json_parse, period)
        expect(json_parse['grading_periods_read_only']).to eql(false)
      end

      it 'is ordered by start_date' do
        create_course_grading_period(course, start_date: 2.days.from_now)
        create_course_grading_period(course, start_date: 5.days.from_now)
        create_course_grading_period(course, start_date: 3.days.from_now)
        get :index, { course_id: course.id }
        expect(json_parse['grading_periods']).to be_sorted_by('start_date')
      end

      it "can get any account associated grading periods with read_only set to true" do
        period = create_account_grading_period(root_account)
        get :index, { course_id: course.id }
        expect_grading_period_id_match(json_parse, period)
        expect(json_parse['grading_periods_read_only']).to eql(true)
      end

      it "gets course associated grading periods if both are available" do
        course_period = create_course_grading_period(course)
        account_period = create_account_grading_period(root_account)
        get :index, { course_id: course.id }
        expect_grading_period_id_match(json_parse, course_period)
      end

      it "sets read_only to false if no grading periods are given" do
        get :index, { course_id: course.id }
        expect(json_parse['grading_periods_read_only']).to eql(false)
      end
    end

    describe 'with account context' do
      it "can get any account associated grading periods with read_only set to false" do
        period = create_account_grading_period(root_account)
        get :index, { account_id: root_account.id }
        expect_grading_period_id_match(json_parse, period)
        expect(json_parse['grading_periods_read_only']).to eql(false)
      end

      it 'is ordered by start_date' do
        create_account_grading_period(root_account, start_date: 2.days.from_now)
        create_account_grading_period(root_account, start_date: 5.days.from_now)
        create_account_grading_period(root_account, start_date: 3.days.from_now)
        get :index, { account_id: root_account.id }
        expect(json_parse['grading_periods']).to be_sorted_by('start_date')
      end

      it "cannot get any course associated grading periods" do
        period = create_course_grading_period(course)
        get :index, { account_id: root_account.id }
        expect(json_parse['grading_periods'].count).to eql(0)
      end

      it "sets read_only to false if no grading periods are given" do
        get :index, { account_id: root_account.id }
        expect(json_parse['grading_periods_read_only']).to eql(false)
      end
    end
  end

  describe 'GET show' do
    it 'can show course associated grading periods' do
      period = create_course_grading_period(course)
      get :show, { course_id: course.id, id: period.to_param }
      expect_grading_period_id_match(json_parse, period)
    end

    it 'can show account associated grading periods' do
      period = create_account_grading_period(root_account)
      get :show, { course_id: course.id, id: period.to_param }
      expect_grading_period_id_match(json_parse, period)
    end

    it 'returns the expected attributes' do
      period = create_course_grading_period(course)
      get :show, { course_id: course.id, id: period.to_param }
      expected_attributes = [
        "id",
        "grading_period_group_id",
        "start_date",
        "end_date",
        "close_date",
        "weight",
        "title",
        "permissions"
      ]
      period_attributes = json_parse['grading_periods'].first.keys
      expect(period_attributes).to match_array(expected_attributes)
    end
  end

  describe "PUT update" do
    before(:each) do
      login_admin
    end

    it "can update any course associated grading periods" do
      period = create_course_grading_period(course, { title: 'Grading Period' })
      put :update, {
        course_id: course.id,
        id: period.to_param,
        grading_periods: [{
          title: 'Grading Period New'
        }]
      }
      expect(period.reload.title).to eql('Grading Period New')
    end

    it "cannot update any account associated grading periods" do
      period = create_account_grading_period(root_account, { title: 'Grading Period' })
      put :update, {
        course_id: course.id,
        id: period.to_param,
        grading_periods: [{
          title: 'Grading Period New'
        }]
      }
      expect(period.reload.title).to eql('Grading Period')
      expect(response).to be_not_found
    end
  end

  describe "DELETE destroy" do
    before(:each) do
      login_admin
    end

    describe "with course context" do
      it "can destroy any course associated grading periods" do
        period = create_course_grading_period(course)
        delete :destroy, { course_id: course.id, id: period.to_param }
        expect(period.reload).to be_deleted
      end

      it "cannot destroy any account associated grading periods" do
        period = create_account_grading_period(root_account)
        delete :destroy, { course_id: course.id, id: period.to_param }
        expect(period.reload).not_to be_deleted
        expect(response).to be_not_found
      end
    end

    describe "with account context" do
      it "can destroy any account associated grading periods" do
        period = create_account_grading_period(root_account)
        delete :destroy, { account_id: root_account.id, id: period.to_param }
        expect(period.reload).to be_deleted
      end

      it "cannot destroy any course associated grading periods" do
        period = create_course_grading_period(course)
        delete :destroy, { account_id: root_account.id, id: period.to_param }
        expect(period.reload).not_to be_deleted
        expect(response).to be_not_found
      end
    end
  end

  describe "PATCH batch_update" do
    describe "with account context" do
      describe "with account associated grading periods" do
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
        let(:group) { group_helper.create_for_account(root_account) }
        let(:period_1) { group.grading_periods.create!(period_1_params) }
        let(:period_2) { group.grading_periods.create!(period_2_params) }

        it "ignores unrelated grading period sets" do
          unrelated_group = group_helper.create_for_account(root_account)
          patch :batch_update, {
            set_id: group.id,
            grading_periods: [period_1_params]
          }
          expect(group.grading_periods.count).to eql(1)
          expect(unrelated_group.grading_periods).to be_empty
        end

        it "compares the in memory periods' dates for overlapping" do
          patch :batch_update, {
            set_id: group.id,
            grading_periods: [
              period_1_params.merge(id: period_1.id, end_date: 3.days.from_now(now), close_date: 3.days.from_now(now)),
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

        describe "with root account admins" do
          before do
            login_admin
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

      describe "with course associated grading periods" do
        let(:period_1_params) do
          {
            title: 'Original Title',
            start_date: 2.days.ago(now).to_s,
            end_date: 2.days.from_now(now).to_s
          }
        end
        let(:group) { group_helper.legacy_create_for_course(course) }
        let(:period_1) { group.grading_periods.create!(period_1_params) }

        before(:each) do
          login_admin
        end

        it "cannot update any grading periods" do
          patch :batch_update, { set_id: group.id, grading_periods: [
            period_1_params.merge(id: period_1.id, title: 'Updated Title')
          ] }
          expect(period_1.reload.title).to eql('Original Title')
          expect(GradingPeriod.for(course).find(period_1.id).title).to eql('Original Title')
        end

        it "responds with 404 not found upon failure" do
          patch :batch_update, { set_id: group.id, grading_periods: [
            period_1_params.merge(id: period_1.id, title: 'Updated Title')
          ] }
          expect(response).to be_not_found
        end
      end
    end

    describe "with course context" do
      describe "with course associated grading periods" do
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
        let(:group) { group_helper.legacy_create_for_course(course) }
        let(:period_1) { group.grading_periods.create!(period_1_params) }
        let(:period_2) { group.grading_periods.create!(period_2_params) }

        it "compares the in memory periods' dates for overlapping" do
          patch :batch_update, {
            course_id: course.id,
            grading_periods: [
              period_1_params.merge(id: period_1.id, end_date: 3.days.from_now(now), close_date: 3.days.from_now(now)),
              period_2_params.merge(id: period_2.id, start_date: 3.days.from_now(now))
            ]
          }
          expect(period_1.reload.end_date).to eql(3.days.from_now(now))
          expect(period_2.reload.start_date).to eql(3.days.from_now(now))
        end

        it "responds with json upon success" do
          request.content_type = 'application/json' unless CANVAS_RAILS4_2
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

        describe "with root account admins" do
          before do
            login_admin
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

        describe "with sub account admins" do
          before do
            login_sub_account
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
      end

      describe "with account associated grading periods" do
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
          login_admin
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
          expect(response.status).to eql(Rack::Utils.status_code(:not_found))
          json = JSON.parse(response.body)
          expect(json['errors']).to be_present
          expect(json).not_to have_key('grading_periods')
        end
      end
    end
  end
end
