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

class Alert < ActiveRecord::Base
  belongs_to :context, polymorphic: [:account, :course]
  has_many :criteria, class_name: "AlertCriterion", dependent: :destroy, autosave: true

  serialize :recipients

  validates :context_id, presence: true
  validates :context_type, presence: true
  validates :criteria, presence: true
  validates_associated :criteria
  validates :recipients, presence: true

  before_save :infer_defaults

  def find_role_by_name(role_name)
    context.is_a?(Account) ? context.get_account_role_by_name(role_name) : context.account.get_account_role_by_name(role_name)
  end

  def resolve_recipients(student_id, teachers = nil)
    include_student = false
    include_teachers = false
    admin_role_ids = []
    recipients.try(:each) do |recipient|
      case recipient
      when :student
        include_student = true
      when :teachers
        include_teachers = true
      when String
        admin_role_ids << find_role_by_name(recipient).id
      when Hash
        admin_role_ids << recipient[:role_id]
      else
        raise "Unsupported recipient type!"
      end
    end

    recipients = []

    recipients << student_id if include_student
    recipients.concat(Array(teachers)) if teachers.present? && include_teachers
    if context_type == "Account" && !admin_role_ids.empty?
      recipients.concat context.account_users.active.where(role_id: admin_role_ids).distinct.pluck(:user_id)
    end
    recipients.uniq
  end

  def infer_defaults
    self.repetition = nil if repetition.blank?
  end

  def as_json(*)
    converted_recipients = recipients.to_a.map do |recipient|
      case recipient
      when String
        find_role_by_name(recipient).id
      when Hash
        recipient[:role_id]
      else
        ":#{recipient}"
      end
    end
    {
      id:,
      criteria: criteria.map { |c| c.as_json(include_root: false) },
      recipients: converted_recipients,
      repetition:
    }.with_indifferent_access
  end

  def criteria=(values)
    if values[0].is_a? Hash
      values = values.map do |params|
        if params[:id].present?
          id = params.delete(:id).to_i
          criterion = criteria.to_ary.find { |c| c.id == id }
          criterion.attributes = params
        else
          criterion = criteria.build(params)
        end
        criterion
      end
    end
    criteria.replace(values)
  end
end
