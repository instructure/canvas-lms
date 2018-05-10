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
    if opts[:uol]
      @observation_link = opts[:uol]
    else
      @observee = opts[:observee] || course_with_student(opts).user
      @observer = opts[:observer] || user_model
      @observation_link = UserObservationLink.create!(user_id: @observee, observer_id: @observer)
    end

    valid_attrs = [:title, :alert_type, :workflow_state, :action_date]
    default_attrs = {
      title: 'value for type',
      alert_type: 'value for type',
      workflow_state: 'active',
      action_date: Time.zone.now
    }

    attrs = default_attrs.deep_merge(opts.slice(*valid_attrs))

    if opts[:oat_id]
      attrs[:observer_alert_threshold_id] = opts[:oat_id]
    else
      @observer_alert_threshold = observer_alert_threshold_model(opts)
      attrs[:observer_alert_threshold_id] = @observer_alert_threshold.id
    end

    attrs[:context] = opts[:context] || nil

    @observer_alert = @observation_link.observer_alerts.create(attrs)
  end
end
