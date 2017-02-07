#
# Copyright (C) 2015 Instructure, Inc.
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
#

# This is an initializer, but needs to be required earlier in the load process,
# and before canvas-jobs

# We need to make sure that safe_yaml is loaded *after* the YAML engine
# is switched to Psych. Otherwise we
# won't have access to (safe|unsafe)_load.
require 'yaml'
require 'safe_yaml'

module FixSafeYAMLNullMerge
  def merge_into_hash(hash, array)
    return unless array
    super
  end
end
SafeYAML::Resolver.prepend(FixSafeYAMLNullMerge)

SafeYAML::OPTIONS.merge!(
    default_mode: :safe,
    deserialize_symbols: true,
    raise_on_unknown_tag: true,
    # This tag whitelist is syck specific. We'll need to tweak it when we upgrade to psych.
    # See the tests in spec/lib/safe_yaml_spec.rb
    whitelisted_tags: %w[
        !ruby/symbol
        !binary
        !float
        !float#exp
        !float#inf
        !str
        tag:yaml.org,2002:str
        !timestamp
        !timestamp#iso8601
        !timestamp#spaced
        !map:HashWithIndifferentAccess
        !map:ActiveSupport::HashWithIndifferentAccess
        !map:WeakParameters
        !ruby/hash:HashWithIndifferentAccess
        !ruby/hash:ActiveSupport::HashWithIndifferentAccess
        !ruby/hash:WeakParameters
        !ruby/hash:ActionController::Parameters
        !ruby/object:Class
        !ruby/object:OpenStruct
        !ruby/object:Scribd::Document
        !ruby/object:Mime::Type
        !ruby/object:URI::HTTP
        !ruby/object:URI::HTTPS
        !ruby/object:OpenObject
        !ruby/object:DateTime
        !ruby/object:BigDecimal
      ]
)

module Syckness
  TAG = "#GETDOWNWITHTHESYCKNESS\n"
end

[Object, Hash, Struct, Array, Exception, String, Symbol, Range, Regexp, Time,
  Date, Integer, Float, Rational, Complex, TrueClass, FalseClass, NilClass].each do |klass|
  klass.class_eval do
    alias :to_yaml :psych_to_yaml
  end
end

SafeYAML::PsychResolver.class_eval do
  attr_accessor :aliased_nodes
end

module MaintainAliases
  def accept(node)
    if node.respond_to?(:anchor) && node.anchor && @resolver.get_node_type(node) != :alias
      @resolver.aliased_nodes[node.anchor] = node
    end
    super
  end
end
SafeYAML::SafeToRubyVisitor.prepend(MaintainAliases)

module FloatScannerFix
  def tokenize string
    return nil if string.empty?
    return string if @string_cache.key?(string)
    return @symbol_cache[string] if @symbol_cache.key?(string)

    case string
      # Check for a String type, being careful not to get caught by hash keys, hex values, and
      # special floats (e.g., -.inf).
    when /^[^\d\.:-]?[A-Za-z_\s!@#\$%\^&\*\(\)\{\}\<\>\|\/\\~;=]+/
      if string.length > 5
        @string_cache[string] = true
        return string
      end

      case string
      when /^[^ytonf~]/i
        @string_cache[string] = true
        string
      when '~', /^null$/i
        nil
      when /^(yes|true|on)$/i
        true
      when /^(no|false|off)$/i
        false
      else
        @string_cache[string] = true
        string
      end
    when Psych::ScalarScanner::TIME
      begin
        parse_time string
      rescue ArgumentError
        string
      end
    when /^\d{4}-(?:1[012]|0\d|\d)-(?:[12]\d|3[01]|0\d|\d)$/
      require 'date'
      begin
        class_loader.date.strptime(string, '%Y-%m-%d')
      rescue ArgumentError
        string
      end
    when /^\.inf$/i
      Float::INFINITY
    when /^-\.inf$/i
      -Float::INFINITY
    when /^\.nan$/i
      Float::NAN
    when /^:./
      if string =~ /^:(["'])(.*)\1/
        @symbol_cache[string] = class_loader.symbolize($2.sub(/^:/, ''))
      else
        @symbol_cache[string] = class_loader.symbolize(string.sub(/^:/, ''))
      end
    when /^[-+]?[0-9][0-9_]*(:[0-5]?[0-9])+$/
      i = 0
      string.split(':').each_with_index do |n,e|
        i += (n.to_i * 60 ** (e - 2).abs)
      end
      i
    when /^[-+]?[0-9][0-9_]*(:[0-5]?[0-9])+\.[0-9_]*$/
      i = 0
      string.split(':').each_with_index do |n,e|
        i += (n.to_f * 60 ** (e - 2).abs)
      end
      i
    when Psych::ScalarScanner::FLOAT
      if string =~ /\A[-+]?\.\Z/
        @string_cache[string] = true
        string
      else
        Float(string.gsub(/[,_:]|\.([Ee]|$)/, '\1')) # TODO: Remove when https://github.com/tenderlove/psych/pull/276 is merged
      end
    else
      int = parse_int string.gsub(/[,_]/, '')
      return int if int

      @string_cache[string] = true
      string
    end
  end
end
Psych::ScalarScanner.prepend(FloatScannerFix)

module ScalarTransformFix
  def to_guessed_type(value, quoted=false, options=nil)
    return value if quoted

    if value.is_a?(String)
      @ss ||= Psych::ScalarScanner.new(Psych::ClassLoader.new)
      return @ss.tokenize(value) # just skip straight to Psych if it's a scalar because SafeYAML's transform mades me a sad panda
    end

    value
  end
end
SafeYAML::Transform.singleton_class.prepend(ScalarTransformFix)
