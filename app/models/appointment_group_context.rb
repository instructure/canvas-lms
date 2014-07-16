#
# Copyright (C) 2012 Instructure, Inc.
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

class AppointmentGroupContext < ActiveRecord::Base
  belongs_to :appointment_group
  belongs_to :context, :polymorphic => true
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['Course']

  attr_accessible :appointment_group, :context
  EXPORTABLE_ATTRIBUTES = [:id, :appointment_group_id, :context_id, :context_type, :created_at, :updated_at]

  EXPORTABLE_ASSOCIATIONS =[:appointment_group, :context]

  before_validation :default_values

  def default_values
    self.context_code ||= context_string
  end
end
