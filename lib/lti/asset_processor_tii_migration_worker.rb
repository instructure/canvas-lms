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
    def initialize(account, email = nil)
      @account = account
      @email = email
      @results = {}
    end

    def perform(progress)
      @progress = progress
      tps = tool_proxies
      @progress.calculate_completion!(0, tps.size)

      tps.each do |tool_proxy|
        Rails.logger.info("Migrating Turnitin Tool Proxy ID=#{tool_proxy.global_id}")
        initialize_results(tool_proxy)
        migrate_tool_proxy(tool_proxy)
        next unless @results[tool_proxy.id][:errors].empty?

        # migrate Assignments
        # migrate reports
        @progress.increment_completion!(1)
      end
    end

    private

    # Fetch all active Turnitin tool proxies in the account (either course level or account level, but not in the sub-tree)
    def tool_proxies
      account_level_tps = Lti::ToolProxy
                          .active
                          .joins(:bindings)
                          .joins("INNER JOIN #{Lti::ProductFamily.quoted_table_name} ON lti_product_families.id = lti_tool_proxies.product_family_id")
                          .joins("INNER JOIN #{Account.quoted_table_name} ON lti_tool_proxy_bindings.context_type = 'Account' AND lti_tool_proxy_bindings.context_id = accounts.id")
                          .where(lti_tool_proxy_bindings: { enabled: true })
                          .where(lti_product_families: { vendor_code: "turnitin.com", product_code: "turnitin-lti" })
                          .where(accounts: { id: @account.id })

      course_level_tps = Lti::ToolProxy
                         .active
                         .joins(:bindings)
                         .joins("INNER JOIN #{Lti::ProductFamily.quoted_table_name} ON lti_product_families.id = lti_tool_proxies.product_family_id")
                         .joins("INNER JOIN #{Course.quoted_table_name} ON lti_tool_proxy_bindings.context_type = 'Course' AND lti_tool_proxy_bindings.context_id = courses.id")
                         .where(lti_tool_proxy_bindings: { enabled: true })
                         .where(lti_product_families: { vendor_code: "turnitin.com", product_code: "turnitin-lti" })
                         .where(courses: { account_id: @account.id })

      account_level_tps.to_a + course_level_tps.to_a
    end

    def migrate_tool_proxy(tool_proxy)
      if tool_proxy.migrated_to_context_external_tool.present?
        @results[tool_proxy.id][:warnings] << "Tool Proxy ID=#{tool_proxy.id} has already been migrated to CET ID=#{tool_proxy.migrated_to_context_external_tool.id}, skipping."
        return
      end

      # Find LTI 1.3 deployments with ActivityAssetProcessor placement and Turnitin developer key
      deployments = find_tii_asset_processor_deployments(tool_proxy.context)
      context_matching_deployments = deployments.select { |deployment| deployment.context == tool_proxy.context }

      if deployments.length > 1
        @results[tool_proxy.id][:errors] << "Multiple TII AP deployments found in context. #{deployments.map(&:id).join(", ")}"
        return
      end

      if context_matching_deployments.empty?
        if deployments.any?
          @results[tool_proxy.id][:errors] << "Found #{deployments.map { |d| "CET ID=#{d.id}" }.join(", ")}} TII AP deployments in context of Tool Proxy ID=#{tool_proxy.global_id}, but none match the context. Skipping migration."
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
      return [] unless tii_developer_key

      Lti::ContextToolFinder.all_tools_for(
        context,
        placements: [:ActivityAssetProcessor]
      ).select { |tool| tool.developer_key_id == tii_developer_key.id }
    end

    def create_tii_deployment(tool_proxy)
      unless tii_developer_key
        Rails.logger.error("turnitin_asset_processor_client_id setting is not configured or developer key not found")
        @results[tool_proxy.id][:errors] << "Developer key not found"
        return nil
      end

      # Create deployment (ContextExternalTool) in the same context as the tool_proxy
      deployment = tii_developer_key.lti_registration.new_external_tool(
        tool_proxy.context,
        verify_uniqueness: true,
        current_user: @progress.user
      )
      Rails.logger.info("Created TII Asset Processor deployment ID=#{deployment.global_id} for Tool Proxy ID=#{tool_proxy.global_id}")
      deployment
    rescue Lti::ContextExternalToolErrors => e
      Rails.logger.error("Failed to create deployment for Tool Proxy ID=#{tool_proxy.global_id}: #{e.message}")
      @results[tool_proxy.id][:errors] << "Failed to create deployment: #{e.message}"
      nil
    rescue => e
      Canvas::Errors.capture_exception(:tii_migration, e, :info)
      Rails.logger.error("Unexpected error creating deployment for Tool Proxy ID=#{tool_proxy.global_id}: #{e.message}")
      @results[tool_proxy.id][:errors] << "Unexpected error creating deployment: #{e.message}"
      nil
    end

    def tii_tp_migration(tool_proxy, deployment)
      Rails.logger.info("Migrating Tool Proxy ID=#{tool_proxy.global_id} to deployment ID=#{deployment.global_id}")

      migration_endpoint = extract_migration_endpoint(tool_proxy)
      unless migration_endpoint
        @results[tool_proxy.id][:errors] << "Failed to extract migration endpoint from Tool Proxy ID=#{tool_proxy.global_id}"
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
        Rails.logger.error(error_msg)
        @results[tool_proxy.id][:errors] << error_msg
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

    def initialize_results(tool_proxy)
      @results[tool_proxy.id] = { errors: [], warnings: [] }
    end
  end
end
