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

module I18nTasks
  module Lolcalize
    def translate(*args)
      key, options = I18nliner::CallHelpers.infer_arguments(args)
      if options[:default]
        key = :lols # so that it doesn't find a real translation
        options[:default] = i18n_lolcalize(options[:default]) if options[:default].present?
      end
      super(key, options)
    end

    # see also app/coffeescripts/str/i18nLolcalize.coffee
    def let_there_be_lols(str)
      # don't want to mangle placeholders, wrappers, etc.
      pattern = /(\s*%h?\{[^\}]+\}\s*|\s*[\n\\`\*_\{\}\[\]\(\)\#\+\-!]+\s*|^\s+)/
      result = str.split(pattern).map do |token|
        if token =~ pattern
          token
        else
          s = +''
          token.chars.each_with_index do |c, i|
            s << (i % 2 == 1 ? c.upcase : c.downcase)
          end
          s.gsub!(/\.( |\z)/, '!!?! ')
          s.sub!(/\A(\w+)\z/, '\1!')
          s << " LOL!" if s.length > 2
          s
        end
      end
      result.join('')
    end

    def i18n_lolcalize(default_thing)
      case default_thing
      when Array
        default_thing.map { |item| i18n_lolcalize(item) }
      when String
        let_there_be_lols(default_thing)
      when Hash
        result = {}
        default_thing.each do |k,v|
          result[k] = let_there_be_lols(v)
        end
        result
      else
        default_thing
      end
    end

    def self.extended(klass)
      klass.class_eval do
        class << self
          alias_method :t, :translate
        end
      end
    end
  end
end
