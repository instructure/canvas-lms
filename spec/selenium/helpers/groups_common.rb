def seed_users(count)
  count.times do |n|
    @student = User.create!(:name => "Test Student #{n+1}")
    @course.enroll_student(@student).accept!
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
  seed_users(user_count)
  seed_groups(groupset_count, groups_per_set)
end

def add_user_to_group(user,group)
  group.add_user user
  group.save!
end