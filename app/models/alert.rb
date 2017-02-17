#
# Copyright (C) 2011 Instructure, Inc.
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
  has_many :criteria, :class_name => 'AlertCriterion', :dependent => :destroy, :autosave => true

  serialize :recipients

  validates_presence_of :context_id
  validates_presence_of :context_type
  validates_presence_of :criteria
  validates_associated :criteria
  validates_presence_of :recipients

  before_save :infer_defaults

  def find_role_by_name(role_name)
    context.is_a?(Account) ? context.get_account_role_by_name(role_name) : context.account.get_account_role_by_name(role_name)
  end

  def resolve_recipients(student_id, teachers = nil)
    include_student = false
    include_teachers = false
    admin_role_ids = []
    self.recipients.try(:each) do |recipient|
      case
        when recipient == :student
          include_student = true
        when recipient == :teachers
          include_teachers = true
        when recipient.is_a?(String)
          admin_role_ids << find_role_by_name(recipient).id
        when recipient.is_a?(Hash)
          admin_role_ids << recipient[:role_id]
        else
          raise "Unsupported recipient type!"
      end
    end

    recipients = []

    recipients << student_id if include_student
    recipients.concat(Array(teachers)) if teachers.present? && include_teachers
    if context_type == 'Account' && !admin_role_ids.empty?
      recipients.concat context.account_users.where(:role_id => admin_role_ids).uniq.pluck(:user_id)
    end
    recipients.uniq
  end

  def infer_defaults
    self.repetition = nil if self.repetition.blank?
  end

  def as_json(*args)
    converted_recipients = self.recipients.to_a.map do |recipient|
      if recipient.is_a?(String)
        find_role_by_name(recipient).id
      elsif recipient.is_a?(Hash)
        recipient[:role_id]
      else
        ":#{recipient}"
      end
    end
    {
      :id => id,
      :criteria => criteria.map { |c| c.as_json(:include_root => false) },
      :recipients => converted_recipients,
      :repetition => repetition
    }.with_indifferent_access
  end

  def criteria=(values)
    if values[0].is_a? Hash
      values = values.map do |params|
        if(params[:id].present?)
          id = params.delete(:id).to_i
          criterion = self.criteria.to_ary.find { |c| c.id == id }
          criterion.attributes = params
        else
          criterion = self.criteria.build(params)
        end
        criterion
      end
    end
    self.criteria.replace(values)
  end
end
