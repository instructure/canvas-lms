# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

class CoursePacing::PaceServiceInterface
  def self.paces_in_course(course)
    raise NotImplementedError
  end

  def self.pace_for(context, should_duplicate: false)
    return nil unless valid_context?(context)

    pace_in_context(context)
  rescue ActiveRecord::RecordNotFound
    template = template_pace_for(context) || raise(ActiveRecord::RecordNotFound)
    should_duplicate ? template.duplicate(create_params(context)) : template
  end

  def self.pace_in_context(context)
    raise NotImplementedError
  end

  def self.template_pace_for(context)
    raise NotImplementedError
  end

  def self.valid_context?(_context)
    true
  end

  def self.create_in_context(context)
    return nil unless valid_context?(context)

    pace = context.course_paces.not_deleted.take
    if pace.nil?
      course = course_for(context)
      template_pace = course.course_paces.primary.published.take
      if template_pace
        pace = template_pace.duplicate(create_params(context))
      else
        pace = course.course_paces.new(create_params(context))
        course.context_module_tags.can_have_assignment.not_deleted.each do |module_item|
          pace.course_pace_module_items.create(module_item: module_item, duration: 0)
        end
      end
      if pace.save
        pace.create_publish_progress(run_at: Time.now)
      end
    end

    pace
  end

  def self.update_pace(pace, update_params)
    if pace.update(update_params)
      pace.create_publish_progress(run_at: Time.now)
      # Force the updated_at to be updated, because if the update just changed the items the course pace's
      # updated_at doesn't get modified
      pace.touch
      pace
    else
      false
    end
  end

  def self.progress(pace, publish: true)
    progress = Progress.order(created_at: :desc).find_by(context: pace, tag: "course_pace_publish")

    if (publish && !progress) || (progress.queued? && progress.delayed_job.blank?)
      progress = pace.create_publish_progress(run_at: Time.now)
    elsif progress.queued? && progress.delayed_job.present?
      progress.delayed_job.update(run_at: Time.now)
    end

    progress
  end

  def self.delete_in_context(context)
    pace_in_context(context).destroy!
  end

  def self.create_params(_context)
    { workflow_state: "unpublished" }
  end

  def self.course_for(context)
    raise NotImplementedError
  end
end
