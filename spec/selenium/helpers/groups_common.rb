require File.expand_path(File.dirname(__FILE__) + '/../common')

# ======================================================================================================================
# Shared Examples
# ======================================================================================================================
shared_examples 'home_page' do |context|
  it "should display a coming up section with relevant events", priority: pick_priority(context,"1","2"), test_id: pick_test_id(context, 273602, 319909) do
    # Create an event to have something in the Coming up Section
    event = @testgroup[0].calendar_events.create!(title: "ohai",
                                                  start_at: Time.zone.now + 1.day)
    get url

    expect('.coming_up').to be_present
    expect(ff('.calendar.tooltip').size).to eq 1
    expect(f('.calendar.tooltip b')).to include_text("#{event.title}")
  end

  it "should display a view calendar link on the group home page", priority: pick_priority(context,"1","2"), test_id: pick_test_id(context, 273603, 319910) do
    get url
    expect(f('.event-list-view-calendar')).to be_displayed
  end

  it "should have a working link to add an announcement from the group home page", priority: pick_priority(context,"1","2"), test_id: pick_test_id(context, 273604, 319911) do
    get url
    expect_new_page_load { fln('New Announcement').click }
    expect(f('.btn-primary')).to be_displayed
  end

  it "should display recent activity feed on the group home page", priority: pick_priority(context,"1","2"), test_id: pick_test_id(context, 273605, 319912) do
    DiscussionTopic.create!(context: @testgroup.first, user: @teacher,
                            title: 'Discussion Topic', message: 'test')
    @testgroup.first.announcements.create!(title: 'Test Announcement', message: 'Message',user: @teacher)

    get url
    expect(f('.recent-activity-header')).to be_displayed
    activity = ff('.stream_header .title')
    expect(activity.size).to eq 2
    expect(activity[0]).to include_text('1 Announcement')
    expect(activity[1]).to include_text('1 Discussion')
  end

  it "should display announcements on the group home page feed", priority: pick_priority(context,"1","2"), test_id: pick_test_id(context, 273609, 319913) do
    @testgroup.first.announcements.create!(title: 'Test Announcement', message: 'Message',user: @teacher)
    get url
    expect(f('.title')).to include_text('1 Announcement')
    f('.toggle-details').click
    expect(f('.content_summary')).to include_text('Test Announcement')
  end
end

#-----------------------------------------------------------------------------------------------------------------------
shared_examples 'announcements_page' do |context|
  it "should center the add announcement button if no announcements are present", priority: pick_priority(context,"1","2"), test_id: pick_test_id(context, 273606, 324936) do
    get announcements_page
    expect(f('#content.container-fluid div')).to have_attribute(:style, 'text-align: center;')
    expect(f('.btn.btn-large.btn-primary')).to be_displayed
  end

  it "should list all announcements", priority: pick_priority(context,"1","2"), test_id: pick_test_id(context, 273608, 324935) do
    # Create 5 announcements in the group
    announcements = []
    5.times do |n|
      announcements << @testgroup.first.announcements.create!(title: "Announcement #{n+1}", message: "Message #{n+1}",user: @teacher)
    end

    get announcements_page
    expect(ff('.discussion-topic').size).to eq 5
  end

  it "should only list in-group announcements in the content right pane", priority: pick_priority(context,"1","2"), test_id: pick_test_id(context, 273621, 324934) do
    # create group and course announcements
    @testgroup.first.announcements.create!(title: 'Group Announcement', message: 'Group',user: @teacher)
    @course.announcements.create!(title: 'Course Announcement', message: 'Course',user: @teacher)

    get announcements_page
    expect_new_page_load { f('.btn-primary').click }
    fj(".ui-accordion-header a:contains('Announcements')").click
    expect(fln('Group Announcement')).to be_displayed
    expect(fln('Course Announcement')).to be_nil
  end

  it "should only access group files in announcements right content pane", priority: pick_priority(context,"1","2"), test_id: pick_test_id(context, 273624, 324931) do
    add_test_files
    get announcements_page
    expect_new_page_load { f('.btn-primary').click }
    expand_files_on_content_pane
    expect(ffj('.file .text:visible').size).to eq 1
  end
