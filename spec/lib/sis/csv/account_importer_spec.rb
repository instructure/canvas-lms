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
    warnings.should == ["No account_id given for an account"]
    errors.should == []

    importer = process_csv_data(
      "account_id,parent_account_id,name,status",
      "A002,A000,English,active",
      "A003,,English,inactive",
      "A004,,,active")
    Account.count.should == before_count + 1

    errors = importer.errors.map { |r| r.last }
    warnings = importer.warnings.map { |r| r.last }
    errors.should == []
    warnings.should == ["Parent account didn't exist for A002",
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
    Account.count.should == before_count + 4

    a1 = @account.sub_accounts.where(sis_source_id: 'A001').first
    a1.should_not be_nil
    a1.parent_account_id.should == @account.id
    a1.root_account_id.should == @account.id
    a1.name.should == 'Humanities'

    a2 = a1.sub_accounts.where(sis_source_id: 'A002').first
    a2.should_not be_nil
    a2.parent_account_id.should == a1.id
    a2.root_account_id.should == @account.id
    a2.name.should == 'English'

    a3 = a2.sub_accounts.where(sis_source_id: 'A003').first
    a3.should_not be_nil
    a3.parent_account_id.should == a2.id
    a3.root_account_id.should == @account.id
    a3.name.should == 'English Literature'
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
    Account.count.should == before_count + 4

    ['A001', 'A002', 'A003', 'A004'].each do |id|
      Account.where(sis_source_id: id).first.parent_account.should == @account
    end
    Account.where(sis_source_id: 'A002').first.workflow_state.should == "deleted"
    Account.where(sis_source_id: 'A003').first.name.should == "English Literature"

    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A002,A001,,",
      "A003,A002,,",
      "A004,A002,,"
    )
    Account.count.should == before_count + 4

    a1 = Account.where(sis_source_id: 'A001').first
    a2 = Account.where(sis_source_id: 'A002').first
    a3 = Account.where(sis_source_id: 'A003').first
    a4 = Account.where(sis_source_id: 'A004').first
    a1.parent_account.should == @account
    a2.parent_account.should == a1
    a3.parent_account.should == a2
    a4.parent_account.should == a2

    Account.where(sis_source_id: 'A002').first.workflow_state.should == "deleted"
    Account.where(sis_source_id: 'A003').first.name.should == "English Literature"

  end

  it 'should support sticky fields' do
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,Humanities,active"
    )
    Account.where(sis_source_id: 'A001').first.name.should == "Humanities"
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,Math,active"
    )
    Account.where(sis_source_id: 'A001').first.tap do |a|
      a.name.should == "Math"
      a.name = "Science"
      a.save!
    end
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,History,active"
    )
    Account.where(sis_source_id: 'A001').first.name.should == "Science"
  end

  it 'should match headers case-insensitively' do
    before_count = Account.count
    process_csv_data_cleanly(
      "Account_ID,Parent_Account_ID,Name,Status",
      "A001,,Humanities,active"
    )
    Account.count.should == before_count + 1

    a1 = @account.sub_accounts.where(sis_source_id: 'A001').first
    a1.should_not be_nil
    a1.parent_account_id.should == @account.id
    a1.root_account_id.should == @account.id
    a1.name.should == 'Humanities'
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
    errors.should == []
    warnings.should == ["Setting account A001's parent to A002 would create a loop"]
  end
end
