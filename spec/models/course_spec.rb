#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'socket'

describe Course do
  before(:each) do
    @course = Course.new
  end
  
  context "validation" do
    it "should create a new instance given valid attributes" do
      course_model
    end
  end
  
  it "should create a unique course." do
    @course = Course.create_unique
    @course.name.should eql("My Course")
    @uuid = @course.uuid
    @course2 = Course.create_unique(@uuid)
    @course.should eql(@course2)
  end
  
  it "should always have a uuid, if it was created" do
    @course.save!
    @course.uuid.should_not be_nil
  end

  context "permissions" do
    it "should follow account chain when looking for generic permissions from AccountUsers" do
      account = Account.create!
      sub_account = Account.create!(:parent_account => account)
      sub_sub_account = Account.create!(:parent_account => sub_account)
      user = account_admin_user(:account => sub_account)
      course = Course.create!(:account => sub_sub_account)
      course.grants_right?(user, nil, :manage).should be_true
    end

    it "should grant delete to the proper individuals" do
      account_admin_user_with_role_changes(:membership_type => 'managecourses', :role_changes => {:manage_courses => true})
      @admin1 = @admin
      account_admin_user_with_role_changes(:membership_type => 'managesis', :role_changes => {:manage_sis => true})
      @admin2 = @admin
      course_with_teacher(:active_all => true)

      @course.grants_right?(@teacher, nil, :delete).should be_true
      @course.grants_right?(@admin1, nil, :delete).should be_true
      @course.grants_right?(@admin2, nil, :delete).should be_false

      @course.complete!

      @course.grants_right?(@teacher, nil, :delete).should be_true
      @course.grants_right?(@admin1, nil, :delete).should be_true
      @course.grants_right?(@admin2, nil, :delete).should be_false

      @course.sis_source_id = 'sis_id'
      @course.save!

      @course.grants_right?(@teacher, nil, :delete).should be_false
      @course.grants_right?(@admin1, nil, :delete).should be_true
      @course.grants_right?(@admin2, nil, :delete).should be_true
    end
  end

  it "should clear content when resetting" do
    course_with_student
    @course.discussion_topics.create!
    @course.quizzes.create!
    @course.assignments.create!
    @course.wiki.wiki_page.save!
    @course.sis_source_id = 'sis_id'
    @course.stuck_sis_fields = [].to_set
    @course.save!
    @course.course_sections.should_not be_empty
    @course.students.should == [@student]
    @course.stuck_sis_fields.should == [].to_set

    @new_course = @course.reset_content

    @course.reload
    @course.stuck_sis_fields.should == [].to_set
    @course.course_sections.should be_empty
    @course.students.should be_empty
    @course.sis_source_id.should be_nil

    @new_course.reload
    @new_course.course_sections.should_not be_empty
    @new_course.students.should == [@student]
    @new_course.discussion_topics.should be_empty
    @new_course.quizzes.should be_empty
    @new_course.assignments.should be_empty
    @new_course.sis_source_id.should == 'sis_id'
    @new_course.syllabus_body.should be_blank
    @new_course.stuck_sis_fields.should == [].to_set

    @course.uuid.should_not == @new_course.uuid
    @course.wiki_id.should_not == @new_course.wiki_id
    @course.replacement_course_id.should == @new_course.id
  end

  it "should preserve sticky fields when resetting content" do
    course_with_student
    @course.sis_source_id = 'sis_id'
    @course.course_code = "cid"
    @course.save!
    @course.stuck_sis_fields = [].to_set
    @course.name = "course_name"
    @course.stuck_sis_fields.should == [:name].to_set
    @course.save!
    @course.stuck_sis_fields.should == [:name].to_set

    @new_course = @course.reset_content

    @course.reload
    @course.stuck_sis_fields.should == [:name].to_set
    @course.sis_source_id.should be_nil

    @new_course.reload
    @new_course.sis_source_id.should == 'sis_id'
    @new_course.stuck_sis_fields.should == [:name].to_set

    @course.uuid.should_not == @new_course.uuid
    @course.replacement_course_id.should == @new_course.id
  end

  it "group_categories should not include deleted categories" do
    course = course_model
    course.group_categories.count.should == 0
    category1 = course.group_categories.create(:name => 'category 1')
    category2 = course.group_categories.create(:name => 'category 2')
    course.group_categories.count.should == 2
    category1.destroy
    course.reload
    course.group_categories.count.should == 1
    course.group_categories.to_a.should == [category2]
  end

  it "all_group_categories should include deleted categories" do
    course = course_model
    course.all_group_categories.count.should == 0
    category1 = course.group_categories.create(:name => 'category 1')
    category2 = course.group_categories.create(:name => 'category 2')
    course.all_group_categories.count.should == 2
    category1.destroy
    course.reload
    course.all_group_categories.count.should == 2
  end

  context "users_not_in_groups" do
    before :each do
      @course = course(:active_all => true)
      @user1 = user_model
      @user2 = user_model
      @user3 = user_model
      @enrollment1 = @course.enroll_user(@user1)
      @enrollment2 = @course.enroll_user(@user2)
      @enrollment3 = @course.enroll_user(@user3)
    end

    it "should not include users through deleted/rejected/completed enrollments" do
      @enrollment1.destroy
      @course.users_not_in_groups([]).size.should == 2
    end

    it "should not include users in one of the groups" do
      group = @course.groups.create
      group.add_user(@user1)
      users = @course.users_not_in_groups([group])
      users.size.should == 2
      users.should_not be_include(@user1)
    end

    it "should include users otherwise" do
      group = @course.groups.create
      group.add_user(@user1)
      users = @course.users_not_in_groups([group])
      users.should be_include(@user2)
      users.should be_include(@user3)
    end
  end

  it "should order results of paginate_users_not_in_groups by user's sortable name" do
    @course = course(:active_all => true)
    @user1 = user_model; @user1.sortable_name = 'jonny'; @user1.save
    @user2 = user_model; @user2.sortable_name = 'bob'; @user2.save
    @user3 = user_model; @user3.sortable_name = 'richard'; @user3.save
    @course.enroll_user(@user1)
    @course.enroll_user(@user2)
    @course.enroll_user(@user3)
    users = @course.paginate_users_not_in_groups([], 1)
    users.map{ |u| u.id }.should == [@user2.id, @user1.id, @user3.id]
  end
end

describe Course, "enroll" do
  
  before(:each) do
    @course = Course.create(:name => "some_name")
    @user = user_with_pseudonym
  end
  
  it "should be able to enroll a student" do
    @course.enroll_student(@user)
    @se = @course.student_enrollments.first
    @se.user_id.should eql(@user.id)
    @se.course_id.should eql(@course.id)
  end
  
  it "should be able to enroll a TA" do
    @course.enroll_ta(@user)
    @tae = @course.ta_enrollments.first
    @tae.user_id.should eql(@user.id)
    @tae.course_id.should eql(@course.id)
  end
  
  it "should be able to enroll a teacher" do
    @course.enroll_teacher(@user)
    @te = @course.teacher_enrollments.first
    @te.user_id.should eql(@user.id)
    @te.course_id.should eql(@course.id)
  end
  
  it "should enroll a student as creation_pending if the course isn't published" do
    @se = @course.enroll_student(@user)
    @se.user_id.should eql(@user.id)
    @se.course_id.should eql(@course.id)
    @se.should be_creation_pending
  end
  
  it "should enroll a teacher as invited if the course isn't published" do
    Notification.create(:name => "Enrollment Registration", :category => "registration")
    @tae = @course.enroll_ta(@user)
    @tae.user_id.should eql(@user.id)
    @tae.course_id.should eql(@course.id)
    @tae.should be_invited
    @tae.messages_sent.should be_include("Enrollment Registration")
  end
  
  it "should enroll a ta as invited if the course isn't published" do
    Notification.create(:name => "Enrollment Registration", :category => "registration")
    @te = @course.enroll_teacher(@user)
    @te.user_id.should eql(@user.id)
    @te.course_id.should eql(@course.id)
    @te.should be_invited
    @te.messages_sent.should be_include("Enrollment Registration")
  end
