#
# Copyright (C) 2011 - 2015 Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper.rb')

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

  let_once(:multi_student) do
    u = user_with_pseudonym(name: 'Child Multi', active_all: true)
    pseudonym(u, account: external_account)
    u
  end
  let_once(:multi_parent) do
    u = user_with_pseudonym(name: 'Parent Multi', active_all: true)
    pseudonym(u, account: external_account)
    u
  end

  let(:params) { { controller: 'user_observees', format: 'json' } }

  def index_call(opts={})
    json = raw_index_call(opts)
    return nil if opts[:expected_status]
    json.map{|o| o['id'] }.sort
  end
  def raw_index_call(opts={})
    params[:user_id] = opts[:user_id] || parent.id
    if opts[:page]
      params.merge!(per_page: 1, page: opts[:page])
      page = "?per_page=1&page=#{opts[:page]}"
    end

    if(opts[:avatars])
      params.merge!(include: ["avatar_url"])
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
    json
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
      opts.slice(:root_account_id),
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
    specs_require_sharding
    it 'should list observees' do
      parent.linked_students << student
      expect(index_call).to eq [student.id]
    end

    it 'should list observees (for self managed users)' do
      parent.linked_students << student
      expect(index_call(api_user: parent)).to eq [student.id]
    end

    it 'should list observees (for external accounts)' do
      external_parent.linked_students << external_student
      json = index_call(user_id: external_parent.id, api_user: multi_admin, domain_root_account: external_account)
      expect(json).to eq [external_student.id]
    end

    it 'should paginate' do
      parent.linked_students << student
      parent.linked_students << student2

      expect(index_call(page: 1)).to eq [student2.id]
      expect(index_call(page: 2)).to eq [student.id]
    end

    it 'should not include deleted observers' do
      parent.linked_students << student
      parent.linked_students << student2
      parent.as_observer_observation_links.where(user_id: student2).destroy_all

      expect(index_call).to eq [student.id]
    end

    it 'should not accept an invalid user' do
      index_call(user_id: 0, expected_status: 404)
    end

    it 'should not allow admins from an external account' do
      external_parent.linked_students << external_student
      index_call(user_id: external_parent.id, domain_root_account: external_account, expected_status: 401)
    end

    it 'should not allow unauthorized admins' do
      index_call(api_user: disallowed_admin, expected_status: 401)
    end

    it 'should return avatar if avatar service enabled on account' do
      student.account.set_service_availability(:avatars, true)
      student.account.save!
      student.avatar_image_source = 'attachment'
      student.avatar_image_url = "/relative/canvas/path"
      student.save!
      parent.linked_students << student
      opts = {:avatars=>true}
      json = raw_index_call(opts )
      expect(json.map{|o| o['id'] }).to eq [student.id]
      expect(json.map{|o| o["avatar_url"]}).to eq ["http://www.example.com/relative/canvas/path"]
    end

    it 'should return avatar if avatar service enabled on account when called from shard with avatars disabled' do
      @shard2.activate do
        student= User.create
        student.account.set_service_availability(:avatars, true)
        student.account.save!
        student.save!
      end
      student.avatar_image_source = 'attachment'
      student.avatar_image_url = "/relative/canvas/path"
      student.save!
      parent.linked_students << student
      parent.account.set_service_availability(:avatars, false)
      opts = {:avatars=>true}
      json = raw_index_call(opts )
      expect(json.map{|o| o['id'] }).to eq [student.id]
      expect(json.map{|o| o["avatar_url"]}).to eq ["http://www.example.com/relative/canvas/path"]
    end

    it "should only return linked root accounts the admin has rights for" do
      UserObservationLink.create_or_restore(observer: multi_parent, student: multi_student, root_account: Account.default)
      UserObservationLink.create_or_restore(observer: multi_parent, student: multi_student, root_account: external_account)
      json = raw_index_call(:user_id => multi_parent.id, :api_user => allowed_admin)
      expect(json.first["observation_link_root_account_ids"]).to eq [Account.default.id]

      json2 = raw_index_call(:user_id => multi_parent.id, :api_user => multi_admin)
      expect(json2.first["observation_link_root_account_ids"]).to match_array [Account.default.id, external_account.id]
    end
  end

  context 'POST #create' do
    it 'should add an observee, given credentials' do
      observee = {
        unique_id: student_pseudonym.unique_id,
        password: student_pseudonym.password,
      }
      expect(create_call({observee: observee})).to eq student.id

      expect(parent.reload.linked_students).to eq [student]
    end

    it 'should add an observee, given valid credentials (for self managed users)' do
      observee = {
        unique_id: student_pseudonym.unique_id,
        password: student_pseudonym.password,
      }
      expect(create_call({observee: observee}, api_user: parent)).to eq student.id

      expect(parent.reload.linked_students).to eq [student]
    end

    it 'should add an observee, given valid credentails (for external accounts)' do
      observee = {
        unique_id: external_student_pseudonym.unique_id,
        password: external_student_pseudonym.password,
      }
      json = create_call({observee: observee}, user_id: external_parent.id, api_user: multi_admin, domain_root_account: external_account)
      expect(json).to eq external_student.id

      expect(external_parent.reload.linked_students).to eq [external_student]
    end

    it 'should not add an observee, given bad credentials' do
      observee = {
        unique_id: student_pseudonym.unique_id,
        password: student_pseudonym.password + 'bad credentials',
      }
      create_call({observee: observee}, expected_status: 401)

      expect(parent.reload.linked_students).to eq []
    end

    it 'should not add an observee from an external account' do
      observee = {
        unique_id: external_student_pseudonym.unique_id,
        password: external_student_pseudonym.password,
      }
      create_call({observee: observee, root_account_id: 'all'}, domain_root_account: external_account, expected_status: 422)

      expect(parent.reload.linked_students).to eq []
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

      expect(parent.reload.linked_students).to eq []
    end

    it 'should not allow a user to observe oneself' do
      observee = {
        unique_id: student_pseudonym.unique_id,
        password: student_pseudonym.password,
      }
      create_call({observee: observee}, api_user: student, expected_status: 401)

      expect(student.reload.linked_students).to eq []
    end
  end

  context 'GET #show' do
    it 'should show an observee' do
      parent.linked_students << student
      expect(show_call).to eq student.id
    end

    it 'should show an observee (for self managed users)' do
      parent.linked_students << student
      expect(show_call(api_user: parent)).to eq student.id
    end

    it 'should show an observee (for external accounts)' do
      external_parent.linked_students << external_student
      json = show_call(user_id: external_parent.id, observee_id: external_student.id, api_user: multi_admin, domain_root_account: external_account)
      expect(json).to eq external_student.id
    end

    it 'should not accept an invalid user' do
      show_call(user_id: 0, expected_status: 404)
    end

    it 'should not accept a non-observed user' do
      parent.linked_students << student
      show_call(observee_id: student2.id, expected_status: 404)
    end

    it 'should not allow admins from an external account' do
      external_parent.linked_students << external_student
      show_call(user_id: external_parent.id, observee_id: external_student.id, domain_root_account: external_account, expected_status: 401)
    end

    it 'should not allow unauthorized admins' do
      parent.linked_students << student
      show_call(api_user: disallowed_admin, expected_status: 401)
    end
  end

  context 'PUT #update' do
    it 'should add an observee by id' do
      expect(update_call).to eq student.id
      expect(parent.reload.linked_students).to eq [student]
    end

    it 'should not error if the observee already exists' do
      parent.linked_students << student
      expect(update_call).to eq student.id
      expect(parent.reload.linked_students).to eq [student]
    end

    it 'should add an observee by id (for external accounts)' do
      json = update_call(user_id: external_parent.id, observee_id: external_student.id, api_user: multi_admin, domain_root_account: external_account)
      expect(json).to eq external_student.id
      expect(external_parent.reload.linked_students).to eq [external_student]
    end

    it 'should not accept an invalid user' do
      update_call(user_id: 0, expected_status: 404)
    end

    it 'should not accept an invalid observee' do
      update_call(observee_id: 0, expected_status: 404)
      expect(parent.reload.linked_students).to eq []
    end

    it 'should not accept an observee from an external account' do
      update_call(observee_id: external_student.id, expected_status: 404)
      expect(parent.reload.linked_students).to eq []
    end

    it 'should not allow admins from an external account' do
      update_call(user_id: external_parent.id, observee_id: external_student.id, domain_root_account: external_account, expected_status: 401)
    end

    it 'should not allow self managed users' do
      update_call(api_user: parent, expected_status: 401)
    end

    it 'should not allow unauthorized admins' do
      update_call(api_user: disallowed_admin, expected_status: 401)
    end

    context "multiple root accounts" do
      it "should add a link for for the domain root account if not specified" do
        update_call(user_id: multi_parent.id, observee_id: multi_student.id, api_user: multi_admin)
        expect(multi_parent.as_observer_observation_links.pluck(:root_account_id)).to match_array([Account.default.id])
      end

      it "should only add a link to one root account if specified" do
        update_call(user_id: multi_parent.id, observee_id: multi_student.id, api_user: multi_admin, root_account_id: external_account.id)
        expect(multi_parent.as_observer_observation_links.pluck(:root_account_id)).to eq([external_account.id])
      end

      it "should add a link for each associated root account if specified" do
        update_call(user_id: multi_parent.id, observee_id: multi_student.id, api_user: multi_admin, root_account_id: "all")
        expect(multi_parent.as_observer_observation_links.pluck(:root_account_id)).to match_array([Account.default.id, external_account.id])
      end

      it "should only add a link for the commonly associated root accounts" do
        update_call(user_id: multi_parent.id, observee_id: student.id, api_user: multi_admin, root_account_id: "all")
        expect(multi_parent.as_observer_observation_links.pluck(:root_account_id)).to eq([Account.default.id])
      end

      it "should only add a link for the commonly associated root accounts the admin has rights for" do
        update_call(user_id: multi_parent.id, observee_id: multi_student.id, api_user: allowed_admin, root_account_id: "all")
        expect(multi_parent.as_observer_observation_links.pluck(:root_account_id)).to eq([Account.default.id])
      end
    end
  end

  context 'DELETE #destroy' do
    it 'should remove an observee by id' do
      parent.linked_students << student
      course_factory.enroll_user(student)
      observer_enrollment = parent.observer_enrollments.first

      expect(delete_call).to eq student.id
      expect(parent.reload.linked_students).to eq []
      expect(observer_enrollment.reload).to be_deleted
    end

    it 'should remove an observee by id (for external accounts)' do
      external_parent.linked_students << external_student
      course_factory(:account => external_account).enroll_user(external_student)
      observer_enrollment = external_parent.observer_enrollments.first

      json = delete_call(user_id: external_parent.id, observee_id: external_student.id, api_user: multi_admin, domain_root_account: external_account)
      expect(json).to eq external_student.id
      expect(external_parent.reload.linked_students).to eq []
      expect(observer_enrollment.reload).to be_deleted
    end

    it 'should not succeed if the observee is not found' do
      parent.linked_students << student
      delete_call(observee_id: student2.id, expected_status: 404)
      expect(parent.reload.linked_students).to eq [student]
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

    it 'should not allow unauthorized admins' do
      parent.linked_students << student
      delete_call(api_user: disallowed_admin, expected_status: 401)
      expect(parent.reload.linked_students).to eq [student]
    end

    it 'should allow observer to remove observee' do
      parent.linked_students << student
      delete_call(api_user: parent, expected_status: 200)
      expect(parent.reload.linked_students).to eq []
      expect(UserObservationLink.where(:observer_id => parent).first.workflow_state).to eq 'deleted'
    end
  end

    context "Add observer by token" do
      shared_examples "handle_observees_by_auth_token" do
        it 'should add an observee, given a valid access token' do
          expect(create_call({access_token: access_token_for_user(@token_student)})).to eq @token_student.id
          expect(parent.reload.linked_students).to eq [@token_student]
        end

        it 'should not add an observee, given an invalid access token' do
          create_call({access_token: "Not A Valid Token"}, expected_status: 422)
          expect(parent.reload.linked_students).to eq []
        end
      end

      context "with sharding" do
        specs_require_sharding
        before :each do
          @shard2.activate do
            @token_student = user_with_pseudonym(name: "Sharded Student", active_all: true)
          end
        end
        include_examples "handle_observees_by_auth_token"
      end

      context "without sharding" do
        before :once do
          @token_student = user_with_pseudonym(name: "Sameshard Student", active_all: true)
        end
        include_examples "handle_observees_by_auth_token"
      end
    end

end
