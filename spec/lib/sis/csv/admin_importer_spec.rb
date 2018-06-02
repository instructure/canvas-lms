#
# Copyright (C) 2017 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe SIS::CSV::AdminImporter do

  before do
    account_model
    sis = @account.sis_batches.create
    @sub_account = Account.create(parent_account: @account)
    @sub_account.sis_source_id = 'sub1'
    @sub_account.sis_batch_id = sis.id
    @sub_account.save!
  end

  it 'should skip bad content' do
    user_with_managed_pseudonym(account: @account, sis_user_id: 'U001')
    before_count = AccountUser.active.count
    importer = process_csv_data(
      'user_id,account_id,role_id,role,status',
      ',sub1,,AccountAdmin,active',
      'invalid,sub1,,AccountAdmin,active',
      'U001,invalid,,AccountAdmin,active',
      'U001,sub1,,invalid role,active',
      'U001,sub1,invalid,,active',
      'U001,sub1,,AccountAdmin,invalid',
      'U001,sub1,,AccountAdmin,',
      'U001,sub1,,,deleted'
    )
    expect(AccountUser.active.count).to eq before_count

    errors = importer.errors.map(&:last)
    expect(errors).to eq ["No user_id given for admin",
                            "Invalid or unknown user_id 'invalid' for admin",
                            "Invalid account_id given for admin",
                            "Invalid role 'invalid role' for admin",
                            "Invalid role_id 'invalid' for admin",
                            "Invalid status invalid for admin",
                            "No status given for admin",
                            "No role_id or role given for admin"]
  end

  it 'should add and remove admins' do
    u1 = user_with_managed_pseudonym(account: @account, sis_user_id: 'U001')

    before_count = AccountUser.active.count
    process_csv_data_cleanly(
      'user_id,account_id,role,status',
      'U001,sub1,AccountAdmin,active'
    )
    expect(AccountUser.active.count).to eq before_count + 1

    # sis_batch is not set process_csv_data_cleanly but is set on a typical sis
    # import, set it here so it is will be managed and allow deletion.
    b1 = @account.sis_batches.create
    AccountUser.where(account_id: @sub_account, user_id: u1).update_all(sis_batch_id: b1.id)

    process_csv_data_cleanly(
      'user_id,account_id,role,status',
      'U001,sub1,AccountAdmin,deleted',
      'U001,,AccountAdmin,active'
    )
    expect(AccountUser.active.count).to eq before_count + 1
    expect(@sub_account.account_users.where(user_id: u1).take.workflow_state).to eq 'deleted'
    expect(@account.account_users.where(user_id: u1).count).to eq 1
  end

  it 'should add admins from other root_account' do
    account2 = Account.create!
    user_with_managed_pseudonym(account: account2, sis_user_id: 'U001')

    before_count = @account.account_users.active.count

    work = SIS::AdminImporter::Work.new(@account.sis_batches.create!, @account, Rails.logger)
    expect(work).to receive(:root_account_from_id).with('account2').once.and_return(account2)
    expect(SIS::AdminImporter::Work).to receive(:new).with(any_args).and_return(work)

    process_csv_data_cleanly(
      'user_id,account_id,role,status,root_account',
      'U001,,AccountAdmin,active,account2'
    )
    expect(@account.account_users.active.count).to eq before_count + 1
  end

  it 'should add admins by role_id' do
    user_with_managed_pseudonym(account: @account, sis_user_id: 'U001')

    role = @sub_account.available_account_roles.first

    before_count = AccountUser.active.count
    process_csv_data_cleanly(
      'user_id,account_id,role_id,status',
      "U001,sub1,#{role.id.to_s},active"
    )
    expect(AccountUser.active.count).to eq before_count + 1
  end

  it 'should create rollback data' do
    user_with_managed_pseudonym(account: @account, sis_user_id: 'U001')
    batch1 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      'user_id,account_id,role,status',
      'U001,,AccountAdmin,active',
      batch: batch1
    )
    expect(batch1.roll_back_data.where(previous_workflow_state: 'non-existent').count).to eq 1
    batch2 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      'user_id,account_id,role,status',
      'U001,,AccountAdmin,deleted',
      batch: batch2
    )
    expect(batch2.roll_back_data.first.updated_workflow_state).to eq 'deleted'
    batch2.restore_states_for_batch
    user = @account.pseudonyms.where(sis_user_id: 'U001').take.user
    admin = @account.account_users.where(user_id: user).take
    expect(admin.workflow_state).to eq 'active'
  end
end
