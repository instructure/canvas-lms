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
    # Top 100 common passwords > 8 characters as per NIST Guidelines, as at June 2023, excluding profanity
    COMMON_PASSWORDS = %w[
      password
      12345678
      baseball
      football
      superman
      1qaz2wsx
      trustno1
      jennifer
      sunshine
      iloveyou
      starwars
      computer
      michelle
      11111111
      princess
      corvette
      1234qwer
      88888888
      internet
      samantha
      whatever
      maverick
      steelers
      mercedes
      qwer1234
      hardcore
      q1w2e3r4
      midnight
      bigdaddy
      victoria
      1q2w3e4r
      cocacola
      marlboro
      asdfasdf
      87654321
      12344321
      jordan23
      jonathan
      liverpool
      danielle
      abcd1234
      scorpion
      slipknot
      startrek
      12341234
      redskins
      butthead
      qwertyui
      dolphins
      nicholas
      elephant
      mountain
      xxxxxxxx
      metallic
      benjamin
      creative
      rush2112
      asdfghjk
      passw0rd
      1qazxsw2
      garfield
      69696969
      december
      11223344
      godzilla
      airborne
      lifehack
      brooklyn
      platinum
      darkness
      blink182
      12qwaszx
      snowball
      pakistan
      redwings
      williams
      nintendo
      guinness
      november
      asdf1234
      lasvegas
      babygirl
      12121212
      explorer
      snickers
      alexande
      paradise
      michigan
      carolina
      lacrosse
      christin
      kimberly
      kristina
      poohbear
      bollocks
      drowssap
      qweasdzxc
      1232323q
      westside
      12345qwert
      aaaaaaaa
].freeze
  end
end
