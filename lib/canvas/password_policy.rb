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
      record.errors.add attr, "too_long" if value.length > Setting.get('password_policy_max_length', '255').to_i
      record.errors.add attr, "common" if policy[:disallow_common_passwords] && COMMON_PASSWORDS.include?(value.downcase)
      # same char repeated
      record.errors.add attr, "repeated" if policy[:max_repeats] && value =~ /(.)\1{#{policy[:max_repeats]},}/
      # long sequence/run of chars
      if policy[:max_sequence]
        candidates = (value.length - policy[:max_sequence]).times.map{ |i|
          Regexp.new(Regexp.escape(value[i, policy[:max_sequence] + 1]))
        }
        record.errors.add attr, "sequence" if candidates.any?{ |candidate| SEQUENCES.grep(candidate).present? }
      end
    end

    def self.default_policy
      {
        # :max_repeats => nil,
        # :max_sequence => nil,
        # :disallow_common_passwords => false,
        :min_length => 8
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

    # per http://www.prweb.com/releases/2012/10/prweb10046001.htm
    COMMON_PASSWORDS = %w{
      password
      123456
      12345678
      abc123
      qwerty
      monkey
      letmein
      dragon
      111111
      baseball
      iloveyou
      trustno1
      1234567
      sunshine
      master
      123123
      welcome
      shadow
      ashley
      football
      jesus
      michael
      ninja
      mustang
      password1
    }
  end
end
