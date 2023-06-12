# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module I18n
  module Backend
    # Based off of I18n::Backend::LazyLoadable, this backend takes a list of "meta"
    # keys, and make sure those files are always loaded regardless of locale. And
    # if a request is made for a translation beginning with a meta key, it does not
    # trigger loading of that entire locale. This accommodates methods like those
    # found in the {LocaleSelection} module.
    class MetaLazyLoadable < I18n::Backend::LazyLoadable
      def initialize(meta_keys: [], lazy_load: false)
        super(lazy_load:)
        @meta_keys = meta_keys.map(&:to_s).freeze
        @pending_meta_keys = true
      end

      def available_locales
        (super - @meta_keys).uniq # the uniq shouldn't be necessary. See https://github.com/ruby-i18n/i18n/pull/655
      end

      private

      def filenames_for_current_locale
        # have to ensure data from locales.yml overwrites anything in locale-specific files
        super + I18n.load_path.flatten.select { |p| @meta_keys.include?(File.basename(p, ".*")) }
      end

      def assert_file_named_correctly!(file, translations)
        return if @meta_keys.include?(File.basename(file, ".*"))

        super
      end

      def init_meta_translations
        files = I18n.load_path.flatten.select { |p| @meta_keys.include?(File.basename(p, ".*")) }
        load_translations(files)
        @pending_meta_keys = false
      end

      def lookup(locale, key, scope = [], options = EMPTY_HASH)
        keys = I18n.normalize_keys(locale, key, scope, options[:separator])

        # first key is the locale, second key is the "first" key
        meta_key = @meta_keys.include?(keys[1].to_s)
        if meta_key
          init_meta_translations if @pending_meta_keys
        elsif lazy_load?
          I18n.with_locale(locale) do
            init_translations unless initialized?
          end
        else
          init_translations unless initialized?
        end

        # copy-pasta from Simple
        keys.inject(translations) do |result, k|
          return nil unless result.is_a?(Hash)

          unless result.key?(k)
            k = k.to_s.to_sym
            return nil unless result.key?(k)
          end
          result = result[k]
          result = resolve_entry(locale, k, result, Utils.except(options.merge(scope: nil), :count)) if result.is_a?(Symbol)
          result
        end
      end
    end
  end
end
