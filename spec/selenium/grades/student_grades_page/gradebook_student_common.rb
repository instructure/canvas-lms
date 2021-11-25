# frozen_string_literal: true

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

require_relative "../../common"
require_relative "../../helpers/shared_examples_common"

shared_examples "Arrange By dropdown" do |context|
  include SharedExamplesCommon

  before do
    enroll_context(context)
    get "/courses/#{@course.id}/grades/#{@student.id}"
  end

  let(:due_date_order) { [@assignment0.title, @quiz.title, @discussion.title, @assignment1.title] }
  let(:title_order) { [@quiz.title, @assignment1.title, @assignment0.title, @discussion.title] }
  let(:module_order) { [@quiz.title, @assignment0.title, @assignment1.title, @discussion.title] }
  let(:assign_group_order) { [@assignment0.title, @discussion.title, @quiz.title, @assignment1.title] }

  it "persists", priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    click_option("#assignment_sort_order_select_menu", "Name")
    expect_new_page_load { f("#apply_select_menus").click }
    get "/courses/#{@course.id}"
    get "/courses/#{@course.id}/grades/#{@student.id}"

    table_rows = ff("#grades_summary tr")
    title_order.each_with_index do |assign_name, index|
      expect(table_rows[(4 * index) + 1].find_element(:css, "th")).to include_text assign_name
    end
  end

  it "exists with one course", priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    expect(f("#assignment_sort_order_select_menu")).to be_present
  end

  it "exists with more than one course", priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    course2 = Course.create!(name: "Second Course")
    course2.offer!
    course2.enroll_student(@student).accept!

    get "/courses/#{@course.id}/grades/#{@student.id}"

    expect(f("#assignment_sort_order_select_menu")).to be_present
  end

  it "contains Title", priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    expect(option_values).to include "title"
  end

  it "contains Due Date", priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    expect(option_values).to include "due_at"
  end

  it "contains Module", priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    expect(option_values).to include "module"
  end

  it "contains Assignment Group", priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    expect(option_values).to include "assignment_group"
  end

  it "sorts by Name", priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    click_option("#assignment_sort_order_select_menu", "Name")
    expect_new_page_load { f("#apply_select_menus").click }

    table_rows = ff("#grades_summary tr")
    title_order.each_with_index do |assign_name, index|
      expect(table_rows[(4 * index) + 1].find_element(:css, "th")).to include_text assign_name
    end
  end

  it "sorts by Due Date", priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    click_option("#assignment_sort_order_select_menu", "Due Date")

    table_rows = ff("#grades_summary tr")
    due_date_order.each_with_index do |assign_name, index|
      expect(table_rows[(4 * index) + 1].find_element(:css, "th")).to include_text assign_name
    end
  end

  it "sorts by Module", priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    click_option("#assignment_sort_order_select_menu", "Module")
    expect_new_page_load { f("#apply_select_menus").click }

    table_rows = ff("#grades_summary tr")
    module_order.each_with_index do |assign_name, index|
      expect(table_rows[(4 * index) + 1].find_element(:css, "th")).to include_text assign_name
    end
  end

  it "sorts by Assignment Group", priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    click_option("#assignment_sort_order_select_menu", "Assignment Group")
    expect_new_page_load { f("#apply_select_menus").click }
    table_rows = ff("#grades_summary tr")

    assign_group_order.each_with_index do |assign_name, index|
      expect(table_rows[(4 * index) + 1].find_element(:css, "th")).to include_text assign_name
    end
  end

  def enroll_context(context)
    case context
    when :student
      user_session(@student)
    when :teacher
      @teacher = User.create!(name: "Teacher")
      @course.enroll_teacher(@teacher).accept!
      user_session(@teacher)
    when :admin
      admin_logged_in
    when :ta
      @ta = User.create!(name: "TA")
      @course.enroll_ta(@ta).accept!
      user_session(@ta)
    else
      raise("Error: Invalid context")
    end
  end

  def option_values
    INSTUI_Select_options("#assignment_sort_order_select_menu").map { |o| o.attribute("value") }
  end
end
