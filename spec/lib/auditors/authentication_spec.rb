#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../../cassandra_spec_helper')

describe AuthenticationAuditApiController do
  it_should_behave_like "cassandra audit logs"

  before do
    @account = Account.default
    user_with_pseudonym(active_all: true)
    @event = Auditors::Authentication.record(@pseudonym, 'login')
  end

  context "nominal cases" do
    it "should include event for pseudonym" do
      Auditors::Authentication.for_pseudonym(@pseudonym).paginate(:per_page => 1).
        should include(@event)
    end

    it "should include event for account" do
      Auditors::Authentication.for_account(@account).paginate(:per_page => 1).
        should include(@event)
    end

    it "should include event at user" do
      Auditors::Authentication.for_user(@user).paginate(:per_page => 1).
        should include(@event)
    end
  end

  context "with a second account (same user)" do
    before do
      @account = account_model
      user_with_pseudonym(user: @user, account: @account, active_all: true)
    end

    it "should not include cross-account events for pseudonym" do
      Auditors::Authentication.for_pseudonym(@pseudonym).paginate(:per_page => 1).
        should_not include(@event)
    end

    it "should not include cross-account events for account" do
      Auditors::Authentication.for_account(@account).paginate(:per_page => 1).
        should_not include(@event)
    end

    it "should include cross-account events for user" do
      Auditors::Authentication.for_user(@user).paginate(:per_page => 1).
        should include(@event)
    end
  end

  context "with a second user (same account)" do
    before do
      user_with_pseudonym(active_all: true)
    end

    it "should not include cross-user events for pseudonym" do
      Auditors::Authentication.for_pseudonym(@pseudonym).paginate(:per_page => 1).
        should_not include(@event)
    end

    it "should include cross-user events for account" do
      Auditors::Authentication.for_account(@account).paginate(:per_page => 1).
        should include(@event)
    end

    it "should not include cross-user events for user" do
      Auditors::Authentication.for_user(@user).paginate(:per_page => 1).
        should_not include(@event)
    end
  end

  describe "sharding" do
    specs_require_sharding

    context "different shard, same database server" do
      before do
        @shard1.activate do
          @account = account_model
          user_with_pseudonym(account: @account, active_all: true)
          @event1 = Auditors::Authentication.record(@pseudonym, 'login')
        end
        user_with_pseudonym(user: @user, active_all: true)
        @event2 = Auditors::Authentication.record(@pseudonym, 'login')
      end

      it "should include events from the user's native shard" do
        Auditors::Authentication.for_user(@user).paginate(:per_page => 2).
          should include(@event1)
      end

      it "should include events from the other pseudonym's shard" do
        Auditors::Authentication.for_user(@user).paginate(:per_page => 2).
          should include(@event2)
      end

      it "should not include duplicate events" do
        Auditors::Authentication.for_user(@user).paginate(:per_page => 4).
          size.should == 2
      end
    end

    context "different shard, different database server" do
      before do
        @shard2.activate do
          @account = account_model
          user_with_pseudonym(account: @account, active_all: true)
          @event1 = Auditors::Authentication.record(@pseudonym, 'login')
        end
        user_with_pseudonym(user: @user, active_all: true)
        @event2 = Auditors::Authentication.record(@pseudonym, 'login')
      end

      it "should include events from the user's native shard" do
        Auditors::Authentication.for_user(@user).paginate(:per_page => 2).
          should include(@event1)
      end

      it "should include events from the other pseudonym's shard" do
        Auditors::Authentication.for_user(@user).paginate(:per_page => 2).
          should include(@event2)
      end
    end
  end
end
