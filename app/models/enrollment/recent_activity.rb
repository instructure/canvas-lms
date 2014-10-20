#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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


class Enrollment
  class RecentActivity
    attr_reader :context, :enrollment

    def initialize(enrollment, context = nil, settings = Setting)
      @context = context || enrollment.try(:context)
      @enrollment = enrollment
      @settings = settings
    end

    def record_for_access(response)
      return if response.response_code.to_s =~ /^((4|5)\d{2})$/
      if context.is_a?(Course) && enrollment
        record!
      end
    end

    def record!(as_of = Time.zone.now)
      return unless record_worthwhile?(as_of, last_threshold)
      if increment_total_activity?(as_of)
        enrollment.total_activity_time= total_activity_interval(as_of)
        update_with(total_activity_time: total_activity_time, last_activity_at: as_of)
      else
        update_with(last_activity_at: as_of)
      end
      enrollment.last_activity_at = as_of
    end

    private
    def total_activity_interval(as_of)
      total_activity_time + (as_of - last_activity_at).to_i
    end

    def update_with(options)
      enrollment.class.where(id: enrollment).update_all(options)
    end

    def increment_total_activity?(as_of)
      !last_activity_at.nil? &&
        (as_of - last_activity_at >= last_threshold) &&
        (as_of - last_activity_at < total_threshold)
    end

    def last_threshold
      @_last_threshold ||= @settings.
        get('enrollment_last_activity_at_threshold', 2.minutes).to_i
    end

    def total_threshold
      @_total_threshold ||= @settings.
        get('enrollment_total_activity_time_threshold', 10.minutes).to_i
    end

    def record_worthwhile?(as_of, threshold)
      last_activity_at.nil? || (as_of - last_activity_at >= threshold)
    end

    def last_activity_at
      enrollment.last_activity_at
    end

    def total_activity_time
      enrollment.total_activity_time
    end

  end
end
