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

module Canvas
  module PasswordPolicy
    def self.validate(record, attr, value)
      policy = record.account.password_policy
      value = value.to_s
      record.errors.add attr, "too_short" if policy[:min_length] > value.length
      record.errors.add attr, "too_long" if value.length > Setting.get("password_policy_max_length", "255").to_i
      record.errors.add attr, "common" if policy[:disallow_common_passwords] && COMMON_PASSWORDS.include?(value.downcase)
      # same char repeated
      record.errors.add attr, "repeated" if policy[:max_repeats] && value =~ /(.)\1{#{policy[:max_repeats]},}/
      # long sequence/run of chars
      if policy[:max_sequence]
        candidates = Array.new(value.length - policy[:max_sequence]) do |i|
          Regexp.new(Regexp.escape(value[i, policy[:max_sequence] + 1]))
        end
        record.errors.add attr, "sequence" if candidates.any? { |candidate| SEQUENCES.grep(candidate).present? }
      end
    end

    def self.default_policy
      {
        # :max_repeats => nil,
        # :max_sequence => nil,
        # :disallow_common_passwords => false,
        min_length: 8
      }
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

    # per https://en.wikipedia.org/wiki/Wikipedia:10,000_most_common_passwords
    # Licensed under CC BY-SA 3.0: https://creativecommons.org/licenses/by-sa/3.0/legalcode
    # Top 100 common passwords as at May 2023, excluding profanity
    COMMON_PASSWORDS = %w[
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
  end
end
