# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class DifferentiationTag::Jobs::Workers::TagOverrideConverterWorker
  def self.start_job(course)
    progress = Progress.create!(context: course, tag: DifferentiationTag::DELAYED_JOB_TAG)
    progress.process_job(self, :perform, { max_attempts: 3, preserve_method_args: true }, course)
  end

  def self.perform(course)
    @job_progress = Progress.find_by(context_type: "Course", context_id: course.id, tag: "convert_tag_overrides_to_adhoc_overrides", workflow_state: ["queued", "running"])
    raise "No job progress found for course #{course.id}" unless @job_progress

    learning_objects = learning_objects_with_tag_overrides_in_course(course)

    @num_learning_objects_to_convert = learning_objects.length
    @num_learning_objects_converted = 0

    @job_progress.update!(workflow_state: "running", completion: 0)

    learning_objects.each_slice(25) do |learning_objects_slice|
      convert_tags(course, learning_objects_slice)

      # Update progress in the job
      conversion_progress = ((@num_learning_objects_converted.to_f / @num_learning_objects_to_convert) * 100).round
      @job_progress.update!(completion: conversion_progress)
    end

    @job_progress.update!(workflow_state: "completed", completion: 100)
  end

  def self.convert_tags(course, learning_objects)
    learning_objects.each do |learning_object|
      concrete_object = get_concrete_learning_object(learning_object)
      next unless concrete_object

      errors = DifferentiationTag::OverrideConverterService.convert_tags_to_adhoc_overrides_for(
        learning_object: concrete_object,
        course:
      )

      if errors.present?
        error = "Failed to convert tags for learning object #{concrete_object.id}: #{errors.join(", ")}"
        @job_progress.update!(workflow_state: "failed")

        # updated the delayed job if it exists
        @job_progress.delayed_job&.update!(last_error: error)

        raise DifferentiationTag::DifferentiationTagServiceError, error
      end

      @num_learning_objects_converted += 1
    end
  end

  def self.get_concrete_learning_object(learning_object)
    if learning_object.assignment_id.present?
      Assignment.where(id: learning_object.assignment_id).first
    elsif learning_object.quiz_id.present?
      Quizzes::Quiz.where(id: learning_object.quiz_id).first
    elsif learning_object.discussion_topic_id.present?
      DiscussionTopic.where(id: learning_object.discussion_topic_id).first
    elsif learning_object.wiki_page_id.present?
      WikiPage.where(id: learning_object.wiki_page_id).first
    elsif learning_object.context_module_id.present?
      ContextModule.where(id: learning_object.context_module_id).first
    else
      nil
    end
  end

  def self.learning_objects_with_tag_overrides_in_course(course)
    AssignmentOverride.joins(:group)
                      .where(groups: { context: course, non_collaborative: true })
                      .distinct
                      .select(:assignment_id, :quiz_id, :discussion_topic_id, :wiki_page_id, :context_module_id)
  end
end