end

describe Course, "score_to_grade" do
  it "should correctly map scores to grades" do
    default = GradingStandard.default_grading_standard
    default.to_json.should eql([["A", 0.94], ["A-", 0.90], ["B+", 0.87], ["B", 0.84], ["B-", 0.80], ["C+", 0.77], ["C", 0.74], ["C-", 0.70], ["D+", 0.67], ["D", 0.64], ["D-", 0.61], ["F", 0]].to_json)
    course_model
    @course.score_to_grade(95).should eql("")
    @course.grading_standard_id = 0
    @course.score_to_grade(1005).should eql("A")
    @course.score_to_grade(105).should eql("A")
    @course.score_to_grade(100).should eql("A")
    @course.score_to_grade(99).should eql("A")
    @course.score_to_grade(94).should eql("A")
    @course.score_to_grade(93.999).should eql("A-")
    @course.score_to_grade(93.001).should eql("A-")
    @course.score_to_grade(93).should eql("A-")
    @course.score_to_grade(92.999).should eql("A-")
    @course.score_to_grade(90).should eql("A-")
    @course.score_to_grade(89).should eql("B+")
    @course.score_to_grade(87).should eql("B+")
    @course.score_to_grade(86).should eql("B")
    @course.score_to_grade(85).should eql("B")
    @course.score_to_grade(83).should eql("B-")
    @course.score_to_grade(80).should eql("B-")
    @course.score_to_grade(79).should eql("C+")
    @course.score_to_grade(76).should eql("C")
    @course.score_to_grade(73).should eql("C-")
    @course.score_to_grade(71).should eql("C-")
    @course.score_to_grade(69).should eql("D+")
    @course.score_to_grade(67).should eql("D+")
    @course.score_to_grade(66).should eql("D")
    @course.score_to_grade(65).should eql("D")
    @course.score_to_grade(62).should eql("D-")
    @course.score_to_grade(60).should eql("F")
    @course.score_to_grade(59).should eql("F")
    @course.score_to_grade(0).should eql("F")
    @course.score_to_grade(-100).should eql("F")
  end
  
end

describe Course, "gradebook_to_csv" do
  it "should generate gradebook csv" do
    course_with_student(:active_all => true)
    @group = @course.assignment_groups.create!(:name => "Some Assignment Group", :group_weight => 100)
    @assignment = @course.assignments.create!(:title => "Some Assignment", :points_possible => 10, :assignment_group => @group)
    @assignment.grade_student(@user, :grade => "10")
    @assignment2 = @course.assignments.create!(:title => "Some Assignment 2", :points_possible => 10, :assignment_group => @group)
    @course.recompute_student_scores
    @user.reload
    @course.reload
    
    csv = @course.gradebook_to_csv
    csv.should_not be_nil
    rows = FasterCSV.parse(csv)
    rows.length.should equal(3)
    rows[0][-1].should == "Final Score"
    rows[1][-1].should == "(read only)"
    rows[2][-1].should == "50"
    rows[0][-2].should == "Current Score"
    rows[1][-2].should == "(read only)"
    rows[2][-2].should == "100"
  end
  
  it "should order assignments by due date" do
    course_with_student(:active_all => true)
    @assignment = @course.assignments.create!(:title => "Some Assignment 1", :points_possible => 10, :assignment_group => @group, :due_at => Time.now + 1.days)
    @assignment = @course.assignments.create!(:title => "Some Assignment 2", :points_possible => 10, :assignment_group => @group, :due_at => Time.now + 2.days)
    @assignment = @course.assignments.create!(:title => "Some Assignment 3", :points_possible => 10, :assignment_group => @group, :due_at => Time.now + 3.days)
    @assignment = @course.assignments.create!(:title => "Some Assignment 5", :points_possible => 10, :assignment_group => @group, :due_at => Time.now + 4.days)
    @assignment = @course.assignments.create!(:title => "Some Assignment 4", :points_possible => 10, :assignment_group => @group, :due_at => Time.now + 5.days)
    @assignment = @course.assignments.create!(:title => "Some Assignment 6", :points_possible => 10, :assignment_group => @group, :due_at => Time.now + 7.days)
    @assignment = @course.assignments.create!(:title => "Some Assignment 7", :points_possible => 10, :assignment_group => @group, :due_at => Time.now + 6.days)
    @course.recompute_student_scores
    @user.reload
    @course.reload

    csv = @course.gradebook_to_csv
    csv.should_not be_nil
    rows = FasterCSV.parse(csv)
    rows.length.should equal(3)
    assignments = []
    rows[0].each do |column|
      assignments << column.sub(/ \([0-9]+\)/, '') if column =~ /Some Assignment/
    end
    assignments.should == ["Some Assignment 1", "Some Assignment 2", "Some Assignment 3", "Some Assignment 5", "Some Assignment 4", "Some Assignment 7", "Some Assignment 6"]
  end

  it "should generate csv with final grade if enabled" do
    course_with_student(:active_all => true)
    @course.grading_standard_id = 0
    @course.save!
    @group = @course.assignment_groups.create!(:name => "Some Assignment Group", :group_weight => 100)
    @assignment = @course.assignments.create!(:title => "Some Assignment", :points_possible => 10, :assignment_group => @group)
    @assignment.grade_student(@user, :grade => "10")
    @assignment2 = @course.assignments.create!(:title => "Some Assignment 2", :points_possible => 10, :assignment_group => @group)
    @assignment2.grade_student(@user, :grade => "8")
    @course.recompute_student_scores
    @user.reload
    @course.reload
    
    csv = @course.gradebook_to_csv
    csv.should_not be_nil
    rows = FasterCSV.parse(csv)
    rows.length.should equal(3)
    rows[0][-1].should == "Final Grade"
    rows[1][-1].should == "(read only)"
    rows[2][-1].should == "A-"
    rows[0][-2].should == "Final Score"
    rows[1][-2].should == "(read only)"
    rows[2][-2].should == "90"
    rows[0][-3].should == "Current Score"
    rows[1][-3].should == "(read only)"
    rows[2][-3].should == "90"
  end

  it "should include sis ids if enabled" do
    course(:active_all => true)
    @user1 = user_with_pseudonym(:active_all => true, :name => 'Brian', :username => 'brianp@instructure.com')
    student_in_course(:user => @user1)
    @user2 = user_with_pseudonym(:active_all => true, :name => 'Cody', :username => 'cody@instructure.com')
    student_in_course(:user => @user2)
    @user3 = user(:active_all => true, :name => 'JT')
    student_in_course(:user => @user3)
    @user1.pseudonym.sis_user_id = "SISUSERID"
    @user1.pseudonym.save!
    @group = @course.assignment_groups.create!(:name => "Some Assignment Group", :group_weight => 100)
    @assignment = @course.assignments.create!(:title => "Some Assignment", :points_possible => 10, :assignment_group => @group)
    @assignment.grade_student(@user1, :grade => "10")
    @assignment.grade_student(@user2, :grade => "9")
    @assignment.grade_student(@user3, :grade => "9")
    @assignment2 = @course.assignments.create!(:title => "Some Assignment 2", :points_possible => 10, :assignment_group => @group)
    @course.recompute_student_scores
    @course.reload

    csv = @course.gradebook_to_csv(:include_sis_id => true)
    csv.should_not be_nil
    rows = FasterCSV.parse(csv)
    rows.length.should == 5
    rows[0][1].should == 'ID'
    rows[0][2].should == 'SIS User ID'
    rows[0][3].should == 'SIS Login ID'
    rows[0][4].should == 'Section'
    rows[1][2].should == ''
    rows[1][3].should == ''
    rows[1][4].should == ''
    rows[1][-1].should == '(read only)'
    rows[2][1].should == @user1.id.to_s
    rows[2][2].should == 'SISUSERID'
    rows[2][3].should == @user1.pseudonym.unique_id
    rows[3][1].should == @user2.id.to_s
    rows[3][2].should be_nil
    rows[3][3].should == @user2.pseudonym.unique_id
    rows[4][1].should == @user3.id.to_s
    rows[4][2].should be_nil
    rows[4][3].should be_nil
  end
