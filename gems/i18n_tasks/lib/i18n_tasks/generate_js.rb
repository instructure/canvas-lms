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
    def apply(locales:, translations:, scope_keys:)
      Hash.include I18nTasks::HashExtensions unless {}.is_a?(I18nTasks::HashExtensions)

      flat_translations = translations.flatten_keys
      file_translations = scope_keys
      modules = []

      dump_translations = lambda do |filename, content|
        modules.push([filename, content])
      end

      translation_for_key = lambda do |locale, key|
        try_locales = [locale.to_s, locale.to_s.split("-")[0], "en"].uniq

        try_locales.each do |try_locale|
          return [key, flat_translations["#{try_locale}.#{key}"]] if flat_translations.has_key?("#{try_locale}.#{key}")
        end

        # puts "key #{key} not found for locale #{locale} or possible fallbacks #{try_locales.to_sentence}"
        nil
      end

      # Compute common metadata for all locales
      key_counts = {}
      scopes = {}
      unique_key_scopes = {}
      file_translations.map do |scope, keys|
        stripped_scope = scope.split(".")[0]
        keys.each do |key|
          key_counts[key] = (key_counts[key] || 0) + 1
          unique_key_scopes[key] = stripped_scope
          scopes[stripped_scope] = true
          scopes[key.split(".")[0]] = true if key.count(".") > 0
        end
      end

      flat_translations.map do |key, translation|
        I18nTasks::Utils::CORE_KEYS.map do |scope|
          stripped_key = key.split(".", 2)[1] # remove the language prefix

          next unless stripped_key.start_with?(scope.to_s)

          key_counts[stripped_key] = (key_counts[stripped_key] || 0) + 1
          unique_key_scopes[stripped_key] = scope
          scopes[scope.to_s] = true
        end
      end

      # 1. Find all of the keys that are used more than once, they will be stored at the root-level and always loaded.
      # 2. Find the best translation for the given key.
      common_keys, unique_keys = I18nTasks::Utils.partition_hash(key_counts) { |k, v| v > 1 }

      puts "Common Keys: #{common_keys.count}"
      puts "Unique Keys: #{unique_keys.count}"

      eager_common_keys, lazy_common_keys = I18nTasks::Utils.partition_hash(common_keys) { |k, v| k.count(".") == 0 }
      lazy_unique_root_keys, lazy_unique_nested_keys = I18nTasks::Utils.partition_hash(unique_keys) { |k, v| k.count(".") == 0 }

      # 3. All common, non-nested translations will be loaded immediately.
      # 4. All other translations will be loaded when their scope is first accessed.

      eager_root_keys = eager_common_keys
      lazy_nested_keys = lazy_common_keys.merge(lazy_unique_nested_keys)
      lazy_root_keys = lazy_unique_root_keys
      lazy_root_keys_by_scope = lazy_root_keys.each_with_object(Hash.new { |hash, k| hash[k] = [] }) { |(k, v), obj| obj[unique_key_scopes[k]] << k }

      puts "Eager-Loaded Keys: #{eager_root_keys.count}"
      puts "Lazy-Loaded Root Keys: #{lazy_root_keys.count}"
      puts "Lazy-Loaded Nested Keys: #{lazy_nested_keys.count}"

      base_translations_js_start = "import { setRootTranslations, setLazyTranslations } from '@canvas/i18n/mergeI18nTranslations.js'; (function(setRootTranslations, setLazyTranslations) {"
      base_translations_js_end = "})(setRootTranslations, setLazyTranslations)"

      locales.each do |locale|
        puts "Generating JS for #{locale}"

        eager_root_translations = eager_root_keys.filter_map { |k, v| translation_for_key.call(locale, k) }.to_h
        lazy_nested_translations_by_scope = I18nTasks::Utils.flat_keys_to_nested(lazy_nested_keys.filter_map { |k, v| translation_for_key.call(locale, k) }.to_h)
        lazy_root_translations_by_scope = lazy_root_keys_by_scope.map { |scope, keys| [scope, keys.filter_map { |k| translation_for_key.call(locale, k) }.to_h] }.to_h

        common_translations_js = I18nTasks::Utils.eager_translations_js(locale, eager_root_translations)

        translations_js = scopes.map do |scope, _unused|
          lazy_root_translations = lazy_root_translations_by_scope.fetch(scope, {})
          lazy_scoped_translations = lazy_nested_translations_by_scope.fetch(scope.to_sym, {})

          I18nTasks::Utils.lazy_translations_js(locale, scope, lazy_root_translations, lazy_scoped_translations)
        end

        dump_translations.call locale, [base_translations_js_start, common_translations_js, *translations_js, base_translations_js_end].compact.join("\n\n")

        next unless locale == :en

        puts "Generating Default JS"

        core_translations_js = I18nTasks::Utils::CORE_KEYS.map do |scope|
          lazy_scoped_translations = lazy_nested_translations_by_scope.fetch(scope.to_sym, {})

          I18nTasks::Utils.lazy_translations_js(locale, scope, {}, lazy_scoped_translations)
        end

        dump_translations.call "_core_en", [base_translations_js_start, core_translations_js, base_translations_js_end].compact.join("\n\n")
      end

      modules
    end
  end
end
