# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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
#
class TermsOfService < ActiveRecord::Base
  include Canvas::SoftDeletable
  belongs_to :account
  belongs_to :terms_of_service_content
  validates :terms_type, presence: true

  before_save :set_content_on_type_change, if: :terms_type_changed?

  validate :validate_account_is_root

  cattr_accessor :skip_automatic_terms_creation

  def validate_account_is_root
    if account_id_changed? && !account.root_account?
      errors.add(:account, "must be root account")
    end
  end

  def set_content_on_type_change
    self.terms_of_service_content = custom? ? account.terms_of_service_content : nil
  end

  def custom?
    terms_type == "custom"
  end

  def self.ensure_terms_for_account(account, is_new_account = false)
    return unless table_exists?
    return if account.dummy?

    passive = is_new_account || !(Setting.get("terms_required", "true") == "true" && account.account_terms_required?)
    unique_constraint_retry do |retry_count|
      account.reload_terms_of_service if retry_count > 0
      account.terms_of_service || account.create_terms_of_service!(term_options_for_account(account).merge(passive:))
    end
  end

  DEFAULT_OPTIONS = { terms_type: "default" }.freeze
  def self.term_options_for_account(_account)
    DEFAULT_OPTIONS
  end

  def self.type_dropdown_options_for_account(_account = nil)
    type_dropdown_options
  end

  def self.type_dropdown_options
    [
      [t("Default"), "default"],
      [t("Custom"), "custom"],
      [t("No Terms"), "no_terms"]
    ]
  end

  class CacheTermsOfServiceContentOnAssociation < ActiveRecord::Associations::BelongsToAssociation
    def find_target
      Shard.default.activate do
        key = ["terms_of_service_content", owner.attribute(reflection.foreign_key)].cache_key
        MultiCache.fetch(key) { super }
      end
    end
  end

  reflections["terms_of_service_content"].instance_eval do
    def association_class
      CacheTermsOfServiceContentOnAssociation
    end
  end
end
