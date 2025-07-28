# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

module Canvas::Security
  module PasswordPolicy
    MIN_CHARACTER_LENGTH = "8"
    MAX_CHARACTER_LENGTH = "255"
    MIN_LOGIN_ATTEMPTS = "3"
    MAX_LOGIN_ATTEMPTS = "20"

    DEFAULT_CHARACTER_LENGTH = "8"
    DEFAULT_LOGIN_ATTEMPTS = "10"

    def self.validate(record, attr, value)
      policy = record.account.password_policy
      value = value.to_s
      # too long
      record.errors.add attr, "too_long" if value.length > MAX_CHARACTER_LENGTH.to_i
      # same char repeated
      record.errors.add attr, "repeated" if policy[:max_repeats] && value =~ /(.)\1{#{policy[:max_repeats]},}/
      # long sequence/run of chars
      if policy[:max_sequence] && value.length > policy[:max_sequence]
        candidates = Array.new(value.length - policy[:max_sequence]) do |i|
          Regexp.new(Regexp.escape(value[i, policy[:max_sequence] + 1]))
        end
        record.errors.add attr, "sequence" if candidates.any? { |candidate| SEQUENCES.grep(candidate).present? }
      end
      # check for common passwords
      if Canvas::Plugin.value_to_boolean(policy[:disallow_common_passwords]) && policy[:common_passwords_attachment_id].blank?
        record.errors.add attr, "common" if DEFAULT_COMMON_PASSWORDS.include?(value.downcase)
      end
      # only enforce these policies if password complexity feature is enabled
      if record.account.password_complexity_enabled?
        # too short
        record.errors.add attr, "too_short" if value.length < policy[:minimum_character_length].to_i
        # not enough numbers
        if Canvas::Plugin.value_to_boolean(policy[:require_number_characters])
          record.errors.add attr, "no_digits" unless /\d/.match?(value)
        end
        # not enough symbols
        if Canvas::Plugin.value_to_boolean(policy[:require_symbol_characters])
          symbol_regex = %r{[\!\@\#\$\%\^\&\*\(\)\_\+\-\=\[\]\{\}\|\;\:\'\"\<\>\,\.\?/]}
          record.errors.add attr, "no_symbols" unless symbol_regex.match?(value)
        end
        # a password dictionary has been provided to check against
        if policy[:common_passwords_attachment_id].present?
          # key {tag} is to ensure related keys are stored on the same node
          # given a production-like distributed Redis setup (e.g., Redis Cluster)
          key = ["common_passwords:{#{record.account.global_id}}", policy[:common_passwords_attachment_id]].cache_key
          # validate password against the Redis set
          password_membership = check_password_membership(key, value, policy)
          if password_membership
            record.errors.add attr, "common"
          elsif password_membership.nil?
            record.errors.add attr, "unexpected"
          end
        end
      elsif value.length < MIN_CHARACTER_LENGTH.to_i
        # fallback to minimum character length
        record.errors.add attr, "too_short"
      end
    end

    def self.default_policy
      {
        # max_repeats: nil,
        # max_sequence: nil,
        # disallow_common_passwords: false,
        minimum_character_length: DEFAULT_CHARACTER_LENGTH,
        maximum_login_attempts: DEFAULT_LOGIN_ATTEMPTS
      }
    end

    def self.load_common_passwords_file_data(policy)
      return false unless (attachment = Attachment.not_deleted.find_by(id: policy[:common_passwords_attachment_id]))
      return false unless attachment.root_account.feature_enabled?(:password_complexity)
      # avoid processing and loading large files into memory
      # this will keep the line count to a reasonable size ~ 100k
      return false if attachment.size > 1.megabyte

      begin
        stream = attachment.open(integrity_check: true)
      rescue CorruptedDownload => e
        Rails.logger.error("Corrupted download for common passwords attachment: #{e}")
        return false
      end

      stream.read.force_encoding("utf-8").split("\n").map(&:strip)
    end

    def self.add_password_membership(key, passwords)
      Canvas.redis.pipelined do
        Array(passwords).each_slice(10_000) do |slice|
          Canvas.redis.sadd(key, slice)
        end
      end
    end

    def self.check_password_membership(key, value, policy)
      if Canvas.redis_enabled?
        begin
          if Canvas.redis.srandmember(key).present?
            # if an element exists, we can assume the set is populated
            return Canvas.redis.sismember(key, value)
          else
            # if the set is empty, we need to populate it
            file_data = load_common_passwords_file_data(policy)
            if file_data
              add_password_membership(key, file_data)
            else
              false
            end
          end

          Canvas.redis.sismember(key, value)
        rescue Redis::BaseConnectionError, Redis::Distributed::CannotDistribute
          nil
        end
      end
    end

    SEQUENCES = begin
      sequences = [
        "abcdefghijklmnopqrstuvwxyz",
        "`1234567890-=",
        "qwertyuiop[]\\",
        "asdfghjkl;'",
        "zxcvbnm,./"
      ]
      sequences + sequences.map(&:reverse)
    end
    private_constant :SEQUENCES

    # per https://en.wikipedia.org/wiki/Wikipedia:10,000_most_common_passwords
    # Licensed under CC BY-SA 3.0: https://creativecommons.org/licenses/by-sa/3.0/legalcode
    # Top 100 common passwords as at May 2023, excluding profanity
    DEFAULT_COMMON_PASSWORDS = %w[
      123456
      password
      12345678
      qwerty
      123456789
      12345
      1234
      111111
      1234567
      dragon
      123123
      baseball
      abc123
      football
      monkey
      letmein
      696969
      shadow
      master
      666666
      qwertyuiop
      123321
      mustang
      1234567890
      michael
      654321
      superman
      1qaz2wsx
      7777777
      121212
      000000
      qazwsx
      123qwe
      killer
      trustno1
      jordan
      jennifer
      zxcvbnm
      asdfgh
      hunter
      buster
      soccer
      harley
      batman
      andrew
      tigger
      sunshine
      iloveyou
      2000
      charlie
      robert
      thomas
      hockey
      ranger
      daniel
      starwars
      klaster
      112233
      george
      computer
      michelle
      jessica
      pepper
      1111
      zxcvbn
      555555
      11111111
      131313
      freedom
      777777
      pass
      maggie
      159753
      aaaaaa
      ginger
      princess
      joshua
      cheese
      amanda
      summer
      love
      ashley
      6969
      nicole
      chelsea
      biteme
      matthew
      access
      yankees
      987654321
      dallas
      austin
      thunder
      taylor
      matrix
    ].freeze
    private_constant :DEFAULT_COMMON_PASSWORDS
  end
end
