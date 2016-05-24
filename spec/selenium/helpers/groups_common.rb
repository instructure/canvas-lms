module GroupsCommon

  def setup_group_page_urls
    let(:url) {"/groups/#{@testgroup.first.id}"}
    let(:announcements_page) {url + '/announcements'}
    let(:people_page) {url + '/users'}
    let(:discussions_page) {url + '/discussion_topics'}
    let(:pages_page) {url + '/pages'}
    let(:files_page) {url + '/files'}
    let(:conferences_page) {url + '/conferences'}
    let(:collaborations_page) {url + '/collaborations'}
  end

  def seed_students(count, base_name = 'Test Student')
    @students = []
    count.times do |n|
      @students << User.create!(:name => "#{base_name} #{n+1}")
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
    students.each(&:click)
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
        add_students_to_group: false
    }
    params = default_params.merge(params)

    # Sets up a group category for the group if one isn't passed in
    params[:group_category] = create_category(category_name:params[:category_name]) if params[:group_category].nil?

    group = @course.groups.create!(
      name: params[:group_name],
      group_category: params[:group_category]
    )

    if params[:has_max_membership]
      group.update_attribute(:max_membership,params[:member_limit])
    end

    if params[:add_self_to_group] == true
      add_user_to_group(@student, group, params[:is_leader])
    end

    seed_students(params[:enroll_student_count]) if params[:enroll_student_count] > 0
    if params[:add_students_to_group]
      @students.each do |student|
        add_user_to_group(student, group, false)
      end
    end

    group
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
    get announcements_page
    expect_new_page_load { f('.btn-primary').click }
    replace_content(f('input[name=title]'), title)
    type_in_tiny('textarea[name=message]', text)
    expect_new_page_load { submit_form('.form-actions') }
    get announcements_page
  end

  # Checks that a group member can click a specified page entry on the index page and see its show page
  # Expects @page is defined and index is defined as which wiki page is desired to click on. First page entry is default
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
    Selenium::WebDriver::Wait.new(timeout: 5).until do
      fj('.ui-state-default.ui-corner-top:contains("Files")').present?
    end
    fj('.ui-state-default.ui-corner-top:contains("Files")').click
    wait_for_ajaximations
    f('.sign.plus').click
    wait_for_ajaximations
  end

  def move_file_to_folder(file_name,destination_name)
    move(file_name, 1, :toolbar_menu)
    wait_for_ajaximations
    expect(f('#flash_message_holder').text).to eq "#{file_name} moved to #{destination_name}"
    # Click folder
    ff('.ef-name-col__text').first.click
    wait_for_ajaximations
    expect(fln(file_name)).to be_displayed
  end

  # For files page, creates a folder and then adds a folder within it
  def create_folder_structure
    @top_folder = 'Top Folder'
    @inner_folder = 'Inner Folder'
    add_folder(@top_folder)
    ff('.ef-name-col__text')[0].click
    wait_for_ajaximations
    add_folder(@inner_folder)
    wait_for_ajaximations
  end

  # Moves a folder to the top level file structure
  def move_folder(folder_name)
    move(folder_name, 0, :toolbar_menu)
    wait_for_ajaximations
    expect(f('#flash_message_holder').text).to eq "#{folder_name} moved to files"
    expect(ff('.treeLabel span')[2].text).to eq folder_name
  end

  def verify_no_course_user_access(path)
    # User.create! creates a course user, who won't be able to access the page
    user_session(User.create!(name: 'course student'))
    get path
    expect(f('.ui-state-error')).to be_displayed
  end

  def edit_group_announcement
    get announcements_page
    expect_new_page_load { ff('li.discussion-topic').first.click }
    click_edit_btn
    # edit also verifies it has been edited
    edit('I edited it','My test message')
  end
end
