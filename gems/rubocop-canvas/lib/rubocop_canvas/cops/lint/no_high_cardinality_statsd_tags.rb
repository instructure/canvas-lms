# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module RuboCop
  module Cop
    module Lint
      class NoHighCardinalityStatsdTags < Base
        MSG = "High-cardinality tag detected in StatsD metric. Tags like user_id, " \
              "domain, email, etc. create unique values per entity and can " \
              "dramatically increase DataDog costs. Use low-cardinality tags like " \
              "cluster, environment, or type instead."

        STATSD_METHODS = %i[distributed_increment increment gauge timing count].freeze

        HIGH_CARDINALITY_KEYS = %w[
          user_id
          account_id
          course_id
          global_id
          email
          domain
          host
          hostname
          ip
          ip_address
          uuid
          timestamp
          time
        ].freeze

        HIGH_CARDINALITY_KEY_PATTERNS = [
          /_id$/,
        ].freeze

        SAFE_ID_KEYS = %w[shard_id].freeze

        def_node_matcher :statsd_call?, <<~PATTERN
          (send
            (const (const nil? :InstStatsd) :Statsd)
            {#{STATSD_METHODS.map(&:inspect).join(" ")}}
            ...)
        PATTERN

        def on_send(node)
          return unless statsd_call?(node)

          node.arguments.each do |arg|
            next unless arg.hash_type?

            arg.each_pair do |key, value|
              next unless key.sym_type? && key.value == :tags
              next unless value.hash_type?

              check_tags_hash(value, node)
            end
          end
        end

        private

        def check_tags_hash(tags_hash, node)
          tags_hash.each_pair do |key, value|
            check_tag_pair(key, value, node)
          end
        end

        def check_tag_pair(key, value, node)
          add_offense(node, severity: :error) if high_cardinality_key?(key) || high_cardinality_value?(value)
        end

        def high_cardinality_key?(key)
          return false unless key.sym_type? || key.str_type?

          key_name = key.value.to_s

          return false if SAFE_ID_KEYS.include?(key_name)
          return true if HIGH_CARDINALITY_KEYS.include?(key_name)

          HIGH_CARDINALITY_KEY_PATTERNS.any? { |pattern| key_name.match?(pattern) }
        end

        def high_cardinality_value?(value)
          return false unless value.send_type?

          receiver, method_name, *_args = *value

          return true if method_name == :global_id
          return true if method_name == :id && receiver && !receiver.const_type? && !shard_related?(receiver)

          false
        end

        def shard_related?(node)
          return false unless node

          return true if node.send_type? && node.method_name == :shard
          return true if node.const_type? && node.const_name == :Shard

          shard_related?(node.receiver) if node.respond_to?(:receiver)
        end
      end
    end
  end
end
