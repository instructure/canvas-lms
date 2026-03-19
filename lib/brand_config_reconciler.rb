# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

# Periodic job that detects and fixes stale/inconsistent BrandConfig parent references.
# This handles cases where BrandConfigRegenerator jobs fail mid-execution, leaving
# child accounts with brand_config_md5 pointing to configs with stale parent_md5.
class BrandConfigReconciler
  class << self
    # Entry point for periodic job - processes all root accounts on current shard
    def process
      return if Shard.current.default?

      Account.root_accounts.active.non_shadow.find_each do |root_account|
        delay_if_production(
          singleton: "BrandConfigReconciler:#{root_account.global_id}",
          priority: Delayed::LOWER_PRIORITY,
          max_attempts: 1
        ).process_account_async(root_account)
      end
    end

    def process_account_async(root_account)
      root_account.reload
      new(root_account).run
    end

    # Process a specific account tree (for manual invocation via Rails console)
    # @param account [Account] root account to process
    # @param dry_run [Boolean] if true, only detect issues without fixing them
    # @return [Hash] { issues_found: Integer, issues_fixed: Integer, errors: Integer, issues: Array (dry_run only) }
    def process_account(account, dry_run: false)
      new(account, dry_run:).run
    end
  end

  def initialize(root_account, dry_run: false)
    @root_account = root_account
    @dry_run = dry_run
    @fixed = []
    @errors = []
    @detected_issues = []
    @failed_account_ids = Set.new
    @failed_sbc_ids = Set.new
    @chain_cache = {}
    @parent_config_cache = {}
  end

  MAX_ITERATIONS = 5 # Safety guard against infinite loops

  # @return [Hash] { issues_found: Integer, issues_fixed: Integer, errors: Integer, issues: Array (dry_run only) }
  def run
    dry_run_prefix = @dry_run ? "[DRY RUN] " : ""
    total_issues_found = 0
    iteration = 0

    # Iterate until no more issues - needed because fixing a parent account
    # may cause child accounts to become stale (cascading updates)
    loop do
      iteration += 1
      if iteration > MAX_ITERATIONS
        Rails.logger.error("[BrandConfigReconciler] Root account #{@root_account.id}: " \
                           "Max iterations (#{MAX_ITERATIONS}) reached, possible infinite loop")
        break
      end

      issues = detect_all_issues
      break if issues.empty?

      new_issues = issues.reject { |i| already_failed?(i) }
      break if new_issues.empty?

      total_issues_found += new_issues.count
      Rails.logger.info("[BrandConfigReconciler] #{dry_run_prefix}Root account #{@root_account.id} (#{@root_account.name}): " \
                        "Found #{new_issues.count} issues (iteration #{iteration})")

      if @dry_run
        @detected_issues.concat(new_issues)
        break
      end

      reconcile_issues(new_issues)
    end

    if total_issues_found > 0
      if @dry_run
        Rails.logger.info("[BrandConfigReconciler] #{dry_run_prefix}Root account #{@root_account.id}: " \
                          "Would fix #{total_issues_found} issues")
      else
        Rails.logger.info("[BrandConfigReconciler] #{dry_run_prefix}Root account #{@root_account.id}: " \
                          "Fixed #{@fixed.count}/#{total_issues_found} issues, #{@errors.count} errors")
      end
    else
      Rails.logger.info("[BrandConfigReconciler] #{dry_run_prefix}Root account #{@root_account.id} (#{@root_account.name}): " \
                        "Found 0 issues")
    end

    result = { issues_found: total_issues_found, issues_fixed: @fixed.count, errors: @errors.count }
    result[:issues] = @detected_issues if @dry_run
    result
  end

  private

  def detect_all_issues
    GuardRail.activate(:report) do
      [
        detect_account_issues,
        detect_stale_shared_brand_configs
      ].flatten.uniq do |issue|
        [issue[:type], issue[:account]&.id, issue[:shared_brand_config]&.id]
      end
    end
  end

  # Find accounts with stale or orphaned parent references (batch optimized)
  def detect_account_issues
    accounts_with_configs = accounts_with_parent_configs
                            .reject { |a| @failed_account_ids.include?(a.id) }
                            .select { |a| a.brand_config&.parent_md5 }

    return [] if accounts_with_configs.empty?

    parent_md5s = accounts_with_configs.map { |a| a.brand_config.local_parent_md5 }
    existing_md5s = BrandConfig.where(md5: parent_md5s.uniq).pluck(:md5).to_set

    expected_parent_md5s = batch_compute_expected_parent_md5s(accounts_with_configs)

    accounts_with_configs.filter_map do |account|
      local_parent_md5 = account.brand_config.local_parent_md5

      if !existing_md5s.include?(local_parent_md5)
        { type: :orphaned_parent, account: }
      elsif local_parent_md5 != expected_parent_md5s[account.id]
        { type: :stale_parent, account: }
      end
    end
  end

  # Find SharedBrandConfigs with stale parent references
  def detect_stale_shared_brand_configs
    sbcs = SharedBrandConfig
           .joins(:brand_config, :account)
           .where(accounts: { root_account_id: @root_account })
           .where.not(brand_configs: { parent_md5: nil })
           .preload(:brand_config, :account)
           .reject { |sbc| @failed_sbc_ids.include?(sbc.id) }

    return [] if sbcs.empty?

    # Batch compute expected parent md5s for all SBC accounts
    accounts = sbcs.map(&:account).uniq
    expected_parent_md5s = batch_compute_expected_parent_md5s(accounts)

    sbcs.filter_map do |sbc|
      if sbc.brand_config.local_parent_md5 != expected_parent_md5s[sbc.account.id]
        { type: :stale_shared_brand_config, shared_brand_config: sbc, account: sbc.account }
      end
    end
  end

  def accounts_with_parent_configs
    Account.active
           .where(root_account_id: @root_account)
           .where.not(brand_config_md5: nil)
           .joins(:brand_config)
           .where.not(brand_configs: { parent_md5: nil })
           .preload(:brand_config)
  end

  # Process all detected issues, sorted by hierarchy depth (parents first)
  def reconcile_issues(issues)
    account_issues = issues.select { |i| i[:account] && !i[:shared_brand_config] }
    sbc_issues = issues.select { |i| i[:shared_brand_config] }

    account_ids = account_issues.map { |i| i[:account].id }
    batch_load_account_chains(account_ids)

    # Sort by hierarchy depth (fewer ancestors = higher in tree = process first)
    sorted_account_issues = account_issues.sort_by { |i| chain_depth(i[:account]) }

    sorted_account_issues.each { |issue| reconcile_account(issue[:account]) }

    # Process SharedBrandConfigs after their accounts are fixed
    sbc_issues.each { |issue| reconcile_shared_brand_config(issue[:shared_brand_config]) }
  end

  def reconcile_account(account)
    account.reload
    config = account.brand_config
    return unless config

    # Fetch current expected parent (may have changed if parent account was just fixed)
    current_expected_parent = account.first_parent_brand_config
    new_config = config.clone_with_new_parent(current_expected_parent)
    new_config.save_unless_dup!
    new_config.sync_to_s3_and_save_to_account!(nil, account)

    @fixed << {
      type: :account,
      account_id: account.id,
      account_name: account.name,
      old_config_md5: config.md5,
      new_config_md5: new_config.md5
    }

    Rails.logger.info("[BrandConfigReconciler] Fixed account #{account.id} (#{account.name}): " \
                      "#{config.md5} -> #{new_config.md5}")
  rescue => e
    @failed_account_ids << account.id
    handle_error("account", account.id, e)
  end

  def reconcile_shared_brand_config(sbc)
    sbc.reload
    config = sbc.brand_config
    return unless config

    # Fetch current expected parent (may have changed if parent account was just fixed)
    current_expected_parent = sbc.account.first_parent_brand_config
    new_config = config.clone_with_new_parent(current_expected_parent)
    new_config.save_unless_dup!
    new_config.sync_to_s3_and_save_to_shared_brand_config!(nil, sbc)

    @fixed << {
      type: :shared_brand_config,
      sbc_id: sbc.id,
      sbc_name: sbc.name,
      old_config_md5: config.md5,
      new_config_md5: new_config.md5
    }

    Rails.logger.info("[BrandConfigReconciler] Fixed SharedBrandConfig #{sbc.id} (#{sbc.name}): " \
                      "#{config.md5} -> #{new_config.md5}")
  rescue => e
    @failed_sbc_ids << sbc.id
    handle_error("SharedBrandConfig", sbc.id, e)
  end

  def already_failed?(issue)
    return true if issue[:account] && @failed_account_ids.include?(issue[:account].id)
    return true if issue[:shared_brand_config] && @failed_sbc_ids.include?(issue[:shared_brand_config].id)

    false
  end

  def handle_error(entity_type, entity_id, exception)
    Canvas::Errors.capture_exception(:brand_config_reconciler, exception, {
                                       root_account_id: @root_account.id,
                                       entity_type:,
                                       entity_id:
                                     })
    Rails.logger.error("[BrandConfigReconciler] Failed for #{entity_type} #{entity_id}: #{exception.message}")
    @errors << { entity_type:, entity_id:, error: exception.message }
  end

  # Batch load account chains for multiple accounts in a single query.
  # Returns hash: { account_id => [ancestor_ids from parent to root] }
  def batch_load_account_chains(account_ids)
    return {} if account_ids.empty?

    uncached_ids = account_ids.reject { |id| @chain_cache.key?(id) }
    if uncached_ids.any?
      chains = Account.account_chain_ids_for_multiple_accounts(uncached_ids)
      chains.each do |account_id, chain_ids|
        # chain_ids includes self, we want ancestors only (skip first element)
        @chain_cache[account_id] = chain_ids[1..] || []
      end
    end

    account_ids.index_with { |id| @chain_cache[id] || [] }
  end

  # Batch compute expected parent brand config md5 for multiple accounts.
  # Returns hash: { account_id => expected_parent_md5 or nil }
  def batch_compute_expected_parent_md5s(accounts)
    return {} if accounts.empty?

    account_ids = accounts.map(&:id)
    chains = batch_load_account_chains(account_ids)

    all_ancestor_ids = chains.values.flatten.uniq

    ancestors_with_configs = Account.where(id: all_ancestor_ids)
                                    .where.not(brand_config_md5: nil)
                                    .pluck(:id, :brand_config_md5)
                                    .to_h

    # For each account, find the first ancestor in its chain that has a brand config
    accounts.to_h do |account|
      chain_ids = chains[account.id] || []
      first_ancestor_with_config = chain_ids.find { |id| ancestors_with_configs.key?(id) }
      [account.id, ancestors_with_configs[first_ancestor_with_config]]
    end
  end

  # Get chain depth for an account (for sorting by hierarchy)
  def chain_depth(account)
    @chain_cache[account.id]&.length || account.account_chain.length
  end
end
