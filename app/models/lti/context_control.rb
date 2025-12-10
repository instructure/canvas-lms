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
  # While id, account_id, course_id, and deployment_id are tracked, they don't really change
  # (deployment_id & id literally can't), but it makes it easier in the UI to associate a
  # changed control with a specific context and deployment.
  TRACKED_ATTRIBUTES = %i[id account_id course_id deployment_id available workflow_state].freeze

  extend RootAccountResolver

  resolves_root_account through: ->(cc) { cc.account&.resolved_root_account_id || cc.course&.root_account_id }

  include Canvas::SoftDeletable

  belongs_to :deployment, class_name: "ContextExternalTool", inverse_of: :context_controls, optional: false
  belongs_to :registration, class_name: "Lti::Registration", inverse_of: :context_controls, optional: false
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"

  belongs_to :context, polymorphic: %i[account course], separate_columns: true, optional: false

  validates :deployment_id, uniqueness: { scope: %i[account_id course_id] }

  validates :path, on: :update, if: -> { path.present? }, comparison: { equal_to: :path_was, message: t("cannot be changed") }
  validates :course_id, on: :update, if: -> { course_id.present? }, comparison: { equal_to: :course_id_was, message: t("cannot be changed") }
  validates :account_id, on: :update, if: -> { account_id.present? }, comparison: { equal_to: :account_id_was, message: t("cannot be changed") }

  validate :context_belongs_to_deployment

  before_validation :set_registration_id
  before_create :set_path
  before_destroy :prevent_primary_deletion
  after_destroy :soft_delete_child_controls

  scope :active, -> { where.not(workflow_state: :deleted) }

  class << self
    # Generate a path string based on the given account chain.
    # A path looks like "a1.a2.c3.", where "a" represents an account and "c" represents a course.
    # The path starts at the root account and ends at the given context.
    def calculate_path(context)
      if context.is_a?(Group) || context.is_a?(Assignment)
        context = context.context
      end

      segments = context.account_chain_ids.reverse.map { |id| "a#{id}" }
      if context.is_a?(Course)
        segments << "c#{context.id}"
      end
      segments.join(".").concat(".")
    end

    # Given a context and a registration, returns the nearest non-deleted context control that
    # is associated with that registration.
    #
    # @example Imagine the following context chain
    #     Account 1 > SubAccount 2 > Course 3
    # Where there's a context control in Account 1 and Course 3. Calling this method from the course
    # will return the context control that's associated with the course, while calling it from the
    # account or subaccount will return the context control associated with Account 1.
    #
    # @param [Account | Course | Group | Assignment] context
    # @param [Lti::Registration] registration
    # @param [ContextExternalTool] deployment
    def nearest_control_for_registration(context, registration, deployment)
      query_by_paths(context:, registration:, deployment:).take
    end

    # Given a context, will return all the ids of all LTI 1.3 ContextExternalTools that are available
    # in that context, based on the configured, active context controls.
    # @param [Account | Course | Group | Assignment] context
    def deployment_ids_for_context(context)
      # Need to use map, not pluck, because pluck will override the select statement,
      # and we need to use the special "DISTINCT ON (registration_id)" select statement
      # here.
      where(id: query_by_paths(context:).map(&:id), available: true).pluck(:deployment_id)
    end

    # Generate a path string based on the given course ID and account IDs.
    # A path looks like "a1.a2.c3.", where "a" represents an account and "c" represents a course.
    # The path starts at the root account and ends at the given course.
    # Note that account_ids are expected to be in leaf-to-root order, as returned by
    # Account#account_chain_ids or Account#account_chain_ids_for_multiple_accounts.
    def calculate_path_for_course_id(course_id, account_ids)
      segments = calculate_path_for_account_ids(account_ids)
      segments << "c#{course_id}."
      segments
    end

    # Generate a path string based on the given account IDs.
    # A path looks like "a1.a2.", where "a" represents an account.
    # The path starts at the root account and ends at the given account.
    # Note that account_ids are expected to be in leaf-to-root order, as returned by
    # Account#account_chain_ids or Account#account_chain_ids_for_multiple_accounts.
    def calculate_path_for_account_ids(account_ids)
      segments = account_ids.reverse.map { |id| "a#{id}." }
      segments.join
    end

    # Keep paths in sync when the account chain changes for
    # an account or a course.
    # This references an account's "parent account" or a course's "account".
    #
    # This is the only time when paths can be changed post-creation.
    #
    # @param context [Account|Course] the account or course that was reparented
    # @param old_parent_id [Integer] the account or course's previous parent account ID
    # @param new_parent_id [Integer] the account or course's new parent account ID
    def update_paths_for_reparent(context, old_parent_id, new_parent_id)
      old_parent = Account.find_by(id: old_parent_id)
      new_parent = Account.find_by(id: new_parent_id)
      return unless old_parent && new_parent && context

      context_segment = path_segment_for(context)
      old_path = calculate_path(old_parent) + context_segment
      new_path = calculate_path(new_parent) + context_segment

      where("path like ?", "%#{old_path}%").update_all(sanitize_sql("path = replace(path, '#{old_path}', '#{new_path}')"))
    end

    def path_segment_for(context)
      prefix = context.is_a?(Course) ? "c" : "a"

      "#{prefix}#{context.id}."
    end

    # Get the path for a context (account or course) and the paths of all of
    # its parent accounts. If given a string, will simply return the string itself
    # and all of its possible ancestral paths.
    #
    # Note: this does not return paths for context controls that necessarily
    # exist; it does not query to see if there is a control at each path.
    # It returns a list of paths that *could* exist as parent paths of the
    # provided context's level.
    #
    # E.g. with a root account 1, subaccount 3, and course 1, for
    # context = course 1 this will return:
    # [ "a1.", "a1.a3.", "a1.a3.c1." ]
    #
    # This method should be used when searching for context controls by path, to
    # get all context controls that could affect the provided context.
    #
    # @returns An array of strings, with each string being a path like what is
    #          returned from calculate_path.
    #
    # @param context_or_path [Account|Course|String] the context to find paths for, or
    # an already computed path
    def self_and_all_parent_paths(context_or_path)
      path = if context_or_path.is_a?(String)
               context_or_path
             else
               calculate_path(context_or_path)
             end

      path_parts = path.split(".")
      path_parts.reduce([]) do |all_paths, segment|
        appended_path = (all_paths.last || "") + "#{segment}."
        all_paths.push(appended_path)
      end
    end

    # Given one-to-many deployments, return the primary control for each.
    # Similar to ContextExternalTool#primary_control, but for multiple deployments.
    # `deployments` is an array of ContextExternalTool objects or their IDs.
    def primary_controls_for(deployments:)
      lcc = quoted_table_name
      join_sql = <<~SQL.squish
        INNER JOIN #{ContextExternalTool.quoted_table_name} cet
        ON cet.id = #{lcc}.deployment_id
        AND (
          (cet.context_id = #{lcc}.account_id AND cet.context_type = 'Account')
          OR
          (cet.context_id = #{lcc}.course_id AND cet.context_type = 'Course')
        )
      SQL

      where(deployment_id: deployments).active.joins(join_sql)
    end

    private

    def query_by_paths(context:, registration: nil, deployment: nil)
      paths = self_and_all_parent_paths(context)
      query = active.where(path: paths)
      query = query.where(registration:) if registration.present?
      query = query.where(deployment:) if deployment.present?
      # Because all ancestors will have the same prefix path, we can safely order by path length instead
      # of splitting on segments and worrying about that.
      query.order("deployment_id, LENGTH(path) DESC").select("DISTINCT ON (deployment_id) *")
    end
  end

  def self_and_all_parent_paths
    Lti::ContextControl.self_and_all_parent_paths(path)
  end

  def context_name
    account&.name || course.name
  end

  # Array of names of all parents in this control's account chain,
  # not including the control's context itself. Meant for UI display.
  def display_path
    calculated_attrs[:display_path]
  end

  # Includes all nested subaccounts that belong to the control's account.
  def subaccount_count
    return 0 unless account

    # equivalent to `Account.sub_account_ids_recursive(account.id).count`
    calculated_attrs[:subaccount_count]
  end

  # Includes all courses in the control's account and in all nested subaccounts.
  def course_count
    return 0 unless account

    # equivalent to `Course.where(account_id: subaccount_ids + [account_id]).active.count`
    calculated_attrs[:course_count]
  end

  # Includes all ContextControls for the same deployment that are present in
  # any subaccount or course that belong to the control's account.
  def child_control_count
    return 0 unless account

    # equivalent to Lti::ContextControl.active.where(deployment:).where("path like ?", "#{path}%").where.not(id:).count
    calculated_attrs[:child_control_count]
  end

  private

  def soft_delete_child_controls
    Lti::ContextControl
      .active
      .where("path LIKE ?", "#{path}%")
      .where(deployment_id:, registration_id:)
      .where.not(id:)
      .in_batches do |batch|
      batch.update_all(workflow_state: "deleted", updated_at: Time.current, updated_by_id:)
    end
  end

  def prevent_primary_deletion
    context_id = account_id || course_id
    context_type = account_id ? "Account" : "Course"

    if deployment.context_id == context_id && deployment.context_type == context_type
      errors.add(:base, I18n.t("Cannot delete primary control for deployment"))
      throw :abort
    end
  end

  def calculated_attrs
    @calculated_attrs ||= Lti::ContextControlService.preload_calculated_attrs([self])[id]
  end

  def set_path
    self.path = self.class.calculate_path(context)
  end

  def set_registration_id
    self.registration_id ||= deployment.lti_registration_id
  end

  def context_belongs_to_deployment
    return unless (account_id || course_id) && deployment

    if deployment.context_type == "Course"
      # context can only be the course itself
      unless course_id == deployment.context_id
        errors.add(:context, I18n.t("must be the deployment's context"))
      end
    else
      # context must be a child of the account at any level, or the account itself
      valid_account_ids = Account.sub_account_ids_recursive(deployment.context_id)
      valid_account_ids << deployment.context_id

      context_id = account_id || course&.account_id
      unless valid_account_ids.include?(context_id)
        errors.add(:context, I18n.t("must belong to the deployment's context"))
      end
    end
  end
end
