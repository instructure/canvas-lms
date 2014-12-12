#
# Copyright (C) 2014 Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../../lti_spec_helper.rb')

module Lti
  describe ToolProxyController, type: :request do
    let (:account) { Account.create }

    describe "#destroy" do

      context 'course' do
        it 'marks a tool proxy as deleted from a course' do
          course_with_teacher(active_all: true, user: user_with_pseudonym, account: account)
          tp = create_tool_proxy(context: @course)
          api_call(:delete, "/api/v1/courses/#{@course.id}/tool_proxies/#{tp.id}",
                   {controller: 'lti/tool_proxy', action: 'destroy', format: 'json', course_id: @course.id.to_s, tool_proxy_id: tp.id})
          expect(tp.reload.workflow_state).to eq 'deleted'
        end

        it "doesn't allow a student to delete tool proxies" do
          course_with_student(active_all: true, user: user_with_pseudonym, account: account)
          tp = create_tool_proxy(context: @course)
          raw_api_call(:delete, "/api/v1/courses/#{@course.id}/tool_proxies/#{tp.id}",
                   {controller: 'lti/tool_proxy', action: 'destroy', format: 'json', course_id: @course.id.to_s, tool_proxy_id: tp.id})
          assert_status(401)
          expect(tp.reload.workflow_state).to eq 'active'
        end

      end

      context 'account' do
        it 'marks a tool proxy as deleted from a account' do
          account_admin_user(account: account)
          tp = create_tool_proxy(context: account)
          api_call(:delete, "/api/v1/accounts/#{account.id}/tool_proxies/#{tp.id}",
                   {controller: 'lti/tool_proxy', action: 'destroy', format: 'json', account_id: account.id.to_s, tool_proxy_id: tp.id})
          expect(tp.reload.workflow_state).to eq 'deleted'
        end

        it "doesn't allow a non-admin to delete tool proxies" do
          user_with_pseudonym(account: account )
          tp = create_tool_proxy(context: account)
          raw_api_call(:delete, "/api/v1/accounts/#{account.id}/tool_proxies/#{tp.id}",
                       {controller: 'lti/tool_proxy', action: 'destroy', format: 'json', account_id: account.id.to_s, tool_proxy_id: tp.id})
          assert_status(401)
          expect(tp.reload.workflow_state).to eq 'active'
        end

      end

    end

    describe '#update' do
      context 'course' do
        it 'updates a tools workflow state' do
          course_with_teacher(active_all: true, user: user_with_pseudonym, account: account)
          tp = create_tool_proxy(context: @course)
          api_call(:put, "/api/v1/courses/#{@course.id}/tool_proxies/#{tp.id}",
                   {controller: 'lti/tool_proxy', action: 'update', format: 'json', course_id: @course.id.to_s, tool_proxy_id: tp.id, workflow_state: 'disabled'})
          expect(tp.reload.workflow_state).to eq 'disabled'
        end

        it "doesn't allow a student to update" do
          course_with_student(active_all: true, user: user_with_pseudonym, account: account)
          tp = create_tool_proxy(context: @course)
          raw_api_call(:put, "/api/v1/courses/#{@course.id}/tool_proxies/#{tp.id}",
                       {controller: 'lti/tool_proxy', action: 'update', format: 'json', course_id: @course.id.to_s, tool_proxy_id: tp.id, workflow_state: 'disabled'})
          assert_status(401)
          expect(tp.reload.workflow_state).to eq 'active'
        end

      end

      context 'account' do
        it 'updates a tools workflow state' do
          account_admin_user(account: account)
          tp = create_tool_proxy(context: account)
          api_call(:put, "/api/v1/accounts/#{account.id}/tool_proxies/#{tp.id}",
                   {controller: 'lti/tool_proxy', action: 'update', format: 'json', account_id: account.id.to_s, tool_proxy_id: tp.id, workflow_state: 'disabled'})
          expect(tp.reload.workflow_state).to eq 'disabled'
        end

        it "doesn't allow a non-admin to update workflow_state" do
          user_with_pseudonym(account: account )
          tp = create_tool_proxy(context: account)
          raw_api_call(:put, "/api/v1/accounts/#{account.id}/tool_proxies/#{tp.id}",
                       {controller: 'lti/tool_proxy', action: 'update', format: 'json', account_id: account.id.to_s, tool_proxy_id: tp.id, workflow_state: 'disabled'})
          assert_status(401)
          expect(tp.reload.workflow_state).to eq 'active'
        end

      end
    end

  end
end