end

describe Course, "merge_into" do
  it "should merge in another course" do
    @c = Course.create!(:name => "some course")
    @c.wiki.wiki_pages.length.should == 1
    @c2 = Course.create!(:name => "another course")
    g = @c2.assignment_groups.create!(:name => "some group")
    due = Time.parse("Jan 1 2000 5:00pm")
    @c2.assignments.create!(:title => "some assignment", :assignment_group => g, :due_at => due)
    @c2.wiki.wiki_pages.create!(:title => "some page")
    @c2.quizzes.create!(:title => "some quiz")
    @c.assignments.length.should eql(0)
    @c.merge_in(@c2, :everything => true)
    @c.reload
    @c.assignment_groups.length.should eql(1)
    @c.assignment_groups.last.name.should eql(@c2.assignment_groups.last.name)
    @c.assignment_groups.last.should_not eql(@c2.assignment_groups.last)
    @c.assignments.length.should eql(1)
    @c.assignments.last.title.should eql(@c2.assignments.last.title)
    @c.assignments.last.should_not eql(@c2.assignments.last)
    @c.assignments.last.due_at.should eql(@c2.assignments.last.due_at)
    @c.wiki.wiki_pages.length.should eql(2)
    @c.wiki.wiki_pages.map(&:title).include?(@c2.wiki.wiki_pages.last.title).should be_true
    @c.wiki.wiki_pages.first.should_not eql(@c2.wiki.wiki_pages.last)
    @c.wiki.wiki_pages.last.should_not eql(@c2.wiki.wiki_pages.last)
    @c.quizzes.length.should eql(1)
    @c.quizzes.last.title.should eql(@c2.quizzes.last.title)
    @c.quizzes.last.should_not eql(@c2.quizzes.last)
  end
  
  it "should update due dates for date changes" do
    new_start = Date.parse("Jun 1 2000")
    new_end = Date.parse("Sep 1 2000")
    @c = Course.create!(:name => "some course", :start_at => new_start, :conclude_at => new_end)
    @c2 = Course.create!(:name => "another course", :start_at => Date.parse("Jan 1 2000"), :conclude_at => Date.parse("Mar 1 2000"))
    g = @c2.assignment_groups.create!(:name => "some group")
    @c2.assignments.create!(:title => "some assignment", :assignment_group => g, :due_at => Time.parse("Jan 3 2000 5:00pm"))
    @c.assignments.length.should eql(0)
    @c2.calendar_events.create!(:title => "some event", :start_at => Time.parse("Jan 11 2000 3:00pm"), :end_at => Time.parse("Jan 11 2000 4:00pm"))
    @c.calendar_events.length.should eql(0)
    @c.merge_in(@c2, :everything => true, :shift_dates => true)
    @c.reload
    @c.assignments.length.should eql(1)
    @c.assignments.last.title.should eql(@c2.assignments.last.title)
    @c.assignments.last.should_not eql(@c2.assignments.last)
    @c.assignments.last.due_at.should > new_start
    @c.assignments.last.due_at.should < new_end
    @c.assignments.last.due_at.hour.should eql(@c2.assignments.last.due_at.hour)
    @c.calendar_events.length.should eql(1)
    @c.calendar_events.last.title.should eql(@c2.calendar_events.last.title)
    @c.calendar_events.last.should_not eql(@c2.calendar_events.last)
    @c.calendar_events.last.start_at.should > new_start
    @c.calendar_events.last.start_at.should < new_end
    @c.calendar_events.last.start_at.hour.should eql(@c2.calendar_events.last.start_at.hour)
    @c.calendar_events.last.end_at.should > new_start
    @c.calendar_events.last.end_at.should < new_end
    @c.calendar_events.last.end_at.hour.should eql(@c2.calendar_events.last.end_at.hour)
  end
  
  it "should match times for changing due dates in a different time zone" do
    Time.zone = "Mountain Time (US & Canada)"
    new_start = Date.parse("Jun 1 2000")
    new_end = Date.parse("Sep 1 2000")
    @c = Course.create!(:name => "some course", :start_at => new_start, :conclude_at => new_end)
    @c2 = Course.create!(:name => "another course", :start_at => Date.parse("Jan 1 2000"), :conclude_at => Date.parse("Mar 1 2000"))
    g = @c2.assignment_groups.create!(:name => "some group")
    @c2.assignments.create!(:title => "some assignment", :assignment_group => g, :due_at => Time.parse("Jan 3 2000 5:00pm"))
    @c.assignments.length.should eql(0)
    @c2.calendar_events.create!(:title => "some event", :start_at => Time.parse("Jan 11 2000 3:00pm"), :end_at => Time.parse("Jan 11 2000 4:00pm"))
    @c.calendar_events.length.should eql(0)
    @c.merge_in(@c2, :everything => true, :shift_dates => true)
    @c.reload
    @c.assignments.length.should eql(1)
    @c.assignments.last.title.should eql(@c2.assignments.last.title)
    @c.assignments.last.should_not eql(@c2.assignments.last)
    @c.assignments.last.due_at.should > new_start
    @c.assignments.last.due_at.should < new_end
    @c.assignments.last.due_at.wday.should eql(@c2.assignments.last.due_at.wday)
    @c.assignments.last.due_at.utc.hour.should eql(@c2.assignments.last.due_at.utc.hour)
    @c.calendar_events.length.should eql(1)
    @c.calendar_events.last.title.should eql(@c2.calendar_events.last.title)
    @c.calendar_events.last.should_not eql(@c2.calendar_events.last)
    @c.calendar_events.last.start_at.should > new_start
    @c.calendar_events.last.start_at.should < new_end
    @c.calendar_events.last.start_at.wday.should eql(@c2.calendar_events.last.start_at.wday)
    @c.calendar_events.last.start_at.utc.hour.should eql(@c2.calendar_events.last.start_at.utc.hour)
    @c.calendar_events.last.end_at.should > new_start
    @c.calendar_events.last.end_at.should < new_end
    @c.calendar_events.last.end_at.wday.should eql(@c2.calendar_events.last.end_at.wday)
    @c.calendar_events.last.end_at.utc.hour.should eql(@c2.calendar_events.last.end_at.utc.hour)
    Time.zone = nil
  end
end

describe Course, "update_account_associations" do
  it "should update account associations correctly" do
    account1 = Account.create!(:name => 'first')
    account2 = Account.create!(:name => 'second')
    
    @c = Course.create!(:account => account1)
    @c.associated_accounts.length.should eql(1)
    @c.associated_accounts.first.should eql(account1)
    
    @c.account = account2
    @c.save!
    @c.reload
    @c.associated_accounts.length.should eql(1)
    @c.associated_accounts.first.should eql(account2)
  end
end

