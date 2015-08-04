require File.expand_path(File.dirname(__FILE__) + '/../common')

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