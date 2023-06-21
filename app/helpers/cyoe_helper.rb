# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

module CyoeHelper
  def cyoe_able?(item)
    case item.content_type
    when "Assignment"
      item.graded? && item.content.graded?
    when "Quizzes::Quiz"
      item.graded? && item.content.assignment?
    else
      item.graded?
    end
  end

  def cyoe_enabled?(context)
    ConditionalRelease::Service.enabled_in_context?(context)
  end

  def cyoe_rules(context, current_user, session)
    ConditionalRelease::Service.rules_for(context, current_user, session)
  end

  def conditional_release_rule_for_module_item(content_tag, opts = {})
    rules = opts[:conditional_release_rules] || cyoe_rules(opts[:context], opts[:user], opts[:session])
    assignment_id = content_tag.assignment.try(:id)
    path_data = conditional_release_assignment_set(rules, assignment_id) if rules.present? && assignment_id.present?
    if path_data.present? && opts[:is_student]
      path_data[:is_student] = true
      build_path_data(path_data, content_tag.id.to_s)
      check_if_processing(path_data)
    end
    path_data
  end

  def conditional_release_assignment_set(rules, id)
    result = rules.find { |rule| rule[:trigger_assignment].to_s == id.to_s || rule[:trigger_assignment_id] == id }
    return if result.blank?

    result.slice(:locked, :assignment_sets, :selected_set_id)
  end

  def assignment_set_action_ids(rules, user)
    ConditionalRelease::AssignmentSetAction
      .active
      .where(student_id: user)
      .where(assignment_set_id: rules.map { |rule| rule[:assignment_sets].pluck(:id) }.flatten.uniq)
      .pluck(:id)
  end

  def conditional_release_json(content_tag, user, opts = {})
    result = conditional_release_rule_for_module_item(content_tag, opts)
    return if result.blank?

    result[:assignment_sets].each do |as|
      associations = as[:assignment_set_associations]
      next if associations.blank?

      associations.each do |a|
        a[:model] = assignment_json(a[:model], user, nil) if a[:model]
      end
    end
    result
  end

  def show_cyoe_placeholder(mastery_paths)
    (mastery_paths[:selected_set_id].nil? && mastery_paths[:assignment_sets].present?) ||
      mastery_paths[:awaiting_choice] ||
      mastery_paths[:still_processing] ||
      mastery_paths[:locked]
  end

  private

  def check_if_processing(data)
    if !data[:awaiting_choice] && data[:assignment_sets].length == 1
      set = data[:assignment_sets][0]
      data[:still_processing] = !ConditionalRelease::AssignmentSetAction.where(assignment_set_id: set[:id], student_id: @current_user.id).exists?
    end
  end

  def build_path_data(data, tag_id)
    awaiting_choice = data[:selected_set_id].nil? && data[:assignment_sets].present?
    modules_url = context_url(@context, :context_url) + "/modules"
    choose_url = modules_url + "/items/" + tag_id + "/choose"
    modules_disabled = @context.tabs_available(@current_user).select { |tabs| tabs[:label] == "Modules" }.blank?
    data.merge!({
                  awaiting_choice:,
                  modules_url:,
                  choose_url:,
                  modules_tab_disabled: modules_disabled
                })
  end
end
