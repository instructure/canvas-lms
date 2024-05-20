# frozen_string_literal: true

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
      log_entry_ids(entry, field_name).each do |log_entry_id|
        @dynamo.put_item(
          table_name: AuditLogFieldExtension.ddb_table_name,
          item: {
            # TODO: this is where you redirect
            "object_id" => log_entry_id,
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
      end
    rescue Aws::DynamoDB::Errors::ServiceError => e
      ::Canvas::Errors.capture_exception(:graphql_mutation_audit_logs, e)
      Rails.logger.error "Couldn't log mutation: #{e}"
    end

    def log_entry_ids(entry, field_name)
      override_entry_method = :"#{field_name}_log_entry"
      entry = @mutation.send(override_entry_method, entry, @context) if @mutation.respond_to?(override_entry_method)

      domain_root_account_ids = root_account_ids_for(entry)

      domain_root_account_ids.map do |domain_root_account_id|
        "#{domain_root_account_id}-#{entry.asset_string}"
      end
    end

    ##
    # it's too expensive to try to determine if a user has permission for each
    # log entry on the mutation audit log, so instead we make sure that they
    # have permission to view logs in their domain root account, and embed the
    # root_account_id for every object in its identifier.
    #
    # this method will have to know how to resolve a root account for every
    # object that is logged by a mutation
    def root_account_ids_for(entry)
      if entry.is_a?(Progress)
        entry = entry.context
      end

      if entry.respond_to? :global_root_account_ids
        return entry.global_root_account_ids
      end

      if entry.respond_to? :root_account_id
        return [Shard.global_id_for(entry.root_account_id, entry.shard)]
      end

      case entry
      when SubmissionDraft
        [Shard.global_id_for(entry.submission.root_account_id, entry.shard)]
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
      params = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter(arguments[:input].to_h)
      truncate_params!(params)
    end

    def truncate_params!(o)
      case o
      when Hash
        o.each { |k, v| o[k] = truncate_params!(v) }
      when Array
        o.map! { |x| truncate_params!(x) }
      when String
        (o.size > 256) ? o.slice(0, 256) : o
      else
        o
      end
    end
  end

  def self.enabled?
    Canvas::DynamoDB::DatabaseBuilder.configured?(:auditors)
  end

  def self.ddb_table_name
    Setting.get("graphql_mutations_ddb_table_name", "graphql_mutations")
  end

  def resolve(object:, arguments:, context:, **)
    yield(object, arguments).tap do |value|
      next unless AuditLogFieldExtension.enabled?

      mutation = field.mutation
      # DiscussionEntryDrafts are not objects that need audit logs, they are
      # only allowed to be created by the user, and they have timestamps, so
      # skip audit logs for this mutation.
      #
      # Also skip audit logs for internal setting mutations, which can only
      # be executed by siteadmins.
      #
      # Also skip audit logs for user inbox label mutations, which can only
      # be executed by the user itself. We can improve that later outside of
      # hackweek.
      next if [Mutations::CreateDiscussionEntryDraft,
               Mutations::CreateInternalSetting,
               Mutations::UpdateInternalSetting,
               Mutations::DeleteInternalSetting,
               Mutations::CreateUserInboxLabel,
               Mutations::DeleteUserInboxLabel].include? mutation

      logger = Logger.new(mutation, context, arguments)

      # TODO? I make a log entry all the fields of the mutation, but maybe I
      # should make them on the arguments too???
      mutation.fields.each_value do |return_field|
        next if return_field.original_name == :errors

        if (entry = value[return_field.original_name])
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
