#
# Copyright (C) 2012 - present Instructure, Inc.
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

# on-demand in-memory model caching for those times where the rails query
# cache can't help you, like in this contrived example:
#
# # given:
#
# class Foo < ActiveRecord::Base
#   has_many :bars
# end
#
# class Bar < ActiveRecord::Base
#   belongs_to :foo
#   def something!
#     update_attribute :stuff, "my foo is: #{foo.name}"
#   end
# end
#
# # if you do:
# foo.bars.each(&:something!)
#
# # then by default, AR loads each bar's foo separately and won't use the
# # query cache, since each update blows it away.
#
# granted, the example is a bit contrived, as preloading would be one possible
# solution. ModelCache is useful for those times when preloading is just not
# feasible. See Conversation and ConversatonParticipant for real-world usage.

module ModelCache
  module ClassMethods
    # e.g. use this to cache calls to ConversationParticipant#conversation,
    # no matter how those conversation_participants were loaded
    def cacheable_method(method, options={})
      options[:cache_name] ||= method.to_s.pluralize.to_sym
      options[:key_method] ||= "#{method}_id"
      options[:key_lookup] ||= :id
      options[:type] ||= :instance

      # ensure the target class is ModelCache-aware, and set up the :id lookup
      target_klass = reflections[method.to_s].klass
      raise "`#{target_klass}` needs to `include ModelCache` before you can make `#{self}##{method}` cacheable" unless target_klass.included_modules.include?(ModelCache)
      unless ModelCache.keys[target_klass.name].include?(options[:key_lookup])
        ModelCache.keys[target_klass.name] << options[:key_lookup]
      end

      ModelCache.make_cacheable self, method, options
    end
  end

  module InstanceMethods
    def add_to_caches
      return unless cache = ModelCache[self.class.name.underscore.pluralize.to_sym]
      cache.keys.each do |key|
        cache[key][send(key)] = self
      end
    end

    def update_in_caches
      return unless cache = ModelCache[self.class.name.underscore.pluralize.to_sym]
      cache.keys.each do |key|
        if saved_change_to_attribute?(key)
          cache[key][send(key)] = self
          cache[key].delete(attribute_before_last_save(key))
        end
      end
    end
  end

  def self.with_cache(lookups)
    @cache = lookups.inject({}){ |h, (k, v)| h[k] = prepare_lookups(v); h }
    yield
  ensure
    @cache = nil
  end

  def self.[](cache_name)
    return nil unless @cache
    @cache[cache_name] || {}
  end

  def self.keys
    @keys ||= Hash.new{ |h, k| h[k] = [] }
  end

  def self.prepare_lookups(records)
    return records if records.is_a?(Hash)
    return {} if records.empty?

    keys[records.first.class.name].inject({}) do |h, k|
      h[k] = records.index_by(&k)
      h
    end
  end

  def self.make_cacheable(klass, method, options={})
    options[:type] ||= :class
    options[:cache_name] ||= klass.name.underscore.pluralize.to_sym
    options[:key_lookup] ||= method

    orig_method = "super"
    alias_method = nil

    key_value = options[:key_method] || "args.first"
    # if extra args are provided, we should clear out the current value
    # (e.g. if you call c.user(:lock => true) )
    expected_args = options[:key_method] ? 0 : 1
    maybe_reset = "cache[#{key_value}] = #{orig_method} if args.size > #{expected_args}"

    klass.send(options[:type] == :instance ? :class_eval : :instance_eval, <<-CODE, __FILE__, __LINE__+1)
      def #{method}(*args)
        if cache = ModelCache[#{options[:cache_name].inspect}] and cache = cache[#{options[:key_lookup].inspect}]
          #{maybe_reset}
          cache[#{key_value}] ||= #{orig_method}
        else
          #{orig_method}
        end
      end
      #{alias_method}
    CODE
  end

  def self.included(klass)
    klass.send :include, InstanceMethods
    klass.extend ClassMethods
    klass.after_create :add_to_caches
    klass.after_update :update_in_caches
  end
end
