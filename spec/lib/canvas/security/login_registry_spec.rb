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

  describe ".audit_login" do
    before do
      skip("requires redis config to run") unless Canvas.redis_enabled?
      Setting.set("login_attempts_total", "2")
      Setting.set("login_attempts_per_ip", "1")
      u = user_with_pseudonym active_user: true,
                              username: "nobody@example.com",
                              password: "asdfasdf"
      u.save!
      @p = u.pseudonym
    end

    it "returns nil to allow user through" do
      expect(registry.audit_login(@p, "5.5.5.5", true)).to be_nil
    end

    it "doesn't prohibit operation just because password was wrong" do
      expect(registry.audit_login(@p, "6.6.6.6", false)).to be_nil
    end

    it "will stop too many logins in too short a time" do
      registry.failed_login!(@p, "7.7.7.7")
      registry.failed_login!(@p, "7.7.7.7")
      expect(registry.audit_login(@p, "7.7.7.7", true)).to eq(:too_many_attempts)
    end

    it "allows 3 rapid fire successful logins" do
      3.times { expect(registry.audit_login(@p, "7.7.7.7", true)).to be_nil }
    end

    it "prohibits rapid fire successful logins" do
      6.times { registry.audit_login(@p, "7.7.7.7", true) }
      expect(registry.audit_login(@p, "7.7.7.7", true)).to be :too_recent_login
      expect(registry.audit_login(@p, "7.7.7.7", false)).to be_nil
    end

    describe "internal implementation" do
      it "is limited for the same ip" do
        expect(registry.allow_login_attempt?(@p, "5.5.5.5")).to be true
        registry.failed_login!(@p, "5.5.5.5")
        expect(registry.allow_login_attempt?(@p, "5.5.5.5")).to be false
      end

      it "has a higher limit for other ips" do
        registry.failed_login!(@p, "5.5.5.5")
        expect(registry.allow_login_attempt?(@p, "5.5.5.6")).to be true
        registry.failed_login!(@p, "5.5.5.7")
        expect(registry.allow_login_attempt?(@p, "5.5.5.8")).to be false # different ip but too many total failures
        expect(registry.allow_login_attempt?(@p, nil)).to be false # no ip but too many total failures
      end

      it "does not block other users with the same ip" do
        registry.failed_login!(@p, "5.5.5.5")
        # schools like to NAT hundreds of people to the same IP, so we don't
        # ever block the IP address as a whole
        u2 = user_with_pseudonym(active_user: true, username: "second@example.com", password: "12341234")
        u2.save!
        expect(registry.allow_login_attempt?(u2.pseudonym, "5.5.5.5")).to be true
        expect(registry.allow_login_attempt?(u2.pseudonym, "5.5.5.6")).to be true
      end

      it "timeouts the login block after a waiting period" do
        Setting.set("login_attempts_ttl", 5.seconds)
        registry.failed_login!(@p, "5.5.5.5")
        expect(registry.time_until_login_allowed(@p, "5.5.5.6")).to eq 0
        expect(registry.time_until_login_allowed(@p, "5.5.5.5")).to be <= 5
      end
    end
  end
end