describe Course, "tabs_available" do
  it "should return the defaults if nothing specified" do
    course_with_teacher(:active_all => true)
    length = Course.default_tabs.length
    tab_ids = @course.tabs_available(@user).map{|t| t[:id] }
    tab_ids.should eql(Course.default_tabs.map{|t| t[:id] })
    tab_ids.length.should eql(length)
  end
  
  it "should overwrite the order of tabs if configured" do
    course_with_teacher(:active_all => true)
    length = Course.default_tabs.length
    @course.tab_configuration = [{'id' => Course::TAB_COLLABORATIONS}, {'id' => Course::TAB_CHAT}]
    tab_ids = @course.tabs_available(@user).map{|t| t[:id] }
    tab_ids.should eql(([Course::TAB_COLLABORATIONS, Course::TAB_CHAT] + Course.default_tabs.map{|t| t[:id] }).uniq)
    tab_ids.length.should eql(length)
  end
  
  it "should remove ids for tabs not in the default list" do
    course_with_teacher(:active_all => true)
    @course.tab_configuration = [{'id' => 912}]
    @course.tabs_available(@user).map{|t| t[:id] }.should_not be_include(912)
    tab_ids = @course.tabs_available(@user).map{|t| t[:id] }
    tab_ids.should eql(Course.default_tabs.map{|t| t[:id] })
    tab_ids.length.should > 0
    @course.tabs_available(@user).map{|t| t[:label] }.compact.length.should eql(tab_ids.length)
  end
  
  it "should hide unused tabs if not an admin" do
    course_with_student(:active_all => true)
    tab_ids = @course.tabs_available(@user).map{|t| t[:id] }
    tab_ids.should_not be_include(Course::TAB_SETTINGS)
    tab_ids.length.should > 0
  end
  
  it "should show grades tab for students" do
    course_with_student(:active_all => true)
    tab_ids = @course.tabs_available(@user).map{|t| t[:id] }
    tab_ids.should be_include(Course::TAB_GRADES)
  end
  
  it "should not show grades tab for observers" do
    course_with_student(:active_all => true)
    @student = @user
    user(:active_all => true)
    @oe = @course.enroll_user(@user, 'ObserverEnrollment')
    @oe.accept
    @user.reload
    tab_ids = @course.tabs_available(@user).map{|t| t[:id] }
    tab_ids.should_not be_include(Course::TAB_GRADES)
  end
    
  it "should show grades tab for observers if they are linked to a student" do
    course_with_student(:active_all => true)
    @student = @user
    user(:active_all => true)
    @oe = @course.enroll_user(@user, 'ObserverEnrollment')
    @oe.accept
    @oe.associated_user_id = @student.id
    @oe.save!
    @user.reload
    tab_ids = @course.tabs_available(@user).map{|t| t[:id] }
    tab_ids.should be_include(Course::TAB_GRADES)
  end
end

