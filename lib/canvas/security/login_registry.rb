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

module Canvas::Security
  ##
  # LoginRegistry is used to track login attempts and decide
  # whether we should allow a given login attempt
  #
  # "allow_login_attempt" returns false if there have been too
  # many recent failed attempts for the provided pseudonym. Failed attempts are tracked
  # by both (pseudonym) and (pseudonym, requesting_ip) , with the latter having
  # a lower threshold. This way a malicious user can't trivially lock out
  # another user by just making a bunch of bogus requests, they'll be blocked
  # themselves first. A distributed attack would still succeed in locking out
  # the user.
  #
  # in redis this is stored as a hash :
  # { 'unique_id' => pseudonym.unique_id, # for debugging
  #   'total' => <total failed attempts>,
  #   some_ip => <failed attempts for this ip>,
  #   some_other_ip => <failed attempts for this ip>,
  #   ...
  # }
  module LoginRegistry
    # for easy stubbing of Redis accesses from this module, without overriding
    # other accesses to Redis
    def self.redis
      Canvas.redis
    end

    ##
    # this is the expected interface for the rest of the application.
    # When a pseudonym tries to login, it should be run through this method.
    #
    # TODO: we really only use the global id off of the pseudonym model,
    # we could break the dependency on that class by just accepting a unique
    # identifier as the first parameter and making sure it IS the global id?
    #
    # @param [Pseudonym] pseudonym Pseudonym model instance with global_id and unique_id methods
    # @param [String] remote_ip the IP the login attempt originated from
    # @param [Boolean] valid_password whether the provided credentials were valid for this user
    #
    # @return [:too_many_attempts, :too_recent_login, nil] :too_many_attempts if login is prohibited, nil if it's fine to proceed
    def self.audit_login(pseudonym, remote_ip, valid_password)
      return :too_many_attempts unless allow_login_attempt?(pseudonym, remote_ip)

      if valid_password
        return :too_recent_login if recently_logged_in?(pseudonym)

        successful_login!(pseudonym)
      else
        failed_login!(pseudonym, remote_ip)
      end
      nil
    end

    def self.allow_login_attempt?(pseudonym, ip)
      return true unless Canvas.redis_enabled? && pseudonym

      ip.present? || ip = "no_ip"
      total_allowed = Setting.get("login_attempts_total", "20").to_i
      ip_allowed = Setting.get("login_attempts_per_ip", "10").to_i
      total, from_this_ip = redis.hmget(login_attempts_key(pseudonym), "total", ip, failsafe: nil)
      (!total || total.to_i < total_allowed) && (!from_this_ip || from_this_ip.to_i < ip_allowed)
    end

    def self.recently_logged_in?(pseudonym)
      return false unless Canvas.redis_enabled? && pseudonym

      attempts_allowed = Setting.get("succesful_logins_allowed", "5").to_i
      recent_attempts = redis.hget(succesful_logins_key(pseudonym), "count", failsafe: nil).to_i
      recent_attempts > attempts_allowed
    end

    # log a successful login, resetting the failed login attempts counter
    def self.successful_login!(pseudonym)
      return unless Canvas.redis_enabled? && pseudonym

      redis.del(login_attempts_key(pseudonym), failsafe: nil)

      key = succesful_logins_key(pseudonym)
      exptime = Setting.get("successful_login_window", "5").to_f.seconds
      redis.pipelined(key, failsafe: nil) do |pipeline|
        pipeline.hincrby(key, "count", 1)
        pipeline.expire(key, exptime)
      end
    end

    # log a failed login attempt
    def self.failed_login!(pseudonym, ip)
      return unless Canvas.redis_enabled? && pseudonym

      key = login_attempts_key(pseudonym)
      exptime = Setting.get("login_attempts_ttl", 5.minutes.to_s).to_i
      redis.pipelined(key, failsafe: nil) do |pipeline|
        pipeline.hset(key, "unique_id", pseudonym.unique_id)
        pipeline.hincrby(key, "total", 1)
        pipeline.hincrby(key, ip, 1) if ip.present?
        pipeline.expire(key, exptime)
      end
    end

    # returns time in seconds
    def self.time_until_login_allowed(pseudonym, ip)
      if allow_login_attempt?(pseudonym, ip)
        0
      else
        redis.ttl(login_attempts_key(pseudonym), failsafe: 0)
      end
    end

    def self.login_attempts_key(pseudonym)
      "login_attempts:#{pseudonym.global_id}"
    end

    def self.succesful_logins_key(pseudonym)
      "successful_logins:#{pseudonym.global_id}"
    end
  end
end