end

#-----------------------------------------------------------------------------------------------------------------------
shared_examples 'pages_page' do |context|
  it "should load pages index and display all pages", priority: pick_priority(context,"1","2"), test_id: pick_test_id(context, 273610, 324927) do
    @testgroup.first.wiki.wiki_pages.create!(title: "Page 1", user: @teacher)
    @testgroup.first.wiki.wiki_pages.create!(title: "Page 2", user: @teacher)
    get pages_page
    expect(ff('.collectionViewItems .clickable').size).to eq 2
  end

  it "should only list in-group pages in the content right pane", priority: pick_priority(context,"1","2"), test_id: pick_test_id(context, 273620,324928) do
    # create group and course announcements
    group_page = @testgroup.first.wiki.wiki_pages.create!(user: @teacher,
                                                          title: 'Group Page', message: 'Group')
    course_page = @course.wiki.wiki_pages.create!(user: @teacher,
                                                  title: 'Course Page', message: 'Course')

    get pages_page
    f('.btn-primary').click
    wait_for_ajaximations
    fj(".ui-accordion-header a:contains('Wiki Pages')").click
    expect(fln("#{group_page.title}")).to be_displayed
    expect(fln("#{course_page.title}")).to be_nil
  end

  it "should only access group files in pages right content pane", priority: pick_priority(context,"1","2"), test_id: pick_test_id(context, 303700,324932) do
    add_test_files
    get pages_page
    f('.btn-primary').click
    wait_for_ajaximations
    expand_files_on_content_pane
    expect(ffj('.file .text:visible').size).to eq 1
  end
end

#-----------------------------------------------------------------------------------------------------------------------
shared_examples 'people_page' do |context|
  it "should allow group users to see group registered services page", priority: pick_priority(context,"1","2"),test_id: pick_test_id(context, 323329, 324926) do
    get people_page
    expect_new_page_load { fln('View Registered Services').click }
    # Checks that we are on the Registered Services page
    expect(f('.btn.button-sidebar-wide')).to be_displayed
  end
end

#-----------------------------------------------------------------------------------------------------------------------
shared_examples 'discussions_page' do |context|
  it "should only list in-group discussions in the content right pane", priority: pick_priority(context,"1","2"), test_id: pick_test_id(context, 273622,324930) do
    # create group and course announcements
    group_dt = DiscussionTopic.create!(context: @testgroup.first, user: @teacher,
                                       title: 'Group Discussion', message: 'Group')
    course_dt = DiscussionTopic.create!(context: @course, user: @teacher,
                                        title: 'Course Discussion', message: 'Course')

    get discussions_page
    expect_new_page_load { f('.btn-primary').click }
    fj(".ui-accordion-header a:contains('Discussions')").click
    expect(fln("#{group_dt.title}")).to be_displayed
    expect(fln("#{course_dt.title}")).to be_nil
  end

  it "should only access group files in discussions right content pane", priority: pick_priority(context,"1","2"), test_id: pick_test_id(context, 303701, 324933) do
    add_test_files
    get discussions_page
    expect_new_page_load { f('.btn-primary').click }
    expand_files_on_content_pane
    expect(ffj('.file .text:visible').size).to eq 1
  end
end

#-----------------------------------------------------------------------------------------------------------------------
shared_examples 'files_page' do |context|
  it "should allow group users to rename a file", priority: "2", test_id: pick_test_id(context, 312869, 315577) do
    add_test_files
    get files_page
    edit_name_from_cog_icon('cool new name')
    wait_for_ajaximations
    expect(fln('cool new name')).to be_present
  end

  it "should search files only within the scope of a group", priority: pick_priority(context,"1","2"), test_id: pick_test_id(context, 273627, 324937) do
    add_test_files
    get files_page
    f('input[type="search"]').send_keys 'example.pdf'
    driver.action.send_keys(:return).perform
    refresh_page
    # This checks to make sure there is only one file and it is the group-level one
    expect(get_all_files_folders.count).to eq 1
    expect(ff('.media-body').first).to include_text('example.pdf')
  end
