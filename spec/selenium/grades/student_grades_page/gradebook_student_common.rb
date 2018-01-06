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

require_relative '../../common'
require_relative '../../helpers/shared_examples_common'

shared_examples 'Arrange By dropdown' do |context|
  include SharedExamplesCommon

  before :each do
    enroll_context(context)
    get "/courses/#{@course.id}/grades/#{@student.id}"
  end

  let(:due_date_order) {[@assignment0.title, @quiz.title, @discussion.title, @assignment1.title]}
  let(:title_order) {[@quiz.title, @assignment1.title, @assignment0.title, @discussion.title]}
  let(:module_order) {[@quiz.title, @assignment0.title, @assignment1.title, @discussion.title]}
  let(:assign_group_order) {[@assignment0.title, @discussion.title, @quiz.title, @assignment1.title]}

  it 'should persist', test_id: pick_test_id(context, student: "591860", teacher: "592108", admin: "592119", ta: "592130"), priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    click_option('#assignment_sort_order_select_menu', 'Title')
    expect_new_page_load { f('#apply_select_menus').click }
    get "/courses/#{@course.id}"
    get "/courses/#{@course.id}/grades/#{@student.id}"

    table_rows = ff('#grades_summary tr')
    title_order.each_with_index do |assign_name, index|
      expect(table_rows[4 * index + 1].find_element(:css, 'th')).to include_text assign_name
    end
  end

  it 'should exist with one course', test_id: pick_test_id(context, student: "591850", teacher: "592109", admin: "592120", ta: "592131"), priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    expect(f('#assignment_sort_order_select_menu')).to be_present
  end

  it 'should exist with more than one course', test_id: pick_test_id(context, student: "591851", teacher: "592110", admin: "592121", ta: "592132"), priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    course2 = Course.create!(name: 'Second Course')
    course2.offer!
    course2.enroll_student(@student).accept!

    get "/courses/#{@course.id}/grades/#{@student.id}"

    expect(f('#assignment_sort_order_select_menu')).to be_present
  end

  it 'should contain Title', test_id: pick_test_id(context, student: "591852", teacher: "592111", admin: "592122", ta: "592133"), priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    f('#assignment_sort_order_select_menu').click
    expect(f("#assignment_sort_order_select_menu option[value=\"title\"]")).to be_present
  end

  it 'should contain Due Date', test_id: pick_test_id(context, student: "591853", teacher: "592112", admin: "592123", ta: "592134"), priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    f('#assignment_sort_order_select_menu').click
    expect(f("#assignment_sort_order_select_menu option[value=\"due_at\"]")).to be_present
  end

  it 'should contain Module', test_id: pick_test_id(context, student: "591854", teacher: "592113", admin: "592124", ta: "592135"), priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    f('#assignment_sort_order_select_menu').click
    expect(f("#assignment_sort_order_select_menu option[value=\"module\"]")).to be_present
  end

  it 'should contain Assignment Group', test_id: pick_test_id(context, student: "591855", teacher: "592114", admin: "592125", ta: "592136"), priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    f('#assignment_sort_order_select_menu').click
    expect(f("#assignment_sort_order_select_menu option[value=\"assignment_group\"]")).to be_present
  end

  it 'should sort by Title', test_id: pick_test_id(context, student: "591856", teacher: "592115", admin: "592126", ta: "592137"), priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    click_option('#assignment_sort_order_select_menu', 'Title')
    expect_new_page_load { f('#apply_select_menus').click }

    table_rows = ff('#grades_summary tr')
    title_order.each_with_index do |assign_name, index|
      expect(table_rows[4 * index + 1].find_element(:css, 'th')).to include_text assign_name
    end
  end

  it 'should sort by Due Date', test_id: pick_test_id(context, student: "591857", teacher: "592116", admin: "592127", ta: "592138"), priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    click_option('#assignment_sort_order_select_menu', 'Due Date')

    table_rows = ff('#grades_summary tr')
    due_date_order.each_with_index do |assign_name, index|
      expect(table_rows[4 * index + 1].find_element(:css, 'th')).to include_text assign_name
    end
  end

  it 'should sort by Module', test_id: pick_test_id(context, student: "591858", teacher: "592117", admin: "592128", ta: "592139"), priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    click_option('#assignment_sort_order_select_menu', 'Module')
    expect_new_page_load { f('#apply_select_menus').click }

    table_rows = ff('#grades_summary tr')
    module_order.each_with_index do |assign_name, index|
      expect(table_rows[4 * index + 1].find_element(:css, 'th')).to include_text assign_name
    end
  end

  it 'should sort by Assignment Group', test_id: pick_test_id(context, student: "591859", teacher: "592118", admin: "592129", ta: "592140"), priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    click_option('#assignment_sort_order_select_menu', 'Assignment Group')
    expect_new_page_load { f('#apply_select_menus').click }
    table_rows = ff('#grades_summary tr')

    assign_group_order.each_with_index do |assign_name, index|
      expect(table_rows[4 * index + 1].find_element(:css, 'th')).to include_text assign_name
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
      raise('Error: Invalid context')
    end
  end
end
