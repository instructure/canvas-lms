#
# Copyright (C) 2019 - present Instructure, Inc.
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

class AuditLogFieldExtension < GraphQL::Schema::FieldExtension
  # this Logger class exists because grahpql-ruby freezes FieldExtensions, but
  # rspec can't mock methods on frozen objects
  class Logger
    @@_sequence = 1
    def self.log(entry, timestamp, ttl, mutation, context, arguments)
      raise "mutation results must respond_to #global_asset_string" unless entry.respond_to? :global_asset_string

      dynamo = Canvas::DynamoDB::DatabaseBuilder.from_config(:auditors)
      dynamo.put_item(
        table_name: "graphql_mutations",
        item: {
          # NOTE: global_asset_string is exactly the sort of thing I
          # need, but maybe not very user-friendly? The names of classes
          # may not correspond to what users are used to seeing in the
          # ui/api.
          "object_id" => entry.global_asset_string,
          # TODO: i need the timestamp in this column for ordering, and
          # the request_id and sequence to guarantee uniqueness...
          # should i also break the request_id / timestamp out into
          # their own attribute?
          "mutation_id" => "#{timestamp}-#{context[:request_id]}-##{@@_sequence += 1}",
          "expires" => ttl,
          "mutation_name" => mutation.graphql_name,
          "current_user_id" => context[:current_user]&.global_id&.to_s,
          "real_current_user_id" => context[:real_current_user]&.global_id&.to_s,
          "params" => ActionDispatch::Http::ParameterFilter.new(Rails.application.config.filter_parameters).filter(arguments[:input].to_h),
        },
        return_consumed_capacity: "TOTAL"
      )
    rescue Aws::DynamoDB::Errors::ServiceError => e
      Rails.logger.error "Couldn't log mutation: #{e}"
    end
  end

  def self.enabled?
    Canvas::DynamoDB::DatabaseBuilder.configured?(:auditors)
  end

  def resolve(object:, arguments:, context:, **rest)
    yield(object, arguments).tap do |value|
      next unless AuditLogFieldExtension.enabled?

      timestamp = Time.now.iso8601
      ttl = 90.days.from_now.to_i
      mutation = field.mutation

      mutation.fields.each do |_, return_field|
        next if return_field.original_name == :errors
        if entry = value[return_field.original_name]
          # technically we could be returning lists of lists but gosh dang i
          # hope we never do that
          if entry.respond_to?(:each)
            entry.each { |e| Logger.log(e, timestamp, ttl, mutation, context, arguments) }
          else
            Logger.log(entry, timestamp, ttl, mutation, context, arguments)
          end
        end
      end
    end
  end
end