end

#-----------------------------------------------------------------------------------------------------------------------
shared_examples 'conferences_page' do |context|
  it "should allow group users to create a conference", priority: pick_priority(context,"1","2"),test_id: pick_test_id(context, 307624, 308534) do
    title = 'test conference'
    get conferences_page
    create_conference(title)
    expect(f('#new-conference-list .ig-title').text).to include(title)
  end

  it "should allow group users to delete an active conference", priority: pick_priority(context,"1","2"),test_id: pick_test_id(context, 323557, 323558) do
    WimbaConference.create!(title: "new conference", user: @user, context: @testgroup.first)
    get conferences_page

    click_gear_menu(0)
    delete_conference
    expect(f('#new-conference-list')).to include_text('There are no new conferences')
  end

  it "should allow group users to delete a concluded conference", priority: pick_priority(context,"1","2"),test_id: pick_test_id(context, 323559, 323560) do
    cc = WimbaConference.create!(title: "cncluded conference", user: @user, context: @testgroup.first)
    conclude_conference(cc)
    get conferences_page
    click_gear_menu(0)
    delete_conference
    expect(f('#concluded-conference-list')).to include_text('There are no concluded conferences')
  end
end

# ======================================================================================================================
# Helper Methods
# ======================================================================================================================
def pick_test_id(context, id1, id2)
  case context
  when 'student'
     id1
  when 'teacher'
     id2
  else
     raise('Error: Invalid context!')
  end
end

def pick_priority(context, p1, p2)
  case context
  when 'student'
    p1
  when 'teacher'
    p2
  else
    raise('Error: Invalid context!')
  end
end

def seed_students(count)
  @students = []
  count.times do |n|
    @students << User.create!(:name => "Test Student #{n+1}")
    @course.enroll_student(@students.last).accept!
  end
end

# Creates group sets equal to groupset_count and groups within each group set equal to groups_per_set
def seed_groups(groupset_count, groups_per_set)
  @group_category = []
  @testgroup = []
  groupset_count.times do |n|
    @group_category << @course.group_categories.create!(:name => "Test Group Set #{n+1}")

    groups_per_set.times do |i|
      @testgroup << @course.groups.create!(:name => "Test Group #{i+1}", :group_category => @group_category[n])
    end
  end
end

# Sets up groups and users for testing. Default is 1 user, 1 groupset, and 1 group per groupset.
def group_test_setup(user_count = 1, groupset_count = 1, groups_per_set = 1)
  seed_students(user_count)
  seed_groups(groupset_count, groups_per_set)
end

def add_user_to_group(user,group,is_leader = false)
  group.add_user user
  group.leader = user if is_leader
  group.save!
end

# Adds all given users to group, can use arrays or a single variable
def add_users_to_group(students, group)
  count = students.size
  count.times do |n|
    group.add_user students[n]
    group.save!
  end
end

def create_default_student_group(group_name = "Windfury")
  fj("#groupName").send_keys(group_name.to_s)
  fj('button.confirm-dialog-confirm-btn').click
  wait_for_ajaximations
end

def create_group_and_add_all_students(group_name = "Windfury")
  fj("#groupName").send_keys(group_name.to_s)
  students = ffj(".checkbox")
  students.each do |student|
    student.click
  end
  fj('button.confirm-dialog-confirm-btn').click
  wait_for_ajaximations
end

def create_category(params={})
  default_params = {
    category_name:'category1',
    has_max_membership:false,
    member_limit:0,
  }
  params = default_params.merge(params)

  category1 = @course.group_categories.create!(name: params[:category_name])
  category1.configure_self_signup(true, false)
  if params[:has_max_membership]
    category1.update_attribute(:group_limit,params[:member_limit])
  end

  category1
end

