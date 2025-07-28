# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class RoleOverride < ActiveRecord::Base
  extend RootAccountResolver
  belongs_to :context, polymorphic: [:account]

  belongs_to :role

  validates :enabled, inclusion: [true, false]
  validates :locked, inclusion: [true, false]

  validate :must_apply_to_something

  after_save :clear_caches

  resolves_root_account through: ->(record) { record.context.resolved_root_account_id }
  include Role::AssociationHelper

  def clear_caches
    RoleOverride.clear_caches(account, role)
  end

  def self.clear_caches(account, role)
    account.delay_if_production(singleton: "clear_downstream_role_caches:#{account.global_id}")
           .clear_downstream_caches(:role_overrides)
    role.touch
  end

  def must_apply_to_something
    errors.add(nil, "Must apply to something") unless applies_to_self? || applies_to_descendants?
  end

  def applies_to
    result = []
    result << :self if applies_to_self?
    result << :descendants if applies_to_descendants?
    result.presence
  end

  ACCOUNT_ADMIN_LABEL = -> { t("roles.account_admin", "Account Admin") }
  def self.account_membership_types(account)
    res = [{ id: Role.get_built_in_role("AccountAdmin", root_account_id: account.resolved_root_account_id).id,
             name: "AccountAdmin",
             base_role_name: Role::DEFAULT_ACCOUNT_TYPE,
             label: ACCOUNT_ADMIN_LABEL.call }]
    account.available_custom_account_roles.each do |r|
      res << { id: r.id, name: r.name, base_role_name: Role::DEFAULT_ACCOUNT_TYPE, label: r.name }
    end
    res
  end

  ENROLLMENT_TYPE_LABELS =
    [
      # StudentViewEnrollment permissions will mirror StudentPermissions
      { base_role_name: "StudentEnrollment", name: "StudentEnrollment", label: -> { t("roles.student", "Student") }, plural_label: -> { t("roles.students", "Students") } },
      { base_role_name: "TeacherEnrollment", name: "TeacherEnrollment", label: -> { t("roles.teacher", "Teacher") }, plural_label: -> { t("roles.teachers", "Teachers") } },
      { base_role_name: "TaEnrollment", name: "TaEnrollment", label: -> { t("roles.ta", "TA") }, plural_label: -> { t("roles.tas", "TAs") } },
      { base_role_name: "DesignerEnrollment", name: "DesignerEnrollment", label: -> { t("roles.designer", "Designer") }, plural_label: -> { t("roles.designers", "Designers") } },
      { base_role_name: "ObserverEnrollment", name: "ObserverEnrollment", label: -> { t("roles.observer", "Observer") }, plural_label: -> { t("roles.observers", "Observers") } }
    ].freeze
  def self.enrollment_type_labels
    ENROLLMENT_TYPE_LABELS
  end

  # Common set of granular permissions for checking rights against
  GRANULAR_FILE_PERMISSIONS = %i[manage_files_add manage_files_edit manage_files_delete].freeze
  GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS =
    %i[manage_course_content_add manage_course_content_edit manage_course_content_delete].freeze
  GRANULAR_MANAGE_GROUPS_PERMISSIONS = %i[manage_groups_add manage_groups_manage manage_groups_delete].freeze
  GRANULAR_MANAGE_LTI_PERMISSIONS = %i[manage_lti_add manage_lti_edit manage_lti_delete].freeze
  GRANULAR_MANAGE_USER_PERMISSIONS = %i[
    allow_course_admin_actions
    add_student_to_course
    add_teacher_to_course
    add_ta_to_course
    add_observer_to_course
    add_designer_to_course
    remove_student_from_course
    remove_teacher_from_course
    remove_ta_from_course
    remove_observer_from_course
    remove_designer_from_course
  ].freeze
  GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS = %i[
    manage_assignments_add
    manage_assignments_edit
    manage_assignments_delete
  ].freeze
  MANAGE_TEMPORARY_ENROLLMENT_PERMISSIONS = %i[
    temporary_enrollments_add
    temporary_enrollments_edit
    temporary_enrollments_delete
  ].freeze
  GRANULAR_MANAGE_TAGS_PERMISSIONS = %i[manage_tags_add manage_tags_manage manage_tags_delete].freeze
  GRANULAR_COURSE_ENROLLMENT_PERMISSIONS = %i[
    add_ta_to_course
    add_student_to_course
    add_teacher_to_course
    add_designer_to_course
    add_observer_to_course
  ].freeze

  ACCESS_TOKEN_SCOPE_PREFIX = "https://api.instructure.com/auth/canvas"

  def self.permissions
    Permissions.retrieve
  end

  # permissions that apply to concluded courses/enrollments
  def self.concluded_permission_types
    permissions.select { |_k, p| p[:applies_to_concluded] }
  end

  def self.manageable_permissions(context, base_role_type = nil)
    permissions = self.permissions.dup
    permissions.reject! { |_k, p| p[:account_only] == :site_admin } unless context.site_admin?
    permissions.reject! { |_k, p| p[:account_only] == :root } unless context.root_account?
    permissions.reject! { |_k, p| p[:available_to].exclude?(base_role_type) } unless base_role_type.nil?
    permissions.reject! { |_k, p| p[:account_allows] && !p[:account_allows].call(context) }
    permissions.reject! do |_k, p|
      p[:enabled_for_plugin] &&
        !((plugin = Canvas::Plugin.find(p[:enabled_for_plugin])) && plugin.enabled?)
    end
    permissions
  end

  def self.manageable_access_token_scopes(context)
    permissions = manageable_permissions(context).dup
    permissions.select! { |_, p| p[:acts_as_access_token_scope].present? }

    permissions.map do |k, p|
      {
        name: "#{ACCESS_TOKEN_SCOPE_PREFIX}.#{k}",
        label: p.key?(label_v2) ? p[:label_v2].call : p[:label].call
      }
    end
  end

  def self.readonly_for(context, permission, role, role_context = :role_account)
    permission_for(context, permission, role, role_context)[:readonly]
  end

  def self.title_for(context, permission, role, role_context = :role_account)
    if readonly_for(context, permission, role, role_context)
      t "tooltips.readonly", "you do not have permission to change this."
    else
      t "tooltips.toogle", "Click to toggle this permission ON or OFF"
    end
  end

  def self.locked_for(context, permission, role, role_context = :role_account)
    permission_for(context, permission, role, role_context)[:locked]
  end

  def self.hidden_value_for(context, permission, role, role_context = :role_account)
    generated_permission = permission_for(context, permission, role, role_context)
    if !generated_permission[:readonly] && generated_permission[:explicit]
      generated_permission[:enabled] ? "checked" : "unchecked"
    else
      ""
    end
  end

  def self.clear_cached_contexts; end

  # permission changes won't register right away but we already cache user permission checks for an hour so adding some latency here isn't the worst
  def self.local_cache_ttl
    return 0.seconds if ::Rails.env.test? # untangling the billion specs where this goes wrong is hard

    Setting.get("role_override_local_cache_ttl_seconds", "300").to_i.seconds
  end

  def self.permission_for(context, permission, role_or_role_id, role_context = :role_account, no_caching = false, preloaded_overrides: nil)
    # we can avoid a query since we're just using it for the batched keys on redis
    permissionless_base_key = ["role_override_calculation2", Shard.global_id_for(role_or_role_id)].join("/") unless no_caching
    account = context.is_a?(Account) ? context : Account.new(id: context.account_id)
    default_data = permissions[permission]

    if default_data[:account_allows] || no_caching
      # could depend on anything - can't cache (but that's okay because it's not super common)
      uncached_permission_for(context, permission, role_or_role_id, role_context, account, permissionless_base_key, default_data, no_caching, preloaded_overrides:)
    else
      full_base_key = [permissionless_base_key, permission, Shard.global_id_for(role_context)].join("/")
      LocalCache.fetch([full_base_key, account.global_id].join("/"), expires_in: local_cache_ttl) do
        Rails.cache.fetch_with_batched_keys(full_base_key,
                                            batch_object: account,
                                            batched_keys: [:account_chain, :role_overrides],
                                            skip_cache_if_disabled: true) do
          uncached_permission_for(context, permission, role_or_role_id, role_context, account, permissionless_base_key, default_data, preloaded_overrides:)
        end
      end
    end.freeze
  end

  def self.preload_overrides(account, roles, role_context = account)
    return Hash.new([].freeze) if roles.empty?

    account.shard.activate do
      result = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = {} } }

      account_root_id = account.root_account_id&.nonzero? ? account.global_root_account_id : account.global_id

      # skip loading from site admin if the role is not from site admin
      Shard.partition_by_shard(account.account_chain(include_federated_parent: true, include_site_admin: role_context == Account.site_admin)) do |shard_accounts|
        uniq_root_account_ids = shard_accounts.map { |sa| sa.root_account_id&.nonzero? ? sa.root_account_id : sa.id }.uniq
        uniq_root_account_ids -= [account_root_id] if Shard.current == account.shard
        all_roles = roles + Role.where(
          workflow_state: "built_in",
          root_account_id: uniq_root_account_ids,
          base_role_type: roles.select(&:built_in?).map(&:base_role_type)
        )
        id_map = all_roles.flat_map do |r|
          ret = [[r.global_id, r.global_id]]
          # If and only if we are supposed to inherit permissions cross root account, match up the built-in roles
          # since the ids won't match between root accounts
          if r.built_in? && r.global_root_account_id != account_root_id && !account.root_account.primary_settings_root_account?
            # These will all be built-in role copies
            ret << [r.global_id, roles.detect { |local| local.built_in? && local.base_role_type == r.base_role_type }.global_id]
          end
          ret
        end.to_h

        RoleOverride.where(role: all_roles, account: shard_accounts).find_each do |ro|
          permission_hash = result[ro.permission]
          permission_hash[ro.global_context_id][id_map[ro.global_role_id]] = ro
        end
        nil
      end
      result
    end
  end

  # this is a very basic PORO to represent when an actual RoleOverride
  # doesn't exist for passing between internal methods. It's _much_
  # faster than creating an AR object.
  class OverrideDummy
    attr_reader :context_id

    def initialize(context_id)
      @context_id = context_id
    end

    def new_record?
      true
    end

    def context_type
      "Account"
    end

    def locked?
      false
    end

    def has_asset?(asset)
      asset.instance_of?(Account) && asset.id == context_id
    end
  end
  private_constant :OverrideDummy

  def self.uncached_overrides_for(context, role, role_context, preloaded_overrides: nil, only_permission: nil)
    context.shard.activate do
      accounts = context.account_chain(include_site_admin: true)

      preloaded_overrides ||= preload_overrides(context, [role], role_context)

      overrides = {}

      dummies = RequestCache.cache("role_override_dummies") do
        Hash.new do |h, account_id|
          h[account_id] = OverrideDummy.new(account_id)
        end
      end

      # every context has to be represented so that we can't miss role_context below
      preloaded_overrides.each do |(permission, overrides_by_account)|
        next if only_permission && permission != only_permission

        overrides[permission] = accounts.reverse_each.map do |account|
          overrides_by_account[account.global_id][role.global_id] || dummies[account.id]
        end
      end
      overrides
    end
  end

  EMPTY_ARRAY = [].freeze
  private_constant :EMPTY_ARRAY

  def self.uncached_permission_for(context,
                                   permission,
                                   role_or_role_id,
                                   role_context,
                                   account,
                                   permissionless_base_key,
                                   default_data,
                                   no_caching = false,
                                   preloaded_overrides: nil)
    role = role_or_role_id.is_a?(Role) ? role_or_role_id : Role.get_role_by_id(role_or_role_id)

    true_for_custom_site_admin_role =
      (!account.site_admin? || !default_data[:account_only] == :site_admin) &&
      role.account == Account.site_admin && role.belongs_to_account? &&
      Setting.get("allowed_custom_site_admin_roles", "").split(",").uniq.include?(role.name)

    # be explicit that we're expecting calculation to stop at the role's account rather than, say, passing in a course
    # unnecessarily to make sure we go all the way down the chain (when nil would work just as well)
    role_context = role.account if role_context == :role_account

    # Determine if the permission is able to be used for the account. A non-setting is 'true'.
    # Execute linked proc if given.
    account_allows = !!(default_data[:account_allows].nil? || (default_data[:account_allows].respond_to?(:call) &&
        default_data[:account_allows].call(context.root_account)))

    base_role = role.base_role_type
    enabled = if account_allows && (default_data[:true_for].include?(base_role) || true_for_custom_site_admin_role)
                [:self, :descendants]
              else
                false
              end
    locked = !default_data[:available_to].include?(base_role) || !account_allows

    generated_permission = {
      account_allows:,
      permission:,
      enabled:,
      locked:,
      readonly: locked,
      explicit: false,
      base_role_type: base_role,
      enrollment_type: role.name,
      role_id: role.id,
    }
    generated_permission[:group] = default_data[:group] if default_data[:group].present?

    # NOTE: built-in roles don't have an account so we need to remember to send it in explicitly
    if default_data[:account_only] &&
       ((default_data[:account_only] == :root && !(role_context && role_context.is_a?(Account) && role_context.root_account?)) ||
        (default_data[:account_only] == :site_admin && !(role_context && role_context.is_a?(Account) && role_context.site_admin?)))
      generated_permission[:enabled] = false
      return generated_permission # shouldn't be able to be overridden because the account_user doesn't belong to the root/site_admin
    end

    # cannot be overridden; don't bother looking for overrides
    return generated_permission if locked

    overrides = if no_caching
                  uncached_overrides_for(context, role, role_context, preloaded_overrides:, only_permission: permission.to_s)
                else
                  RequestCache.cache(permissionless_base_key, account) do
                    LocalCache.fetch([permissionless_base_key, account.global_id].join("/"), expires_in: local_cache_ttl) do
                      Rails.cache.fetch_with_batched_keys(permissionless_base_key,
                                                          batch_object: account,
                                                          batched_keys: [:account_chain, :role_overrides],
                                                          skip_cache_if_disabled: true) do
                        uncached_overrides_for(context, role, role_context, preloaded_overrides:)
                      end
                    end
                  end
                end

    # walk the overrides from most general (site admin, root account) to most specific (the role's account)
    # and apply them; short-circuit once someone has locked it
    last_override = false
    hit_role_context = false
    (overrides[permission.to_s] || EMPTY_ARRAY).each do |override|
      # set the flag that we have an override for the context we're on
      last_override = override.context_id == context.id && override.context_type == context.class.base_class.name

      generated_permission[:context_id] = override.context_id unless override.new_record?
      generated_permission[:locked] = override.locked?
      # keep track of the value for the parent
      generated_permission[:prior_default] = generated_permission[:enabled]

      # override.enabled.nil? is no longer possible, but is important for the migration that removes nils
      if override.new_record? || override.enabled.nil?
        if last_override
          case generated_permission[:enabled]
          when [:descendants]
            generated_permission[:enabled] = [:self, :descendants]
          when [:self]
            generated_permission[:enabled] = nil
          end
        end
      else
        generated_permission[:explicit] = true if last_override
        if hit_role_context
          generated_permission[:enabled] ||= override.enabled? ? override.applies_to : nil
        else
          generated_permission[:enabled] = override.enabled? ? override.applies_to : nil
        end
      end
      hit_role_context ||= role_context.is_a?(Account) && override.has_asset?(role_context)

      break if override.locked?
      break if generated_permission[:enabled] && hit_role_context
    end

    # there was not an override matching this context, so do a half loop
    # to set the inherited values
    unless last_override
      generated_permission[:prior_default] = generated_permission[:enabled]
      generated_permission[:readonly] = true if generated_permission[:locked]
    end

    generated_permission
  end

  # returns just the :enabled key of permission_for, adjusted for applying it to a certain
  # context
  def self.enabled_for?(context, permission, role, role_context = :role_account)
    permission = permission_for(context, permission, role, role_context)
    return [] unless permission[:enabled]

    # this override applies to self, and we are self; no adjustment necessary
    return permission[:enabled] if context.id == permission[:context_id]
    # this override applies to descendants, and we're not applying it to self
    #   (presumed that other logic prevents calling this method with context being a parent of role_context)
    return [:self, :descendants] if context.id != permission[:context_id] && permission[:enabled].include?(:descendants)

    []
  end

  # settings is a hash with recognized keys :override and :locked. each key
  # differentiates nil, false, and truthy as possible values
  def self.manage_role_override(context, role, permission, settings)
    context.shard.activate do
      role_override = context.role_overrides.where(permission:, role_id: role.id).first
      if !settings[:override].nil? || settings[:locked]
        role_override ||= context.role_overrides.build(
          permission:,
          role:
        )
        role_override.enabled = settings[:override] unless settings[:override].nil?
        role_override.locked = settings[:locked] unless settings[:locked].nil?
        role_override.applies_to_self = settings[:applies_to_self] unless settings[:applies_to_self].nil?
        unless settings[:applies_to_descendants].nil?
          role_override.applies_to_descendants = settings[:applies_to_descendants]
        end
        role_override.save!
      elsif role_override
        account = role_override.account
        role = role_override.role
        role_override.destroy
        RoleOverride.clear_caches(account, role)
        role_override = nil
      end
      role_override
    end
  end
end
