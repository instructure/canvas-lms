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

class AlertCriterion < ActiveRecord::Base
  belongs_to :alert

  attr_accessible :criterion_type, :threshold
  EXPORTABLE_ATTRIBUTES = [:id, :alert_id, :criterion_type, :threshold]
  EXPORTABLE_ASSOCIATIONS = [:alert]

  validates_numericality_of :threshold, :only_integer => true, :greater_than_or_equal_to => 0

end