def create_group(params={})
  default_params = {
      group_name:'Windfury',
      enroll_student_count:0,
      add_self_to_group:true,
      category_name:'category1',
      is_leader:'true',
      has_max_membership:false,
      member_limit: 0,
      group_category: nil,
  }
  params = default_params.merge(params)

  # Sets up a group category for the group if one isn't passed in
  params[:group_category] = create_category(category_name:params[:category_name]) if params[:group_category].nil?

  group = @course.groups.create!(
      name:params[:group_name],
      group_category:params[:group_category])

  if params[:has_max_membership]
    group.update_attribute(:max_membership,params[:member_limit])
  end

  if params[:add_self_to_group] == true
    add_user_to_group(@student, group, params[:is_leader])
  end

  seed_students(params[:enroll_student_count]) if params[:enroll_student_count] > 0
end

def create_student_group_as_a_teacher(group_name = "Windfury", enroll_student_count = 0)
  @student = User.create!(:name => "Test Student 1")
  @course.enroll_student(@student).accept!

  group = @course.groups.create!(:name => group_name)
  add_user_to_group(@student, group, false)

  enroll_student_count.times do |n|
    @student = User.create!(:name => "Test Student #{n+2}")
    @course.enroll_student(@student).accept!

    add_user_to_group(@student, group, false)
  end

  group
end

def manually_create_group(params={})
  default_params = {
    group_name:'Test Group',
    has_max_membership:false,
    member_limit:0,
  }
  params = default_params.merge(params)

  f('.btn.add-group').click
  wait_for_ajaximations
  f('#group_name').send_keys(params[:group_name])
  if params[:has_max_membership]
    f('#group_max_membership').send_keys(params[:member_limit])
    wait_for_ajaximations
  end
  f('#groupEditSaveButton').click
  wait_for_ajaximations
end

# Used to set group_limit field manually. Assumes you are on Edit Group Set page and self-sign up is checked
def manually_set_groupset_limit(member_limit = "2")
  replace_content(fj('input[name="group_limit"]:visible'), member_limit)
  fj('.btn.btn-primary[type=submit]').click
  wait_for_ajaximations
end

def manually_fill_limited_group(member_limit ="2",student_count = 0)
  student_count.times do |n|
    # Finds all student add buttons and updates the through each iteration
    studs = ff('.assign-to-group')
    studs.first.click

    wait_for_ajaximations
    f('.set-group').click
    expect(f('.group-summary')).to include_text("#{n+1} / #{member_limit} students")
  end
  expect(f('.show-group-full')).to be_displayed
end

# Used to enable self-signup on an already created group set by opening Edit Group Set
def manually_enable_self_signup
  f('.icon-settings').click
  wait_for_ajaximations
  f('.edit-category').click
  wait_for_ajaximations

  f('.self-signup-toggle').click
end

def open_clone_group_set_option
  f('.icon-settings').click
  wait_for_ajaximations
  f('.clone-category').click
  wait_for_ajaximations
end

def set_cloned_groupset_name(groupset_name="Test Group Set Clone",page_reload=false)
  replace_content(f('#cloned_category_name'), groupset_name)
  if page_reload
    expect_new_page_load {f('#clone_category_submit_button').click}
  else
    f('#clone_category_submit_button').click
    wait_for_ajaximations
  end
end

def select_randomly_assign_students_option
  f('.icon-settings').click
  wait_for_ajaximations
  f('.randomly-assign-members').click
  wait_for_ajaximations
  f('.randomly-assign-members-confirm').click
  wait_for_ajaximations
end

def select_change_groups_option
  (ff('#option_change_groups').last).click
  (ff('#clone_category_submit_button').last).click
  wait_for_ajaximations
end

def move_unassigned_student_to_group(group=0)
  f('.assign-to-group').click
  wait_for_ajaximations
  ff('.set-group')[group].click
  wait_for_ajaximations
end

# Moves student from one group to another group. Assumes student can be seen by toggling group's collapse arrow.
def move_student_to_group(group_destination, student=0)
  ff('.group-user-actions')[student].click
  wait_for_ajaximations
  ff('.edit-group-assignment')[student].click
  wait_for_ajaximations
  click_option('.single-select', "#{@testgroup[group_destination].name}")
  f('.set-group').click
  wait_for_ajaximations
end

# Assumes student can be seen by toggling group's collapse arrow
def remove_student_from_group(student=0)
  ff('.group-user-actions')[student].click
  wait_for_ajaximations
  ff('.remove-from-group')[student].click
  wait_for_ajaximations
