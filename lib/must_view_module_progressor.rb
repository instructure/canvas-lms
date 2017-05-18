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
#

class MustViewModuleProgressor
  def initialize(user, course)
    @user = user
    @course = course
  end
  attr_reader :user, :course

  def modules
    course.context_modules
  end

  def make_progress
    modules.each do |mod|
      mod.evaluate_for(user)
      if mod.require_sequential_progress
        progress_sequential_module(mod)
      else
        progress_random_access_module(mod)
      end
    end
  end

  def current_progress
    progress = {}
    modules.each do |mod|
      progress[mod.id] =
        if (progression = mod.find_or_create_progression(user)&.evaluate)
          { status: progression.workflow_state }
        elsif mod.grants_right?(user, :read)
          { status: 'unlocked' }
        else
          { status: 'locked' }
        end
      progress[mod.id][:items] = items_current_progress(mod, progression)
    end
    progress
  end

  private

  def always_skippable?(item)
    return true unless item.visible_to_user?(user)

    progression = item.context_module.find_or_create_progression(user)
    # unenrolled users don't have progressions and can always skip
    return true if progression.nil?
    return true if progression.finished_item?(item)

    content = item.content
    return true if content.respond_to?(:published?) && !content.published?

    false
  end

  def random_access_should_skip?(item)
    always_skippable?(item) || sequential_access_should_stop?(item)
  end

  def sequential_access_should_stop?(item)
    content = item.content
    return true if content.respond_to?(:locked_for?) && content.locked_for?(user, deep_check_if_needed: true)
    return true unless item.context_module.completion_requirement_for(:read, item)
    false
  end

  def progress_random_access_module(mod)
    items = mod.content_tags
    items.each do |item|
       next if random_access_should_skip?(item)
       progress_item(item)
    end
  end

  def progress_sequential_module(mod)
    mod.content_tags.each do |item|
      next if always_skippable?(item)
      break if sequential_access_should_stop?(item)
      progress_item(item)
    end
  end

  def progress_item(item)
    item.context_module_action(user, :read)
  end

  def items_current_progress(mod, progression)
    progress = {}
    mod.content_tags.each do |item|
      progress[item.id] = (progression&.finished_item?(item) || false)
    end
    progress
  end

end
