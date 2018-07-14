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
    opts[:active_all] ||= true
    opts[:student] ||= course_with_student(opts).user
    @student = opts[:student]
    opts[:associated_user_id] ||= @student.id
    opts[:observer] ||= course_with_observer(opts).user
    @observer = opts[:observer]

    @observation_link = opts[:link] || UserObservationLink.create!(student: @student, observer: @observer)

    valid_attrs = [:alert_type, :threshold, :workflow_state, :student, :observer]
    default_attrs = {
      alert_type: 'course_announcement',
      threshold: nil,
      workflow_state: 'active'
    }

    attrs = default_attrs.deep_merge(opts.slice(*valid_attrs))
    @observer_alert_threshold = ObserverAlertThreshold.create(attrs)
  end
end
