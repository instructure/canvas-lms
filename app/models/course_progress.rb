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

class CourseProgress
  include Rails.application.routes.url_helpers

  attr_accessor :course, :user

  def initialize(course, user)
    @course = course
    @user = user
  end

  def modules
    @_modules ||= course.modules_visible_to(user)
  end

  def current_module
    @_current_module ||= modules.detect { |m| m.evaluate_for(user).completed? == false }
  end

  def module_progressions
    @_module_progressions ||= user.context_module_progressions
                                  .where("context_module_id IN (?)", modules.map(&:id))
  end

  def current_position
    return unless in_progress?
    @current_position ||= current_module.evaluate_for(user).current_position
  end

  def current_content_tag
    return unless in_progress?
    current_module.content_tags_visible_to(user).where(:position => current_position).first
  end

  def requirements
    # e.g. [{id: 1, type: 'must_view'}, {id: 2, type: 'must_view'}]
    @_requirements ||= modules.flat_map { |m| m.completion_requirements_visible_to(@user) }.uniq
  end

  def requirement_count
    requirements.size
  end

  def has_requirements?
    requirement_count > 0
  end

  def requirements_completed
    # find the list of requirements that have been recorded as met for this module, then
    # select only those requirements that are current, and filter out any duplicates
    @_requirements_completed ||= module_progressions.flat_map { |cmp| cmp.requirements_met }
                                                    .select { |req| requirements.include?(req) }
                                                    .uniq
  end

  def requirement_completed_count
    requirements_completed.size
  end

  def current_requirement_url
    return unless in_progress? && current_content_tag
    course_context_modules_item_redirect_url(:course_id => course.id,
                                             :id => current_content_tag.id,
                                             :host => HostUrl.context_host(course))
  end

  def in_progress?
    current_module && current_module.require_sequential_progress
  end

  def completed?
    has_requirements? && requirement_completed_count >= requirement_count
  end

  def most_recent_module_completed_at
    return unless module_progressions
    module_progressions.maximum(:completed_at)
  end

  def completed_at
    return unless completed?
    most_recent_module_completed_at.utc.iso8601 rescue nil
  end

  def to_json
    if course.module_based? && course.user_is_student?(user)
      {
        requirement_count: requirement_count,
        requirement_completed_count: requirement_completed_count,
        next_requirement_url: current_requirement_url,
        completed_at: completed_at
      }
    else
      { error:
          { message: 'no progress available because this course is not module based (has modules and module completion requirements) or the user is not enrolled as a student in this course' }
      }
    end
  end
end
