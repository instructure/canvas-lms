# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require "i18nliner/extractors/ruby_extractor"
require "i18nliner/extractors/translate_call"
require "i18nliner/processors/ruby_processor"
require "i18nliner/processors/erb_processor"
require "i18nliner/errors"
require_relative "i18nliner_scope_extensions"

require "active_support/core_ext/module/aliasing"

module I18nliner
  class HtmlTagsInDefaultTranslationError < ExtractionError; end

  class AmbiguousTranslationKeyError < ExtractionError; end
end

module I18nExtraction; end

module I18nExtraction::Extensions
  module TranslateCall
    def validate_default
      if @default.is_a?(String) && %r{<[a-z][a-z0-9]*[> /]}i.match?(@default)
        raise I18nliner::HtmlTagsInDefaultTranslationError.new(@line, @default)
      end

      super
    end

    def validate_key
      if @scope.root? &&
         !@meta[:explicit_receiver] &&
         !@options[:i18nliner_inferred_key] &&
         key !~ I18nliner::Scope::ABSOLUTE_KEY
        raise I18nliner::AmbiguousTranslationKeyError.new(@line, @key)
      end

      super
    end
  end

  module RubyExtractor
    LABEL_CALLS = %i[label blabel label_tag _label_symbol_translation before_label].freeze
    CANVAS_TRANSLATE_CALLS = [:mt, :ot].freeze
    ALL_CALLS = (I18nliner::Extractors::RubyExtractor::TRANSLATE_CALLS +
      LABEL_CALLS + CANVAS_TRANSLATE_CALLS +
      # this one can go away when Canvas' initializer that adds it changes to Module#prepend
      [:label_with_symbol_translation]).freeze

    module ClassMethods
      # to get a slight speedup, i18nliner uses a regex to see if it even
      # needs to run RubyParser on the source
      def pattern
        @pattern ||= begin
          calls = (I18nliner::Extractors::RubyExtractor::TRANSLATE_CALLS + LABEL_CALLS).map { |c| Regexp.escape(c.to_s) }
          /(^|\W)(#{calls.join("|")})(\W|$)/
        end
      end
    end

    def self.prepended(klass)
      klass::TRANSLATE_CALLS.concat(CANVAS_TRANSLATE_CALLS)
    end

    def process_call(exp)
      # TODO: I18N: deprecate and drop this feature
      # automagically scope our plugin `-> { t ... }` stuff
      call_scope = @scope
      if exp[1] && exp[1].last == :Plugin && exp[2] == :register &&
         exp[3] && [:lit, :str].include?(exp[3].sexp_type)
        call_scope = I18nliner::Scope.new("plugins.#{exp[3].last}")
      end

      with_scope(call_scope) do
        super
      end
    end

    def with_scope(scope)
      orig_scope = @scope
      @scope = scope
      yield if block_given?
    ensure
      @scope = orig_scope
    end

    # override the default to:
    # 1. know about our label stuff and
    # 2. skip translate calls that happen inside something like `def t`
    def extractable_call?(receiver, method)
      return false unless ALL_CALLS.include?(method)
      return false if ALL_CALLS.include?(current_defn)

      receiver.nil? || receiver == :I18n || LABEL_CALLS.include?(method)
    end

    # add support for:
    # 1. labels
    # 2. whitespace preservation for mt
    def process_translate_call(receiver, method, args)
      remove_whitespace = @scope.remove_whitespace?
      if LABEL_CALLS.include?(method)
        process_label_call(receiver, method, args)
      else
        @scope.remove_whitespace = false if method == :mt
        super
      end
    ensure
      @scope.remove_whitespace = remove_whitespace
    end

    # TODO: I18N: deprecate and drop this (very convoluted) feature
    #
    # stuff we support:
    #  label :bar, :foo, :en => "Foo"
    #  label :bar, :foo, :foo_key, :en => "Foo"
    #  f.label :foo, :en => "Foo"
    #  f.label :foo, :foo_key, :en => "Foo"
    #  label_tag :foo, :en => "Foo"
    #  label_tag :foo, :foo_key, :en => "Foo"
    #  before_label :foo, "Foo"
    def process_label_call(receiver, method, args)
      args.shift if !receiver && [:label, :blabel].include?(method) # remove object_name arg

      return if args.size == 1 && method == :before_label

      default = nil
      key = args.shift
      # these can have an optional explicit key arg
      if %i[label blabel label_tag].include?(method) && (args[0].is_a?(Symbol) || args[0].is_a?(String))
        key = args.shift
      end

      if method == :before_label
        default = args.first
      elsif args.first.is_a?(Hash)
        default = args.first["en"] || args.first[:en]
      end

      if key && default
        key = "labels.#{key}" unless I18nliner::Scope::ABSOLUTE_KEY.match?(key)
        process_translate_call(nil, :t, [key, default])
      end
    end
  end

  # legacy automatic-file-scoping logic for explicit keys
  #
  # See various `i18n_scope` redefinitions in
  # config/initializers/i18n.rb for runtime counterparts

  module RubyProcessor
    STI_SUPERCLASSES = (`grep '^class.*<' ./app/models/*rb|grep -v '::'|sed 's~.*< ~~'|sort|uniq`
      .split("\n") - ["OpenStruct"])
                       .map(&:underscore).freeze

    def scope_for(filename)
      scope = case filename
              when %r{app/controllers/}
                scope = filename.gsub(%r{.*app/controllers/|_controller\.rb}, "").gsub(%r{/_?}, ".")
                (scope == "application.") ? "" : scope
              when %r{app/models/}
                scope = filename.gsub(%r{.*app/models/|\.rb}, "")
                STI_SUPERCLASSES.include?(scope) ? "" : scope
              end
      I18nliner::Scope.new scope
    end
  end

  module ErbProcessor
    def scope_for(filename)
      remove_whitespace = true
      scope = case filename
              when %r{app/messages/}
                remove_whitespace = false unless filename.include?("html")
                filename.gsub(%r{.*app/|\.erb}, "").gsub(%r{/_?}, ".")
              when %r{app/views/}
                filename.gsub(%r{.*app/views/|\.(html\.|fbml\.)?erb\z}, "").gsub(%r{/_?}, ".")
              end
      I18nliner::Scope.new scope, remove_whitespace:
    end
  end
end

I18nliner::Extractors::TranslateCall.prepend(I18nExtraction::Extensions::TranslateCall)
I18nliner::Extractors::RubyExtractor.prepend(I18nExtraction::Extensions::RubyExtractor)
I18nliner::Extractors::RubyExtractor.singleton_class.prepend(I18nExtraction::Extensions::RubyExtractor::ClassMethods)
I18nliner::Processors::RubyProcessor.prepend(I18nExtraction::Extensions::RubyProcessor)
I18nliner::Processors::ErbProcessor.prepend(I18nExtraction::Extensions::ErbProcessor)
