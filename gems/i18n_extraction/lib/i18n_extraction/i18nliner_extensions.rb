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

class I18nliner::Extractors::TranslateCall
  def validate_default_with_html_check
    if @default.is_a?(String)
      if @default =~ /<[a-z][a-z0-9]*[> \/]/i
        raise I18nliner::HtmlTagsInDefaultTranslationError.new(@line, @default)
      end
    end
    validate_default_without_html_check
  end
  alias_method_chain :validate_default, :html_check

  def validate_key_with_scoping_check
    if @scope.root? && !@meta[:explicit_receiver] && !@options[:i18nliner_inferred_key] && key !~ I18nliner::Scope::ABSOLUTE_KEY
      raise I18nliner::AmbiguousTranslationKeyError.new(@line, @key)
    end
    validate_key_without_scoping_check
  end
  alias_method_chain :validate_key, :scoping_check
end

class I18nliner::Extractors::RubyExtractor
  # make the extractor aware of all of our canvas i18n-y helpers
  TRANSLATE_CALLS << :mt << :ot
  LABEL_CALLS = [:label, :blabel, :label_tag, :_label_symbol_translation, :before_label]
  ALL_CALLS = TRANSLATE_CALLS + LABEL_CALLS + [:label_with_symbol_translation]

  # to get a slight speedup, i18nliner uses a regex to see if it even
  # needs to run RubyParser on the source
  def self.pattern
    @pattern ||= begin
      calls = (TRANSLATE_CALLS + LABEL_CALLS).map{ |c| Regexp.escape(c.to_s) }
      /(^|\W)(#{calls.join('|')})(\W|$)/
    end
  end

  def process_call_with_scope(exp)
    # TODO I18N: deprecate and drop this feature
    # automagically scope our plugin `-> { t ... }` stuff
    call_scope = @scope
    if exp[1] && exp[1].last == :Plugin && exp[2] == :register &&
        exp[3] && [:lit, :str].include?(exp[3].sexp_type)
      call_scope = I18nliner::Scope.new("plugins.#{exp[3].last}")
    end

    with_scope(call_scope) do
      process_call_without_scope(exp)
    end
  end
  alias_method_chain :process_call, :scope

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
    (receiver.nil? || receiver == :I18n || LABEL_CALLS.include?(method))
  end

  # add support for:
  # 1. labels
  # 2. whitespace preservation for mt
  def process_translate_call_with_extras(receiver, method, args)
    remove_whitespace = @scope.remove_whitespace?
    if LABEL_CALLS.include?(method)
      process_label_call(receiver, method, args)
    else
      @scope.remove_whitespace = false if method == :mt
      process_translate_call_without_extras(receiver, method, args)
    end
  ensure
    @scope.remove_whitespace = remove_whitespace
  end
  alias_method_chain :process_translate_call, :extras

  # TODO I18N: deprecate and drop this (very convoluted) feature
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
    if [:label, :blabel, :label_tag].include?(method) && (args[0].is_a?(Symbol) || args[0].is_a?(String))
      key = args.shift
    end

    if method == :before_label
      default = args.first
    elsif args.first.is_a?(Hash)
      default = args.first['en'] || args.first[:en]
    end

    if key && default
      key = "labels.#{key}" unless key =~ I18nliner::Scope::ABSOLUTE_KEY
      process_translate_call(nil, :t, [key, default])
    end
  end
end


# legacy automatic-file-scoping logic for explicit keys
#
# See various `i18n_scope` redefinitions in
# config/initializers/i18n.rb for runtime counterparts

class I18nliner::Processors::RubyProcessor
  STI_SUPERCLASSES = (`grep '^class.*<' ./app/models/*rb|grep -v '::'|sed 's~.*< ~~'|sort|uniq`.split("\n") - ['OpenStruct', 'Tableless']).
    map(&:underscore)

  def scope_for(filename)
    scope = case filename
    when /app\/controllers\//
      scope = filename.gsub(/.*app\/controllers\/|_controller\.rb/, '').gsub(/\/_?/, '.')
      scope == 'application.' ? '' : scope
    when /app\/models\//
      scope = filename.gsub(/.*app\/models\/|\.rb/, '')
      STI_SUPERCLASSES.include?(scope) ? '' : scope
    end
    I18nliner::Scope.new scope
  end
end

class I18nliner::Processors::ErbProcessor
  def scope_for(filename)
    remove_whitespace = true
    scope = case filename
    when /app\/messages\//
      remove_whitespace = false unless filename =~ /html/
      filename.gsub(/.*app\/|\.erb/, '').gsub(/\/_?/, '.')
    when /app\/views\//
      filename.gsub(/.*app\/views\/|\.(html\.|fbml\.)?erb\z/, '').gsub(/\/_?/, '.')
    end
    I18nliner::Scope.new scope, remove_whitespace: remove_whitespace
  end
end
