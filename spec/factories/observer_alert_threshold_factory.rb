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

module Factories
  def observer_alert_threshold_model(opts = {})
    @observee = opts[:observee] || course_with_student(opts).user
    @observer = opts[:observer] || user_model
    @observation_link = UserObservationLink.create!(user_id: @observee, observer_id: @observer)

    attrs = default_attrs.merge(opts.slice(*valid_attrs_list))
    @observer_alert_threshold = @observation_link.observer_alert_thresholds.create(attrs)
  end

  def default_attrs
    {
      alert_type: 'value for type',
      threshold: nil,
      workflow_state: 'active',
    }
  end

  def valid_attrs_list
    [:alert_type, :threshold, :workflow_state]
  end
end
