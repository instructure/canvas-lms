# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module I18nTasks
  class GenerateJs
    PLURAL_KEYWORDS = %w[zero one two few many other].freeze

    attr_reader :index

    def initialize(index:)
      @index = index
    end

    # Compile a map of all the translations with fully-qualified keys that
    # include the scope when it's relevant (i.e. non-inferred keys.)
    #
    # Translations MUST be loaded for this to work correctly!
    #
    # Phrases are sorted by their key, and ones that do not have a translation
    # are omitted.
    def translations(locale)
      pool = core_translations(locale)

      index.each do |phrase|
        if (translation = lookup(locale, phrase["key"]))
          pool[phrase["key"]] = translation
        end
      end

      pool = pluralize(pool)
      pool.sort.to_h
    end

    private

    def pluralize(pool)
      result = Hash.new { |hash, key| hash[key] = {} }

      pool.each do |key, value|
        key_components = key.split(".")
        plural_keyword = key_components.last
        if PLURAL_KEYWORDS.include? plural_keyword
          new_key = key_components[0...-1].join(".")
          result[new_key][plural_keyword] = value
        else
          result[key] = value
        end
      end

      result
    end

    def core_translations(locale)
      pool = {}

      CORE_KEYS.map(&:to_s).each do |scope|
        phrases = lookup(locale, scope) || {}
        phrases.flatten_keys.each do |key, value|
          pool["#{scope}.#{key}"] = value
        end
      end

      pool
    end

    def lookup(locale, key)
      ::I18n.translate!(key.to_sym, locale:, raise: true)
    rescue ::I18n::MissingTranslationData
      nil
    end
  end
end
