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
  # many recent failed attempts for the provided pseudonym. Failed attempts
  # are tracked by pseudonym.
  #
  # in redis this is stored as a hash:
  # for debugging purposes, the key is "login_attempts:<global_id>"
  # { 'unique_id' => pseudonym.unique_id,
  #   'total' => <total failed attempts>,
  #   ...
  # }
  module LoginRegistry
    # for easy stubbing of Redis accesses from this module, without overriding
    # other accesses to Redis
    def self.redis
      Canvas.redis
    end

    WARNING_ATTEMPTS = {
      remaining_attempts_2: 2,
      remaining_attempts_1: 1,
      final_attempt: 0,
    }.freeze

    ##
    # this is the expected interface for the rest of the application.
    # When a pseudonym tries to login, it should be run through this method.
    #
    # TODO: we really only use the global id off of the pseudonym model,
    # we could break the dependency on that class by just accepting a unique
    # identifier as the first parameter and making sure it IS the global id?
    #
    # @param [Pseudonym] pseudonym Pseudonym model instance with global_id and unique_id methods
    # @param [Boolean] valid_password whether the provided credentials were valid for this user
    #
    # @return [:too_many_attempts, :too_recent_login, nil] :too_many_attempts if login is prohibited,
    # :too_recent_login if too many successful logins in succession, nil if it's fine to proceed
    def self.audit_login(pseudonym, valid_password)
      if pseudonym&.account&.allow_login_suspension?
        attempt = allow_login_attempt?(pseudonym)

        return attempt if WARNING_ATTEMPTS.key?(attempt)
      else
        return :too_many_attempts unless allow_login_attempt?(pseudonym)
      end

      if valid_password
        return :too_recent_login if recently_logged_in?(pseudonym)

        successful_login!(pseudonym)
      else
        failed_login!(pseudonym)
      end
      nil
    end

    def self.allow_login_attempt?(pseudonym)
      return true unless Canvas.redis_enabled? && pseudonym

      max_attempts_hard_limit = Canvas::Security::PasswordPolicy::MAX_LOGIN_ATTEMPTS.to_i
      max_attempts = pseudonym.account.password_policy[:maximum_login_attempts].to_i

      # if the lower or upper bound setting is invalid, fall back to the default value
      if max_attempts <= 0 || max_attempts > max_attempts_hard_limit
        max_attempts = Canvas::Security::PasswordPolicy::DEFAULT_LOGIN_ATTEMPTS.to_i
      end

      total, _count = redis.hmget(login_attempts_key(pseudonym), "total", failsafe: nil)
      total = total.to_i

      if pseudonym.account.allow_login_suspension?
        return :final_attempt if total > max_attempts

        difference = (max_attempts - total).abs
        case difference
        when 3
          failed_login!(pseudonym)
          return :remaining_attempts_2
        when 2
          failed_login!(pseudonym)
          return :remaining_attempts_1
        when 1
          pseudonym.suspend! if pseudonym.active?
          return :final_attempt
        end
      end

      total < max_attempts
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
    def self.failed_login!(pseudonym)
      return unless Canvas.redis_enabled? && pseudonym

      key = login_attempts_key(pseudonym)
      exptime = Setting.get("login_attempts_ttl", 5.minutes.to_s).to_i
      redis.pipelined(key, failsafe: nil) do |pipeline|
        pipeline.hset(key, "unique_id", pseudonym.unique_id)
        pipeline.hincrby(key, "total", 1)
        pipeline.expire(key, exptime)
      end
    end

    # returns time in seconds
    def self.time_until_login_allowed(pseudonym)
      if allow_login_attempt?(pseudonym)
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
