#
# Copyright (C) 2018 - present Instructure, Inc.
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
module CanvasDynamoDB

  class Database

    DEFAULT_MIN_CAPACITY = 5
    DEFAULT_MAX_CAPACITY = 10000

    attr_reader :client, :fingerprint

    def initialize(fingerprint, prefix, autoscaling_role_arn, opts, logger)
      @client = Aws::DynamoDB::Client.new(opts)
      @region = opts[:region]
      @fingerprint = fingerprint
      @prefix = prefix
      @autoscaling_role_arn = autoscaling_role_arn
      @logger = logger
    end

    %i(create_table delete_item delete_table get_item put_item query scan update_item
       update_table update_time_to_live describe_time_to_live).each do |method|
      define_method(method) do |params|
        params = params.merge(
          table_name: prefixed_table_name(params[:table_name])
        )
        execute(method, params)
      end
    end

    %i(create_global_table update_global_table).each do |method|
      define_method(method) do |params|
        params = params.merge(
          global_table_name: prefixed_table_name(params[:global_table_name])
        )
        execute(method, params)
      end
    end

    %i(batch_get_item batch_write_item).each do |method|
      define_method(method) do |params|
        request_items = {}
        params[:request_items].each_key do |table_name|
          request_items[prefixed_table_name(table_name)] = params[:request_items][table_name]
        end
        execute(method, params.merge({ request_items: request_items }))
      end
    end

    def prefixed_table_name(table_name)
      "#{@prefix}-#{table_name}"
    end

    def batch_get
      BatchGetBuilder.new(self)
    end

    def batch_write
      BatchWriteBuilder.new(self)
    end

    def execute(method, params)
      result = nil
      ms = 1000 * Benchmark.realtime do
        result = @client.send(method, params)
      end
      @logger.debug("  #{"DDB (%.2fms)" % [ms]}  #{method}(#{params.inspect}) [#{fingerprint}]")
      result
    end

    def create_table_with_autoscaling(params)
      out = create_table(params)
      if scaling 
        scaling.register_scalable_target(register_scaling_target_params(
          params[:table_name],
          :read,
          min_capacity: params.dig(:provisioned_throughput, :read_capacity_units)
        ))
        scaling.put_scaling_policy(scaling_policy_params(params[:table_name], :read))
        scaling.register_scalable_target(register_scaling_target_params(
          params[:table_name],
          :write,
          min_capacity: params.dig(:provisioned_throughput, :write_capacity_units)
        ))
        scaling.put_scaling_policy(scaling_policy_params(params[:table_name], :write))
      end
      out
    end

    def delete_table_with_autoscaling(params)
      if scaling
        scaling.deregister_scalable_target(scaling_target_params(params[:table_name], :read,))
        scaling.deregister_scalable_target(scaling_target_params(params[:table_name], :write))
      end
      delete_table(params)
    end

    def scaling
      @scaling ||= begin
        if @autoscaling_role_arn
          require 'aws-sdk-applicationautoscaling'
          Aws::ApplicationAutoScaling::Client.new({ region: @region })
        end
      end
    end

    private

    def scaling_target_params(table_name, rw)
      scalable_dimension = rw == :read ?
        'dynamodb:table:ReadCapacityUnits' :
        'dynamodb:table:WriteCapacityUnits'
      {
        resource_id: "table/#{@prefix}#{table_name}", 
        scalable_dimension: scalable_dimension,
        service_namespace: "dynamodb",
      }
    end

    def register_scaling_target_params(table_name, rw, min_capacity: nil, max_capacity: nil)
      scaling_target_params(table_name, rw).merge({
        min_capacity: min_capacity || DEFAULT_MIN_CAPACITY, 
        max_capacity: max_capacity || DEFAULT_MAX_CAPACITY, 
        role_arn: @autoscaling_role_arn, 
      })
    end

    def scaling_policy_params(table_name, rw)
      predefined_metric_type = rw == :read ?
        'DynamoDBReadCapacityUtilization' :
        'DynamoDBWriteCapacityUtilization'
      scalable_dimension = rw == :read ?
        'dynamodb:table:ReadCapacityUnits' :
        'dynamodb:table:WriteCapacityUnits'
      {
        resource_id: "table/#{@prefix}#{table_name}", 
        policy_name: "#{@prefix}#{table_name}--#{predefined_metric_type}",
        policy_type: 'TargetTrackingScaling',
        scalable_dimension: scalable_dimension, 
        service_namespace: "dynamodb",
        target_tracking_scaling_policy_configuration: {
          target_value: 70.0,
          predefined_metric_specification: {
            predefined_metric_type: predefined_metric_type
          },
          scale_out_cooldown: 60,
          scale_in_cooldown: 60
        }
      }
    end

  end
end
