#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

describe UserObserveesController, type: :request do
  let_once(:parent)             { user_with_pseudonym(name: 'Parent Smith', active_all: true) }
  let_once(:student)            { student_pseudonym.user }
  let_once(:student_pseudonym)  { user_with_pseudonym(name: 'Child Smith', active_all: true); @pseudonym }
  let_once(:student2)           { student2_pseudonym.user }
  let_once(:student2_pseudonym) { user_with_pseudonym(name: 'Another Smith', active_all: true); @pseudonym }
  let_once(:allowed_admin) do
    a = account_admin_user_with_role_changes(active_all: true, role_changes: {manage_user_observers: true})
    pseudonym(a)
    a
  end
  let_once(:multi_admin) do
    a = account_admin_user_with_role_changes(active_all: true, role_changes: {manage_user_observers: true})
    pseudonym(a)
    account_admin_user_with_role_changes(active_all: true, user: a, account: external_account, role_changes: {manage_user_observers: true})
    pseudonym(a, account: external_account)
    a
  end
  let(:disallowed_admin) do
    a = account_admin_user_with_role_changes(active_all: true, role_changes: {manage_user_observers: false})
    pseudonym(a)
    a
  end

  let_once(:external_account)           { account_model(name: 'External Account') }
  let_once(:external_parent)            { user_with_pseudonym(name: 'Parent External', active_all: true, account: external_account) }
  let_once(:external_student)           { external_student_pseudonym.user }
  let_once(:external_student_pseudonym) { user_with_pseudonym(name: 'Child External', active_all: true, account: external_account); @pseudonym }
  let_once(:external_allowed_admin) do
    a = account_admin_user_with_role_changes(active_all: true, role_changes: {manage_user_observers: true})
    pseudonym(a, account: external_account)
    a
  end
  let(:external_disallowed_admin) do
    a = account_admin_user_with_role_changes(active_all: true, role_changes: {manage_user_observers: false})
    pseudonym(a, account: external_account)
    a
  end

  let(:params) { { controller: 'user_observees', format: 'json' } }

  def index_call(opts={})
    params[:user_id] = opts[:user_id] || parent.id
    if opts[:page]
      params.merge!(per_page: 1, page: opts[:page])
      page = "?per_page=1&page=#{opts[:page]}"
    end

    json = api_call_as_user(
      opts[:api_user] || allowed_admin,
      :get,
      "/api/v1/users/#{params[:user_id]}/observees#{page}",
      params.merge(action: 'index'),
      {},
      {},
      { expected_status: opts[:expected_status] || 200, domain_root_account: opts[:domain_root_account] || Account.default },
    )
    return nil if opts[:expected_status]
    json.map{|o| o['id'] }.sort
  end

  def create_call(data, opts={})
    params[:user_id] = opts[:user_id] || parent.id

    json = api_call_as_user(
      opts[:api_user] || allowed_admin,
      :post,
      "/api/v1/users/#{params[:user_id]}/observees",
      params.merge(action: 'create'),
      data,
      {},
      { expected_status: opts[:expected_status] || 200, domain_root_account: opts[:domain_root_account] || Account.default },
    )
    return nil if opts[:expected_status]
    json['id']
  end

  def show_call(opts={})
    params[:user_id] = opts[:user_id] || parent.id
    params[:observee_id] = opts[:observee_id] || student.id

    json = api_call_as_user(
      opts[:api_user] || allowed_admin,
      :get,
      "/api/v1/users/#{params[:user_id]}/observees/#{params[:observee_id]}",
      params.merge(action: 'show'),
      {},
      {},
      { expected_status: opts[:expected_status] || 200, domain_root_account: opts[:domain_root_account] || Account.default },
    )
    return nil if opts[:expected_status]
    json['id']
  end

  def update_call(opts={})
    params[:user_id] = opts[:user_id] || parent.id
    params[:observee_id] = opts[:observee_id] || student.id

    json = api_call_as_user(
      opts[:api_user] || allowed_admin,
      :put,
      "/api/v1/users/#{params[:user_id]}/observees/#{params[:observee_id]}",
      params.merge(action: 'update'),
      {},
      {},
      { expected_status: opts[:expected_status] || 200, domain_root_account: opts[:domain_root_account] || Account.default },
    )
    return nil if opts[:expected_status]
    json['id']
  end

  def delete_call(opts={})
    params[:user_id] = opts[:user_id] || parent.id
    params[:observee_id] = opts[:observee_id] || student.id

    json = api_call_as_user(
      opts[:api_user] || allowed_admin,
      :delete,
      "/api/v1/users/#{params[:user_id]}/observees/#{params[:observee_id]}",
      params.merge(action: 'destroy'),
      {},
      {},
      { expected_status: opts[:expected_status] || 200, domain_root_account: opts[:domain_root_account] || Account.default },
    )
    return nil if opts[:expected_status]
    json['id']
  end

  context 'GET #index' do
    it 'should list observees' do
      parent.observed_users << student
      index_call.should == [student.id]
    end

    it 'should list observees (for self managed users)' do
      parent.observed_users << student
      index_call(api_user: parent).should == [student.id]
    end

    it 'should list observees (for external accounts)' do
      external_parent.observed_users << external_student
      json = index_call(user_id: external_parent.id, api_user: multi_admin, domain_root_account: external_account)
      json.should == [external_student.id]
    end

    it 'should paginate' do
      parent.observed_users << student
      parent.observed_users << student2

      index_call(page: 1).should == [student2.id]
      index_call(page: 2).should == [student.id]
    end

    it 'should not accept an invalid user' do
      index_call(user_id: 0, expected_status: 404)
    end

    it 'should not allow admins from an external account' do
      external_parent.observed_users << external_student
      index_call(user_id: external_parent.id, domain_root_account: external_account, expected_status: 401)
    end

    it 'should not allow unauthorized admins' do
      index_call(api_user: disallowed_admin, expected_status: 401)
    end
  end

  context 'POST #create' do
    it 'should add an observee, given credentials' do
      observee = {
        unique_id: student_pseudonym.unique_id,
        password: student_pseudonym.password,
      }
      create_call({observee: observee}).should == student.id

      parent.reload.observed_users.should == [student]
    end

    it 'should add an observee, given valid credentials (for self managed users)' do
      observee = {
        unique_id: student_pseudonym.unique_id,
        password: student_pseudonym.password,
      }
      create_call({observee: observee}, api_user: parent).should == student.id

      parent.reload.observed_users.should == [student]
    end

    it 'should add an observee, given valid credentails (for external accounts)' do
      observee = {
        unique_id: external_student_pseudonym.unique_id,
        password: external_student_pseudonym.password,
      }
      json = create_call({observee: observee}, user_id: external_parent.id, api_user: multi_admin, domain_root_account: external_account)
      json.should == external_student.id

      external_parent.reload.observed_users.should == [external_student]
    end

    it 'should not add an observee, given bad credentials' do
      observee = {
        unique_id: student_pseudonym.unique_id,
        password: student_pseudonym.password + 'bad credentials',
      }
      create_call({observee: observee}, expected_status: 401)

      parent.reload.observed_users.should == []
    end

    it 'should not add an observee from an external account' do
      observee = {
        unique_id: external_student_pseudonym.unique_id,
        password: external_student_pseudonym.password,
      }
      create_call({observee: observee}, domain_root_account: external_account, expected_status: 401)

      parent.reload.observed_users.should == []
    end

    it 'should not accept an invalid user' do
      observee = {
        unique_id: student_pseudonym.unique_id,
        password: student_pseudonym.password,
      }
      create_call({observee: observee}, user_id: 0, expected_status: 404)
    end

    it 'should not allow admins from and external account' do
      observee = {
        unique_id: external_student_pseudonym.unique_id,
        password: external_student_pseudonym.password,
      }
      create_call({observee: observee}, user_id: external_parent.id, domain_root_account: external_account, expected_status: 401)
    end

    it 'should not allow unauthorized admins' do
      observee = {
        unique_id: student_pseudonym.unique_id,
        password: student_pseudonym.password,
      }
      create_call({observee: observee}, api_user: disallowed_admin, expected_status: 401)

      parent.reload.observed_users.should == []
    end
  end

  context 'GET #show' do
    it 'should show an observee' do
      parent.observed_users << student
      show_call.should == student.id
    end

    it 'should show an observee (for self managed users)' do
      parent.observed_users << student
      show_call(api_user: parent).should == student.id
    end

    it 'should show an observee (for external accounts)' do
      external_parent.observed_users << external_student
      json = show_call(user_id: external_parent.id, observee_id: external_student.id, api_user: multi_admin, domain_root_account: external_account)
      json.should == external_student.id
    end

    it 'should not accept an invalid user' do
      show_call(user_id: 0, expected_status: 404)
    end

    it 'should not accept a non-observed user' do
      parent.observed_users << student
      show_call(observee_id: student2.id, expected_status: 404)
    end

    it 'should not allow admins from an external account' do
      external_parent.observed_users << external_student
      show_call(user_id: external_parent.id, observee_id: external_student.id, domain_root_account: external_account, expected_status: 401)
    end

    it 'should not allow unauthorized admins' do
      parent.observed_users << student
      show_call(api_user: disallowed_admin, expected_status: 401)
    end
  end

  context 'PUT #update' do
    it 'should add an observee by id' do
      update_call.should == student.id
      parent.reload.observed_users.should == [student]
    end

    it 'should not error if the observee already exists' do
      parent.observed_users << student
      update_call.should == student.id
      parent.reload.observed_users.should == [student]
    end

    it 'should add an observee by id (for external accounts)' do
      json = update_call(user_id: external_parent.id, observee_id: external_student.id, api_user: multi_admin, domain_root_account: external_account)
      json.should == external_student.id
      external_parent.reload.observed_users.should == [external_student]
    end

    it 'should not accept an invalid user' do
      update_call(user_id: 0, expected_status: 404)
    end

    it 'should not accept an invalid observee' do
      update_call(observee_id: 0, expected_status: 404)
      parent.reload.observed_users.should == []
    end

    it 'should not accept an observee from an external account' do
      update_call(observee_id: external_student.id, expected_status: 404)
      parent.reload.observed_users.should == []
    end

    it 'should not allow admins from an external account' do
      update_call(user_id: external_parent.id, domain_root_account: external_account, expected_status: 401)
    end

    it 'should not allow self managed users' do
      update_call(api_user: parent, expected_status: 401)
    end

    it 'should not allow unauthorized admins' do
      update_call(api_user: disallowed_admin, expected_status: 401)
    end
  end

  context 'DELETE #destroy' do
    it 'should remove an observee by id' do
      parent.observed_users << student
      delete_call.should == student.id
      parent.reload.observed_users.should == []
    end

    it 'should remove an observee by id (for external accounts)' do
      external_parent.observed_users << external_student
      json = delete_call(user_id: external_parent.id, observee_id: external_student.id, api_user: multi_admin, domain_root_account: external_account)
      json.should == external_student.id
      external_parent.reload.observed_users.should == []
    end

    it 'should not succeed if the observee is not found' do
      parent.observed_users << student
      delete_call(observee_id: student2.id, expected_status: 404)
      parent.reload.observed_users.should == [student]
    end

    it 'should not accept an invalid user' do
      delete_call(user_id: 0, expected_status: 404)
    end

    it 'should not accept an invalid observee' do
      delete_call(observee_id: 0, expected_status: 404)
    end

    it 'should not allow admins from an external account' do
      delete_call(user_id: external_parent.id, domain_root_account: external_account, expected_status: 401)
    end

    it 'should not allow self managed users' do
      parent.observed_users << student
      delete_call(api_user: parent, expected_status: 401)
      parent.reload.observed_users.should == [student]
    end

    it 'should not allow unauthorized admins' do
      parent.observed_users << student
      delete_call(api_user: disallowed_admin, expected_status: 401)
      parent.reload.observed_users.should == [student]
    end
  end
end
