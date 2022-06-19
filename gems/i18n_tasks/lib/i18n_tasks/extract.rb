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
  class Extract
    attr_reader :rb_translations, :js_translations

    def initialize(rb_translations:, js_translations:)
      @rb_translations = rb_translations
      @js_translations = js_translations
    end

    def apply
      deep_sort_hash_by_keys(
        remove_unwanted_translations(
          remove_dynamic_translations(
            remove_meta_keys(
              combined_translations
            )
          )
        )
      )
    end

    private

    # order all strings alphabetically to prevent the output from changing when
    # the implementation details change, see 09e6058
    def deep_sort_hash_by_keys(value)
      sort = lambda do |node|
        case node
        when Hash
          node.keys.sort.index_with do |key|
            sort[node[key]]
          end
        else
          node
        end
      end

      sort[value]
    end

    def remove_unwanted_translations(translations)
      translations.tap do
        translations.fetch("date", {}).delete("order")
      end
    end

    # Rails 6 added entries that are Procs which YAML cannot serialize so we
    # remove them, see 22abe25
    def remove_dynamic_translations(translations)
      process = lambda do |node|
        case node
        when Hash
          node.delete_if { |_k, v| process.call(v).nil? }
        when Proc
          nil
        else
          node
        end
      end

      process.call(translations)
    end

    def remove_meta_keys(translations)
      translations.except(*%w[
        bigeasy_locale
        crowdsourced
        custom
        fullcalendar_locale
        locales
        moment_locale
      ].freeze)
    end

    def combined_translations
      rb_translations.tap do
        js_translations.each do |key, value|
          rb_translations[key] = value
        end
      end
    end
  end
end
