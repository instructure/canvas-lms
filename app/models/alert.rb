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
  belongs_to :context, :polymorphic => true # Account or Course
  has_many :criteria, :class_name => 'AlertCriterion', :dependent => :destroy, :autosave => true

  serialize :recipients

  attr_accessible :context, :repetition, :criteria, :recipients

  validates_presence_of :context_id
  validates_presence_of :context_type
  validates_presence_of :criteria
  validates_associated :criteria
  validates_presence_of :recipients

  before_save :infer_defaults

  def resolve_recipients(student_id, teachers = nil)
    include_student = false
    include_teacher = false
    include_teachers = false
    admin_roles = []
    self.recipients.try(:each) do |recipient|
      case
        when recipient == :student
          include_student = true
        when recipient == :teachers
          include_teachers = true
        when recipient.is_a?(String)
          admin_roles << recipient
        else
          raise "Unsupported recipient type!"
      end
    end

    recipients = []

    recipients << student_id if include_student
    recipients.concat(Array(teachers)) if teachers.present? && include_teachers
    recipients.concat context.account_users.where(:membership_type => admin_roles).uniq.pluck(:user_id) if context_type == 'Account' && !admin_roles.empty?
    recipients.uniq
  end

  def infer_defaults
    self.repetition = nil if self.repetition.blank?
  end

  def as_json(*args)
    {
      :id => id,
      :criteria => criteria.map { |c| c.as_json(:include_root => false) },
      :recipients => recipients.try(:map) { |r| (r.is_a?(Symbol) ? ":#{r}" : r) },
      :repetition => repetition
    }.with_indifferent_access
  end

  def recipients=(recipients)
    write_attribute(:recipients, recipients.map { |r| (r.is_a?(String) && r[0..0] == ':' ? r[1..-1].to_sym : r) })
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
