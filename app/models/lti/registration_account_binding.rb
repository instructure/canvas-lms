# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class Lti::RegistrationAccountBinding < ActiveRecord::Base
  extend RootAccountResolver

  include Workflow
  workflow do
    state :off
    state :on
    state :allow
    state :deleted
  end

  # Binding always lives on the shard of the account
  belongs_to :account, inverse_of: :lti_registration_account_bindings, optional: false
  # Registration can be cross-shard
  belongs_to :registration, class_name: "Lti::Registration", inverse_of: :lti_registration_account_bindings, optional: false
  belongs_to :root_account, class_name: "Account"
  belongs_to :created_by, class_name: "User", inverse_of: :created_lti_registration_account_bindings
  belongs_to :updated_by, class_name: "User", inverse_of: :updated_lti_registration_account_bindings
  belongs_to :developer_key_account_binding, inverse_of: :lti_registration_account_binding
  resolves_root_account through: :account

  validates :workflow_state, inclusion: { in: %w[off on allow deleted], message: ->(_object, _data) { I18n.t("%{value} is not a valid workflow_state") } }
  validate :validate_allowed_workflow_state
  validate :restrict_federated_child_accounts
  validate :require_root_account
  validate :validate_inherited_registration_in_chain

  after_update :clear_cache_if_site_admin

  def self.find_in_site_admin(registration)
    return nil unless registration.account.site_admin?

    Shard.default.activate do
      MultiCache.fetch(site_admin_cache_key(registration)) do
        GuardRail.activate(:secondary) do
          where.not(workflow_state: :allow).find_by(account: registration.account, registration:)
        end
      end
    end
  end

  def self.find_all_in_site_admin(registrations)
    registrations = registrations.select { |r| r.account.site_admin? }
    return [] if registrations.empty?

    Shard.default.activate do
      list_cache_key = site_admin_list_cache_key(registrations)

      MultiCache.fetch(list_cache_key) do
        cache_pointers_for_clearing(registrations, list_cache_key)

        GuardRail.activate(:secondary) do
          where.not(workflow_state: :allow).where(account: Account.site_admin, registration: registrations).preload(:created_by, :updated_by)
        end
      end
    end
  end

  def self.cache_pointers_for_clearing(registrations, list_cache_key)
    registrations.each { |r| MultiCache.fetch(pointer_to_list_key(r)) { list_cache_key } }
  end

  def self.clear_site_admin_cache(registration)
    Shard.default.activate do
      MultiCache.delete(site_admin_cache_key(registration))

      list_key = MultiCache.fetch(pointer_to_list_key(registration), nil)
      MultiCache.delete(list_key) if list_key
      MultiCache.delete(pointer_to_list_key(registration))
    end
  end

  def self.site_admin_cache_key(registration)
    "accounts/site_admin/lti_registration_account_bindings/#{registration.global_id}"
  end

  def self.site_admin_list_cache_key(registrations)
    ids_hash = Digest::SHA256.hexdigest(registrations.map(&:global_id).sort.join(","))
    "accounts/site_admin/lti_registration_account_bindings/for_registrations:#{ids_hash}"
  end

  def self.pointer_to_list_key(registration)
    "accounts/site_admin/lti_registration_account_bindings/for_registrations:#{registration.global_id}"
  end

  def clear_cache_if_site_admin
    self.class.clear_site_admin_cache(registration) if account.site_admin?
  end

  # -- BEGIN SoftDeleteable --
  # adapting SoftDeleteable, but with no "active" state
  scope :active, -> { where.not(workflow_state: :deleted) }

  alias_method :destroy_permanently!, :destroy
  def destroy
    return true if deleted?

    self.workflow_state = :deleted
    run_callbacks(:destroy) { save! }
  end

  def undestroy(active_state: "off")
    self.workflow_state = active_state
    save!
    true
  end
  # -- END SoftDeleteable --

  private

  def require_root_account
    return if account.root_account?

    errors.add(:account, :not_root_account, message: I18n.t("must be a root account"))
  end

  def validate_allowed_workflow_state
    return unless workflow_state == "allow"
    return if registration.account.site_admin? && account.site_admin?

    errors.add(:workflow_state, :invalid_workflow_state, message: I18n.t("workflow_state 'allow' is only valid for Site Admin registrations"))
  end

  # Federated children can make their own registrations, but for now we are not letting
  # them bind any registrations inherited from either site admin or the federated parent root account.
  def restrict_federated_child_accounts
    return if account.primary_settings_root_account?
    return unless registration.inherited_for?(account)

    errors.add(:account, :ineligible_account, message: I18n.t("Federated child accounts cannot bind inherited registrations"))
  end

  # When enabling an inherited registration, the registration must be from an account in the account chain
  # (ie, either Site Admin or a federated parent root account).
  def validate_inherited_registration_in_chain
    return unless registration.inherited_for?(account)
    return if account.account_chain(include_site_admin: true).include?(registration.account)

    errors.add(:registration, :registration_not_found, message: I18n.t("Registration does not belong to a related account"))
  end
end
