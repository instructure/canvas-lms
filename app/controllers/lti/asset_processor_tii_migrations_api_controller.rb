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
#

module Lti
  class AssetProcessorTiiMigrationsApiController < ApplicationController
    include Api::V1::Progress

    before_action :require_user
    before_action :get_context
    before_action :require_account_context
    before_action :require_root_account, only: [:index, :migrate_all]
    before_action :require_manage_lti_registrations
    before_action { require_feature_enabled :lti_asset_processor_tii_migration }

    def index
      render json: {
        accounts: fetch_accounts_with_tii_tools,
        coordinator_progress: fetch_coordinator_progress
      }
    end

    def create
      progress = create_migration_progress(@context, params[:email])
      render json: progress_json(progress, @current_user, session)
    end

    def migrate_all
      account_data = fetch_accounts_with_tii_tools

      eligible_account_ids = account_data.filter_map do |data|
        progress = data[:migration_progress]
        workflow_state = progress&.dig(:workflow_state)

        data[:account_id] if workflow_state.nil?
      end

      bulk_migration_id = SecureRandom.uuid

      # Create coordinator Progress record to track bulk migration
      coordinator = Progress.create!(
        context: @context,
        tag: Lti::AssetProcessorTiiMigrationWorker::COORDINATOR_TAG,
        user: @current_user
      )
      coordinator.set_results({ bulk_migration_id:, email: params[:email] })
      coordinator.start!

      progress_ids = []

      Account.transaction do
        eligible_account_ids.each do |account_id|
          account = Account.find(account_id)
          progress = create_migration_progress(account, params[:email], coordinator.id)
          progress_ids << progress.id if progress
        end
      end

      render json: {
        progress_ids:,
        account_ids: eligible_account_ids,
        bulk_migration_id:,
        coordinator_id: coordinator.id
      }
    end

    private

    def require_root_account
      raise ActiveRecord::RecordNotFound unless @context.root_account?
    end

    def require_manage_lti_registrations
      require_context_with_permission(@context, :manage_lti_registrations)
    end

    def create_migration_progress(account, email, coordinator_id = nil)
      existing_progress = Progress
                          .is_pending
                          .where(context: account, tag: Lti::AssetProcessorTiiMigrationWorker::PROGRESS_TAG)
                          .order(created_at: :desc)
                          .first

      return existing_progress if existing_progress

      progress = Progress.create!(
        context: account,
        tag: Lti::AssetProcessorTiiMigrationWorker::PROGRESS_TAG,
        user: @current_user
      )
      progress.set_results({ coordinator_id: }) if coordinator_id
      progress.process_job(
        Lti::AssetProcessorTiiMigrationWorker.new(account, email, coordinator_id),
        :perform,
        {
          priority: Delayed::HIGH_PRIORITY,
          strand: "tii_migration_account_#{account.global_id}"
        }
      )
      progress
    end

    def fetch_accounts_with_tii_tools
      account_ids = find_account_ids_with_tii_tool_proxies(@context.id)
      return [] if account_ids.empty?

      progress_by_account = batch_find_migration_progress(account_ids)

      Account.where(id: account_ids).find_each.map do |account|
        {
          account_name: account.name,
          account_id: account.id,
          migration_progress: progress_by_account[account.id]
        }.compact
      end || []
    end

    def find_account_ids_with_tii_tool_proxies(root_account_id)
      account_level_bindings = Lti::ToolProxyBinding
                               .joins(:tool_proxy)
                               .joins("INNER JOIN #{Lti::ProductFamily.quoted_table_name} ON lti_product_families.id = lti_tool_proxies.product_family_id")
                               .joins("INNER JOIN #{Account.quoted_table_name} ON lti_tool_proxy_bindings.context_type = 'Account' AND lti_tool_proxy_bindings.context_id = accounts.id")
                               .where(lti_tool_proxy_bindings: { enabled: true })
                               .where(lti_tool_proxies: { workflow_state: "active" })
                               .where(lti_product_families: { vendor_code: Lti::AssetProcessorTiiMigrationWorker::TII_TOOL_VENDOR_CODE, product_code: Lti::AssetProcessorTiiMigrationWorker::TII_TOOL_PRODUCT_CODE })
                               .where.not(accounts: { workflow_state: "deleted" })
                               .where("accounts.id = ? OR accounts.root_account_id = ?", root_account_id, root_account_id)
                               .distinct
                               .pluck("accounts.id")

      course_level_bindings = Lti::ToolProxyBinding
                              .joins(:tool_proxy)
                              .joins("INNER JOIN #{Lti::ProductFamily.quoted_table_name} ON lti_product_families.id = lti_tool_proxies.product_family_id")
                              .joins("INNER JOIN #{Course.quoted_table_name} ON lti_tool_proxy_bindings.context_type = 'Course' AND lti_tool_proxy_bindings.context_id = courses.id")
                              .where(lti_tool_proxy_bindings: { enabled: true })
                              .where(lti_tool_proxies: { workflow_state: "active" })
                              .where(lti_product_families: { vendor_code: Lti::AssetProcessorTiiMigrationWorker::TII_TOOL_VENDOR_CODE, product_code: Lti::AssetProcessorTiiMigrationWorker::TII_TOOL_PRODUCT_CODE })
                              .where.not(courses: { workflow_state: "deleted" })
                              .where(courses: { root_account_id: })
                              .distinct
                              .pluck("courses.account_id")

      (account_level_bindings + course_level_bindings).uniq
    end

    # Do not call it yet, because it can be quite slow on large shards even if the limit is there.
    def batch_count_tii_assignments(account_ids)
      account_ids.index_with do |account_id|
        AssignmentConfigurationToolLookup
          .where(tool_vendor_code: Lti::AssetProcessorTiiMigrationWorker::TII_TOOL_VENDOR_CODE, tool_product_code: Lti::AssetProcessorTiiMigrationWorker::TII_TOOL_PRODUCT_CODE)
          .joins(assignment: :course)
          .where(courses: { account_id: })
          .where.not(courses: { workflow_state: "deleted" })
          .where.not(assignments: { workflow_state: "deleted" })
          .limit(1001)
          .count
      end
    end

    def batch_find_migration_progress(account_ids)
      Progress
        .where(context_type: "Account", context_id: account_ids, tag: Lti::AssetProcessorTiiMigrationWorker::PROGRESS_TAG)
        .order(created_at: :asc)
        .index_by(&:context_id)
        .transform_values do |progress|
          {
            id: progress.id,
            workflow_state: progress.workflow_state,
            completion: progress.completion,
            message: progress.message,
            results: {
              migration_report_url: progress.results&.dig(:migration_report_url)
            }
          }
        end
    end

    def fetch_coordinator_progress
      coordinator = Progress
                    .where(context: @context, tag: Lti::AssetProcessorTiiMigrationWorker::COORDINATOR_TAG)
                    .order(created_at: :desc)
                    .first

      return nil unless coordinator

      {
        id: coordinator.id,
        workflow_state: coordinator.workflow_state,
        consolidated_report_url: coordinator.results&.dig(:consolidated_report_url)
      }
    end
  end
end
