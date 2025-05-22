# frozen_string_literal: true

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

class Lti::ContextControl < ActiveRecord::Base
  extend RootAccountResolver
  resolves_root_account through: ->(cc) { cc.account&.resolved_root_account_id || cc.course&.root_account_id }

  include Canvas::SoftDeletable

  belongs_to :deployment, class_name: "ContextExternalTool", inverse_of: :context_controls, optional: false
  belongs_to :registration, class_name: "Lti::Registration", inverse_of: :context_controls, optional: false
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"

  belongs_to :course, optional: true
  belongs_to :account, optional: true

  validate :only_one_context?
  validates :course, presence: true, if: -> { account.blank? }
  validates :account, presence: true, if: -> { course.blank? }

  validates :deployment_id, uniqueness: { scope: %i[account_id course_id] }

  validates :path, on: :update, if: -> { path.present? }, comparison: { equal_to: :path_was, message: t("cannot be changed") }
  validates :course_id, on: :update, if: -> { course_id.present? }, comparison: { equal_to: :course_id_was, message: t("cannot be changed") }
  validates :account_id, on: :update, if: -> { account_id.present? }, comparison: { equal_to: :account_id_was, message: t("cannot be changed") }

  before_create :set_path

  # Keep paths in sync when the account chain changes for
  # an account or a course.
  # This references an account's "parent account" or a course's "account".
  #
  # This is the only time when paths can be changed post-creation.
  #
  # @param context [Account|Course] the account or course that was reparented
  # @param old_parent_id [Integer] the account or course's previous parent account ID
  # @param new_parent_id [Integer] the account or course's new parent account ID
  def self.update_paths_for_reparent(context, old_parent_id, new_parent_id)
    old_parent = Account.find_by(id: old_parent_id)
    new_parent = Account.find_by(id: new_parent_id)
    return unless old_parent && new_parent && context

    context_segment = path_segment_for(context)
    old_path = calculate_path(old_parent) + context_segment
    new_path = calculate_path(new_parent) + context_segment

    where("path like ?", "%#{old_path}%").update_all(sanitize_sql("path = replace(path, '#{old_path}', '#{new_path}')"))
  end

  # Generate a path string based on the given account chain.
  # A path looks like "a1.a2.c3.", where "a" represents an account and "c" represents a course.
  # The path starts at the root account and ends at the given context.
  def self.calculate_path(context)
    segments = context.account_chain_ids.reverse.map { |id| "a#{id}" }
    if context.is_a?(Course)
      segments << "c#{context.id}"
    end
    segments.join(".").concat(".")
  end

  def self.path_segment_for(context)
    prefix = context.is_a?(Course) ? "c" : "a"

    "#{prefix}#{context.id}."
  end

  # Generate a path string based on the given course ID and account IDs.
  # A path looks like "a1.a2.c3.", where "a" represents an account and "c" represents a course.
  # The path starts at the root account and ends at the given course.
  # Note that account_ids are expected to be in leaf-to-root order, as returned by
  # Account#account_chain_ids or Account#account_chain_ids_for_multiple_accounts.
  def self.calculate_path_for_course_id(course_id, account_ids)
    segments = calculate_path_for_account_ids(account_ids)
    segments << "c#{course_id}."
    segments
  end

  # Generate a path string based on the given account IDs.
  # A path looks like "a1.a2.", where "a" represents an account.
  # The path starts at the root account and ends at the given account.
  # Note that account_ids are expected to be in leaf-to-root order, as returned by
  # Account#account_chain_ids or Account#account_chain_ids_for_multiple_accounts.
  def self.calculate_path_for_account_ids(account_ids)
    segments = account_ids.reverse.map { |id| "a#{id}." }
    segments.join
  end

  def context_name
    account&.name || course.name
  end

  # A human-readable version of this control's path,
  # meant for UI display.
  # TODO: Fully implement as part of INTEROP-8992
  def path_names
    [context_name]
  end

  private

  def set_path
    self.path = self.class.calculate_path(account || course)
  end

  def only_one_context?
    if account.present? && course.present?
      errors.add(:context, "must have either an account or a course, not both")
    elsif account.blank? && course.blank?
      errors.add(:context, "must have either an account or a course")
    end
  end
end
