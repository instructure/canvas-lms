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
  class Logger
    def initialize(mutation, context, arguments)
      @mutation = mutation
      @context = context
      @params = process_arguments(arguments)

      @dynamo = Canvas::DynamoDB::DatabaseBuilder.from_config(:auditors)
      @sequence = 0
      @timestamp = Time.now
      @ttl = 90.days.from_now.to_i
    end

    def log(entry, field_name)
      @dynamo.put_item(
        table_name: "graphql_mutations",
        item: {
          # TODO: this is where you redirect
          "object_id" => log_entry_id(entry, field_name),
          "mutation_id" => mutation_id,
          "timestamp" => @timestamp.iso8601,
          "expires" => @ttl,
          "mutation_name" => @mutation.graphql_name,
          "current_user_id" => @context[:current_user]&.global_id&.to_s,
          "real_current_user_id" => @context[:real_current_user]&.global_id&.to_s,
          "params" => @params,
        },
        return_consumed_capacity: "TOTAL"
      )
    rescue Aws::DynamoDB::Errors::ServiceError => e
      Rails.logger.error "Couldn't log mutation: #{e}"
    end

    def log_entry_id(entry, field_name)
      override_entry_method = :"#{field_name}_log_entry"
      entry = @mutation.send(override_entry_method, entry, @context) if @mutation.respond_to?(override_entry_method)

      domain_root_account = root_account_for(entry)

      "#{domain_root_account.global_id}-#{entry.asset_string}"
    end

    ##
    # it's too expensive to try to determine if a user has permission for each
    # log entry on the mutation audit log, so instead we make sure that they
    # have permission to view logs in their domain root account, and embed the
    # root_account_id for every object in its identifier.
    #
    # this method will have to know how to resolve a root account for every
    # object that is logged by a mutation
    def root_account_for(entry)
      if Progress === entry
        entry = entry.context
      end

      if entry.respond_to? :root_account_id
        return entry.root_account if entry.root_account.present?
      end

      case entry
      when Course
        entry.root_account
      when Assignment, ContextModule, SubmissionComment
        entry.context.root_account
      when Submission
        entry.assignment.course.root_account
      when SubmissionDraft
        entry.submission.assignment.course.root_account
      when PostPolicy
        (entry.assignment&.course || entry.course).root_account
      else
        raise "don't know how to resolve root_account for #{entry.inspect}"
      end
    end

    # TODO: i need the timestamp in this column for ordering, and
    # the request_id and sequence to guarantee uniqueness...
    # should i also break the request_id / timestamp out into
    # their own attributes?
    def mutation_id
      "#{@timestamp.to_f}-#{@context[:request_id]}-##{@sequence += 1}"
    end

    private

    def process_arguments(arguments)
      params = ActionDispatch::Http::ParameterFilter.new(Rails.application.config.filter_parameters).filter(arguments[:input].to_h)
      truncate_params!(params)
    end

    def truncate_params!(o)
      case o
      when Hash
        o.each { |k,v| o[k] = truncate_params!(v) }
      when Array
        o.map! { |x| truncate_params!(x) }
      when String
        o.size > 256 ? o.slice(0, 256) : o
      else
        o
      end
    end
  end

  def self.enabled?
    Canvas::DynamoDB::DatabaseBuilder.configured?(:auditors)
  end

  def resolve(object:, arguments:, context:, **rest)
    yield(object, arguments).tap do |value|
      next unless AuditLogFieldExtension.enabled?

      mutation = field.mutation

      logger = Logger.new(mutation, context, arguments)

      # TODO? I make a log entry all the fields of the mutation, but maybe I
      # should make them on the arguments too???
      mutation.fields.each do |_, return_field|
        next if return_field.original_name == :errors
        if entry = value[return_field.original_name]
          # technically we could be returning lists of lists but gosh dang i
          # hope we never do that
          if entry.respond_to?(:each)
            entry.each do |e|
              logger.log(e, return_field.original_name)
            end
          else
            logger.log(entry, return_field.original_name)
          end
        end
      end
    end
  end
end
