# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

  attr_accessor :course, :user, :read_only

  # use read_only to avoid triggering more progression evaluations
  def initialize(course, user, read_only: false, preloaded_progressions: nil)
    @course = course
    @user = user
    @read_only = read_only
    @preloaded_progressions = preloaded_progressions
  end

  def modules
    @_modules ||= begin
      result = course.modules_visible_to(user)
      ActiveRecord::Associations.preload(result, :content_tags)
      result
    end
  end

  def current_module
    @_current_module ||= if read_only
                           begin
                             progressions_by_mod_id = module_progressions.index_by(&:context_module_id)
                             modules.detect do |m|
                               prog = progressions_by_mod_id[m.id]
                               prog.nil? || prog.completed? == false
                             end
                           end
                         else
                           modules.detect { |m| m.evaluate_for(user).completed? == false }
                         end
  end

  def module_progressions
    @_module_progressions ||= if @preloaded_progressions
                                module_ids = modules.pluck(:id)
                                @preloaded_progressions[course.id]&.select { |cmp| module_ids.include?(cmp.context_module_id) } ||
                                  ContextModuleProgression.none
                              else
                                course.context_module_progressions
                                      .where(user_id: user, context_module_id: modules)
                              end
  end

  def current_position
    return unless in_progress?

    if read_only
      @current_positions ||= begin
        prog = module_progressions.detect { |p| p.context_module_id == current_module.id }
        prog&.current_position
      end
    else
      @current_position ||= current_module.evaluate_for(user).current_position
    end
  end

  def current_content_tag
    return unless in_progress?

    @current_content_tag ||= begin
      tags = current_module.content_tags.select { |ct| ct.position == current_position }
      if tags.any?
        opts = current_module.visibility_for_user(user)
        tags.detect { |tag| tag.visible_to_user?(user, opts) }
      else
        nil
      end
    end
  end

  def requirements
    # e.g. [{id: 1, type: 'must_view'}, {id: 2, type: 'must_view'}]
    @_requirements ||= modules.flat_map { |m| module_requirements(m) }.uniq
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
    @_requirements_completed ||= module_progressions.flat_map { |cmp| module_requirements_completed(cmp) }.uniq
  end

  def requirement_completed_count
    requirements_completed.size
  end

  def current_requirement_url
    return unless in_progress? && current_content_tag

    course_context_modules_item_redirect_url(course_id: course.id,
                                             id: current_content_tag.id,
                                             host: HostUrl.context_host(course))
  end

  def in_progress?
    current_module&.require_sequential_progress
  end

  def completed?
    has_requirements? && module_progressions.all? { |prog| module_completed?(prog) }
  end

  def most_recent_module_completed_at
    return unless module_progressions

    if module_progressions.is_a? Array
      module_progressions.filter_map(&:completed_at).max
    else
      module_progressions.maximum(:completed_at)
    end
  end

  def completed_at
    return unless completed?

    most_recent_module_completed_at&.utc&.iso8601
  end

  def to_json(*)
    if course.module_based? && course.user_is_student?(user, include_all: true)
      {
        requirement_count:,
        requirement_completed_count:,
        next_requirement_url: current_requirement_url,
        completed_at:
      }
    else
      { error:
        { message: "no progress available because this course is not module based (has modules and module completion requirements) or the user is not enrolled as a student in this course" } }
    end
  end

  def self.dispatch_live_event(context_module_progression)
    if CourseProgress.new(context_module_progression.context_module.course, context_module_progression.user, read_only: true).completed?
      Canvas::LiveEvents.course_completed(context_module_progression)
    else
      Canvas::LiveEvents.course_progress(context_module_progression)
    end
  end

  private

  def module_requirements(mod)
    @_module_requirements ||= {}
    @_module_requirements[mod.id] ||= mod.completion_requirements_visible_to(@user, is_teacher: false)
  end

  def module_requirements_completed(progression)
    @_module_requirements_completed ||= {}
    @_module_requirements_completed[progression.id] ||= progression.requirements_met.select { |req| module_requirements(progression.context_module).include?(req) }.uniq
  end

  def module_reqs_to_complete_count(mod)
    visible_req_count = module_requirements(mod).count
    if visible_req_count > 0
      # this will account for modules that only need to complete one item
      mod.requirement_count || visible_req_count
    else
      # if the user can't see any requirements then they aren't required to do anything even if the module ostensibly requires 1 to complete
      0
    end
  end

  def module_completed?(progression)
    module_requirements_completed(progression).count >= module_reqs_to_complete_count(progression.context_module)
  end
end
