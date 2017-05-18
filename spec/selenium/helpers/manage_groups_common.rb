#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../common')

module ManageGroupsCommon
  def add_category(course, name, opts={})
    f(".add_category_link").click
    wait_for_ajaximations
    form = f("#add_category_form")
    input = form.find_element(:css, "input[type=text]")
    replace_content input, name
    enable_self_signup = form.find_element(:css, "#category_enable_self_signup")
    enable_self_signup.click unless !!enable_self_signup.attribute('checked') == !!opts[:enable_self_signup]

    if opts[:enable_self_signup] && opts[:group_limit]
      replace_content f('#category_group_limit', form), opts[:group_limit]
    end

    restrict_self_signup = form.find_element(:css, "#category_restrict_self_signup")
    restrict_self_signup.click unless !!restrict_self_signup.attribute('checked') == !!opts[:restrict_self_signup]
    if opts[:group_count]
      if enable_self_signup.attribute('checked')
        replace_content form.find_element(:css, "#category_create_group_count"), opts[:group_count].to_s
      else
        form.find_element(:css, "#category_split_groups").click
        replace_content form.find_element(:css, "#category_split_group_count"), (opts[:group_count].to_s)
      end
    elsif enable_self_signup.attribute('checked')
      form.find_element(:css, "#category_create_group_count").clear
    else
      form.find_element(:css, "#category_no_groups").click
    end
    submit_dialog_form(form)
    expect(f("#add_category_form")).not_to be_displayed
    category = course.group_categories.where(name: name).first
    expect(category).not_to be_nil
    expect(fj("#category_#{category.id} .student_links:visible")).to be_displayed
    category
  end

  def groups_student_enrollment(student_count=3, opts={})
    students = []
    student_count.times do |i|
      count = i+1
      student = user_model :name => "student #{count}"
      students.push student
      if (!opts[count.to_s].nil?)
        @course.enroll_student(student, opts[count.to_s])
      else
        @course.enroll_student(student)
      end
    end
    students
  end

  def create_new_set_groups(context, *category_groups)
    category_groups.each_with_index { |cg, i| context.groups.create(:name => "Group #{i}", :group_category => cg) }
  end

  def create_categories(context, i=3)
    categories = []
    i.times { |j| categories.push context.group_categories.create(:name => "Group Category #{j}") }
    categories
  end

  def add_group_to_category(context, name)
    driver.execute_script("$('.add_group_link:visible').click()")
    wait_for_ajaximations
    replace_content(f("#group_name"), name)
    wait_for_ajaximations
    submit_form("#edit_group_form")
    wait_for_ajaximations
    context.groups.where(name: name).first
  end

  def add_groups_in_category (category, i=3)
    groups = []
    i.times { |j| groups.push category.context.groups.create(:name => "group #{j}", :group_category => category) }
    groups
  end

  def simulate_group_drag(user_id, from_group_id, to_group_id)
    from_group = (from_group_id == "blank" ? ".group_blank:visible" : "#group_#{from_group_id}")
    to_group = (to_group_id == "blank" ? ".group_blank:visible" : "#group_#{to_group_id}")
    driver.execute_script(<<-SCRIPT)
        window.contextGroups.moveToGroup(
          $('#{from_group} .user_id_#{user_id}'),
          $('#{to_group}'))
    SCRIPT
    sleep 1
  end

  def expand_group(group_id)
    group_selector = (group_id == "unassigned" ? ".unassigned-students" : ".group[data-id=\"#{group_id}\"]")
    return if group_selector == ".unassigned-students" || f(group_selector).attribute(:class) =~ /group-expanded/
    fj("#{group_selector} .toggle-group").click
    wait_for_ajax_requests
  end
end
