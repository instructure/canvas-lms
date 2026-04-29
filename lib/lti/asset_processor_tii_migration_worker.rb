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
    TII_TOOL_VENDOR_CODE = Rails.env.development? ? "Instructure.com" : "turnitin.com"
    TII_TOOL_PRODUCT_CODE = Rails.env.development? ? "similarity detection reference tool" : "turnitin-lti"
    MIGRATED_ASSET_REPORT_TYPE = "originality_report"
    TRUSTED_MIGRATION_DOMAINS = %w[turnitin.com turnitin.dev turnitin.net turnitin.org turnitinuk.com].freeze
    PROGRESS_UPDATE_BATCH_SIZE = 50
    PROGRESS_UPDATE_THRESHOLD = 1000
    PROGRESS_TAG = "lti_tii_ap_migration"
    COORDINATOR_TAG = "lti_tii_ap_migration_coordinator"

    def initialize(account, email = nil, coordinator_id = nil)
      @account = account
      @email = email
      @coordinator_id = coordinator_id
      @results = { proxies: {}, coordinator_id: @coordinator_id }
      @migrated_tool_proxies = []
    end

    def perform(progress)
      @progress = progress
      if prevalidations_successful?
        @progress.calculate_completion!(0, actls_for_account_count)
        generate_migration_report do |csv|
          migrate_actls(csv)
          migrate_orphan_proxies(csv)
        end
      end
      save_migration_report

      # Clean up subscriptions for migrated tool proxies
      # Can be rolled back with tool_proxy.manage_subscription
      @migrated_tool_proxies.each do |tp|
        tp.delete_subscription
      rescue => e
        capture_and_log_exception(e)
        add_proxy_error(tp, "Unexpected error deleting subscriptions of ToolProxy ID=#{tp.id}")
      end

      @progress.set_results(@results.except(:actl_errors, :actl_warnings)) # actl_errors can be large, exclude from progress results

      if @coordinator_id.present?
        check_and_send_consolidated_email
      else
        send_migration_report_email
      end

      if any_error_occurred?
        Rails.logger.info("TII Asset Processor migration completed with errors")
        @progress.fail!
        on_migration_failed
      else
        Rails.logger.info("TII Asset Processor migration completed successfully")
        @progress.complete!
      end
    end

    # This method is only called from rails console, manually
    def rollback(recursive: false)
      Rails.logger.info("#{"Recursive " if recursive}Rolling back Asset Processor migration in this account=#{@account.global_id}")
      actls_for_account.find_each do |actl|
        tool_proxy = actl.associated_tool_proxy
        next unless tool_proxy.present?
        next unless tool_proxy.migrated_to_context_external_tool.present?
        next unless proxy_in_account?(tool_proxy, @account) || recursive

        resubscribe_tool_proxy(tool_proxy)

        migration_id = generate_migration_id(tool_proxy, actl)
        aps = Lti::AssetProcessor.active.where(assignment: actl.assignment, migration_id:)
        aps.find_each do |ap|
          Rails.logger.info("Rolling back Asset Processor ID=#{ap.id} for ACTL ID=#{actl.id} and tool_proxy ID=#{tool_proxy.id}")
          ap.destroy
        end
      rescue => e
        capture_and_log_exception(e)
        Rails.logger.error("Failed to rollback migration for ACTL ID=#{actl.id}: #{e.message}")
      end

      account_ids = recursive ? sub_account_ids : [@account.id]
      rollback_orphan_proxies(account_ids)

      @migrated_tool_proxies.each do |tp|
        Rails.logger.info("Set migrated_to_context_external_tool to nil from #{tp.migrated_to_context_external_tool_id} for TP #{tp.id}")
        tp.update!(migrated_to_context_external_tool_id: nil)
      end
    end

    # This method is only called from rails console, manually
    def rollback_recursive
      rollback(recursive: true)
    end

    # This method is only called from rails console, manually
    def rollback_progress
      Progress.where(tag: "lti_tii_ap_migration", context: @account).update_all(tag: "lti_tii_ap_migration_rolled_back")
      Progress.where(tag: "lti_tii_ap_migration_coordinator", context: @account).update_all(tag: "lti_tii_ap_migration_coordinator_rolled_back")
    end

    # This method is only called from rails console, manually
    def rollback_progress_recursive
      ids = sub_account_ids
      Progress.where(tag: "lti_tii_ap_migration", context_type: "Account", context_id: ids).update_all(tag: "lti_tii_ap_migration_rolled_back")
      Progress.where(tag: "lti_tii_ap_migration_coordinator", context_type: "Account", context_id: ids).update_all(tag: "lti_tii_ap_migration_coordinator_rolled_back")
    end

    private

    def rollback_orphan_proxies(account_ids)
      Rails.logger.info("Rolling back orphan tool proxies for account=#{@account.global_id}")
      migrated_orphan_proxies(account_ids).find_each do |tool_proxy|
        resubscribe_tool_proxy(tool_proxy)
      rescue => e
        capture_and_log_exception(e)
        Rails.logger.error("Failed to rollback orphan tool proxy ID=#{tool_proxy.id}: #{e.message}")
      end
    end

    def resubscribe_tool_proxy(tool_proxy)
      return if @migrated_tool_proxies.include?(tool_proxy)

      @migrated_tool_proxies << tool_proxy
      Rails.logger.info("Resubscribe tool_proxy #{tool_proxy.id}")
      tool_proxy.manage_subscription
    end

    def migrated_orphan_proxies(account_ids)
      tii_tool_proxies_base_query(account_ids).where.not(lti_tool_proxies: { migrated_to_context_external_tool_id: nil })
    end

    def migrate_actls(csv)
      batch_size = (actls_for_account_count > PROGRESS_UPDATE_THRESHOLD) ? PROGRESS_UPDATE_BATCH_SIZE : 1
      pending_completion = 0
      tool_proxy_cache = {}

      actls_for_account.find_in_batches do |batch|
        ActiveRecord::Associations::Preloader.new(records: batch, associations: { assignment: { context: :account } }).call
        batch.each do |actl|
          subaccount_toolproxy = false
          ap_migration_status = :failed
          report_migration_status = :failed
          cache_key = tool_proxy_cache_key(actl)
          tool_proxy = tool_proxy_cache.fetch(cache_key) { tool_proxy_cache[cache_key] = actl.associated_tool_proxy }
          # only migrate if tool proxy is installed on this account/course (not for sub-accounts)
          unless tool_proxy.present? && proxy_in_account?(tool_proxy, @account)
            subaccount_toolproxy = true
            next
          end
          initialize_proxy_results(tool_proxy)

          next if get_proxy_result(tool_proxy, :cet_creation_failed) # We could not create the CET for this TP earlier

          unless tool_proxy.migrated_to_context_external_tool.present?
            migrate_tool_proxy(tool_proxy)
            unless proxy_errors(tool_proxy).empty? && tool_proxy.reload.migrated_to_context_external_tool.present?
              set_proxy_result(tool_proxy, :cet_creation_failed, true)
              add_proxy_error(tool_proxy, "Tool creation failed for Tool Proxy ID=#{tool_proxy.global_id}")
              next
            end
            @migrated_tool_proxies << tool_proxy
          end

          ap_migration_status, ap = create_asset_processor_from_actl(actl, tool_proxy)

          unless ap_migration_status == :failed
            report_migration_status, reports_count = migrate_reports(actl, ap)
          end
        rescue => e
          capture_and_log_exception(e)
          add_actl_error(actl, "Unexpected error migrating ACTL ID=#{actl.id}")
        ensure
          pending_completion += 1
          if pending_completion >= batch_size
            @progress.increment_completion!(pending_completion)
            pending_completion = 0
          end
          unless subaccount_toolproxy
            assignment = actl.assignment
            csv << [
              assignment.context.account.id,
              assignment.context.account.name,
              assignment.id,
              assignment.name,
              assignment.context.id,
              tool_proxy&.id,
              ap&.context_external_tool_id || "",
              ap_migration_status.to_s,
              report_migration_status.to_s,
              reports_count || 0,
              report_error_message(tool_proxy, actl).join(", "),
              report_warning_message(tool_proxy, actl).join(", ")
            ]
          end
        end
      end
      @progress.increment_completion!(pending_completion) if pending_completion > 0
    end

    def migrate_orphan_proxies(csv)
      tii_orphan_proxies.find_each do |tool_proxy|
        next if @migrated_tool_proxies.include?(tool_proxy)
        next if @results[:proxies][tool_proxy.id]

        initialize_proxy_results(tool_proxy)
        add_proxy_warning(tool_proxy, "This tool proxy was not associated with any assignment")

        migrate_tool_proxy(tool_proxy)

        if proxy_errors(tool_proxy).empty? && tool_proxy.reload.migrated_to_context_external_tool.present?
          @migrated_tool_proxies << tool_proxy
        end
      rescue => e
        capture_and_log_exception(e)
        add_proxy_error(tool_proxy, "Unexpected error migrating orphan Tool Proxy ID=#{tool_proxy.id}")
      ensure
        next unless @results[:proxies][tool_proxy.id]

        if tool_proxy.context_type == "Course"
          proxy_account = tool_proxy.context.account
          course_id = tool_proxy.context_id
        else
          proxy_account = tool_proxy.context
          course_id = ""
        end

        csv << [
          proxy_account.id,
          proxy_account.name,
          "",
          "",
          course_id,
          tool_proxy.id,
          tool_proxy.migrated_to_context_external_tool_id || "",
          "",
          "",
          0,
          report_error_message(tool_proxy, nil).join(", "),
          report_warning_message(tool_proxy, nil).join(", ")
        ]
      end
    end

    def report_error_message(tool_proxy, actl)
      messages = []
      if tool_proxy.present?
        messages += proxy_errors(tool_proxy)
      else
        return ["Missing tool proxy"]
      end
      if actl.present? && @results[:actl_errors].present? && @results[:actl_errors][actl.id].present?
        messages += @results[:actl_errors][actl.id]
      end
      messages
    end

    def report_warning_message(tool_proxy, actl)
      messages = []
      if tool_proxy.present?
        messages += get_proxy_result(tool_proxy, :warnings) || []
      end
      if actl.present? && @results[:actl_warnings].present? && @results[:actl_warnings][actl.id].present?
        messages += @results[:actl_warnings][actl.id]
      end
      messages
    end

    def course_level_tii_proxies?
      return @course_level_tii_proxies if defined?(@course_level_tii_proxies)

      @course_level_tii_proxies = tii_tool_proxies_base_query([@account.id])
                                  .where(lti_tool_proxies: { context_type: "Course" })
                                  .exists?
    end

    def tool_proxy_cache_key(actl)
      context_id = course_level_tii_proxies? ? actl.assignment.context_id : actl.assignment.context.account_id
      [context_id, actl.tool_resource_type_code]
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
          tool_vendor_code: TII_TOOL_VENDOR_CODE,
          tool_product_code: TII_TOOL_PRODUCT_CODE,
          tool_type: "Lti::MessageHandler"
        )
        .joins(:assignment)
        .joins(assignment: :course)
        .where(courses: { account_id: sub_account_ids })
        .where.not(assignments: { workflow_state: "deleted" })
        .where.not(courses: { workflow_state: "deleted" })
    end

    def actls_for_account_count
      @actls_for_account_count ||= actls_for_account.count
    end

    def tii_orphan_proxies(account_ids = [@account.id])
      tii_tool_proxies_base_query(account_ids).where(lti_tool_proxies: { migrated_to_context_external_tool_id: nil })
    end

    def tii_tool_proxies_base_query(account_ids)
      Lti::ToolProxy
        .joins(:product_family)
        .joins("LEFT JOIN #{Course.quoted_table_name} ON courses.id = lti_tool_proxies.context_id AND lti_tool_proxies.context_type = 'Course'")
        .where(
          lti_product_families: {
            vendor_code: TII_TOOL_VENDOR_CODE,
            product_code: TII_TOOL_PRODUCT_CODE
          }
        )
        .where(lti_tool_proxies: { workflow_state: "active" })
        .where(
          "(lti_tool_proxies.context_type = 'Account' AND lti_tool_proxies.context_id IN (:account_ids)) OR " \
          "(lti_tool_proxies.context_type = 'Course' AND courses.account_id IN (:account_ids) AND courses.workflow_state <> 'deleted')",
          account_ids:
        )
    end

    def migrate_tool_proxy(tool_proxy)
      # Find LTI 1.3 deployments with ActivityAssetProcessor placement and Turnitin developer key
      deployments = find_tii_asset_processor_deployments(tool_proxy.context)
      context_matching_deployments = deployments.select { |deployment| deployment.context == tool_proxy.context }

      if context_matching_deployments.length > 1
        add_proxy_error(tool_proxy, "Multiple TII AP deployments found in context. #{deployments.map(&:id).join(", ")}")
        return
      end

      if context_matching_deployments.empty?
        # Every TP must have a deployment in the exact same context, because there are TPs where contexts are overlapping (there's one in the root account and one in the subaccount)
        # this is a TII requirement
        if deployments.any?
          Rails.logger.info("No TII AP deployment found in the same context for Tool Proxy ID=#{tool_proxy.global_id}, there's one above, but we strictly creating one in the same context")
        end
        Rails.logger.info("No TII AP deployment found for Tool Proxy ID=#{tool_proxy.global_id}, creating one")
        deployment = create_tii_deployment(tool_proxy)
        return unless deployment

        context_matching_deployments = [deployment]
      else
        Rails.logger.info("Found 1 TII AP deployment for Tool Proxy ID=#{tool_proxy.global_id}, migrating")
      end

      tii_tp_migration(tool_proxy, context_matching_deployments.first)
    rescue => e
      capture_and_log_exception(e)
      add_proxy_error(tool_proxy, "Unexpected error when migrating Tool Proxy ID=#{tool_proxy.global_id}: #{e.message}")
    end

    def tii_developer_key
      return @tii_developer_key if defined?(@tii_developer_key)

      dk_id = @account.root_account.turnitin_asset_processor_client_id
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
        current_user: @progress.user
      )
      Rails.logger.info("Created TII Asset Processor deployment ID=#{deployment.global_id} for Tool Proxy ID=#{tool_proxy.global_id}")
      deployment
    rescue Lti::ContextExternalToolErrors => e
      add_proxy_error(tool_proxy, "Failed to create deployment for Tool Proxy ID=#{tool_proxy.global_id}: #{e.message}")
      nil
    rescue => e
      capture_and_log_exception(e)
      add_proxy_error(tool_proxy, "Unexpected error creating deployment for Tool Proxy ID=#{tool_proxy.global_id}: #{e.message}")
      nil
    end

    def tii_tp_migration(tool_proxy, deployment)
      Rails.logger.info("Migrating Tool Proxy ID=#{tool_proxy.global_id} to deployment ID=#{deployment.global_id}")

      migration_endpoint = extract_migration_endpoint(tool_proxy)
      unless migration_endpoint || Rails.env.development?
        add_proxy_error(tool_proxy, "Failed to extract migration endpoint from Tool Proxy ID=#{tool_proxy.global_id}")
        return
      end

      if Rails.env.development? || call_tii_migration_endpoint(tool_proxy, deployment, migration_endpoint)
        # Save deployment ID to tool_proxy
        tool_proxy.update_column(:migrated_to_context_external_tool_id, deployment.id)
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

        capture_and_log_exception(e)
        error_msg = "Exception during migration for Tool Proxy ID=#{tool_proxy.global_id}: #{e.message}"
        add_proxy_error(tool_proxy, error_msg)
        false
      end
    end

    def extract_migration_endpoint(tool_proxy)
      endpoint = tool_proxy.raw_data.dig("tool_profile", "service_offered")&.first&.dig("endpoint")
      return nil unless endpoint

      # Construct migration endpoint URL from base endpoint
      uri = URI.parse(endpoint)

      unless trusted_migration_host?(uri.host)
        Rails.logger.error("Invalid migration endpoint host: #{uri.host}. Must be a trusted Turnitin domain")
        return nil
      end

      "#{uri.scheme}://#{uri.host}/api/migrate"
    rescue => e
      capture_and_log_exception(e)
      Rails.logger.error("Failed to extract migration endpoint from Tool Proxy: #{e.message}")
      nil
    end

    def trusted_migration_host?(host)
      return false if host.blank?

      extra = Setting.get("asset_processor_tii_migration_extra_domains", "").split(",").map(&:strip).reject(&:empty?)
      domains = TRUSTED_MIGRATION_DOMAINS + extra
      domains.any? { |domain| host == domain || host.end_with?(".#{domain}") }
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

    def add_proxy_error(tool_proxy, message)
      Rails.logger.error(message)
      @results[:proxies][tool_proxy.id][:errors] << message
    end

    def add_proxy_warning(tool_proxy, message)
      Rails.logger.warn(message)
      unless @results[:proxies][tool_proxy.id][:warnings].include?(message)
        @results[:proxies][tool_proxy.id][:warnings] << message
      end
    end

    def add_actl_error(actl, message)
      @results[:actl_errors] ||= {}
      @results[:actl_errors][actl.id] ||= []
      unless @results[:actl_errors][actl.id].include?(message)
        @results[:actl_errors][actl.id] << message
      end
    end

    def add_actl_warning(actl, message)
      @results[:actl_warnings] ||= {}
      @results[:actl_warnings][actl.id] ||= []
      unless @results[:actl_warnings][actl.id].include?(message)
        @results[:actl_warnings][actl.id] << message
      end
    end

    def get_proxy_result(tool_proxy, key)
      @results[:proxies][tool_proxy.id][key]
    end

    def set_proxy_result(tool_proxy, key, value)
      @results[:proxies][tool_proxy.id][key] = value
    end

    def proxy_errors(tool_proxy)
      get_proxy_result(tool_proxy, :errors) || []
    end

    def capture_and_log_exception(exception)
      error_info = Canvas::Errors.capture_exception(:tii_migration, exception)
      if error_info.is_a?(Hash) && error_info[:error_report].present?
        error_report_id = error_info[:error_report]
        @results[:error_report_ids] ||= []
        @results[:error_report_ids] << error_report_id
        Rails.logger.error("Captured exception with error report ID: #{error_report_id}")
      end
      error_info
    end

    def create_asset_processor_from_actl(actl, tool_proxy)
      unless tool_proxy.migrated_to_context_external_tool.present?
        add_actl_error(actl, "Cannot create Asset Processor for ACTL ID=#{actl.id} as Tool Proxy ID=#{tool_proxy.global_id} has not been migrated to LTI 1.3")
        return [:failed, nil]
      end

      migration_id = generate_migration_id(tool_proxy, actl)
      existing_ap = Lti::AssetProcessor.active.where(assignment: actl.assignment, migration_id:).first
      if existing_ap.present?
        Rails.logger.warn("Asset Processor already exists for ACTL ID=#{actl.id} and migration_id=#{migration_id}, skipping")
        return [:existing, existing_ap]
      end

      proxy_id = tool_proxy.raw_data&.dig("custom", "proxy_instance_id")
      unless proxy_id.present?
        add_proxy_warning(tool_proxy, "No proxy_instance_id found in Tool Proxy ID=#{tool_proxy.global_id}")
      end

      ap = Lti::AssetProcessor.new(
        custom: {
          proxy_instance_id: proxy_id,
          migrated_from_cpf: "true",
          tii_app_key: "cpf-migrated"
        }.compact,
        assignment: actl.assignment,
        context_external_tool: tool_proxy.migrated_to_context_external_tool,
        migration_id:
      )
      ap.save!
      Rails.logger.info("Created Asset Processor ID=#{ap.id} for ACTL ID=#{actl.id}")
      [:created, ap]
    rescue => e
      capture_and_log_exception(e)
      add_actl_error(actl, "Failed to create Asset Processor for ACTL ID=#{actl.id}: #{e.message}")
      [:failed, nil]
    end

    def generate_migration_report
      @csv_content = CSV.generate do |csv|
        csv << [
          "Account ID",
          "Account Name",
          "Assignment ID",
          "Assignment Name",
          "Course ID",
          "Tool Proxy ID",
          "Lti 1.3 Tool ID",
          "Asset Processor Migration",
          "Asset Report Migration",
          "Number of Reports Migrated",
          "Error Message",
          "Warnings"
        ]
        yield csv
      end
    end

    def save_migration_report
      return unless @csv_content

      save_report(@csv_content)
    end

    def save_report(csv)
      attachment = Attachment.new(
        context: @account,
        filename: "tii_ap_migration_report_#{@progress.id}.csv",
        content_type: "text/csv"
      )
      Attachments::Storage.store_for_attachment(attachment, StringIO.new(csv))
      attachment.save!
      @results[:migration_report_attachment_id] = attachment.id
      @results[:migration_report_url] = report_download_url(attachment.id, @account)
    end

    def send_migration_report_email
      return if @email.blank?

      download_url = @results[:migration_report_url]
      return unless download_url # Don't send email if report wasn't created

      m = Message.new
      m.to = @email
      m.from = HostUrl.outgoing_email_address
      m.subject = I18n.t(:asset_processor_migration_report_subject, "Turnitin Asset Processor Migration Report")
      m.body = any_error_occurred? ? failure_email_body(download_url) : success_email_body(download_url)

      Mailer.deliver(Mailer.create_message(m))
      Rails.logger.info("Sent migration report email to #{@email}")
    rescue => e
      capture_and_log_exception(e)
      Rails.logger.error("Failed to send migration report email: #{e.message}")
      @results[:email_error] = true
    end

    def check_and_send_consolidated_email
      coordinator = Progress.find_by(id: @coordinator_id)
      if coordinator.nil?
        Rails.logger.warn("Unable to find coordinator by id: #{@coordinator_id}")
        return
      end

      Progress.transaction do
        coordinator.lock!

        return if coordinator.results&.dig(:report_created)

        all_migrations = Progress
                         .where(tag: PROGRESS_TAG)
                         .to_a
                         .select { |p| p.results&.dig(:coordinator_id) == @coordinator_id }

        return if all_migrations.empty?

        # Check if all migrations have finished their work (report generated)
        # Note: workflow_state won't be "completed" yet since that happens AFTER this check
        all_complete = all_migrations.all? do |p|
          !p.pending? || p.results&.dig(:migration_report_attachment_id).present?
        end
        return unless all_complete

        report_url = send_consolidated_report_email(all_migrations, coordinator)

        results = coordinator.results || {}
        results[:report_created] = true
        results[:consolidated_report_url] = report_url
        coordinator.set_results(results)
        coordinator.complete!
      end
    rescue => e
      capture_and_log_exception(e)
      Rails.logger.error("Failed to check and send consolidated email: #{e.message}")
    end

    def send_consolidated_report_email(all_migrations, coordinator)
      root_account = @account.root_account
      bulk_migration_id = coordinator.results&.dig(:bulk_migration_id)
      email = coordinator.results&.dig(:email)

      consolidated_csv = generate_consolidated_report(all_migrations)
      download_url = save_consolidated_report(consolidated_csv, root_account, bulk_migration_id)
      return unless download_url
      return download_url unless email.present?

      any_failed = all_migrations.any? { |p| p.workflow_state == "failed" }
      subject = I18n.t(
        :asset_processor_bulk_migration_report_subject,
        "Turnitin Asset Processor Bulk Migration Report"
      )
      body = consolidated_email_body(download_url, all_migrations.size, any_failed)

      m = Message.new
      m.to = email
      m.from = HostUrl.outgoing_email_address
      m.subject = subject
      m.body = body

      Mailer.deliver(Mailer.create_message(m))
      Rails.logger.info("Sent consolidated migration report email to #{email} for #{all_migrations.size} migrations")
      download_url
    rescue => e
      capture_and_log_exception(e)
      Rails.logger.error("Failed to send consolidated migration report email: #{e.message}")
      download_url
    end

    def generate_consolidated_report(all_migrations)
      content = +""
      header_written = false

      all_migrations.sort_by(&:context_id).each do |progress|
        attachment_id = progress.results&.dig(:migration_report_attachment_id)
        next unless attachment_id

        begin
          attachment = Attachment.find(attachment_id)
          report_content = attachment.open.read
          lines = report_content.split("\n")

          unless header_written
            content << lines.first << "\n"
            header_written = true
          end

          lines[1..].each do |line|
            content << line << "\n" if line.present?
          end
        rescue => e
          Rails.logger.error("Failed to read migration report for progress #{progress.id}: #{e.message}")
        end
      end
      content
    end

    def save_consolidated_report(csv_content, root_account, bulk_migration_id)
      attachment = Attachment.new(
        context: root_account,
        filename: "tii_ap_bulk_migration_report_#{bulk_migration_id}.csv",
        content_type: "text/csv"
      )
      Attachments::Storage.store_for_attachment(attachment, StringIO.new(csv_content))
      attachment.save!
      report_download_url(attachment, root_account)
    rescue => e
      capture_and_log_exception(e)
      Rails.logger.error("Failed to save consolidated migration report: #{e.message}")
      nil
    end

    def consolidated_email_body(download_url, migration_count, any_failed)
      if any_failed
        I18n.t(
          :asset_processor_bulk_migration_partial_success_email_body,
          "The bulk Turnitin migration from LTI 2.0 to LTI 1.3 Asset Processor has completed with some failures.\n\n" \
          "Migrated %{count} account(s). Some migrations failed - please review the report for details.\n\n" \
          "Click here to download the consolidated report: %{url}",
          count: migration_count,
          url: download_url
        )
      else
        I18n.t(
          :asset_processor_bulk_migration_success_email_body,
          "The bulk Turnitin migration from LTI 2.0 to LTI 1.3 Asset Processor has completed successfully.\n\n" \
          "Migrated %{count} account(s).\n\n" \
          "Click here to download the consolidated report: %{url}",
          count: migration_count,
          url: download_url
        )
      end
    end

    def report_download_url(attachment_id, account)
      return unless attachment_id

      Rails.application.routes.url_helpers.account_file_download_url(
        account.id,
        attachment_id,
        host: account.environment_specific_domain
      )
    end

    def success_email_body(download_url)
      I18n.t(
        :asset_processor_migration_report_email_body,
        "The Turnitin migration from LTI 2.0 to LTI 1.3 Asset Processor on account %{account} has completed successfully.\n\n" \
        "Click here to download the report: %{url}",
        account: @account.name,
        url: download_url
      )
    end

    def failure_email_body(download_url)
      I18n.t(
        :asset_processor_migration_failure_email_body,
        "The Turnitin migration from LTI 2.0 to LTI 1.3 Asset Processor on account %{account} has completed with errors. " \
        "Click here to download the report: %{url}",
        account: @account.name,
        url: download_url
      )
    end

    def prevalidations_successful?
      unless tii_developer_key
        Rails.logger.error("LTI 1.3 Developer key for Turnitin Asset Processor not found")
        @results[:fatal_error] = "LTI 1.3 Developer key not found"
        return false
      end
      true
    end

    def migrate_reports(actl, asset_processor)
      raise "Asset Processor is not created" unless asset_processor

      # Get the most recent originality report for each submission/group/attachment combination
      reports = OriginalityReport.eager_load(:submission, :lti_link)
                                 .where(submissions: { assignment_id: actl.assignment_id })
                                 .order(created_at: :desc)
                                 .group_by { |report| [report.submission.group_id || report.submission_id, report.attachment_id] }
                                 .values
                                 .map(&:first)
      reports_count = reports.count

      # Preload older versions of submissions whis have reports for previous attempts
      stale_submission_ids = reports
                             .reject { |r| r.attachment_id.present? || r.submission.submitted_at == r.submission_time }
                             .map(&:submission_id)
                             .uniq
      @version_attempt_cache = build_version_attempt_cache(stale_submission_ids)

      report_keys = reports.index_with { |r| asset_cache_key(r) }
      asset_cache = batch_find_or_create_assets(report_keys)
      successful_migrated_count = batch_migrate_asset_reports(actl, report_keys, asset_processor, asset_cache)

      status = if successful_migrated_count == 0 && reports_count.positive?
                 :failed
               elsif successful_migrated_count == reports_count
                 :success
               else
                 :partially_failed
               end

      [status, successful_migrated_count]
    rescue => e
      capture_and_log_exception(e)
      add_actl_error(actl, "Failed to migrate reports for ACTL ID=#{actl.id}: #{e.message}")
      [:failed, 0]
    end

    # Loads existing Lti::Assets for the given reports' submissions in one query,
    # inserts missing ones in bulk, and returns a cache keyed by asset locator.
    def batch_find_or_create_assets(report_keys)
      submission_ids = report_keys.keys.map(&:submission_id).uniq
      existing = Lti::Asset.where(submission_id: submission_ids).to_a

      cache = existing.index_by { |asset| key_for_asset(asset) }.reject { |key, _asset| key.nil? }

      # Determine which reports are missing an asset
      missing = report_keys.reject { |_cpf_report, key| key.nil? || cache[key] }

      if missing.any?
        now = Time.zone.now
        inserts = missing.to_h do |cpf_report, key|
          attachment_id = cpf_report.attachment_id.presence
          submission_attempt = attachment_id ? nil : key[2]
          record = {
            uuid: SecureRandom.uuid,
            submission_id: cpf_report.submission_id,
            root_account_id: cpf_report.submission.root_account_id,
            workflow_state: "active",
            created_at: now,
            updated_at: now,
            # Both keys must be present in every record so insert_all
            # sees a uniform column set across attachment and text-entry rows.
            attachment_id:,
            submission_attempt:
          }
          [key, record]
        end

        Lti::Asset.insert_all(inserts.values)

        new_assets = Lti::Asset.where(uuid: inserts.values.pluck(:uuid)).index_by(&:uuid)
        inserts.each do |key, record|
          asset = new_assets[record[:uuid]]
          cache[key] = asset if asset
        end
      end

      cache
    end

    def asset_cache_key(cpf_report)
      if cpf_report.attachment_id.present?
        [:attachment, cpf_report.submission_id, cpf_report.attachment_id]
      else
        attempt = find_attempt_for_report(cpf_report)
        return nil unless attempt

        [:attempt, cpf_report.submission_id, attempt]
      end
    end

    def key_for_asset(asset)
      if asset.attachment_id.present?
        [:attachment, asset.submission_id, asset.attachment_id]
      elsif asset.submission_attempt.present?
        [:attempt, asset.submission_id, asset.submission_attempt]
      end
    end

    # Batch-deletes stale AssetReports and inserts new ones for all cpf_reports,
    # returning the count of successfully migrated reports.
    def batch_migrate_asset_reports(actl, report_keys, asset_processor, asset_cache)
      visible_to_owner = actl.assignment.turnitin_settings&.dig(:s_view_report) == "1"
      now = Time.zone.now

      asset_ids = asset_cache.values.map(&:id).uniq
      existing_by_asset_id = asset_processor.asset_reports
                                            .where(lti_asset_id: asset_ids, report_type: MIGRATED_ASSET_REPORT_TYPE)
                                            .index_by(&:lti_asset_id)

      to_delete_ids = []
      to_insert = []
      successful_count = 0

      report_keys.each do |cpf_report, key|
        asset = key && asset_cache[key]
        unless asset
          add_actl_error(actl, "Cannot find Lti::Asset for CPF report ID=#{cpf_report.id}")
          next
        end

        if asset.deleted?
          add_actl_warning(actl, "Lti::Asset for CPF report ID=#{cpf_report.id} is soft-deleted; skipping")
          next
        end

        timestamp = cpf_report.updated_at
        existing = existing_by_asset_id[asset.id]

        if existing
          if existing.timestamp > timestamp
            # Existing report is newer; leave it in place and count as success
            successful_count += 1
            next
          end
          to_delete_ids << existing.id
        end

        indication_color, indication_alt = calc_indications_from_cpf_report(cpf_report)
        custom_sourcedid = extract_custom_sourcedid(cpf_report)
        unless custom_sourcedid.present?
          add_actl_warning(actl, "No custom_sourcedid found on report")
        end

        to_insert << {
          lti_asset_id: asset.id,
          lti_asset_processor_id: asset_processor.id,
          report_type: MIGRATED_ASSET_REPORT_TYPE,
          title: "Turnitin Similarity",
          extensions: {
            "https://www.instructure.com/legacy_custom_sourcedid" => custom_sourcedid,
            "migrated_from" => cpf_report.id
          },
          timestamp:,
          result: cpf_report.originality_score.present? ? "#{cpf_report.originality_score}%" : nil,
          priority: priority_from_cpf_report(cpf_report),
          processing_progress: processing_progress_from_cpf_report(cpf_report),
          visible_to_owner:,
          indication_alt:,
          indication_color:,
          workflow_state: "active",
          root_account_id: asset.root_account_id,
          created_at: now,
          updated_at: now
        }
        successful_count += 1
      rescue => e
        capture_and_log_exception(e)
        add_actl_error(actl, "Failed to migrate report ID=#{cpf_report.id}: #{e.message}")
      end

      Lti::AssetReport.transaction do
        Lti::AssetReport.where(id: to_delete_ids).update_all(workflow_state: "deleted", updated_at: now) if to_delete_ids.any?
        Lti::AssetReport.insert_all(to_insert) if to_insert.any?
      end

      successful_count
    end

    def priority_from_cpf_report(cpf_report)
      if cpf_report.workflow_state == "error"
        Lti::AssetReport::PRIORITY_TIME_CRITICAL # 5
      elsif cpf_report.workflow_state == "scored" && cpf_report.originality_score.present?
        if cpf_report.originality_score >= 75
          Lti::AssetReport::PRIORITY_TIME_CRITICAL
        elsif cpf_report.originality_score >= 50
          Lti::AssetReport::PRIORITY_SEMI_TIME_CRITICAL
        elsif cpf_report.originality_score >= 25
          Lti::AssetReport::PRIORITY_NOT_TIME_CRITICAL
        else
          Lti::AssetReport::PRIORITY_GOOD
        end
      else
        Lti::AssetReport::PRIORITY_GOOD
      end
    end

    def processing_progress_from_cpf_report(cpf_report)
      case cpf_report.workflow_state
      when "pending"
        Lti::AssetReport::PROGRESS_PROCESSING
      when "error"
        Lti::AssetReport::PROGRESS_FAILED
      when "scored"
        Lti::AssetReport::PROGRESS_PROCESSED
      else
        Lti::AssetReport::PROGRESS_NOT_READY
      end
    end

    def extract_custom_sourcedid(cpf_report)
      resource_url = cpf_report.lti_link&.resource_url
      return nil unless resource_url

      uri = URI.parse(resource_url)
      params = URI.decode_www_form(uri.query || "").to_h
      params["custom_sourcedid"]
    rescue URI::InvalidURIError
      nil
    end

    def build_version_attempt_cache(submission_ids)
      return {} if submission_ids.empty?

      SimplyVersioned::Version
        .where(versionable_type: "Submission", versionable_id: submission_ids)
        .each_with_object({}) do |v, cache|
          model = v.model
          cache[[v.versionable_id, model.submitted_at]] ||= model.attempt
        end
    end

    def find_attempt_for_report(cpf_report)
      return nil if cpf_report.attachment_id.present?

      submission = cpf_report.submission
      return submission.attempt if submission.submitted_at == cpf_report.submission_time

      if @version_attempt_cache
        @version_attempt_cache[[submission.id, cpf_report.submission_time]]
      else
        submission.versions.find { |v| v.model.submitted_at == cpf_report.submission_time }&.model&.attempt
      end
    end

    def calc_indications_from_cpf_report(cpf_report)
      if cpf_report.originality_score.present?
        case Turnitin.state_from_similarity_score(cpf_report.originality_score)
        when "none"
          ["#00AC18", "No matching content found"]
        when "acceptable"
          ["#00AC18", "Low similarity - acceptable"]
        when "warning"
          ["#FC5E13", "Medium similarity - review recommended"]
        when "problem"
          ["#EE0612", "High similarity - attention needed"]
        when "failure"
          ["#8B1A1A", "Very high similarity - immediate attention required"]
        end
      else
        [nil, nil]
      end
    end

    def any_error_occurred?
      @results[:fatal_error].present? ||
        @results[:proxies].values.any? { |r| r[:errors].any? } ||
        @results[:actl_errors].present?
    end

    def generate_migration_id(tool_proxy, actl)
      "cpf_#{tool_proxy.guid}_#{actl.assignment.global_id}"
    end

    def on_migration_failed
      # overridden in MRA
    end
  end
end