end

def toggle_group_collapse_arrow
  f('.toggle-group').click
  wait_for_ajaximations
end

def manually_delete_group
  f('.group-actions .icon-settings').click
  wait_for_ajaximations
  f('.delete-group').click

  driver.switch_to.alert.accept
  wait_for_animations
end

def delete_group
  f(".icon-settings").click
  wait_for_animations

  fln('Delete').click

  driver.switch_to.alert.accept
  wait_for_animations
end

# Only use to add group_set if no group sets already exist
def click_add_group_set
  f('#add-group-set').click
  wait_for_ajaximations
end

def save_group_set
  f('#newGroupSubmitButton').click
  wait_for_ajaximations
end

def create_and_submit_assignment_from_group(student)
  category = @group_category[0]
  assignment = @course.assignments.create({
    :name => "test assignment",
    :group_category => category})
  assignment.submit_homework(student)
end

def create_group_announcement_manually(title,text)
  expect_new_page_load { f('.btn-primary').click }
  replace_content(f('input[name=title]'), title)
  type_in_tiny('textarea[name=message]', text)
  expect_new_page_load { submit_form('.form-actions') }
end

# Checks that a group member can click a specified page entry on the index page and see its show page
#   Expects @page is defined and index is defined as which wiki page is desired to click on. First page entry is default
def verify_member_sees_group_page(index = 0)
  get pages_page
  expect_new_page_load { ff('.wiki-page-link')[index].click }
  expect expect(f('.page-title')).to include_text("#{@page.title}")
end

# context test. if true, allows you to test files both in and out of group context,
#   otherwise it adds two files to the group
def add_test_files(context_test = true)
  if context_test
    second_file_context = @course
  else
    second_file_context = @testgroup.first
  end

  add_file(fixture_file_upload('files/example.pdf', 'application/pdf'),
           @testgroup.first, "example.pdf")
  add_file(fixture_file_upload('files/a_file.txt', 'text/plain'),
           second_file_context, "a_file.txt")
end

def expand_files_on_content_pane
  fj('.ui-state-default.ui-corner-top:contains("Files")').click
  wait_for_ajaximations
  f('.sign.plus').click
  wait_for_ajaximations
end

def move_file_to_folder(file_name,destination_name)
  move(file_name, 1, :toolbar_menu)
  wait_for_ajaximations
  expect(f('#flash_message_holder').text).to eq "#{file_name} moved to #{destination_name}\nClose"
  # Click folder
  ff('.media-body').first.click
  wait_for_ajaximations
  expect(fln(file_name)).to be_displayed
end

# For files page, creates a folder and then adds a folder within it
def create_folder_structure
  @top_folder = 'Top Folder'
  @inner_folder = 'Inner Folder'
  add_folder(@top_folder)
  ff('.media-body')[0].click
  wait_for_ajaximations
  add_folder(@inner_folder)
  wait_for_ajaximations
end

# Moves a folder to the top level file structure
def move_folder(folder_name)
  move(folder_name, 0, :toolbar_menu)
  wait_for_ajaximations
  expect(f('#flash_message_holder').text).to eq "#{folder_name} moved to files\nClose"
  expect(ff('.treeLabel span')[2].text).to eq folder_name
end

def verify_no_course_user_access(path)
  # User.create! creates a course user, who won't be able to access the page
  user_session(User.create!(name: 'course student'))
  get path
  expect(f('.ui-state-error')).to be_displayed
end

def setup_group_page_urls
  let(:url) {"/groups/#{@testgroup.first.id}"}
  let(:announcements_page) {url + '/announcements'}
  let(:people_page) {url + '/users'}
  let(:discussions_page) {url + '/discussion_topics'}
  let(:pages_page) {url + '/pages'}
  let(:files_page) {url + '/files'}
  let(:conferences_page) {url + '/conferences'}
end

def edit_group_announcement
  get announcements_page
  expect_new_page_load { ff('li.discussion-topic').first.click }
  click_edit_btn
  # edit also verifies it has been edited
  edit('I edited it','My test message')
end