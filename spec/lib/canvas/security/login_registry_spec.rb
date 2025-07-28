# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe Canvas::Security::LoginRegistry do
  let(:registry) { Canvas::Security::LoginRegistry }

  before_once do
    skip("requires redis config to run") unless Canvas.redis_enabled?
    u = user_with_pseudonym active_user: true,
                            username: "nobody@example.com",
                            password: "asdfasdf"
    u.save!
    @p = u.pseudonym
  end

  describe ".audit_login" do
    before do
      @p.account.settings[:password_policy] = { maximum_login_attempts: 2 }
      @p.account.save!
    end

    it "returns nil to allow user through" do
      expect(registry.audit_login(@p, true)).to be_nil
    end

    it "doesn't prohibit operation just because password was wrong" do
      expect(registry.audit_login(@p, false)).to be_nil
    end

    it "prohibits rapid fire successful logins beyond the set limit (defaults to 5)" do
      6.times { registry.audit_login(@p, true) }
      expect(registry.audit_login(@p, true)).to be :too_recent_login
      expect(registry.audit_login(@p, false)).to be_nil
    end

    it "allows 3 rapid fire successful logins" do
      3.times { expect(registry.audit_login(@p, true)).to be_nil }
    end

    it "falls back to the default maximum_login_attempts if the account setting is missing" do
      # default maximum login attempts is currently set at 10
      @p.account.settings.delete(:password_policy)
      @p.account.save!
      9.times { registry.failed_login!(@p) }
      expect(registry.audit_login(@p, true)).to be_nil
    end

    it "falls back to the default if maximum_login_attempts is set beyond allowed threshold" do
      @p.account.settings[:password_policy] = { maximum_login_attempts: 30 }
      @p.account.save!
      10.times { registry.failed_login!(@p) }
      expect(registry.audit_login(@p, true)).to eq(:too_many_attempts)
    end

    it "falls back to the default if maximum_login_attempts is not greater than 0" do
      @p.account.settings[:password_policy] = { maximum_login_attempts: 0 }
      @p.account.save!
      # allows authentication to proceed as the fallback is used
      expect(registry.audit_login(@p, true)).to be_nil
    end

    it "timeouts the login block after a waiting period" do
      Setting.set("login_attempts_ttl", 5.seconds)
      registry.failed_login!(@p)
      expect(registry.time_until_login_allowed(@p)).to eq 0
      expect(registry.time_until_login_allowed(@p)).to be <= 5
    end
  end

  describe ".allow_login_attempt?" do
    subject { registry.allow_login_attempt?(@p) }

    context "with login suspension enabled" do
      before do
        @p.account.enable_feature!(:password_complexity)
        @p.account.settings[:password_policy] = { maximum_login_attempts: "3", allow_login_suspension: true }
        @p.account.save!
      end

      it "returns :final_attempt when total is greater than maximum_login_attempts" do
        4.times { registry.failed_login!(@p) }
        expect(subject).to eq(:final_attempt)
      end

      it "returns :remaining_attempts_2 when total is less than maximum_login_attempts by 3" do
        expect(registry.audit_login(@p, false)).to eq(:remaining_attempts_2)
      end

      it "returns :remaining_attempts_1 when total is less than maximum_login_attempts by 2" do
        registry.audit_login(@p, false)
        expect(registry.audit_login(@p, false)).to eq(:remaining_attempts_1)
      end

      it "returns :final_attempt when total is less than maximum_login_attempts by 1" do
        2.times { registry.audit_login(@p, false) }
        expect(registry.audit_login(@p, false)).to eq(:final_attempt)
      end

      it "suspends the user's login after the last failed login attempt" do
        3.times { registry.audit_login(@p, false) }
        expect(@p.reload.workflow_state).to eq "suspended"
      end

      it "allows up to maximum_login_attempts of failed login attempts before suspending the user" do
        @p.account.settings[:password_policy] = { maximum_login_attempts: "10", allow_login_suspension: true }
        @p.account.save!

        7.times { registry.failed_login!(@p) }
        expect(registry.audit_login(@p, false)).to eq(:remaining_attempts_2)
        expect(@p.reload.workflow_state).to eq "active"
        expect(registry.audit_login(@p, false)).to eq(:remaining_attempts_1)
        expect(@p.reload.workflow_state).to eq "active"
        expect(registry.audit_login(@p, false)).to eq(:final_attempt)
        expect(@p.reload.workflow_state).to eq "suspended"
      end
    end
  end
end
