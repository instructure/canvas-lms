#
# Copyright (C) 2012 - 2015 Instructure, Inc.
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

class MarkDonePresenter

  def initialize(ctrl, context, content, user)
    @ctrl = ctrl
    @context = context
    @content = content
    @item = _find_item
    @module = @item.context_module if @item
    @user = user
  end

  def _find_item
    return nil unless @context.respond_to? :context_modules
    @context.context_modules.map do |modules|
      modules.content_tags.find do |tag|
        tag.content_id == @content.id && tag.content_type == @content.class.name
      end
    end.find(&:present?)
  end

  def has_requirement?
    return false unless @module
    requirements = @module.completion_requirements
    requirement = requirements.find {|i| i[:id] == @item.id}
    return false unless requirement
    requirement[:type] == 'must_mark_done'
  end

  def checked?
    return false unless has_requirement?
    progression = @module.context_module_progressions.find{|p| p[:user_id] == @user.id}
    return false unless progression
    !!progression.requirements_met.find {|r| r[:id] == @item.id && r[:type] == "must_mark_done" }
  end

  def api_url
    @ctrl.api_v1_course_context_module_item_done_path(:course_id => @context.id,
                                                      :module_id => @item.context_module_id,
                                                      :id => @item.id)
  end
end
