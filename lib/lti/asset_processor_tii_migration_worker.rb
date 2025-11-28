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
  class AssetProcessorTiiMigrationWorker
    TII_TOOL_VENDOR_CODE = "turnitin.com"
    TII_TOOL_PRODUCT_CODE = "turnitin-lti"

    def initialize(account, email = nil)
      @account = account
      @email = email
      @results = { proxies: {} }
    end

    def perform(progress)
      @progress = progress

      if prevalidations_successful?
        @progress.calculate_completion!(0, actls_for_account_count)
        migrate_actls
      end
      @progress.set_results(@results)
      create_migration_report
      send_migration_report_email

      # TODO: fail the job if there were fatal errors
    end

    private

    def migrate_actls
      actls_for_account.find_each do |actl|
        tool_proxy = actl.associated_tool_proxy
        # only migrate if tool proxy is installed on this account/course (not for sub-accounts)
        next unless tool_proxy.present? && proxy_in_account?(tool_proxy, @account)

        initialize_proxy_results(tool_proxy)

        if get_proxy_result(tool_proxy, :cet_creation_failed) # We could not create the CET for this TP earlier so skipping
          next
        end

        unless tool_proxy.migrated_to_context_external_tool.present?
          migrate_tool_proxy(tool_proxy)
          unless proxy_errors(tool_proxy).empty? && tool_proxy.reload.migrated_to_context_external_tool.present?
            set_proxy_result(tool_proxy, :cet_creation_failed, true)
            log_proxy_error(tool_proxy, "Skipping ACTL ID=#{actl.id} migration due to failed CET creation Tool Proxy ID=#{tool_proxy.global_id}")
            next
          end
        end

        create_asset_processor_from_actl(actl, tool_proxy)

        # TODO: migrate reports
      rescue => e
        Canvas::Errors.capture_exception(:tii_migration, e)
        log_proxy_error(tool_proxy, "Unexpected error migrating ACTL ID=#{actl.id}")
      ensure
        @progress.increment_completion!(1)
      end
    end

    def proxy_in_account?(tool_proxy, account)
      if tool_proxy.context_type == "Account"
        tool_proxy.context == account
      elsif tool_proxy.context_type == "Course"
        tool_proxy.context.account == account
      end
    end

    def sub_account_ids
      @sub_account_ids ||= [@account.id] + Account.sub_account_ids_recursive(@account.id)
    end

    def actls_for_account
      AssignmentConfigurationToolLookup
        .where(
          tool_vendor_code: "turnitin.com",
          tool_product_code: "turnitin-lti",
          tool_type: "Lti::MessageHandler"
        )
        .joins(:assignment)
        .joins(assignment: :course)
        .where(courses: { account_id: sub_account_ids })
        .where.not(assignments: { workflow_state: "deleted" })
        .where.not(courses: { workflow_state: "deleted" })
    end

    def actls_for_account_count
      actls_for_account.count
    end

    def migrate_tool_proxy(tool_proxy)
      # Find LTI 1.3 deployments with ActivityAssetProcessor placement and Turnitin developer key
      deployments = find_tii_asset_processor_deployments(tool_proxy.context)
      context_matching_deployments = deployments.select { |deployment| deployment.context == tool_proxy.context }

      if deployments.length > 1
        log_proxy_error(tool_proxy, "Multiple TII AP deployments found in context. #{deployments.map(&:id).join(", ")}")
        return
      end

      if context_matching_deployments.empty?
        if deployments.any?
          log_proxy_error(tool_proxy, "Found #{deployments.map { |d| "CET ID=#{d.id}" }.join(", ")}} TII AP deployments in context of Tool Proxy ID=#{tool_proxy.global_id}, but none match the context. Skipping migration.")
          return
        end
        Rails.logger.info("No TII AP deployment found for Tool Proxy ID=#{tool_proxy.global_id}, creating one")
        deployment = create_tii_deployment(tool_proxy)
        return unless deployment

        context_matching_deployments = [deployment]
      else
        Rails.logger.info("Found 1 TII AP deployment for Tool Proxy ID=#{tool_proxy.global_id}, migrating")
      end

      tii_tp_migration(tool_proxy, context_matching_deployments.first)
    end

    def tii_developer_key
      return @tii_developer_key if defined?(@tii_developer_key)

      dk_id = Setting.get("turnitin_asset_processor_client_id", "")
      @tii_developer_key = if dk_id.blank?
                             nil
                           else
                             DeveloperKey.find(dk_id)
                           end
    rescue ActiveRecord::RecordNotFound
      Rails.logger.warn("Developer key not found for client_id: #{dk_id}")
      @tii_developer_key = nil
    end

    def find_tii_asset_processor_deployments(context)
      Lti::ContextToolFinder.all_tools_for(
        context,
        placements: [:ActivityAssetProcessor]
      ).select { |tool| tool.developer_key_id == tii_developer_key.id }
    end

    def create_tii_deployment(tool_proxy)
      # Create deployment (ContextExternalTool) in the same context as the tool_proxy
      deployment = tii_developer_key.lti_registration.new_external_tool(
        tool_proxy.context,
        verify_uniqueness: true,
        current_user: @progress.user
      )
      Rails.logger.info("Created TII Asset Processor deployment ID=#{deployment.global_id} for Tool Proxy ID=#{tool_proxy.global_id}")
      deployment
    rescue Lti::ContextExternalToolErrors => e
      log_proxy_error(tool_proxy, "Failed to create deployment for Tool Proxy ID=#{tool_proxy.global_id}: #{e.message}")
      nil
    rescue => e
      Canvas::Errors.capture_exception(:tii_migration, e, :info)
      log_proxy_error(tool_proxy, "Unexpected error creating deployment for Tool Proxy ID=#{tool_proxy.global_id}: #{e.message}")
      nil
    end

    def tii_tp_migration(tool_proxy, deployment)
      Rails.logger.info("Migrating Tool Proxy ID=#{tool_proxy.global_id} to deployment ID=#{deployment.global_id}")

      migration_endpoint = extract_migration_endpoint(tool_proxy)
      unless migration_endpoint
        log_proxy_error(tool_proxy, "Failed to extract migration endpoint from Tool Proxy ID=#{tool_proxy.global_id}")
        return
      end

      if call_tii_migration_endpoint(tool_proxy, deployment, migration_endpoint)
        # Save deployment ID to tool_proxy
        tool_proxy.update!(migrated_to_context_external_tool_id: deployment.id)
        Rails.logger.info("Successfully migrated Tool Proxy ID=#{tool_proxy.global_id} to deployment ID=#{deployment.global_id}")
      end
    end

    def call_tii_migration_endpoint(tool_proxy, deployment, migration_endpoint)
      pns_url = construct_pns_url(deployment)

      # Get issuer and client_id
      issuer = Canvas::Security.config["lti_iss"]
      client_id = deployment.developer_key.global_id.to_s

      # Build request payload
      payload = {
        deployment_id: deployment.deployment_id,
        issuer:,
        client_id:,
        tool_proxy_id: tool_proxy.guid,
        platform_notification_service_url: pns_url
      }

      # Generate JWT for authorization
      jwt = generate_migration_jwt(issuer:, client_id:)

      # Make HTTP POST request to TII migration endpoint with retry logic
      attempts = 0
      max_attempts = 2

      begin
        attempts += 1
        response = make_migration_request(migration_endpoint, payload, jwt)

        unless response.is_a?(Net::HTTPSuccess)
          error_msg = "Migration request failed for Tool Proxy ID=#{tool_proxy.global_id}: HTTP #{response.code} - #{response.body}"
          raise error_msg
        end

        true
      rescue => e
        if attempts < max_attempts
          Rails.logger.warn("Migration failed for Tool Proxy ID=#{tool_proxy.global_id}: #{e.message} - Retrying in 2 seconds (attempt #{attempts}/#{max_attempts})")
          sleep(2)
          retry
        end

        Canvas::Errors.capture_exception(:tii_migration, e)
        error_msg = "Exception during migration for Tool Proxy ID=#{tool_proxy.global_id}: #{e.message}"
        log_proxy_error(tool_proxy, error_msg)
        false
      end
    end

    def extract_migration_endpoint(tool_proxy)
      endpoint = tool_proxy.raw_data.dig("tool_profile", "service_offered")&.first&.dig("endpoint")
      return nil unless endpoint

      # Construct migration endpoint URL from base endpoint
      uri = URI.parse(endpoint)

      # Validate that the endpoint is from turnitin.com or a subdomain
      unless uri.host == "turnitin.com" || uri.host&.end_with?(".turnitin.com")
        Rails.logger.error("Invalid migration endpoint host: #{uri.host}. Must be turnitin.com or a subdomain")
        return nil
      end

      "#{uri.scheme}://#{uri.host}/api/migrate"
    rescue => e
      Canvas::Errors.capture_exception(:tii_migration, e, :info)
      Rails.logger.error("Failed to extract migration endpoint from Tool Proxy: #{e.message}")
      nil
    end

    def construct_pns_url(deployment)
      Rails.application.routes.url_helpers.lti_notice_handlers_url(
        context_external_tool_id: deployment.id,
        host: @account.root_account.environment_specific_domain
      )
    end

    def generate_migration_jwt(issuer:, client_id:)
      message = LtiAdvantage::Messages::JwtMessage.new
      message.iss = issuer
      message.aud = client_id
      message.iat = Time.zone.now.to_i
      message.exp = 5.minutes.from_now.to_i

      # Add TurnItIn-specific scope for migration
      message.extensions["scope"] = "https://turnitin.com/cpf/migrate/deployment"

      message.to_jws(Lti::KeyStorage.present_key)
    end

    def make_migration_request(endpoint, payload, jwt)
      headers = { "Authorization" => "Bearer #{jwt}" }
      CanvasHttp.post(endpoint, headers, content_type: "application/json", body: payload.to_json)
    end

    def initialize_proxy_results(tool_proxy)
      @results[:proxies][tool_proxy.id] ||= {
        errors: [],
        warnings: [],
      }
    end

    def log_proxy_error(tool_proxy, message)
      Rails.logger.error(message)
      @results[:proxies][tool_proxy.id][:errors] << message
    end

    def get_proxy_result(tool_proxy, key)
      @results[:proxies][tool_proxy.id][key]
    end

    def set_proxy_result(tool_proxy, key, value)
      @results[:proxies][tool_proxy.id][key] = value
    end

    def proxy_errors(tool_proxy)
      get_proxy_result(tool_proxy, :errors)
    end

    def log_proxy_warning(tool_proxy, message)
      Rails.logger.warn(message)
      @results[:proxies][tool_proxy.id][:warnings] << message
    end

    def create_asset_processor_from_actl(actl, tool_proxy)
      return unless tool_proxy.migrated_to_context_external_tool.present?

      migration_id = "cpf_#{tool_proxy.guid}_#{actl.assignment.global_id}"
      existing_ap = Lti::AssetProcessor.active.where(assignment: actl.assignment, migration_id:).first
      if existing_ap.present?
        Rails.logger.warn("Asset Processor already exists for ACTL ID=#{actl.id} and migration_id=#{migration_id}, skipping")
        return existing_ap
      end

      proxy_id = tool_proxy.raw_data&.dig("custom", "proxy_instance_id")
      unless proxy_id.present?
        log_proxy_warning(tool_proxy, "No proxy_instance_id found in Tool Proxy ID=#{tool_proxy.global_id}")
      end

      ap = Lti::AssetProcessor.new(
        custom: {
          proxy_instance_id: proxy_id,
          migrated_from_cpf: "true"
        }.compact,
        assignment: actl.assignment,
        context_external_tool: tool_proxy.migrated_to_context_external_tool,
        migration_id:
      )
      ap.save!
      Rails.logger.info("Created Asset Processor ID=#{ap.id} for ACTL ID=#{actl.id}")
      ap
    rescue => e
      Canvas::Errors.capture_exception(:tii_migration, e)
      log_proxy_error(tool_proxy, "Failed to create Asset Processor for ACTL ID=#{actl.id}: #{e.message}")
      nil
    end

    def create_migration_report
      # TODO: create report csv
    end

    def send_migration_report_email
      # TODO: Send email with migration results
    end

    def prevalidations_successful?
      unless tii_developer_key
        Rails.logger.error("LTI 1.3 Developer key for Turnitin Asset Processor not found")
        @results[:fatal_error] = "LTI 1.3 Developer key not found"
        return false
      end
      true
    end

    def migrate_reports(_actl, _tool_proxy, _ap)
      # TODO: implement in later commit
    end
  end
end
