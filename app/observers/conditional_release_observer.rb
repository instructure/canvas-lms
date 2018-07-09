#
# Copyright (C) 2016 - present Instructure, Inc.
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

class ConditionalReleaseObserver < ActiveRecord::Observer
  observe :submission,
          :assignment

  def after_update(record)
    clear_caches_for record
  end

  def after_create(record)
    clear_caches_for record
  end

  def after_save(record)
  end

  def after_destroy(record)
    clear_caches_for record
  end

  private
  def clear_caches_for(record)
    case record
    when Submission
      ConditionalRelease::Service.clear_submissions_cache_for(record.global_user_id)
      ConditionalRelease::Service.clear_rules_cache_for(record.assignment&.global_context_id, record.global_user_id)
    when Assignment
      ConditionalRelease::Service.clear_active_rules_cache(record.context)
      ConditionalRelease::Service.clear_applied_rules_cache(record.context)
    end
  end
end
