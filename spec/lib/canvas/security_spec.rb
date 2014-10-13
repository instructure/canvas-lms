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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Canvas::Security do
  if Canvas.redis_enabled?
    describe "max login attempts" do
      before do
        Setting.set('login_attempts_total', '2')
        Setting.set('login_attempts_per_ip', '1')
        u = user_with_pseudonym :active_user => true,
          :username => "nobody@example.com",
          :password => "asdfasdf"
        u.save!
        @p = u.pseudonym
      end

      it "should be limited for the same ip" do
        expect(Canvas::Security.allow_login_attempt?(@p, "5.5.5.5")).to eq true
        Canvas::Security.failed_login!(@p, "5.5.5.5")
        expect(Canvas::Security.allow_login_attempt?(@p, "5.5.5.5")).to eq false
      end

      it "should have a higher limit for other ips" do
        Canvas::Security.failed_login!(@p, "5.5.5.5")
        expect(Canvas::Security.allow_login_attempt?(@p, "5.5.5.6")).to eq true
        Canvas::Security.failed_login!(@p, "5.5.5.7")
        expect(Canvas::Security.allow_login_attempt?(@p, "5.5.5.8")).to eq false # different ip but too many total failures
        expect(Canvas::Security.allow_login_attempt?(@p, nil)).to eq false # no ip but too many total failures
      end

      it "should not block other users with the same ip" do
        Canvas::Security.failed_login!(@p, "5.5.5.5")
        # schools like to NAT hundreds of people to the same IP, so we don't
        # ever block the IP address as a whole
        u2 = user_with_pseudonym(:active_user => true, :username => "second@example.com", :password => "12341234")
        u2.save!
        expect(Canvas::Security.allow_login_attempt?(u2.pseudonym, "5.5.5.5")).to eq true
        expect(Canvas::Security.allow_login_attempt?(u2.pseudonym, "5.5.5.6")).to eq true
      end

      it "should timeout the login block after a waiting period" do
        Setting.set('login_attempts_ttl', 5.seconds)
        Canvas::Security.failed_login!(@p, "5.5.5.5")
        expect(Canvas::Security.time_until_login_allowed(@p, '5.5.5.6')).to eq 0
        expect(Canvas::Security.time_until_login_allowed(@p, '5.5.5.5')).to be <= 5
      end
    end
  end
end
