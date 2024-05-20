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

module Canvas::ICU
  module NaiveCollator
    def self.rules
      ""
    end

    def self.collation_key(string)
      string&.downcase
    end

    def self.compare(a, b)
      collation_key(a) <=> collation_key(b)
    end

    def self.collate(sortable)
      sortable.sort { |a, b| compare(a, b) }
    end
  end

  begin
    Bundler.require "icu"
    require "ffi"
    suffix = ICU::Lib.figure_suffix(ICU::Lib.load_icu)

    unless ICU::Lib.respond_to?(:ucol_getSortKey)
      ICU::Lib.attach_function(:ucol_getSortKey, "ucol_getSortKey#{suffix}", %i[pointer pointer int pointer int], :int)

      ICU::Collation::Collator.class_eval do
        def collation_key(string)
          ptr = ICU::UCharPointer.from_string(string)
          size = ICU::Lib.ucol_getSortKey(@c, ptr, string.jlength, nil, 0)
          buffer = FFI::MemoryPointer.new(:char, size)
          ICU::Lib.ucol_getSortKey(@c, ptr, string.jlength, buffer, size)
          buffer.read_bytes(size - 1)
        end
      end
    end

    unless ICU::Lib.respond_to?(:ucol_getAttribute)
      ICU::Lib.attach_function(:ucol_getAttribute, "ucol_getAttribute#{suffix}", %i[pointer int pointer], :int)
      ICU::Lib.attach_function(:ucol_setAttribute, "ucol_setAttribute#{suffix}", %i[pointer int int pointer], :void)

      class ICU::Collation::Collator
        def [](attribute)
          ATTRIBUTE_VALUES_INVERSE[ICU::Lib.check_error do |error|
            ICU::Lib.ucol_getAttribute(@c, ATTRIBUTES[attribute], error)
          end]
        end

        def []=(attribute, value)
          ICU::Lib.check_error do |error|
            ICU::Lib.ucol_setAttribute(@c, ATTRIBUTES[attribute], ATTRIBUTE_VALUES[value], error)
          end
        end

        ATTRIBUTES = {
          french_collation: 0,
          alternate_handling: 1,
          case_first: 2,
          case_level: 3,
          normalization_mode: 4,
          strength: 5,
          hiragana_quaternary_mode: 6,
          numeric_collation: 7,
        }.freeze

        ATTRIBUTES.each_key do |attribute|
          class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{attribute}
              self[:#{attribute}]
            end

            def #{attribute}=(value)
              self[:#{attribute}] = value
            end
          RUBY
        end

        ATTRIBUTE_VALUES = {
          nil => -1,
          :primary => 0,
          :secondary => 1,
          :default_strength => 2,
          :tertiary => 2,
          :quaternary => 3,
          :identical => 15,

          false => 16,
          true => 17,

          :shifted => 20,
          :non_ignorable => 21,

          :lower_first => 24,
          :upper_first => 25,
        }.freeze
        ATTRIBUTE_VALUES_INVERSE = ATTRIBUTE_VALUES.to_h { |k, v| [v, k] }.freeze
      end
    end

    def self.collator(locale = I18n.locale)
      @collations ||= {}
      @collations[locale] ||= begin
        collator = ICU::Collation::Collator.new(locale.to_s)

        # Reference documentation (some option names differ in ruby-space)for these options is at
        # http://userguide.icu-project.org/collation/customization#TOC-Default-Options
        # if you change these settings, also match the settings in best_unicode_collation_key,
        # natcompare.js, and .icu_locale_name below
        collator.normalization_mode = false # default; other languages override as appropriate
        collator.numeric_collation = true
        collator.strength = :tertiary # default
        collator.alternate_handling = :non_ignorable # default
        collator
      end
    end
  rescue LoadError
    # in test, this will reveal system configuration problems
    throw if Rails.env.test?

    def self.collator # rubocop:disable Lint/DuplicateMethods
      NaiveCollator
    end
  end

  def self.locale_for_collation
    I18n.set_locale_with_localizer
    collator.rules.empty? ? "root" : I18n.locale
  end

  def self.compare(a, b)
    if !a.is_a?(String) || !b.is_a?(String)
      a <=> b
    else
      collator.compare(a, b)
    end
  end

  def self.collation_key(string)
    return string unless string.is_a?(String)

    collator.collation_key(string)
  end

  class << self
    delegate :collate, to: :collator
  end

  def self.collate_by(sortable)
    sortable.sort { |a, b| compare(yield(a), yield(b)) }
  end

  def self.untagged_locale
    I18n.locale.to_s.sub(/-x-.+$/, "")
  end

  def self.icu_locale_name
    I18n.set_locale_with_localizer
    collator.rules.empty? ? "und-u-kn-true" : "#{untagged_locale}-u-kn-true"
  end

  def self.choose_pg12_collation(available_collations)
    schema, collation = available_collations.find { |(_schema, locale)| locale == icu_locale_name }
    if !collation && !collator.rules.empty?
      # we don't have the proper collation for this language, but still try to use the root locale
      # if it exists
      schema, collation = available_collations.find { |(_schema, locale)| locale == "und-u-kn-true" }
    end
    return unless collation

    ::ActiveRecord::ConnectionAdapters::PostgreSQL::Name.new(schema, collation).quoted
  end
end
