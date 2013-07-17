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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

describe AccountNotification do

  before do
    @announcement = Account.default.announcements.create!(:message => 'hello')
    user
  end

  it "should find notifications" do
    AccountNotification.for_user_and_account(@user, Account.default).should == [@announcement]
  end

  it "should find site admin announcements" do
    @announcement.destroy
    @sa_announcement = Account.site_admin.announcements.create!(:message => 'hello')
    AccountNotification.for_user_and_account(@user, Account.default).should == [@sa_announcement]
  end

  it "should allow closing an announcement" do
    @user.close_announcement(@announcement)
    @user.preferences[:closed_notifications].should == [@announcement.id]
    AccountNotification.for_user_and_account(@user, Account.default).should == []
  end

  it "should remove non-applicable announcements from user preferences" do
    @user.close_announcement(@announcement)
    @user.preferences[:closed_notifications].should == [@announcement.id]
    @announcement.destroy
    AccountNotification.for_user_and_account(@user, Account.default).should == []
    @user.preferences[:closed_notifications].should == []
  end

  describe "survey notifications" do
    it "should only display for flagged accounts" do
      flag = AccountNotification::ACCOUNT_SERVICE_NOTIFICATION_FLAGS.first
      @announcement = Account.site_admin.announcements.create!(message: "hello", required_account_service: flag)
      @a1 = account_model
      @a2 = account_model
      @a2.enable_service(flag)
      @a2.save!
      AccountNotification.for_account(@a1).should == []
      AccountNotification.for_account(@a2).should == [@announcement]
    end

    describe "display_for_user?" do
      it "should select each mod value once throughout the cycle" do
        AccountNotification.display_for_user?(5, 3, Time.zone.parse('2012-04-02')).should == false
        AccountNotification.display_for_user?(6, 3, Time.zone.parse('2012-04-02')).should == false
        AccountNotification.display_for_user?(7, 3, Time.zone.parse('2012-04-02')).should == true

        AccountNotification.display_for_user?(5, 3, Time.zone.parse('2012-05-05')).should == true
        AccountNotification.display_for_user?(6, 3, Time.zone.parse('2012-05-05')).should == false
        AccountNotification.display_for_user?(7, 3, Time.zone.parse('2012-05-05')).should == false

        AccountNotification.display_for_user?(5, 3, Time.zone.parse('2012-06-04')).should == false
        AccountNotification.display_for_user?(6, 3, Time.zone.parse('2012-06-04')).should == true
        AccountNotification.display_for_user?(7, 3, Time.zone.parse('2012-06-04')).should == false
      end

      it "should shift the mod values each new cycle" do
        AccountNotification.display_for_user?(7, 3, Time.zone.parse('2012-04-02')).should == true
        AccountNotification.display_for_user?(7, 3, Time.zone.parse('2012-07-02')).should == false
        AccountNotification.display_for_user?(7, 3, Time.zone.parse('2012-09-02')).should == true
      end
    end
  end

  context "sharding" do
    specs_require_sharding

    it "should always find notifications for site admin" do
      @sa_announcement = Account.site_admin.announcements.create!(:message => 'hello')

      @shard1.activate do
        @account = Account.create!
        AccountNotification.for_user_and_account(@user, @account).should == [@sa_announcement]
      end

      @shard2.activate do
        AccountNotification.for_user_and_account(@user, @account).should == [@sa_announcement]
      end
    end

    it "should respect preferences regardless of current shard" do
      @shard1.activate do
        @user.close_announcement(@announcement)
      end
      @user.preferences[:closed_notifications].should == [@announcement.id]
      @shard1.activate do
        AccountNotification.for_user_and_account(@user, Account.default).should == []
      end
    end
  end
end
