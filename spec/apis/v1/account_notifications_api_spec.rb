#
# Copyright (C) 2012 - 2013 Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe 'Account Notification API', type: :request do
  include Api
  include Api::V1::AccountNotifications

  before do
    @admin = account_admin_user
    user_with_pseudonym(:user => @admin)
  end

  describe 'user_index' do
    before do
      account_notification(message: 'default')
      @path = "/api/v1/accounts/#{@admin.account.id}/users/#{@admin.id}/account_notifications"
      @api_params = {controller: 'account_notifications',
                     action: 'user_index',
                     format: 'json',
                     user_id: @admin.id,
                     account_id: @admin.account.id.to_s}
    end

    it "should list notifications" do
      account_notification(message: 'second')
      json = api_call(:get, @path, @api_params,)
      expect(json.length).to eq 2
    end
  end

  describe 'user_close_notification' do
    before do
      @a = account_notification(message: 'default')
      @path = "/api/v1/accounts/#{@admin.account.id}/users/#{@admin.id}/account_notifications/#{@a.id}"
      @api_params = {controller: 'account_notifications',
                     action: 'user_close_notification',
                     format: 'json',
                     id: @a.id.to_param,
                     user_id: @admin.id,
                     account_id: @admin.account.id.to_s}
    end

    it "should close notifications" do
      json = api_call(:delete, @path, @api_params)
      @admin.reload
      expect(@admin.preferences[:closed_notifications]).to eq [@a.id]

      json = api_call(:get, "/api/v1/accounts/#{@admin.account.id}/users/#{@admin.id}/account_notifications", @api_params.merge(action: 'user_index'),)
      expect(json.length).to eq 0
    end
  end

  describe 'create' do
    before :each do
      @path = "/api/v1/accounts/#{@admin.account.id}/account_notifications"
      @api_params = { :controller => 'account_notifications',
                      :action => 'create',
                      :format => 'json',
                      :account_id => @admin.account.id.to_s }
      @start_at = DateTime.now.utc
      @end_at = (DateTime.now + 1.day).utc
    end

   it 'should create an account notification' do
      json = api_call(:post, @path, @api_params,
                       { :account_notification => {
                           :subject => 'New global notification',
                           :start_at => @start_at.iso8601,
                           :end_at => @end_at.iso8601,
                           :message => 'This is a notification',
                           :icon => 'information'}})
      expect(json.keys).to include 'start_at'
      expect(json.keys).to include 'end_at'
      expect(json['subject']).to eq 'New global notification'
      expect(json['message']).to eq 'This is a notification'
      expect(json['icon']).to eq 'information'
      expect(json['roles']).to eq []
    end

    it 'should default icon to warning' do
      json = api_call(:post, @path, @api_params,
                       { :account_notification => {
                           :subject => 'New global notification',
                           :start_at => @start_at.iso8601,
                           :end_at => @end_at.iso8601,
                           :message => 'This is a notification'}})

      expect(json['icon']).to eq 'warning'
    end

    it 'should create an account notification for specific roles using the old role names' do
      json = api_call(:post, @path, @api_params,
                       { :account_notification_roles => ['AccountAdmin'],
                         :account_notification => {
                           :subject => 'New global notification',
                           :start_at => @start_at.iso8601,
                           :end_at => @end_at.iso8601,
                           :message => 'This is a notification'}})

      notification = AccountNotification.last
      roles = notification.account_notification_roles
      expect(roles.count).to eq 1
      expect(roles.first.role_id).to eq admin_role.id
      expect(json['roles']).to eq ["AccountAdmin"]
      expect(json['role_ids']).to eq [admin_role.id]
    end

    it 'should create an account notification for specific roles using role ids' do
      json = api_call(:post, @path, @api_params,
                      { :account_notification_roles => [admin_role.id],
                        :account_notification => {
                            :subject => 'New global notification',
                            :start_at => @start_at.iso8601,
                            :end_at => @end_at.iso8601,
                            :message => 'This is a notification'}})

      notification = AccountNotification.last
      roles = notification.account_notification_roles
      expect(roles.count).to eq 1
      expect(roles.first.role_id).to eq admin_role.id
      expect(json['roles']).to eq ["AccountAdmin"]
      expect(json['role_ids']).to eq [admin_role.id]
    end

    it 'should create an account notification for specific course-level roles using role ids' do
      json = api_call(:post, @path, @api_params,
                      { :account_notification_roles => [student_role.id],
                        :account_notification => {
                            :subject => 'New global notification',
                            :start_at => @start_at.iso8601,
                            :end_at => @end_at.iso8601,
                            :message => 'This is a notification'}})

      notification = AccountNotification.last
      roles = notification.account_notification_roles
      expect(roles.count).to eq 1
      expect(roles.first.role_id).to eq student_role.id
      expect(json['roles']).to eq ["StudentEnrollment"]
      expect(json['role_ids']).to eq [student_role.id]
    end

    it 'should create an account notification for the "nil enrollment"' do
      json = api_call(:post, @path, @api_params,
                      { :account_notification_roles => ["NilEnrollment"],
                        :account_notification => {
                            :subject => 'New global notification',
                            :start_at => @start_at.iso8601,
                            :end_at => @end_at.iso8601,
                            :message => 'This is a notification'}})

      notification = AccountNotification.last
      roles = notification.account_notification_roles
      expect(roles.count).to eq 1
      expect(roles.first.role_id).to eq nil
      expect(json['roles']).to eq ["NilEnrollment"]
      expect(json['role_ids']).to eq [nil]
    end

    it 'should return not authorized for non admin user' do
      user = user_with_managed_pseudonym
      api_call_as_user(user, :post, @path, @api_params,
                        { :account_notification_roles => ['StudentEnrollment'],
                          :account_notification => {
                            :subject => 'New global notification',
                            :start_at => @start_at.iso8601,
                            :end_at => @end_at.iso8601,
                            :message => 'This is a notification'}},
                        {},
                        expected_status: 401)
    end

    it 'should return an error for missing required params' do
      missing = ['subject', 'message', 'start_at', 'end_at']
      raw_api_call(:post, @path, @api_params, { :account_notification => { :icon => 'warning'} })
      expect(response.code).to eql '400'
      json = JSON.parse(response.body)
      errors = json['errors'].keys
      expect(missing - errors).to be_blank
    end

    it 'should return an error for malformed dates' do
      raw_api_call(:post, @path, @api_params,
                   { :account_notification => {
                       :subject => 'New global notification',
                       :start_at => 'asdrsldkfj',
                       :end_at => 'invalid_date',
                       :message => 'This is a notification',
                       :icon => 'information'}})
      expect(response.code).to eql '400'
    end

    it 'should not allow an end date to be before a start date' do
      raw_api_call(:post, @path, @api_params,
                   { :account_notification => {
                       :subject => 'New global notification',
                       :start_at => @end_at.iso8601,
                       :end_at => @start_at.iso8601,
                       :message => 'This is a notification',
                       :icon => 'information'}})
      expect(response.code).to eql '400'
      errors = JSON.parse(response.body)
      expect(errors['errors'].keys).to include 'end_at'
    end
  end

end

