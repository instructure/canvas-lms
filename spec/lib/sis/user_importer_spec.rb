#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe SIS::UserImporter do
  context "time elapsed" do
    it "should split into transactions based on time elapsed" do
      account_model
      Setting.set('sis_transaction_seconds', '1')
      messages = []
      # this is the fun bit where we get to stub User.new to insert a sleep into
      # the transaction loop.

      # yes, enough time has passed for the transaction
      allow_any_instance_of(Time).to receive(:>).and_return(true)

      # two outer transactions (one per batch of 2)
      # three inner transactions (one per user)
      # three implicit transaction (one per user save)
      expect(User).to receive(:transaction).exactly(8).times.and_yield

      user1 = SIS::Models::User.new(user_id: 'U001', login_id: 'user1', status: 'active',
                                    full_name: 'User One', email: 'user1@example.com')
      user2 = SIS::Models::User.new(user_id: 'U002', login_id: 'user2', status: 'active',
                                    full_name: 'User Two', email: 'user2@example.com')
      user3 = SIS::Models::User.new(user_id: 'U003', login_id: 'user3', status: 'active',
                                    full_name: 'User Three', email: 'user3@example.com')

      Setting.set("sis_user_batch_size", "2")
      SIS::UserImporter.new(@account, {batch: @account.sis_batches.create!}).process(messages) do |importer|
        importer.add_user(user1)
        importer.add_user(user2)
        importer.add_user(user3)
      end
      # we don't actually save them, so don't bother checking the results
    end
  end

  context "when the unique_id is invalid the error message reported to the user" do

    before(:once) do
      @user_id = 'sis_id1'
      @login_id = "--*\x01(&*(&%^&*%..-"
      messages = []
      account_model
      Setting.set('sis_transaction_seconds', '1')
      user1 = SIS::Models::User.new(user_id: @user_id, login_id: @login_id, status: 'active',
                                    full_name: 'User One', email: 'user1@example.com')
      SIS::UserImporter.new(@account, {batch: @account.sis_batches.create!}).process(messages) do |importer|
        importer.add_user(user1)
      end

      @message = messages.first.message
    end

    it 'must include the login_id' do
      expect(@message).to include(@login_id)
    end

    it 'must include the user_id field' do
      expect(@message).to include(@user_id)
    end

    it 'must include the text "Invalid login_id"' do
      expect(@message).to include('Invalid login_id')
    end
  end

  it 'should handle user_ids as integers just in case' do
    user1 = SIS::Models::User.new(user_id: 12345, login_id: 'user1', status: 'active',
                                  full_name: 'User One', email: 'user1@example.com')
    SIS::UserImporter.new(account_model, {batch: @account.sis_batches.create!}).process([]) do |importer|
      importer.add_user(user1)
    end
    expect(Pseudonym.last.sis_user_id).to eq '12345'
  end
end
