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
  def observer_alert_model(opts = {})

    opts[:observer] ||= user_model
    @observer = opts[:observer]
    opts[:student] ||= course_with_student(opts).user
    @student = opts[:student]


    @observation_link = opts[:link] || UserObservationLink.create!(student: @student, observer: @observer)

    valid_attrs = [:title, :alert_type, :workflow_state, :action_date, :student, :observer]
    default_attrs = {
      title: 'value for type',
      alert_type: 'course_announcement',
      workflow_state: 'unread',
      action_date: Time.zone.now
    }

    attrs = default_attrs.deep_merge(opts.slice(*valid_attrs))

    if opts[:threshold_id]
      attrs[:observer_alert_threshold_id] = opts[:threshold_id]
    else
      @observer_alert_threshold = observer_alert_threshold_model(opts)
      attrs[:observer_alert_threshold_id] = @observer_alert_threshold.id
    end

    attrs[:context] = opts[:context] || nil

    @observer_alert = ObserverAlert.create(attrs)
  end
end