describe Course, "backup" do
  it "should backup to a valid data structure" do
    course_to_backup
    data = @course.backup
    data.should_not be_nil
    data.length.should > 0
    data.any?{|i| i.is_a?(Assignment)}.should eql(true)
    data.any?{|i| i.is_a?(WikiPage)}.should eql(true)
    data.any?{|i| i.is_a?(DiscussionTopic)}.should eql(true)
    data.any?{|i| i.is_a?(CalendarEvent)}.should eql(true)
  end
  
  it "should backup to a valid json string" do
    course_to_backup
    data = @course.backup_to_json
    data.should_not be_nil
    data.length.should > 0
    parse = JSON.parse(data) rescue nil
    parse.should_not be_nil
    parse.should be_is_a(Array)
    parse.length.should > 0
  end
    
  context "merge_into_course" do
    it "should merge content into another course" do
      course_model
      attachment_model
      @old_attachment = @attachment
      @old_topic = @course.discussion_topics.create!(:title => "some topic", :message => "<a href='/courses/#{@course.id}/files/#{@attachment.id}/download'>download this file</a>")
      html = @old_topic.message
      html.should match(Regexp.new("/courses/#{@course.id}/files/#{@attachment.id}/download"))
      @old_course = @course
      @new_course = course_model
      @new_course.merge_into_course(@old_course, :everything => true)
      @old_attachment.reload
      @old_attachment.cloned_item_id.should_not be_nil
      @new_attachment = @new_course.attachments.find_by_cloned_item_id(@old_attachment.cloned_item_id)
      @new_attachment.should_not be_nil
      @old_topic.reload
      @old_topic.cloned_item_id.should_not be_nil
      @new_topic = @new_course.discussion_topics.find_by_cloned_item_id(@old_topic.cloned_item_id)
      @new_topic.should_not be_nil
      html = @new_topic.message
      html.should match(Regexp.new("/courses/#{@new_course.id}/files/#{@new_attachment.id}/download"))
    end

    it "should merge locked files and retain correct html links" do
      course_model
      attachment_model
      @old_attachment = @attachment
      @old_attachment.update_attribute(:hidden, true)
      @old_attachment.reload.should be_hidden
      @old_topic = @course.discussion_topics.create!(:title => "some topic", :message => "<img src='/courses/#{@course.id}/files/#{@attachment.id}/preview'>")
      html = @old_topic.message
      html.should match(Regexp.new("/courses/#{@course.id}/files/#{@attachment.id}/preview"))
      @old_course = @course
      @new_course = course_model
      @new_course.merge_into_course(@old_course, :everything => true)
      @old_attachment.reload
      @old_attachment.cloned_item_id.should_not be_nil
      @new_attachment = @new_course.attachments.find_by_cloned_item_id(@old_attachment.cloned_item_id)
      @new_attachment.should_not be_nil
      @old_topic.reload
      @old_topic.cloned_item_id.should_not be_nil
      @new_topic = @new_course.discussion_topics.find_by_cloned_item_id(@old_topic.cloned_item_id)
      @new_topic.should_not be_nil
      html = @new_topic.message
      html.should match(Regexp.new("/courses/#{@new_course.id}/files/#{@new_attachment.id}/preview"))
    end

    it "should merge only selected content into another course" do
      course_model
      attachment_model
      @old_attachment = @attachment
      @old_topic = @course.discussion_topics.create!(:title => "some topic", :message => "<a href='/courses/#{@course.id}/files/#{@attachment.id}/download'>download this file</a>")
      html = @old_topic.message
      html.should match(Regexp.new("/courses/#{@course.id}/files/#{@attachment.id}/download"))
      @old_course = @course
      @new_course = course_model
      @new_course.merge_into_course(@old_course, :all_files => true)
      @old_attachment.reload
      @old_attachment.cloned_item_id.should_not be_nil
      @new_attachment = @new_course.attachments.find_by_cloned_item_id(@old_attachment.cloned_item_id)
      @new_attachment.should_not be_nil
      @old_topic.reload
      @old_topic.cloned_item_id.should be_nil
      @new_course.discussion_topics.count.should eql(0)
    end

    it "should migrate syllabus links on copy" do
      course_model
      @old_topic = @course.discussion_topics.create!(:title => "some topic", :message => "some text")
      @old_course = @course
      @old_course.syllabus_body = "<a href='/courses/#{@old_course.id}/discussion_topics/#{@old_topic.id}'>link</a>"
      @old_course.save!
      @new_course = course_model
      @new_course.merge_into_course(@old_course, :course_settings => true, :all_topics => true)
      @old_topic.reload
      @new_topic = @new_course.discussion_topics.find_by_cloned_item_id(@old_topic.cloned_item_id)
      @new_topic.should_not be_nil
      @old_topic.cloned_item_id.should == @new_topic.cloned_item_id
      @new_course.reload
      @new_course.syllabus_body.should match(/\/courses\/#{@new_course.id}\/discussion_topics\/#{@new_topic.id}/)
    end

    it "should merge implied content into another course" do
      course_model
      attachment_model
      @old_attachment = @attachment
      @old_topic = @course.discussion_topics.create!(:title => "some topic", :message => "<a href='/courses/#{@course.id}/files/#{@attachment.id}/download'>download this file</a>")
      html = @old_topic.message
      html.should match(Regexp.new("/courses/#{@course.id}/files/#{@attachment.id}/download"))
      @old_course = @course
      @new_course = course_model
      @new_course.merge_into_course(@old_course, :all_topics => true)
      @old_attachment.reload
      @old_attachment.cloned_item_id.should_not be_nil
      @new_attachment = @new_course.attachments.find_by_cloned_item_id(@old_attachment.cloned_item_id)
      @new_attachment.should_not be_nil
      @old_topic.reload
      @old_topic.cloned_item_id.should_not be_nil
      @new_topic = @new_course.discussion_topics.find_by_cloned_item_id(@old_topic.cloned_item_id)
      @new_topic.should_not be_nil
      html = @new_topic.message
      html.should match(Regexp.new("/courses/#{@new_course.id}/files/#{@new_attachment.id}/download"))
    end

    it "should translate links to the new context" do
      course_model
      attachment_model
      @old_attachment = @attachment
      @old_topic = @course.discussion_topics.create!(:title => "some topic", :message => "<a href='/courses/#{@course.id}/files/#{@attachment.id}/download'>download this file</a>")
      html = @old_topic.message
      html.should match(Regexp.new("/courses/#{@course.id}/files/#{@attachment.id}/download"))
      @old_course = @course
      @new_course = course_model
      @new_attachment = @old_attachment.clone_for(@new_course)
      @new_attachment.save!
      html = Course.migrate_content_links(@old_topic.message, @old_course, @new_course)
      html.should match(Regexp.new("/courses/#{@new_course.id}/files/#{@new_attachment.id}/download"))
    end

    it "should bring over linked files if not already brought over" do
      course_model
      attachment_model
      @old_attachment = @attachment
      @old_topic = @course.discussion_topics.create!(:title => "some topic", :message => "<a href='/courses/#{@course.id}/files/#{@attachment.id}/download'>download this file</a>")
      html = @old_topic.message
      html.should match(Regexp.new("/courses/#{@course.id}/files/#{@attachment.id}/download"))
      @old_course = @course
      @new_course = course_model
      html = Course.migrate_content_links(@old_topic.message, @old_course, @new_course)
      @old_attachment.reload
      @old_attachment.cloned_item_id.should_not be_nil
      @new_attachment = @new_course.attachments.find_by_cloned_item_id(@old_attachment.cloned_item_id)
      @new_attachment.should_not be_nil
      html.should match(Regexp.new("/courses/#{@new_course.id}/files/#{@new_attachment.id}/download"))
    end

    it "should bring over linked files that have been replaced" do
      course_model
      attachment_model
      @orig_attachment = @attachment

      @old_topic = @course.discussion_topics.create!(:title => "some topic", :message => "<a href='/courses/#{@course.id}/files/#{@attachment.id}/download'>download this file</a>")
      html = @old_topic.message
      html.should match(Regexp.new("/courses/#{@course.id}/files/#{@attachment.id}/download"))

      @orig_attachment.destroy
      attachment_model
      @old_attachment = @attachment
      @old_attachment.handle_duplicates(:overwrite)

      @old_course = @course
      @new_course = course_model
      html = Course.migrate_content_links(@old_topic.message, @old_course, @new_course)
      @old_attachment.reload
      @old_attachment.cloned_item_id.should_not be_nil
      @new_attachment = @new_course.attachments.find_by_cloned_item_id(@old_attachment.cloned_item_id)
      @new_attachment.should_not be_nil
      html.should match(Regexp.new("/courses/#{@new_course.id}/files/#{@new_attachment.id}/download"))
    end

    it "should assign the correct parent folder when the parent folder has already been created" do
      old_course = course_model
      folder = Folder.root_folders(@course).first
      folder = folder.sub_folders.create!(:context => @course, :name => 'folder_1')
      attachment_model(:folder => folder, :filename => "dummy.txt")
      folder = folder.sub_folders.create!(:context => @course, :name => 'folder_2')
      folder = folder.sub_folders.create!(:context => @course, :name => 'folder_3')
      old_attachment = attachment_model(:folder => folder, :filename => "merge.test")

      new_course = course_model

      new_course.merge_into_course(old_course, :everything => true)
      old_attachment.reload
      old_attachment.cloned_item_id.should_not be_nil
      new_attachment = new_course.attachments.find_by_cloned_item_id(old_attachment.cloned_item_id)
      new_attachment.should_not be_nil
      new_attachment.full_path.should == "course files/folder_1/folder_2/folder_3/merge.test"
      folder.reload
      new_attachment.folder.cloned_item_id.should == folder.cloned_item_id
    end

    it "should perform day substitutions" do
      old_course = course_model
      old_course.assert_assignment_group
      today = Time.now.utc
      @assignment = old_course.assignments.build
      @assignment.due_at = today
      @assignment.workflow_state = 'published'
      @assignment.save!
      old_course.reload

      new_course = course_model

      new_course.merge_into_course(old_course, :everything => true, :shift_dates => true, :day_substitutions => { today.wday.to_s => (today.wday + 1).to_s})
      new_course.reload
      new_assignment = new_course.assignments.first
      # new_assignment.due_at.should == today + 1.day does not work
      (new_assignment.due_at.to_i - (today + 1.day).to_i).abs.should < 60
    end
  end
  
  it "should not cross learning outcomes with learning outcome groups in the association" do
    # set up two courses with two outcomes
    course = course_model
    default_group = LearningOutcomeGroup.default_for(course)
    outcome = course.created_learning_outcomes.create!
    default_group.add_item(outcome)

    other_course = course_model
    other_default_group = LearningOutcomeGroup.default_for(other_course)
    other_outcome = other_course.created_learning_outcomes.create!
    other_default_group.add_item(other_outcome)

    # add another group to the first course, which "coincidentally" has the
    # same id as the second course's outcome
    other_group = course.learning_outcome_groups.build
    other_group.id = other_outcome.id
    other_group.save!
    default_group.add_item(other_group)

    # reload and check
    course.reload
    other_course.reload
    course.learning_outcomes.should be_include(outcome)
    course.learning_outcomes.should_not be_include(other_outcome)
    other_course.learning_outcomes.should be_include(other_outcome)
  end

  it "should copy learning outcomes into the new course" do
    old_course = course_model
    lo = old_course.learning_outcomes.new
    lo.context = old_course
    lo.short_description = "Lone outcome"
    lo.description = "<p>Descriptions are boring</p>"
    lo.workflow_state = 'active'
    lo.data = {:rubric_criterion=>{:mastery_points=>3, :ratings=>[{:description=>"Exceeds Expectations", :points=>5}, {:description=>"Meets Expectations", :points=>3}, {:description=>"Does Not Meet Expectations", :points=>0}], :description=>"First outcome", :points_possible=>5}}
    lo.save!
    
    old_root = LearningOutcomeGroup.default_for(old_course)
    old_root.add_item(lo)
    
    lo_g = old_course.learning_outcome_groups.new
    lo_g.context = old_course
    lo_g.title = "Lone outcome group"
    lo_g.description = "<p>Groupage</p>"
    lo_g.save!
    old_root.add_item(lo_g)
    
    lo2 = old_course.learning_outcomes.new
    lo2.context = old_course
    lo2.short_description = "outcome in group"
    lo2.workflow_state = 'active'
    lo2.data = {:rubric_criterion=>{:mastery_points=>2, :ratings=>[{:description=>"e", :points=>50}, {:description=>"me", :points=>2}, {:description=>"Does Not Meet Expectations", :points=>0.5}], :description=>"First outcome", :points_possible=>5}}
    lo2.save!
    lo_g.add_item(lo2)
    old_root.reload
    
    # copy outcomes into new course
    new_course = course_model
    new_root = LearningOutcomeGroup.default_for(new_course)
    new_course.merge_into_course(old_course, :all_outcomes => true)
    
    new_course.learning_outcomes.count.should == old_course.learning_outcomes.count
    new_course.learning_outcome_groups.count.should == old_course.learning_outcome_groups.count
    new_root.sorted_content.count.should == old_root.sorted_content.count
    
    lo_2 = new_root.sorted_content.first
    lo_2.short_description.should == lo.short_description
    lo_2.description.should == lo.description
    lo_2.data.should == lo.data
    
    lo_g_2 = new_root.sorted_content.last
    lo_g_2.title.should == lo_g.title
    lo_g_2.description.should == lo_g.description
    lo_g_2.sorted_content.length.should == 1
    lo_g_2.root_learning_outcome_group_id.should == new_root.id
    lo_g_2.learning_outcome_group_id.should == new_root.id
    
    lo_2 = lo_g_2.sorted_content.first
    lo_2.short_description.should == lo2.short_description
    lo_2.description.should == lo2.description
    lo_2.data.should == lo2.data
  end
  
end

def course_to_backup
  @course = course
  group = @course.assignment_groups.create!(:name => "Some Assignment Group")
  @course.assignments.create!(:title => "Some Assignment", :assignment_group => group)
  @course.calendar_events.create!(:title => "Some Event", :start_at => Time.now, :end_at => Time.now)
  @course.wiki.wiki_pages.create!(:title => "Some Page")
  topic = @course.discussion_topics.create!(:title => "Some Discussion")
  topic.discussion_entries.create!(:message => "just a test")
  @course
end

describe Course, 'grade_publishing' do
  before(:each) do
    @course = Course.new
  end
  
  after(:each) do
    Course.valid_grade_export_types.delete("test_export")
    PluginSetting.settings_for_plugin('grade_export')[:format_type] = "instructure_csv"
    PluginSetting.settings_for_plugin('grade_export')[:enabled] = "false"
    PluginSetting.settings_for_plugin('grade_export')[:publish_endpoint] = ""
    PluginSetting.settings_for_plugin('grade_export')[:wait_for_success] = "no"
  end
  
  it 'should pass a quick sanity check' do
    user = User.new
    Course.valid_grade_export_types["test_export"] = {
        :name => "test export",
        :callback => lambda {|course, enrollments, publishing_pseudonym|
          course.should == @course
          publishing_pseudonym.should == nil
          return [[[], "test-jt-data", "application/jtmimetype"]], []
        }}
    PluginSetting.settings_for_plugin('grade_export')[:enabled] = "true"
    PluginSetting.settings_for_plugin('grade_export')[:format_type] = "test_export"
    PluginSetting.settings_for_plugin('grade_export')[:wait_for_success] = "no"
    server, server_thread, post_lines = start_test_http_server
    PluginSetting.settings_for_plugin('grade_export')[:publish_endpoint] = "http://localhost:#{server.addr[1]}/endpoint"

    @course.grading_standard_id = 0
    @course.publish_final_grades(user)
    server_thread.join
    post_lines.should == [
        "POST /endpoint HTTP/1.1",
        "Accept: */*",
        "Content-Type: application/jtmimetype",
        "",
        "test-jt-data"]
  end
  
  it 'should publish csv' do
    user = User.new
    PluginSetting.settings_for_plugin('grade_export')[:enabled] = "true"
    PluginSetting.settings_for_plugin('grade_export')[:format_type] = "instructure_csv"
    PluginSetting.settings_for_plugin('grade_export')[:wait_for_success] = "no"
    server, server_thread, post_lines = start_test_http_server
    PluginSetting.settings_for_plugin('grade_export')[:publish_endpoint] = "http://localhost:#{server.addr[1]}/endpoint"
    @course.grading_standard_id = 0
    @course.publish_final_grades(user)
    server_thread.join
    post_lines.should == [
        "POST /endpoint HTTP/1.1",
        "Accept: */*",
        "Content-Type: text/csv",
        "",
        "publisher_id,publisher_sis_id,section_id,section_sis_id,student_id," +
        "student_sis_id,enrollment_id,enrollment_status,grade,score\n"]
  end

  it 'should publish grades' do
    process_csv_data_cleanly(
      "user_id,login_id,password,first_name,last_name,email,status",
      "T1,Teacher1,,T,1,t1@example.com,active",
      "S1,Student1,,S,1,s1@example.com,active",
      "S2,Student2,,S,2,s2@example.com,active",
      "S3,Student3,,S,3,s3@example.com,active",
      "S4,Student4,,S,4,s4@example.com,active",
      "S5,Student5,,S,5,s5@example.com,active",
      "S6,Student6,,S,6,s6@example.com,active")
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C1,C1,C1,,,active")
    @course = Course.find_by_sis_source_id("C1")
    @course.assignment_groups.create(:name => "Assignments")
    process_csv_data_cleanly(
      "section_id,course_id,name,status,start_date,end_date",
      "S1,C1,S1,active,,",
      "S2,C1,S2,active,,",
      "S3,C1,S3,active,,",
      "S4,C1,S4,active,,")
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status",
      ",T1,teacher,S1,active",
      ",S1,student,S1,active",
      ",S2,student,S2,active",
      ",S3,student,S2,active",
      ",S4,student,S1,active",
      ",S5,student,S3,active",
      ",S6,student,S4,active")
    a1 = @course.assignments.create!(:title => "A1", :points_possible => 10)
    a2 = @course.assignments.create!(:title => "A2", :points_possible => 10)
    
    def getpseudonym(user_sis_id)
      pseudo = Pseudonym.find_by_sis_user_id(user_sis_id)
      pseudo.should_not be_nil
      pseudo
    end
    
    def getuser(user_sis_id)
      user = getpseudonym(user_sis_id).user
      user.should_not be_nil
      user
    end
    
    def getsection(section_sis_id)
      section = CourseSection.find_by_sis_source_id(section_sis_id)
      section.should_not be_nil
      section
    end
    
    def getenroll(user_sis_id, section_sis_id)
      e = Enrollment.find_by_user_id_and_course_section_id(getuser(user_sis_id).id, getsection(section_sis_id).id)
      e.should_not be_nil
      e
    end
    
    a1.grade_student(getuser("S1"), { :grade => "6", :grader => getuser("T1") })
    a1.grade_student(getuser("S2"), { :grade => "6", :grader => getuser("T1") })
    a1.grade_student(getuser("S3"), { :grade => "7", :grader => getuser("T1") })
    a1.grade_student(getuser("S5"), { :grade => "7", :grader => getuser("T1") })
    a1.grade_student(getuser("S6"), { :grade => "8", :grader => getuser("T1") })
    a2.grade_student(getuser("S1"), { :grade => "8", :grader => getuser("T1") })
    a2.grade_student(getuser("S2"), { :grade => "9", :grader => getuser("T1") })
    a2.grade_student(getuser("S3"), { :grade => "9", :grader => getuser("T1") })
    a2.grade_student(getuser("S5"), { :grade => "10", :grader => getuser("T1") })
    a2.grade_student(getuser("S6"), { :grade => "10", :grader => getuser("T1") })
    
    stud5, stud6, sec4 = nil, nil, nil
    Pseudonym.find_by_sis_user_id("S5").tap do |p|
      stud5 = p
      p.sis_user_id = nil
      p.save
    end
    
    Pseudonym.find_by_sis_user_id("S6").tap do |p|
      stud6 = p
      p.sis_user_id = nil
      p.save
    end
    
    getsection("S4").tap do |s|
      sec4 = s
      sec4id = s.sis_source_id
      s.save
    end
    
    GradeCalculator.recompute_final_score(["S1", "S2", "S3", "S4"].map{|x|getuser(x).id}, @course.id)
    @course.reload
    
    teacher = Pseudonym.find_by_sis_user_id("T1")
    teacher.should_not be_nil
    
    PluginSetting.settings_for_plugin('grade_export')[:enabled] = "true"
    PluginSetting.settings_for_plugin('grade_export')[:format_type] = "instructure_csv"
    PluginSetting.settings_for_plugin('grade_export')[:wait_for_success] = "no"
    server, server_thread, post_lines = start_test_http_server
    PluginSetting.settings_for_plugin('grade_export')[:publish_endpoint] = "http://localhost:#{server.addr[1]}/endpoint"
    @course.publish_final_grades(teacher.user)
    server_thread.join
    post_lines.should == [
        "POST /endpoint HTTP/1.1",
        "Accept: */*",
        "Content-Type: text/csv",
        "",
        "publisher_id,publisher_sis_id,section_id,section_sis_id,student_id," +
        "student_sis_id,enrollment_id,enrollment_status,grade,score\n" +
        "#{teacher.id},T1,#{getsection("S1").id},S1,#{getpseudonym("S1").id},S1,#{getenroll("S1", "S1").id},active,\"\",70\n" +
        "#{teacher.id},T1,#{getsection("S2").id},S2,#{getpseudonym("S2").id},S2,#{getenroll("S2", "S2").id},active,\"\",75\n" +
        "#{teacher.id},T1,#{getsection("S2").id},S2,#{getpseudonym("S3").id},S3,#{getenroll("S3", "S2").id},active,\"\",80\n" +
        "#{teacher.id},T1,#{getsection("S1").id},S1,#{getpseudonym("S4").id},S4,#{getenroll("S4", "S1").id},active,\"\",0\n" + 
        "#{teacher.id},T1,#{getsection("S3").id},S3,#{stud5.id},,#{Enrollment.find_by_user_id_and_course_section_id(stud5.user.id, getsection("S3").id).id},active,\"\",85\n" + 
        "#{teacher.id},T1,#{sec4.id},S4,#{stud6.id},,#{Enrollment.find_by_user_id_and_course_section_id(stud6.user.id, sec4.id).id},active,\"\",90\n"]
    @course.grading_standard_id = 0
    @course.save
    server, server_thread, post_lines = start_test_http_server
    PluginSetting.settings_for_plugin('grade_export')[:publish_endpoint] = "http://localhost:#{server.addr[1]}/endpoint"
    @course.publish_final_grades(teacher.user)
    server_thread.join
    post_lines.should == [
        "POST /endpoint HTTP/1.1",
        "Accept: */*",
        "Content-Type: text/csv",
        "",
        "publisher_id,publisher_sis_id,section_id,section_sis_id,student_id," +
        "student_sis_id,enrollment_id,enrollment_status,grade,score\n" +
        "#{teacher.id},T1,#{getsection("S1").id},S1,#{getpseudonym("S1").id},S1,#{getenroll("S1", "S1").id},active,C-,70\n" +
        "#{teacher.id},T1,#{getsection("S2").id},S2,#{getpseudonym("S2").id},S2,#{getenroll("S2", "S2").id},active,C,75\n" +
        "#{teacher.id},T1,#{getsection("S2").id},S2,#{getpseudonym("S3").id},S3,#{getenroll("S3", "S2").id},active,B-,80\n" +
        "#{teacher.id},T1,#{getsection("S1").id},S1,#{getpseudonym("S4").id},S4,#{getenroll("S4", "S1").id},active,F,0\n" + 
        "#{teacher.id},T1,#{getsection("S3").id},S3,#{stud5.id},,#{Enrollment.find_by_user_id_and_course_section_id(stud5.user.id, getsection("S3").id).id},active,B,85\n" + 
        "#{teacher.id},T1,#{sec4.id},S4,#{stud6.id},,#{Enrollment.find_by_user_id_and_course_section_id(stud6.user.id, sec4.id).id},active,A-,90\n"]
  end
  
