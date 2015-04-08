def seed_users(count)
  count.times do |n|
    @student = User.create!(:name => "Test Student #{n+1}")
    @course.enroll_student(@student).accept!
  end
end

# Creates group sets equal to groupset_count and groups within each group set equal to inner_group_count
def seed_groups(groupset_count, inner_group_count)
  @group_category = []
  @testgroup = []
  groupset_count.times do |n|
    @group_category << @course.group_categories.create!(:name => "Test Group Set #{n+1}")

    inner_group_count.times do |i|
      @testgroup << @course.groups.create!(:name => "Test Group #{i+1}", :group_category => @group_category[n])
    end
  end
end