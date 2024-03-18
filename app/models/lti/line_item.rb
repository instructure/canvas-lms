# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

class Lti::LineItem < ApplicationRecord
  include Canvas::SoftDeletable

  validates :score_maximum, :label, :assignment, presence: true
  validates :score_maximum, numericality: true
  validates :client_id, presence: true
  validate :resource_link_id_has_one_assignment
  validate :client_id_is_global?

  before_validation :set_client_id_if_possible

  belongs_to :resource_link,
             inverse_of: :line_items,
             foreign_key: :lti_resource_link_id,
             class_name: "Lti::ResourceLink"
  belongs_to :assignment,
             inverse_of: :line_items,
             class_name: "AbstractAssignment"
  belongs_to :root_account,
             class_name: "Account"
  has_many :results,
           inverse_of: :line_item,
           class_name: "Lti::Result",
           foreign_key: :lti_line_item_id,
           dependent: :destroy

  before_create :set_root_account_id

  AGS_EXT_PREFIX = "https://canvas.instructure.com/lti/"
  AGS_EXT_SUBMISSION_TYPE = "#{AGS_EXT_PREFIX}submission_type".freeze
  AGS_EXT_LAUNCH_URL = "#{AGS_EXT_PREFIX}launch_url".freeze

  include MasterCourses::CollectionRestrictor
  self.collection_owner_association = :assignment
  restrict_columns :content, [:resource_id]

  def assignment_line_item?
    assignment.line_items.order(:created_at).first.id == id
  end

  def undestroy
    results.find_each(&:undestroy)
    super
  end

  def launch_url_extension
    { AGS_EXT_LAUNCH_URL => assignment.external_tool_tag&.url }
  end

  def self.create_line_item!(assignment, context, tool, params)
    transaction do
      assignment_attr = {
        context:,
        name: params[:label],
        points_possible: params[:score_maximum],
        submission_types: "none",
        due_at: params[:end_date_time],
        unlock_at: params[:start_date_time]
      }

      submission_type = params[AGS_EXT_SUBMISSION_TYPE]
      unless submission_type.nil?
        if Assignment::OFFLINE_SUBMISSION_TYPES.include?(submission_type[:type].to_sym)
          assignment_attr[:submission_types] = submission_type[:type]
          assignment_attr[:external_tool_tag_attributes] = {
            url: submission_type[:external_tool_url]
          }

          params = extract_extensions(params)
        else
          raise ActionController::BadRequest, "Invalid submission_type for new assignment: #{submission_type[:type]}"
        end
      end

      line_item = nil
      if assignment.blank?
        # Creating a new assignment of submission type external_tool creates a "default"
        # LineItem (and associated ResourceLink) which we can just modify & use
        assignment = Assignment.create!(assignment_attr)
        line_item = assignment.line_items.first
      end

      line_item ||= new(assignment:, root_account_id: assignment.root_account_id)
      attrs = params.to_h.merge(coupled: false).compact
      attrs[:client_id] = tool.global_developer_key_id if tool
      line_item.update!(attrs)
      line_item
    end
  end

  def self.extract_extensions(params)
    hsh = params.to_unsafe_h
    hsh[:extensions] = { AGS_EXT_SUBMISSION_TYPE => hsh.delete(AGS_EXT_SUBMISSION_TYPE) }
    hsh
  end
  private_class_method :extract_extensions

  private

  def resource_link_id_has_one_assignment
    return if resource_link.blank?

    ids = resource_link.line_items.pluck(:assignment_id)
    return if ids.empty?
    return if ids.uniq.size == 1 && ids.first == assignment_id

    errors.add(:assignment, "does not match ltiLink")
  end

  def set_client_id_if_possible
    return if client_id.present?

    self.client_id = resource_link.current_external_tool(assignment.context)&.developer_key&.global_id unless lti_resource_link_id.blank?
    self.client_id ||= assignment&.external_tool_tag&.content&.developer_key&.global_id
  end

  def client_id_is_global?
    client_id.present? && client_id > Shard::IDS_PER_SHARD
  end

  def set_root_account_id
    self.root_account_id = assignment&.root_account_id unless root_account_id
  end
end
