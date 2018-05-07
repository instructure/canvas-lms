#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe "new account course search" do
  include_context "in-process server selenium tests"

  before :once do
    account_model
    account_admin_user(:account => @account, :active_all => true)
  end

  before do
    user_session(@user)
  end

  def get_rows
    ff('[data-automation="courses list"] tr')
  end

  def wait_for_loading_to_disappear
    expect(f('[data-automation="courses list"]')).not_to contain_css('tr:nth-child(2)') #wait for ajax
  end


  it "should not show the courses tab without permission" do
    @account.role_overrides.create! :role => admin_role, :permission => 'read_course_list', :enabled => false

    get "/accounts/#{@account.id}"
    expect(f("#left-side #section-tabs")).not_to include_text("Courses")
  end

  it "should hide courses without enrollments if checked", test_id: 3454769, priority: 1 do
    empty_course = course_factory(:account => @account, :course_name => "no enrollments")
    not_empty_course = course_factory(:account => @account, :course_name => "yess enrollments", :active_all => true)
    student_in_course(:course => not_empty_course, :active_all => true)

    get "/accounts/#{@account.id}"

    rows = get_rows
    expect(rows.count).to eq 2
    expect(rows[0]).to include_text(empty_course.name)
    expect(rows[1]).to include_text(not_empty_course.name)

    fj('label:contains("Hide courses without students")').click
    wait_for_loading_to_disappear

    rows = get_rows
    expect(rows.count).to eq 1
    expect(rows[0]).to include_text(not_empty_course.name)
    expect(rows[0]).not_to include_text(empty_course.name)
  end

  it "should paginate", test_id: 3454771, priority: 1 do
    16.times { |i| @account.courses.create!(:name => "course #{i + 1}") }

    get "/accounts/#{@account.id}"

    expect(get_rows.count).to eq 15
    expect(get_rows.first).to include_text("course 1")
    expect(f('[data-automation="courses list"]')).not_to include_text("course 16")
    expect(f("#content")).not_to contain_css('button[title="Previous Page"]')

    fj('nav button:contains("2")').click
    wait_for_ajaximations

    expect(get_rows.count).to eq 1
    expect(get_rows.first).to include_text("course 16")
  end

  it "should search by term", test_id: 3454772, priority: 1 do
    term = @account.enrollment_terms.create!(:name => "some term")
    term_course = course_factory(:account => @account, :course_name => "term course_factory")
    term_course.enrollment_term = term
    term_course.save!

    other_course = course_factory(:account => @account, :course_name => "other course_factory")

    get "/accounts/#{@account.id}"

    click_option('select:has([label="Show courses from"])', term.name)
    wait_for_loading_to_disappear

    rows = get_rows
    expect(rows.count).to eq 1
    expect(rows.first).to include_text(term_course.name)
  end

  it "should search by name" do
    match_course = course_factory(:account => @account, :course_name => "course_factory with a search term")
    not_match_course = course_factory(:account => @account, :course_name => "diffrient cuorse")

    get "/accounts/#{@account.id}"

    f('input[placeholder="Search courses..."]').send_keys('search')
    wait_for_loading_to_disappear

    rows = get_rows
    expect(rows.count).to eq 1
    expect(rows.first).to include_text(match_course.name)
  end

  it "should bring up course page when clicking name", priority: "1", test_id: 3415212 do
    named_course = course_factory(:account => @account, :course_name => "named_course")
    named_course.default_view = 'feed'
    named_course.save
    get "/accounts/#{@account.id}"

    fj("[data-automation='courses list'] tr a:contains(#{named_course.name})").click
    wait_for_ajax_requests
    expect(f("#content h2")).to include_text named_course.name
  end

  it "should search but not find bogus course", priority: "1", test_id: 3415214 do
    bogus = 'jtsdumbthing'
    get "/accounts/#{@account.id}"

    f('input[placeholder="Search courses..."]').send_keys(bogus)

    expect(f("#content")).not_to contain_css("[data-automation='courses list'] tr")
  end

  it "should show teachers" do
    course_factory(:account => @account)
    user_factory(:name => "some teacher")
    teacher_in_course(:course => @course, :user => @user)

    get "/accounts/#{@account.id}"

    user_link = get_rows.first.find("a[href='#{user_url(@user)}']")
    expect(user_link).to include_text(@user.name)
  end

  it "should show manageable roles in new enrollment dialog" do
    custom_name = 'Custom Student role'
    role = custom_student_role(custom_name, :account => @account)

    @account.role_overrides.create!(:permission => "manage_admin_users", :enabled => false, :role => admin_role)
    course_factory(:account => @account)

    get "/accounts/#{@account.id}"

    el = get_rows.first.find('[name="IconPlus"]')
    move_to_click_element(el)

    dialog = fj('#add_people_modal:visible')
    expect(dialog).to be_displayed
    role_options = dialog.find_elements(:css, '#peoplesearch_select_role option')
    expect(role_options.map{|r| r.text}).to match_array(["Student", "Observer", custom_name])
  end

  it "should load sections in new enrollment dialog" do
    course = course_factory(:account => @account)
    get "/accounts/#{@account.id}"

    # doing this after the page loads to ensure that the frontend loads them dynamically
    # when the "+ users" is clicked and not as part of the page load
    sections = ('A'..'Z').map { |i| course.course_sections.create!(:name => "Test Section #{i}") }

    el = get_rows.first.find('[name="IconPlus"]')
    move_to_click_element(el)
    section_options = ffj('#add_people_modal:visible #peoplesearch_select_section option')
    expect(section_options.map(&:text)).to eq(sections.map(&:name))
  end

  it "should create a new course from the 'Add a New Course' dialog", test_id: 3454775, priority: 1 do
    @account.enrollment_terms.create!(:name => "Test Enrollment Term")
    subaccount = @account.sub_accounts.create!(name: "Test Sub Account")

    get "/accounts/#{@account.id}"

    # fill out the form
    fj('button:has([name="IconPlus"]):contains("Course")').click
    dialog = f('[aria-label="Add a New Course"]')
    expect(dialog).to be_displayed
    set_value(fj('label:contains("Course Name") input', dialog), 'Test Course Name')
    set_value(fj('label:contains("Reference Code") input', dialog), 'TCN 101')
    click_option('[aria-label="Add a New Course"] label:contains("Subaccount") select', subaccount.to_param, :value)
    click_option('[aria-label="Add a New Course"] label:contains("Enrollment Term") select', "Test Enrollment Term")
    submit_form(dialog)

    # make sure it got saved to db correctly
    new_course = Course.last
    expect(new_course.name).to eq('Test Course Name')
    expect(new_course.course_code).to eq('TCN 101')
    expect(new_course.account.name).to eq('Test Sub Account')
    expect(new_course.enrollment_term.name).to eq('Test Enrollment Term')

    # make sure it shows up on the page
    expect(get_rows.first).to include_text('Test Course Name')
  end

  it "should list course name at top of add user modal", priority: "1", test_id: 3391719 do
    named_course = course_factory(:account => @account, :course_name => "course factory with name")

    get "/accounts/#{@account.id}"
    el = get_rows.first.find('[name="IconPlus"]')
    move_to_click_element(el)
    expect(f('#add_people_modal h2')).to include_text(named_course.name)
  end
end
