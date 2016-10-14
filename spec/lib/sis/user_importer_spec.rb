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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe SIS::UserImporter do
  context "time elapsed" do
    it "should split into transactions based on time elapsed" do
      account_model
      Setting.set('sis_transaction_seconds', '1')
      messages = []
      # this is the fun bit where we get to stub User.new to insert a sleep into
      # the transaction loop.

      # so it stays fast and skips the db
      User.any_instance.expects(:save).times(3).returns(true)

      # yes, enough time has passed for the transaction
      Time.any_instance.stubs(:>).returns(true)

      # two outer transactions (one per batch of 2)
      # three inner transactions (one per user)
      User.expects(:transaction).times(5).yields

      SIS::UserImporter.new(@account, {}).process(2, messages) do |importer|
        importer.add_user(*"U001,user1,active,User,One,user1@example.com".split(','))
        importer.add_user(*"U002,user2,active,User,Two,user2@example.com".split(','))
        importer.add_user(*"U003,user3,active,User,Three,user3@example.com".split(','))
      end
      # we don't actually save them, so don't bother checking the results
    end
  end

  context "when the unique_id is invalid the error message reported to the user" do

    before(:once) do
      @user_id = 'sis_id1'
      @login_id = '--*(&*(&%^&*%..-'
      messages = []
      account_model
      Setting.set('sis_transaction_seconds', '1')

      SIS::UserImporter.new(@account, {}).process(2, messages) do |importer|
        importer.add_user(@user_id, @login_id, 'active','User','One','user1@example.com')
      end

      @message = messages.first
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
    SIS::UserImporter.new(account_model, {}).process(2, []) do |importer|
      importer.add_user(12345, 'user1', 'active', 'User', 'One', 'user1@example.com')
    end
    expect(Pseudonym.last.sis_user_id).to eq '12345'
  end
end
