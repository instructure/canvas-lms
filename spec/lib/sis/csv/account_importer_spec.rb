#
# Copyright (C) 2011 Instructure, Inc.
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

describe SIS::CSV::AccountImporter do

  before { account_model }

  it 'should skip bad content' do
    before_count = Account.count
    importer = process_csv_data(
      "account_id,parent_account_id,name,status",
      "A001,,Humanities,active",
      ",,Humanities 3,active")

    errors = importer.errors.map { |r| r.last }
    warnings = importer.warnings.map { |r| r.last }
    expect(warnings).to eq ["No account_id given for an account"]
    expect(errors).to eq []

    importer = process_csv_data(
      "account_id,parent_account_id,name,status",
      "A002,A000,English,active",
      "A003,,English,inactive",
      "A004,,,active")
    expect(Account.count).to eq before_count + 1

    errors = importer.errors.map { |r| r.last }
    warnings = importer.warnings.map { |r| r.last }
    expect(errors).to eq []
    expect(warnings).to eq ["Parent account didn't exist for A002",
                        "Improper status \"inactive\" for account A003, skipping",
                        "No name given for account A004, skipping"]
  end

  it 'should create accounts' do
    before_count = Account.count
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,Humanities,active",
      "A002,A001,English,active",
      "A003,A002,English Literature,active",
      "A004,,Awesomeness,active"
    )
    expect(Account.count).to eq before_count + 4

    a1 = @account.sub_accounts.where(sis_source_id: 'A001').first
    expect(a1).not_to be_nil
    expect(a1.parent_account_id).to eq @account.id
    expect(a1.root_account_id).to eq @account.id
    expect(a1.name).to eq 'Humanities'

    a2 = a1.sub_accounts.where(sis_source_id: 'A002').first
    expect(a2).not_to be_nil
    expect(a2.parent_account_id).to eq a1.id
    expect(a2.root_account_id).to eq @account.id
    expect(a2.name).to eq 'English'

    a3 = a2.sub_accounts.where(sis_source_id: 'A003').first
    expect(a3).not_to be_nil
    expect(a3.parent_account_id).to eq a2.id
    expect(a3.root_account_id).to eq @account.id
    expect(a3.name).to eq 'English Literature'
  end

  it 'should update the hierarchies of existing accounts' do
    before_count = Account.count
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,Humanities,active",
      "A002,,English,deleted",
      "A003,,English Literature,active",
      "A004,,Awesomeness,active"
    )
    expect(Account.count).to eq before_count + 4

    ['A001', 'A002', 'A003', 'A004'].each do |id|
      expect(Account.where(sis_source_id: id).first.parent_account).to eq @account
    end
    expect(Account.where(sis_source_id: 'A002').first.workflow_state).to eq "deleted"
    expect(Account.where(sis_source_id: 'A003').first.name).to eq "English Literature"

    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A002,A001,,",
      "A003,A002,,",
      "A004,A002,,"
    )
    expect(Account.count).to eq before_count + 4

    a1 = Account.where(sis_source_id: 'A001').first
    a2 = Account.where(sis_source_id: 'A002').first
    a3 = Account.where(sis_source_id: 'A003').first
    a4 = Account.where(sis_source_id: 'A004').first
    expect(a1.parent_account).to eq @account
    expect(a2.parent_account).to eq a1
    expect(a3.parent_account).to eq a2
    expect(a4.parent_account).to eq a2

    expect(Account.where(sis_source_id: 'A002').first.workflow_state).to eq "deleted"
    expect(Account.where(sis_source_id: 'A003').first.name).to eq "English Literature"

  end

  it 'should support sticky fields' do
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,Humanities,active"
    )
    expect(Account.where(sis_source_id: 'A001').first.name).to eq "Humanities"
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,Math,active"
    )
    Account.where(sis_source_id: 'A001').first.tap do |a|
      expect(a.name).to eq "Math"
      a.name = "Science"
      a.save!
    end
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,History,active"
    )
    expect(Account.where(sis_source_id: 'A001').first.name).to eq "Science"
  end

  it 'should match headers case-insensitively' do
    before_count = Account.count
    process_csv_data_cleanly(
      "Account_ID,Parent_Account_ID,Name,Status",
      "A001,,Humanities,active"
    )
    expect(Account.count).to eq before_count + 1

    a1 = @account.sub_accounts.where(sis_source_id: 'A001').first
    expect(a1).not_to be_nil
    expect(a1.parent_account_id).to eq @account.id
    expect(a1.root_account_id).to eq @account.id
    expect(a1.name).to eq 'Humanities'
  end

  it 'should not allow the creation of loops in account chains' do
    process_csv_data_cleanly(
      "Account_ID,Parent_Account_ID,Name,Status",
      "A001,,Humanities,active",
      "A002,A001,Humanities,active"
    )
    importer = process_csv_data(
      "Account_ID,Parent_Account_ID,Name,Status",
      "A001,A002,Humanities,active"
    )
    errors = importer.errors.map { |r| r.last }
    warnings = importer.warnings.map { |r| r.last }
    expect(errors).to eq []
    expect(warnings).to eq ["Setting account A001's parent to A002 would create a loop"]
  end

  it 'should update batch id on unchanging accounts' do
    process_csv_data_cleanly(
      "Account_ID,Parent_Account_ID,Name,Status",
      "A001,,Humanities,active"
    )
    batch = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "Account_ID,Parent_Account_ID,Name,Status",
      "A001,,Humanities,active",
      batch: batch
    )
    a1 = @account.sub_accounts.where(sis_source_id: 'A001').first
    expect(a1).not_to be_nil
    expect(a1.sis_batch_id).to eq batch.id
  end
end
