# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
require "audits/engine"
require "canvas_cassandra"
require "switchman"

module Audits
  class << self
    def stream(&block)
      ::EventStream::Stream.new(&block).tap do |stream|
        stream.raise_on_error = Rails.env.test?

        stream.on_insert do |record|
          EventStream::Logger.info('AUDITOR', identifier, 'insert', record.to_json)
        end

        stream.on_error do |operation, record, exception|
          next unless Audits.configured?
          EventStream::Logger.error('AUDITOR', identifier, operation, record.to_json, exception.message.to_s)
        end
      end
    end

    def logger
      Rails.logger
    end

    def read_stream_options(options)
      return { backend_strategy: :cassandra }.merge(options) if Audits.read_from_cassandra?
      return { backend_strategy: :active_record }.merge(options) if Audits.read_from_postgres?
      # Assume cassandra by default until transition complete
      { backend_strategy: :cassandra }.merge(options)
    end

    def backend_strategy
      strategy_value = :cassandra
      strategy_value = :active_record if read_from_postgres?
      strategy_value
    end

    def configured?
      strategy = backend_strategy
      if strategy == :cassandra
        return CanvasCassandra::DatabaseBuilder.configured?('auditors')
      elsif strategy == :active_record
        return Rails.configuration.database_configuration[Rails.env].present?
      end
      raise ArgumentError, "Unknown Audits Backend Strategy: #{strategy}"
    end

    def write_to_cassandra?
      write_paths.include?('cassandra')
    end

    def write_to_postgres?
      write_paths.include?('active_record')
    end

    def read_from_cassandra?
      read_path == 'cassandra'
    end

    def read_from_postgres?
      read_path == 'active_record'
    end

    def read_path
      config&.[]('read_path') || 'cassandra'
    end

    def write_paths
      paths = [config&.[]('write_paths')].flatten.compact
      # default to both for now.
      # after a year we will have hit our retention period
      # and can safely de-comission all auditors cassandra code.
      paths.empty? ? ['cassandra', 'active_record'] : paths
    end

    def config(shard=::Switchman::Shard.current)
      settings = DynamicSettings.find(tree: :private, cluster: shard.database_server.id)
      YAML.safe_load(settings['auditors.yml'] || '{}')
    end
  end
end