end

describe Course, 'tabs_available' do
  it "should not include external tools if not configured for course navigation" do
    course_model
    tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
    tool.settings[:user_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
    tool.save!
    tool.has_course_navigation.should == false
    @teacher = user_model
    @course.enroll_teacher(@teacher).accept
    tabs = @course.tabs_available(@teacher)
    tabs.map{|t| t[:id] }.should_not be_include(tool.asset_string)
  end
  
  it "should include external tools if configured on the course" do
    course_model
    tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
    tool.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
    tool.save!
    tool.has_course_navigation.should == true
    @teacher = user_model
    @course.enroll_teacher(@teacher).accept
    tabs = @course.tabs_available(@teacher)
    tabs.map{|t| t[:id] }.should be_include(tool.asset_string)
    tab = tabs.detect{|t| t[:id] == tool.asset_string }
    tab[:label].should == tool.settings[:course_navigation][:text]
    tab[:href].should == :course_external_tool_path
    tab[:args].should == [@course.id, tool.id]
  end
  
  it "should include external tools if configured on the account" do
    course_model
    @account = @course.root_account.sub_accounts.create!(:name => "sub-account")
    @course.move_to_account(@account.root_account, @account)
    tool = @account.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
    tool.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
    tool.save!
    tool.has_course_navigation.should == true
    @teacher = user_model
    @course.enroll_teacher(@teacher).accept
    tabs = @course.tabs_available(@teacher)
    tabs.map{|t| t[:id] }.should be_include(tool.asset_string)
    tab = tabs.detect{|t| t[:id] == tool.asset_string }
    tab[:label].should == tool.settings[:course_navigation][:text]
    tab[:href].should == :course_external_tool_path
    tab[:args].should == [@course.id, tool.id]
  end
  
  it "should include external tools if configured on the root account" do
    course_model
    @account = @course.root_account.sub_accounts.create!(:name => "sub-account")
    @course.move_to_account(@account.root_account, @account)
    tool = @account.root_account.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
    tool.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
    tool.save!
    tool.has_course_navigation.should == true
    @teacher = user_model
    @course.enroll_teacher(@teacher).accept
    tabs = @course.tabs_available(@teacher)
    tabs.map{|t| t[:id] }.should be_include(tool.asset_string)
    tab = tabs.detect{|t| t[:id] == tool.asset_string }
    tab[:label].should == tool.settings[:course_navigation][:text]
    tab[:href].should == :course_external_tool_path
    tab[:args].should == [@course.id, tool.id]
  end
  
  it "should only include admin-only external tools for course admins" do
    course_model
    @course.offer
    @course.is_public = true
    @course.save!
    tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
    tool.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL", :visibility => 'admins'}
    tool.save!
    tool.has_course_navigation.should == true
    @teacher = user_model
    @course.enroll_teacher(@teacher).accept
    @student = user_model
    @student.register!
    @course.enroll_student(@student).accept
    tabs = @course.tabs_available(nil)
    tabs.map{|t| t[:id] }.should_not be_include(tool.asset_string)
    tabs = @course.tabs_available(@student)
    tabs.map{|t| t[:id] }.should_not be_include(tool.asset_string)
    tabs = @course.tabs_available(@teacher)
    tabs.map{|t| t[:id] }.should be_include(tool.asset_string)
    tab = tabs.detect{|t| t[:id] == tool.asset_string }
    tab[:label].should == tool.settings[:course_navigation][:text]
    tab[:href].should == :course_external_tool_path
    tab[:args].should == [@course.id, tool.id]
  end
  
  it "should not include member-only external tools for unauthenticated users" do
    course_model
    @course.offer
    @course.is_public = true
    @course.save!
    tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
    tool.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL", :visibility => 'members'}
    tool.save!
    tool.has_course_navigation.should == true
    @teacher = user_model
    @course.enroll_teacher(@teacher).accept
    @student = user_model
    @student.register!
    @course.enroll_student(@student).accept
    tabs = @course.tabs_available(nil)
    tabs.map{|t| t[:id] }.should_not be_include(tool.asset_string)
    tabs = @course.tabs_available(@student)
    tabs.map{|t| t[:id] }.should be_include(tool.asset_string)
    tabs = @course.tabs_available(@teacher)
    tabs.map{|t| t[:id] }.should be_include(tool.asset_string)
    tab = tabs.detect{|t| t[:id] == tool.asset_string }
    tab[:label].should == tool.settings[:course_navigation][:text]
    tab[:href].should == :course_external_tool_path
    tab[:args].should == [@course.id, tool.id]
  end
  
  it "should allow reordering external tool position in course navigation" do
    course_model
    tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
    tool.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
    tool.save!
    tool.has_course_navigation.should == true
    @teacher = user_model
    @course.enroll_teacher(@teacher).accept
    @course.tab_configuration = Course.default_tabs.map{|t| {:id => t[:id] } }.insert(1, {:id => tool.asset_string})
    @course.save!
    tabs = @course.tabs_available(@teacher)
    tabs[1][:id].should == tool.asset_string
  end
  
  it "should not show external tools that are hidden in course navigation" do
    course_model
    tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
    tool.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
    tool.save!
    tool.has_course_navigation.should == true
    @teacher = user_model
    @course.enroll_teacher(@teacher).accept
    tabs = @course.tabs_available(@teacher)
    tabs.map{|t| t[:id] }.should be_include(tool.asset_string)
    
    @course.tab_configuration = Course.default_tabs.map{|t| {:id => t[:id] } }.insert(1, {:id => tool.asset_string, :hidden => true})
    @course.save!
    @course = Course.find(@course.id)
    tabs = @course.tabs_available(@teacher)
    tabs.map{|t| t[:id] }.should_not be_include(tool.asset_string)
    
    tabs = @course.tabs_available(@teacher, :for_reordering => true)
    tabs.map{|t| t[:id] }.should be_include(tool.asset_string)
  end
  
end

describe Course, 'scoping' do
  it 'should search by multiple fields' do
    c1 = Course.new
    c1.root_account = Account.create
    c1.name = "name1"
    c1.sis_source_id = "sisid1"
    c1.course_code = "code1"
    c1.save
    c2 = Course.new
    c2.root_account = Account.create
    c2.name = "name2"
    c2.course_code = "code2"
    c2.sis_source_id = "sisid2"
    c2.save
    Course.name_like("name1").map(&:id).should == [c1.id]
    Course.name_like("sisid2").map(&:id).should == [c2.id]
    Course.name_like("code1").map(&:id).should == [c1.id]    
  end
end

describe Course, "manageable_by_user" do
  it "should include courses associated with the user's active accounts" do
    account = Account.create!
    sub_account = Account.create!(:parent_account => account)
    sub_sub_account = Account.create!(:parent_account => sub_account)
    user = account_admin_user(:account => sub_account)
    course = Course.create!(:account => sub_sub_account)

    Course.manageable_by_user(user.id).map{ |c| c.id }.should be_include(course.id)
  end

  it "should include courses the user is actively enrolled in as a teacher" do
    course = Course.create
    user = user_with_pseudonym
    course.enroll_teacher(user)
    e = course.teacher_enrollments.first
    e.accept

    Course.manageable_by_user(user.id).map{ |c| c.id }.should be_include(course.id)
  end

  it "should include courses the user is actively enrolled in as a ta" do
    course = Course.create
    user = user_with_pseudonym
    course.enroll_ta(user)
    e = course.ta_enrollments.first
    e.accept

    Course.manageable_by_user(user.id).map{ |c| c.id }.should be_include(course.id)
  end

  it "should not include courses the user is enrolled in when the enrollment is non-active" do
    course = Course.create
    user = user_with_pseudonym
    course.enroll_teacher(user)
    e = course.teacher_enrollments.first

    # it's only invited at this point
    Course.manageable_by_user(user.id).should be_empty

    e.destroy
    Course.manageable_by_user(user.id).should be_empty
  end

  it "should not include aborted or deleted courses the user was enrolled in" do
    course = Course.create
    user = user_with_pseudonym
    course.enroll_teacher(user)
    e = course.teacher_enrollments.first
    e.accept

    course.destroy
    Course.manageable_by_user(user.id).should be_empty
  end
end

describe Course, "conclusions" do
  it "should grant concluded users read but not participate" do
    enrollment = course_with_student(:active_all => 1)
    @course.reload

    # active
    @course.grants_rights?(@user, nil, :read, :participate_as_student).should == {:read => true, :participate_as_student => true}

    # soft conclusion
    enrollment.start_at = 4.days.ago
    enrollment.end_at = 2.days.ago
    enrollment.save!
    @course.reload
    @user.reload
    @user.cached_current_enrollments(:reload)

    enrollment.state.should == :active
    enrollment.state_based_on_date.should == :completed
    enrollment.should_not be_participating_student

    @course.grants_rights?(@user, nil, :read, :participate_as_student).should == {:read => true, :participate_as_student => false}

    # hard enrollment conclusion
    enrollment.start_at = enrollment.end_at = nil
    enrollment.workflow_state = 'completed'
    enrollment.save!
    @course.reload
    @user.reload
    @user.cached_current_enrollments(:reload)
    enrollment.state.should == :completed
    enrollment.state_based_on_date.should == :completed

    @course.grants_rights?(@user, nil, :read, :participate_as_student).should == {:read => true, :participate_as_student => false}

    # course conclusion
    enrollment.workflow_state = 'active'
    enrollment.save!
    @course.reload
    @course.complete!
    @user.reload
    @user.cached_current_enrollments(:reload)
    enrollment.reload
    enrollment.state.should == :completed
    enrollment.state_based_on_date.should == :completed

    @course.grants_rights?(@user, nil, :read, :participate_as_student).should == {:read => true, :participate_as_student => false}
  end
end

describe Course, "inherited_assessment_question_banks" do
  it "should include the course's banks if include_self is true" do
    @account = Account.create
    @course = Course.create(:account => @account)
    @course.inherited_assessment_question_banks(true).should be_empty

    bank = @course.assessment_question_banks.create
    @course.inherited_assessment_question_banks(true).should eql [bank]
  end

  it "should include all banks in the account hierarchy" do
    @root_account = Account.create
    root_bank = @root_account.assessment_question_banks.create

    @account = Account.new
    @account.root_account = @root_account
    @account.save
    account_bank = @account.assessment_question_banks.create

    @course = Course.create(:account => @account)
    @course.inherited_assessment_question_banks.sort_by(&:id).should eql [root_bank, account_bank]
  end

  it "should return a useful scope" do
    @root_account = Account.create
    root_bank = @root_account.assessment_question_banks.create

    @account = Account.new
    @account.root_account = @root_account
    @account.save
    account_bank = @account.assessment_question_banks.create

    @course = Course.create(:account => @account)
    bank = @course.assessment_question_banks.create

    banks = @course.inherited_assessment_question_banks(true)
    banks.scoped(:order => :id).should eql [root_bank, account_bank, bank]
    banks.find_by_id(bank.id).should eql bank
    banks.find_by_id(account_bank.id).should eql account_bank
    banks.find_by_id(root_bank.id).should eql root_bank
  end
end

describe Course, "section_visibility" do
  before do
    @course = course(:active_course => true)
    @course.default_section
    @other_section = @course.course_sections.create

    @teacher = User.create
    @course.enroll_teacher(@teacher)

    @ta = User.create
    @course.enroll_user(@ta, "TaEnrollment", :limit_priveleges_to_course_section => true)

    @student1 = User.create
    @course.enroll_user(@student1, "StudentEnrollment", :enrollment_state => 'active')

    @student2 = User.create
    @course.enroll_user(@student2, "StudentEnrollment", :section => @other_section, :enrollment_state => 'active')

    @observer = User.create
    @course.enroll_user(@observer, "ObserverEnrollment")
  end

  context "full" do
    it "should return students from all sections" do
      @course.students_visible_to(@teacher).sort_by(&:id).should eql [@student1, @student2]
      @course.students_visible_to(@student1).sort_by(&:id).should eql [@student1, @student2]
    end

    it "should return all sections if a teacher" do
      @course.sections_visible_to(@teacher).sort_by(&:id).should eql [@course.default_section, @other_section]
    end

    it "should return user's sections if a student" do
      @course.sections_visible_to(@student1).should eql [@course.default_section]
    end
  end

  context "sections" do
    it "should return students from user's sections" do
      @course.students_visible_to(@ta).should eql [@student1]
    end

    it "should return user's sections" do
      @course.sections_visible_to(@ta).should eql [@course.default_section]
    end
  end

  context "restricted" do
    it "should return no students" do
      @course.students_visible_to(@observer).should eql []
    end

    it "should return no sections" do
      @course.sections_visible_to(@observer).should eql []
    end
  end

  context "migrate_content_links" do
    it "should ignore types not in the supported_types arg" do
      c1 = course_model
      c2 = course_model
      orig = <<-HTML
      We aren't translating <a href="/courses/#{c1.id}/assignments/5">links to assignments</a>
      HTML
      html = Course.migrate_content_links(orig, c1, c2, ['files'])
      html.should == orig
    end
  end
end
