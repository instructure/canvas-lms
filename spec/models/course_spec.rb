#
# Copyright (C) 2012 Instructure, Inc.
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
      @designer = user(:active_all => true)
      @course.enroll_designer(@designer).accept!

      @course.grants_right?(@teacher, nil, :delete).should be_true
      @course.grants_right?(@designer, nil, :delete).should be_true
      @course.grants_right?(@admin1, nil, :delete).should be_true
      @course.grants_right?(@admin2, nil, :delete).should be_false

      @course.complete!

      @course.grants_right?(@teacher, nil, :delete).should be_true
      @course.grants_right?(@designer, nil, :delete).should be_true
      @course.grants_right?(@admin1, nil, :delete).should be_true
      @course.grants_right?(@admin2, nil, :delete).should be_false

      @course.sis_source_id = 'sis_id'
      @course.save!

      @course.grants_right?(@teacher, nil, :delete).should be_false
      @course.grants_right?(@designer, nil, :delete).should be_false
      @course.grants_right?(@admin1, nil, :delete).should be_true
      @course.grants_right?(@admin2, nil, :delete).should be_true
    end

    def make_date_completed
      @enrollment.start_at = 4.days.ago
      @enrollment.end_at = 2.days.ago
      @enrollment.save!
      @enrollment.state_based_on_date.should == :completed
    end

    it "should grant read_as_admin and read_forum to date-completed teacher" do
      course_with_teacher(:active_all => 1)
      make_date_completed
      @course.prior_enrollments.should == []
      @course.grants_right?(@teacher, nil, :read_as_admin).should be_true
      @course.grants_right?(@teacher, nil, :read_forum).should be_true
    end

    it "should grant read_as_admin and read to date-completed teacher of unpublished course" do
      course_with_teacher(:active_all => 1)
      @course.update_attribute(:workflow_state, 'claimed')
      make_date_completed
      @course.prior_enrollments.should == []
      @course.grants_right?(@teacher, nil, :read_as_admin).should be_true
      @course.grants_right?(@teacher, nil, :read).should be_true
    end

    it "should grant read_as_admin, read, manage, and update to date-active designer" do
      course(:active_all => 1)
      @designer = user(:active_all => 1)
      @course.enroll_designer(@designer).accept!
      @course.grants_right?(@designer, nil, :read_as_admin).should be_true
      @course.grants_right?(@designer, nil, :read).should be_true
      @course.grants_right?(@designer, nil, :manage).should be_true
      @course.grants_right?(@designer, nil, :update).should be_true
    end

    it "should grant read_as_admin, read_roster, and read_prior_roster to date-completed designer" do
      course(:active_all => 1)
      @designer = user(:active_all => 1)
      @enrollment = @course.enroll_designer(@designer)
      @enrollment.accept!
      @enrollment.start_at = 4.days.ago
      @enrollment.end_at = 2.days.ago
      @enrollment.save!
      @enrollment.state_based_on_date.should == :completed
      @course.prior_enrollments.should == []
      @course.grants_right?(@designer, nil, :read_as_admin).should be_true
      @course.grants_right?(@designer, nil, :read_roster).should be_true
      @course.grants_right?(@designer, nil, :read_prior_roster).should be_true
    end

    it "should grant read_as_admin and read to date-completed designer of unpublished course" do
      course(:active_all => 1)
      @designer = user(:active_all => 1)
      @enrollment = @course.enroll_designer(@designer)
      @enrollment.accept!
      @course.update_attribute(:workflow_state, 'claimed')
      make_date_completed
      @course.prior_enrollments.should == []
      @course.grants_right?(@designer, nil, :read_as_admin).should be_true
      @course.grants_right?(@designer, nil, :read).should be_true
    end

    it "should not grant read_user_notes or view_all_grades to designer" do
      course(:active_all => 1)
      @designer = user(:active_all => 1)
      @course.enroll_designer(@designer).accept!
      @course.grants_right?(@designer, nil, :read_user_notes).should be_false
      @course.grants_right?(@designer, nil, :view_all_grades).should be_false
    end

    it "should grant read_grades read_forum to date-completed student" do
      course_with_student(:active_all => 1)
      make_date_completed
      @course.prior_enrollments.should == []
      @course.grants_right?(@student, nil, :read_grades).should be_true
      @course.grants_right?(@student, nil, :read_forum).should be_true
    end

    it "should not grant read to completed students of an unpublished course" do
      course_with_student(:active_user => 1)
      @course.should be_created
      @enrollment.update_attribute(:workflow_state, 'completed')
      @enrollment.should be_completed
      @course.grants_right?(:read, @student).should be_false
    end

    it "should not grant read to soft-completed students of an unpublished course" do
      course_with_student(:active_user => 1)
      @course.restrict_enrollments_to_course_dates = true
      @course.start_at = 4.days.ago
      @course.conclude_at = 2.days.ago
      @course.save!
      @course.should be_created
      @enrollment.update_attribute(:workflow_state, 'active')
      @enrollment.state_based_on_date.should == :completed
      @course.grants_right?(:read, @student).should be_false
    end

    it "should not grant read to soft-inactive teachers" do
      course_with_teacher(:active_user => 1)
      @course.enrollment_term.update_attributes(:start_at => 2.days.from_now, :end_at => 4.days.from_now)
      @enrollment.update_attribute(:workflow_state, 'active')
      @enrollment.state_based_on_date.should == :inactive
      @course.grants_right?(:read, @teacher).should be_false
    end
  end

  it "should clear content when resetting" do
    course_with_student
    @course.discussion_topics.create!
    @course.quizzes.create!
    @course.assignments.create!
    @course.wiki.wiki_page.save!
    @course.self_enrollment = true
    @course.sis_source_id = 'sis_id'
    @course.stuck_sis_fields = [].to_set
    @course.save!
    @course.course_sections.should_not be_empty
    @course.students.should == [@student]
    @course.stuck_sis_fields.should == [].to_set
    self_enrollment_code = @course.self_enrollment_code
    self_enrollment_code.should_not be_nil

    @new_course = @course.reset_content

    @course.reload
    @course.stuck_sis_fields.should == [:workflow_state].to_set
    @course.course_sections.should be_empty
    @course.students.should be_empty
    @course.sis_source_id.should be_nil
    @course.self_enrollment_code.should be_nil

    @new_course.reload
    @new_course.course_sections.should_not be_empty
    @new_course.students.should == [@student]
    @new_course.discussion_topics.should be_empty
    @new_course.quizzes.should be_empty
    @new_course.assignments.should be_empty
    @new_course.sis_source_id.should == 'sis_id'
    @new_course.syllabus_body.should be_blank
    @new_course.stuck_sis_fields.should == [].to_set
    @new_course.self_enrollment_code.should == self_enrollment_code

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
    @course.stuck_sis_fields.should == [:workflow_state, :name].to_set
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

  context "events_for" do
    it "should return appropriate events" do
      course_with_teacher(:active_all => true)
      event1 = @course.calendar_events.create
      event2 = @course.calendar_events.build :child_event_data => [{:start_at => "2012-01-01", :end_at => "2012-01-02", :context_code => @course.default_section.asset_string}]
      event2.updating_user = @teacher
      event2.save!
      event3 = event2.child_events.first
      appointment_group = AppointmentGroup.create! :title => "ag", :contexts => [@course]
      appointment_group.publish!
      assignment = @course.assignments.create!

      events = @course.events_for(@teacher)
      events.should include event1
      events.should_not include event2
      events.should include event3
      events.should include appointment_group
      events.should include assignment
    end

    it "should return appropriate events when no user is supplied" do
      course_with_teacher(:active_all => true)
      event1 = @course.calendar_events.create
      event2 = @course.calendar_events.build :child_event_data => [{:start_at => "2012-01-01", :end_at => "2012-01-02", :context_code => @course.default_section.asset_string}]
      event2.updating_user = @teacher
      event2.save!
      event3 = event2.child_events.first
      appointment_group = AppointmentGroup.create! :title => "ag", :contexts => [@course]
      appointment_group.publish!
      assignment = @course.assignments.create!

      events = @course.events_for(nil)
      events.should include event1
      events.should_not include event2
      events.should_not include event3
      events.should_not include appointment_group
      events.should include assignment
    end
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
  
  it "should be able to enroll a designer" do
    @course.enroll_designer(@user)
    @de = @course.designer_enrollments.first
    @de.user_id.should eql(@user.id)
    @de.course_id.should eql(@course.id)
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
    @course.score_to_grade(95).should eql(nil)
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
  
  it "should order assignments by due date, assignment_group, position, title" do
    course_with_student(:active_all => true)

    @assignment_group_1, @assignment_group_2 = [@course.assignment_groups.create!(:name => "Some Assignment Group 1", :group_weight => 100), @course.assignment_groups.create!(:name => "Some Assignment Group 2", :group_weight => 100)].sort_by{|a| a.id}

    now = Time.now

    @assignment = @course.assignments.create!(:title => "Some Assignment 01", :points_possible => 10, :due_at => now + 1.days, :position => 3, :assignment_group => @assignment_group_1)
    @assignment = @course.assignments.create!(:title => "Some Assignment 02", :points_possible => 10, :due_at => now + 1.days, :position => 1, :assignment_group => @assignment_group_1)
    @assignment = @course.assignments.create!(:title => "Some Assignment 03", :points_possible => 10, :due_at => now + 1.days, :position => 2, :assignment_group => @assignment_group_1)
    @assignment = @course.assignments.create!(:title => "Some Assignment 05", :points_possible => 10, :due_at => now + 4.days, :position => 4, :assignment_group => @assignment_group_1)
    @assignment = @course.assignments.create!(:title => "Some Assignment 04", :points_possible => 10, :due_at => now + 5.days, :position => 5, :assignment_group => @assignment_group_1)
    @assignment = @course.assignments.create!(:title => "Some Assignment 06", :points_possible => 10, :due_at => now + 7.days, :position => 6, :assignment_group => @assignment_group_1)
    @assignment = @course.assignments.create!(:title => "Some Assignment 07", :points_possible => 10, :due_at => now + 6.days, :position => 7, :assignment_group => @assignment_group_1)
    @assignment = @course.assignments.create!(:title => "Some Assignment 08", :points_possible => 10, :due_at => now + 8.days, :position => 1, :assignment_group => @assignment_group_2)
    @assignment = @course.assignments.create!(:title => "Some Assignment 09", :points_possible => 10, :due_at => now + 8.days, :position => 9, :assignment_group => @assignment_group_1)
    @assignment = @course.assignments.create!(:title => "Some Assignment 10", :points_possible => 10, :due_at => now + 8.days, :position => 10, :assignment_group => @assignment_group_2)
    @assignment = @course.assignments.create!(:title => "Some Assignment 11", :points_possible => 10, :due_at => now + 11.days, :position => 11, :assignment_group => @assignment_group_1)
    @assignment = @course.assignments.create!(:title => "Some Assignment 13", :points_possible => 10, :due_at => now + 11.days, :position => 11, :assignment_group => @assignment_group_1)
    @assignment = @course.assignments.create!(:title => "Some Assignment 12", :points_possible => 10, :due_at => now + 11.days, :position => 11, :assignment_group => @assignment_group_1)
    @assignment = @course.assignments.create!(:title => "Some Assignment 14", :points_possible => 10, :due_at => nil, :position => 14, :assignment_group => @assignment_group_1)
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
    assignments.should == ["Some Assignment 14", "Some Assignment 02", "Some Assignment 03", "Some Assignment 01", "Some Assignment 05", "Some Assignment 04", "Some Assignment 07", "Some Assignment 06", "Some Assignment 09", "Some Assignment 08", "Some Assignment 10", "Some Assignment 11", "Some Assignment 12", "Some Assignment 13"]
  end

  it "should work for just one assignment" do
    course_with_student(:active_all => true)
    now = Time.now
    @assignment = @course.assignments.create!(:title => "Some Assignment 1", :points_possible => 10, :assignment_group => @group, :due_at => now + 1.days, :position => 3)
    @assignment = @course.assignments.create!(:title => "Some Assignment 2", :points_possible => 10, :assignment_group => @group, :due_at => now + 1.days, :position => 1)
    @course.recompute_student_scores
    @user.reload
    @course.reload

    csv = @course.gradebook_to_csv :assignment_id => @assignment
    csv.should_not be_nil
    rows = FasterCSV.parse(csv)
    rows.length.should equal(3)
    assignments = []
    rows[0].each do |column|
      assignments << column.sub(/ \([0-9]+\)/, '') if column =~ /Some Assignment/
    end
    assignments.should == ["Some Assignment 2"]
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

  it "should only include students once" do
    # students might have multiple enrollments in a course
    course(:active_all => true)
    @user1 = user_with_pseudonym(:active_all => true, :name => 'Brian', :username => 'brianp@instructure.com')
    student_in_course(:user => @user1)
    @user2 = user_with_pseudonym(:active_all => true, :name => 'Cody', :username => 'cody@instructure.com')
    student_in_course(:user => @user2)
    @s2 = @course.course_sections.create!(:name => 'section2')
    StudentEnrollment.create!(:user => @user1, :course => @course, :course_section => @s2)
    @course.reload
    csv = @course.gradebook_to_csv(:include_sis_id => true)
    rows = FasterCSV.parse(csv)
    rows.length.should == 4
  end

  it "should include muted if any assignments are muted" do
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
      @assignment.muted = true
      @assignment.save!
      @assignment.grade_student(@user1, :grade => "10")
      @assignment.grade_student(@user2, :grade => "9")
      @assignment.grade_student(@user3, :grade => "9")
      @assignment2 = @course.assignments.create!(:title => "Some Assignment 2", :points_possible => 10, :assignment_group => @group)
      @course.recompute_student_scores
      @course.reload

      csv = @course.gradebook_to_csv(:include_sis_id => true)
      csv.should_not be_nil
      rows = FasterCSV.parse(csv)
      rows.length.should == 6
      rows[0][1].should == 'ID'
      rows[0][2].should == 'SIS User ID'
      rows[0][3].should == 'SIS Login ID'
      rows[0][4].should == 'Section'
      rows[1][0].should == 'Muted assignments do not impact Current and Final score columns'
      rows[1][5].should == 'Muted'
      rows[1][6].should == ''
      rows[2][2].should == ''
      rows[2][3].should == ''
      rows[2][4].should == ''
      rows[2][-1].should == '(read only)'
      rows[3][1].should == @user1.id.to_s
      rows[3][2].should == 'SISUSERID'
      rows[3][3].should == @user1.pseudonym.unique_id
      rows[4][1].should == @user2.id.to_s
      rows[4][2].should be_nil
      rows[4][3].should == @user2.pseudonym.unique_id
      rows[5][1].should == @user3.id.to_s
      rows[5][2].should be_nil
      rows[5][3].should be_nil
  end

  it "should only include students from the appropriate section for a section limited teacher" do
    course(:active_all => 1)
    @teacher.enrollments.first.update_attribute(:limit_privileges_to_course_section, true)
    @section = @course.course_sections.create!(:name => 'section 2')
    @user1 = user_with_pseudonym(:active_all => true, :name => 'Brian', :username => 'brianp@instructure.com')
    @section.enroll_user(@user1, 'StudentEnrollment', 'active')
    @user2 = user_with_pseudonym(:active_all => true, :name => 'Jeremy', :username => 'jeremy@instructure.com')
    @course.enroll_student(@user2)

    csv = @course.gradebook_to_csv(:user => @teacher)
    csv.should_not be_nil
    rows = FasterCSV.parse(csv)
    # two header rows, and one student row
    rows.length.should == 3
    rows[2][1].should == @user2.id.to_s
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

  it "should show discussion tab for observers by default" do
    course_with_observer
    tab_ids = @course.tabs_available(@user).map{|t| t[:id] }
    tab_ids.should be_include(Course::TAB_DISCUSSIONS)
  end

  it "should not show discussion tab for observers without read_forum" do
    course_with_observer
    RoleOverride.create!(:context => @course.account, :permission => 'read_forum',
                         :enrollment_type => "ObserverEnrollment", :enabled => false)
    tab_ids = @course.tabs_available(@user).map{|t| t[:id] }
    tab_ids.should_not be_include(Course::TAB_DISCUSSIONS)
  end

  it "should include tabs for active external tools" do
    course_with_student(:active_all => true)

    tools = []
    2.times do |n|
      tools << @course.context_external_tools.create!(
        :url => "http://example.com/ims/lti",
        :consumer_key => "asdf",
        :shared_secret => "hjkl",
        :name => "external tool #{n+1}",
        :course_navigation => {
          :text => "blah",
          :url =>  "http://example.com/ims/lti",
          :default => false,
        }
      )
    end
    t1, t2 = tools

    t2.workflow_state = "deleted"
    t2.save!

    tabs = @course.tabs_available.map { |tab| tab[:id] }

    tabs.should be_include(t1.asset_string)
    tabs.should_not be_include(t2.asset_string)
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
  end
  
  it "should not cross learning outcomes with learning outcome groups in the association" do
    pending('fails when being run in the single thread rake task')
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

  it "should not count learning outcome groups as having outcomes" do
    course = course_model
    default_group = LearningOutcomeGroup.default_for(course)
    other_group = course.learning_outcome_groups.create!
    default_group.add_item(other_group)
    
    course.has_outcomes.should == false
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
    @course.root_account_id = Account.default.id
    @course.save!
    @course_section = @course.default_section
  end
  
  after(:each) do
    Course.valid_grade_export_types.delete("test_export")
  end

  context 'mocked plugin settings' do
    
    before(:each) do
      @plugin_settings = Canvas::Plugin.find!("grade_export").default_settings.clone
      @plugin = mock()
      Canvas::Plugin.stubs("find!".to_sym).with('grade_export').returns(@plugin)
      @plugin.stubs(:settings).returns{@plugin_settings}
    end
    
    context 'grade_publishing_status_translation' do
      it 'should work with nil statuses and messages' do
        @course.grade_publishing_status_translation(nil, nil).should == "Unpublished"
        @course.grade_publishing_status_translation(nil, "hi").should == "Unpublished: hi"
        @course.grade_publishing_status_translation("published", nil).should == "Published"
        @course.grade_publishing_status_translation("published", "hi").should == "Published: hi"
      end

      it 'should work with invalid statuses' do
        @course.grade_publishing_status_translation("invalid_status", nil).should == "Unknown status, invalid_status"
        @course.grade_publishing_status_translation("invalid_status", "what what").should == "Unknown status, invalid_status: what what"
      end

      it "should work with empty string statuses and messages" do
        @course.grade_publishing_status_translation("", "").should == "Unpublished"
        @course.grade_publishing_status_translation("", "hi").should == "Unpublished: hi"
        @course.grade_publishing_status_translation("published", "").should == "Published"
        @course.grade_publishing_status_translation("published", "hi").should == "Published: hi"
      end

      it 'should work with all known statuses' do
        @course.grade_publishing_status_translation("error", nil).should == "Error"
        @course.grade_publishing_status_translation("error", "hi").should == "Error: hi"
        @course.grade_publishing_status_translation("unpublished", nil).should == "Unpublished"
        @course.grade_publishing_status_translation("unpublished", "hi").should == "Unpublished: hi"
        @course.grade_publishing_status_translation("pending", nil).should == "Pending"
        @course.grade_publishing_status_translation("pending", "hi").should == "Pending: hi"
        @course.grade_publishing_status_translation("publishing", nil).should == "Publishing"
        @course.grade_publishing_status_translation("publishing", "hi").should == "Publishing: hi"
        @course.grade_publishing_status_translation("published", nil).should == "Published"
        @course.grade_publishing_status_translation("published", "hi").should == "Published: hi"
        @course.grade_publishing_status_translation("unpublishable", nil).should == "Unpublishable"
        @course.grade_publishing_status_translation("unpublishable", "hi").should == "Unpublishable: hi"
      end
    end

    def make_student_enrollments
      @student_enrollments = []
      9.times do
        @student_enrollments << student_in_course({:course => @course, :active_all => true})
      end
      @student_enrollments[0].tap do |enrollment|
        enrollment.grade_publishing_status = "published"
        enrollment.save!
      end
      @student_enrollments[2].tap do |enrollment|
        enrollment.grade_publishing_status = "unpublishable"
        enrollment.save!
      end
      @student_enrollments[1].tap do |enrollment|
        enrollment.grade_publishing_status = "error"
        enrollment.grade_publishing_message = "cause of this reason"
        enrollment.save!
      end
      @student_enrollments[3].tap do |enrollment|
        enrollment.grade_publishing_status = "error"
        enrollment.grade_publishing_message = "cause of that reason"
        enrollment.save!
      end
      @student_enrollments[4].tap do |enrollment|
        enrollment.grade_publishing_status = "unpublishable"
        enrollment.save!
      end
      @student_enrollments[5].tap do |enrollment|
        enrollment.grade_publishing_status = "unpublishable"
        enrollment.save!
      end
      @student_enrollments[6].tap do |enrollment|
        enrollment.workflow_state = "inactive"
        enrollment.save!
      end
      @student_enrollments
    end

    def grade_publishing_user
      @user = user_with_pseudonym
      @pseudonym.account_id = @course.root_account_id
      @pseudonym.sis_user_id = "U1"
      @pseudonym.save!
      @user
    end

    context 'grade_publishing_statuses' do
      it 'should generate enrollments categorized by grade publishing message' do
        make_student_enrollments
        messages, overall_status = @course.grade_publishing_statuses
        overall_status.should == "error"
        messages.count.should == 5
        messages["Unpublished"].sort_by(&:id).should == [
            @student_enrollments[7],
            @student_enrollments[8]
          ].sort_by(&:id)
        messages["Published"].should == [
            @student_enrollments[0]
          ]
        messages["Error: cause of this reason"].should == [
            @student_enrollments[1]
          ]
        messages["Error: cause of that reason"].should == [
            @student_enrollments[3]
          ]
        messages["Unpublishable"].sort_by(&:id).should == [
            @student_enrollments[2],
            @student_enrollments[4],
            @student_enrollments[5]
          ].sort_by(&:id)
      end

      it 'should correctly figure out the overall status with no enrollments' do
        @course.grade_publishing_statuses.should == [{}, "unpublished"]
      end

      it 'should correctly figure out the overall status with invalid enrollment statuses' do
        make_student_enrollments
        @student_enrollments.each do |e|
          e.grade_publishing_status = "invalid status"
          e.save!
        end
        messages, overall_status = @course.grade_publishing_statuses
        overall_status.should == "error"
        messages.count.should == 3
        messages["Unknown status, invalid status: cause of this reason"].should == [@student_enrollments[1]]
        messages["Unknown status, invalid status: cause of that reason"].should == [@student_enrollments[3]]
        messages["Unknown status, invalid status"].sort_by(&:id).should == [
            @student_enrollments[0],
            @student_enrollments[2],
            @student_enrollments[4],
            @student_enrollments[5],
            @student_enrollments[7],
            @student_enrollments[8]].sort_by(&:id)
      end

      it 'should fall back to the right overall status' do
        make_student_enrollments
        @student_enrollments.each do |e|
          e.grade_publishing_status = "unpublishable"
          e.grade_publishing_message = nil
          e.save!
        end
        @course.reload.grade_publishing_statuses[1].should == "unpublishable"
        @student_enrollments[0].tap do |e|
          e.grade_publishing_status = "published"
          e.save!
        end
        @course.reload.grade_publishing_statuses[1].should == "published"
        @student_enrollments[1].tap do |e|
          e.grade_publishing_status = "publishing"
          e.save!
        end
        @course.reload.grade_publishing_statuses[1].should == "publishing"
        @student_enrollments[2].tap do |e|
          e.grade_publishing_status = "pending"
          e.save!
        end
        @course.reload.grade_publishing_statuses[1].should == "pending"
        @student_enrollments[3].tap do |e|
          e.grade_publishing_status = "unpublished"
          e.save!
        end
        @course.reload.grade_publishing_statuses[1].should == "unpublished"
        @student_enrollments[4].tap do |e|
          e.grade_publishing_status = "error"
          e.save!
        end
        @course.reload.grade_publishing_statuses[1].should == "error"
      end
    end

    context 'publish_final_grades' do

      it 'should check whether or not grade export is enabled - success' do
        grade_publishing_user
        @course.expects(:send_final_grades_to_endpoint).with(@user).returns(nil)
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
        @course.publish_final_grades(@user)
      end

      it 'should check whether or not grade export is enabled - failure' do
        grade_publishing_user
        @plugin.stubs(:enabled?).returns(false)
        @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
        (lambda {@course.publish_final_grades(@user)}).should raise_error("final grade publishing disabled")
      end

      it 'should update all student enrollments with pending and a last update status' do
        make_student_enrollments
        @student_enrollments.map(&:reload).map(&:grade_publishing_status).should == ["published", "error", "unpublishable", "error", "unpublishable", "unpublishable", "unpublished", "unpublished", "unpublished"]
        @student_enrollments.map(&:grade_publishing_message).should == [nil, "cause of this reason", nil, "cause of that reason", nil, nil, nil, nil, nil]
        @student_enrollments.map(&:workflow_state).should == ["active"] * 6 + ["inactive"] + ["active"] * 2
        @student_enrollments.map(&:last_publish_attempt_at).should == [nil] * 9
        grade_publishing_user
        @course.expects(:send_final_grades_to_endpoint).with(@user).returns(nil)
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
        @course.publish_final_grades(@user)
        @student_enrollments.map(&:reload).map(&:grade_publishing_status).should == ["pending"] * 6 + ["unpublished"] + ["pending"] * 2
        @student_enrollments.map(&:grade_publishing_message).should == [nil] * 9
        @student_enrollments.map(&:workflow_state).should == ["active"] * 6 + ["inactive"] + ["active"] * 2
        @student_enrollments.map(&:last_publish_attempt_at).each_with_index do |time, i|
          if i == 6
            time.should be_nil
          else
            time.should >= @course.created_at
          end
        end
      end

      it 'should kick off the actual grade send' do
        grade_publishing_user
        @course.expects(:send_later_if_production).with(:send_final_grades_to_endpoint, @user).returns(nil)
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
        @course.publish_final_grades(@user)
      end

      it 'should kick off the timeout when a success timeout is defined and waiting is configured' do
        grade_publishing_user
        @course.expects(:send_later_if_production).with(:send_final_grades_to_endpoint, @user).returns(nil)
        current_time = Time.now.utc
        Time.stubs(:now).returns(current_time)
        current_time.stubs(:utc).returns(current_time)
        @course.expects(:send_at).with(current_time + 1.seconds, :expire_pending_grade_publishing_statuses, current_time).returns(nil)
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge!({
            :publish_endpoint => "http://localhost/endpoint",
            :success_timeout => "1",
            :wait_for_success => "yes"
          })
        @course.publish_final_grades(@user)
      end

      it 'should not kick off the timeout when a success timeout is defined and waiting is not configured' do
        grade_publishing_user
        @course.expects(:send_later_if_production).with(:send_final_grades_to_endpoint, @user).returns(nil)
        current_time = Time.now.utc
        Time.stubs(:now).returns(current_time)
        current_time.stubs(:utc).returns(current_time)
        @course.expects(:send_at).times(0)
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge!({
            :publish_endpoint => "http://localhost/endpoint",
            :success_timeout => "1",
            :wait_for_success => "no"
          })
        @course.publish_final_grades(@user)
      end

      it 'should not kick off the timeout when a success timeout is not defined and waiting is not configured' do
        grade_publishing_user
        @course.expects(:send_later_if_production).with(:send_final_grades_to_endpoint, @user).returns(nil)
        current_time = Time.now.utc
        Time.stubs(:now).returns(current_time)
        current_time.stubs(:utc).returns(current_time)
        @course.expects(:send_at).times(0)
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge!({
            :publish_endpoint => "http://localhost/endpoint",
            :success_timeout => "",
            :wait_for_success => "no"
          })
        @course.publish_final_grades(@user)
      end

      it 'should not kick off the timeout when a success timeout is not defined and waiting is configured' do
        grade_publishing_user
        @course.expects(:send_later_if_production).with(:send_final_grades_to_endpoint, @user).returns(nil)
        current_time = Time.now.utc
        Time.stubs(:now).returns(current_time)
        current_time.stubs(:utc).returns(current_time)
        @course.expects(:send_at).times(0)
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge!({
            :publish_endpoint => "http://localhost/endpoint",
            :success_timeout => "no",
            :wait_for_success => "yes"
          })
        @course.publish_final_grades(@user)
      end
    end

    context 'should_kick_off_grade_publishing_timeout?' do
      it 'should cover all the necessary cases' do
        @plugin_settings.merge! :success_timeout => "no", :wait_for_success => "yes"
        @course.should_kick_off_grade_publishing_timeout?.should be_false
        @plugin_settings.merge! :success_timeout => "", :wait_for_success => "no"
        @course.should_kick_off_grade_publishing_timeout?.should be_false
        @plugin_settings.merge! :success_timeout => "1", :wait_for_success => "no"
        @course.should_kick_off_grade_publishing_timeout?.should be_false
        @plugin_settings.merge! :success_timeout => "1", :wait_for_success => "yes"
        @course.should_kick_off_grade_publishing_timeout?.should be_true
      end
    end

    context 'valid_grade_export_types' do
      it "should support instructure_csv" do
        Course.valid_grade_export_types["instructure_csv"][:name].should == "Instructure formatted CSV"
        course = mock()
        enrollments = [mock(), mock()]
        publishing_pseudonym = mock()
        publishing_user = mock()
        course.expects(:generate_grade_publishing_csv_output).with(enrollments, publishing_user, publishing_pseudonym).returns 42
        Course.valid_grade_export_types["instructure_csv"][:callback].call(course,
            enrollments, publishing_user, publishing_pseudonym).should == 42
        Course.valid_grade_export_types["instructure_csv"][:requires_grading_standard].should be_false
        Course.valid_grade_export_types["instructure_csv"][:requires_publishing_pseudonym].should be_false
      end
    end

    context 'send_final_grades_to_endpoint' do
      before { make_student_enrollments }

      it "should clear the grade publishing message of unpublishable enrollments" do
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge! :publish_endpoint => "http://localhost/endpoint", :format_type => "test_format"
        grade_publishing_user
        @ase = @student_enrollments.find_all{|e| e.workflow_state == 'active'}
        Course.stubs(:valid_grade_export_types).returns({
            "test_format" => {
                :callback => lambda {|course, enrollments, publishing_user, publishing_pseudonym|
                  course.should == @course
                  enrollments.sort_by(&:id).should == @ase.sort_by(&:id)
                  publishing_pseudonym.should == @pseudonym
                  publishing_user.should == @user
                  return [
                      [[@ase[2].id, @ase[5].id],
                       "post1",
                       "test/mime1"],
                      [[@ase[4].id, @ase[7].id],
                       "post2",
                       "test/mime2"]]
                }
              }
          })
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post1", "test/mime1")
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post2", "test/mime2")
        @course.send_final_grades_to_endpoint @user
        @student_enrollments.map(&:reload).map(&:grade_publishing_status).should == ["unpublishable", "unpublishable", "published", "unpublishable", "published", "published", "unpublished", "unpublishable", "published"]
        @student_enrollments.map(&:grade_publishing_message).should == [nil] * 9
      end

      it "should try to publish appropriate enrollments" do
        plugin_settings = Course.valid_grade_export_types["instructure_csv"]
        Course.stubs(:valid_grade_export_types).returns(plugin_settings.merge({
          "instructure_csv" => { :requires_grading_standard => true, :requires_publishing_pseudonym => true }}))
        @course.grading_standard_enabled = true
        @course.save!
        grade_publishing_user
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge!({
            :publish_endpoint => "http://localhost/endpoint",
            :format_type => "instructure_csv"
        })
        @checked = false
        Course.stubs(:valid_grade_export_types).returns({
            "instructure_csv" => {
                :callback => lambda {|course, enrollments, publishing_user, publishing_pseudonym|
                  course.should == @course
                  enrollments.sort_by(&:id).should == @student_enrollments.sort_by(&:id).find_all{|e| e.workflow_state == 'active'}
                  publishing_pseudonym.should == @pseudonym
                  publishing_user.should == @user
                  @checked = true
                  return []
                }
              }
          })
        @course.send_final_grades_to_endpoint @user
        @checked.should be_true
      end

      it "should make sure grade publishing is enabled" do
        @plugin.stubs(:enabled?).returns(false)
        (lambda {@course.send_final_grades_to_endpoint nil}).should raise_error("final grade publishing disabled")
        @student_enrollments.map(&:reload).map(&:grade_publishing_status).should == ["error"] * 6 + ["unpublished"] + ["error"] * 2
        @student_enrollments.map(&:grade_publishing_message).should == ["final grade publishing disabled"] * 6 + [nil] + ["final grade publishing disabled"] * 2
      end

      it "should make sure an endpoint is defined" do
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge! :publish_endpoint => ""
        (lambda {@course.send_final_grades_to_endpoint nil}).should raise_error("endpoint undefined")
        @student_enrollments.map(&:reload).map(&:grade_publishing_status).should == ["error"] * 6 + ["unpublished"] + ["error"] * 2
        @student_enrollments.map(&:grade_publishing_message).should == ["endpoint undefined"] * 6 + [nil] + ["endpoint undefined"] * 2
      end

      it "should make sure the publishing user can publish" do
        plugin_settings = Course.valid_grade_export_types["instructure_csv"]
        Course.stubs(:valid_grade_export_types).returns(plugin_settings.merge({
          "instructure_csv" => { :requires_grading_standard => false, :requires_publishing_pseudonym => true }}))
        @user = user
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge! :publish_endpoint => "http://localhost/endpoint"
        (lambda {@course.send_final_grades_to_endpoint @user}).should raise_error("publishing disallowed for this publishing user")
        @student_enrollments.map(&:reload).map(&:grade_publishing_status).should == ["error"] * 6 + ["unpublished"] + ["error"] * 2
        @student_enrollments.map(&:grade_publishing_message).should == ["publishing disallowed for this publishing user"] * 6 + [nil] + ["publishing disallowed for this publishing user"] * 2
      end

      it "should make sure there's a grading standard" do
        plugin_settings = Course.valid_grade_export_types["instructure_csv"]
        Course.stubs(:valid_grade_export_types).returns(plugin_settings.merge({
          "instructure_csv" => { :requires_grading_standard => true, :requires_publishing_pseudonym => false }}))
        @user = user
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge! :publish_endpoint => "http://localhost/endpoint"
        (lambda {@course.send_final_grades_to_endpoint @user}).should raise_error("grade publishing requires a grading standard")
        @student_enrollments.map(&:reload).map(&:grade_publishing_status).should == ["error"] * 6 + ["unpublished"] + ["error"] * 2
        @student_enrollments.map(&:grade_publishing_message).should == ["grade publishing requires a grading standard"] * 6 + [nil] + ["grade publishing requires a grading standard"] * 2
      end

      it "should make sure the format type is supported" do
        grade_publishing_user
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge! :publish_endpoint => "http://localhost/endpoint", :format_type => "invalid_Format"
        (lambda {@course.send_final_grades_to_endpoint @user}).should raise_error("unknown format type: invalid_Format")
        @student_enrollments.map(&:reload).map(&:grade_publishing_status).should == ["error"] * 6 + ["unpublished"] + ["error"] * 2
        @student_enrollments.map(&:grade_publishing_message).should == ["unknown format type: invalid_Format"] * 6 + [nil] + ["unknown format type: invalid_Format"] * 2
      end

      def sample_grade_publishing_request(published_status)
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge! :publish_endpoint => "http://localhost/endpoint", :format_type => "test_format"
        grade_publishing_user
        @ase = @student_enrollments.find_all{|e| e.workflow_state == 'active'}
        Course.stubs(:valid_grade_export_types).returns({
            "test_format" => {
                :callback => lambda {|course, enrollments, publishing_user, publishing_pseudonym|
                  course.should == @course
                  enrollments.sort_by(&:id).should == @ase.sort_by(&:id)
                  publishing_pseudonym.should == @pseudonym
                  publishing_user.should == @user
                  return [
                      [[@ase[1].id, @ase[3].id],
                       "post1",
                       "test/mime1"],
                      [[@ase[4].id, @ase[7].id],
                       "post2",
                       "test/mime2"]]
                }
              }
          })
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post1", "test/mime1")
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post2", "test/mime2")
        @course.send_final_grades_to_endpoint @user
        @student_enrollments.map(&:reload).map(&:grade_publishing_status).should == ["unpublishable", published_status, "unpublishable", published_status, published_status, "unpublishable", "unpublished", "unpublishable", published_status]
        @student_enrollments.map(&:grade_publishing_message).should == [nil] * 9
      end

      it "should make callback's requested posts and mark requested enrollment ids ignored" do
        sample_grade_publishing_request("published")
      end

      it "should recompute final grades" do
        @course.expects(:recompute_student_scores_without_send_later)
        sample_grade_publishing_request("published")
      end

      it "should not set the status to publishing if a timeout didn't kick off - timeout, wait" do
        @plugin_settings.merge! :success_timeout => "1", :wait_for_success => "yes"
        sample_grade_publishing_request("publishing")
      end

      it "should not set the status to publishing if a timeout didn't kick off - timeout, no wait" do
        @plugin_settings.merge! :success_timeout => "2", :wait_for_success => "false"
        sample_grade_publishing_request("published")
      end

      it "should not set the status to publishing if a timeout didn't kick off - no timeout, wait" do
        @plugin_settings.merge! :success_timeout => "no", :wait_for_success => "yes"
        sample_grade_publishing_request("published")
      end

      it "should not set the status to publishing if a timeout didn't kick off - no timeout, no wait" do
        @plugin_settings.merge! :success_timeout => "false", :wait_for_success => "no"
        sample_grade_publishing_request("published")
      end

      it "should try and make all posts even if one of the postings fails" do
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge! :publish_endpoint => "http://localhost/endpoint", :format_type => "test_format"
        grade_publishing_user
        @ase = @student_enrollments.find_all{|e| e.workflow_state == 'active'}
        Course.stubs(:valid_grade_export_types).returns({
            "test_format" => {
                :callback => lambda {|course, enrollments, publishing_user, publishing_pseudonym|
                  course.should == @course
                  enrollments.sort_by(&:id).should == @ase.sort_by(&:id)
                  publishing_pseudonym.should == @pseudonym
                  publishing_user.should == @user
                  return [
                      [[@ase[1].id, @ase[3].id],
                       "post1",
                       "test/mime1"],
                      [[@ase[4].id, @ase[7].id],
                       "post2",
                       "test/mime2"],
                      [[@ase[2].id, @ase[0].id],
                       "post3",
                       "test/mime3"]]
                }
              }
          })
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post1", "test/mime1")
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post2", "test/mime2").raises("waaah fail")
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post3", "test/mime3")
        (lambda {@course.send_final_grades_to_endpoint(@user)}).should raise_error("waaah fail")
        @student_enrollments.map(&:reload).map(&:grade_publishing_status).should == ["published", "published", "published", "published", "error", "unpublishable", "unpublished", "unpublishable", "error"]
        @student_enrollments.map(&:grade_publishing_message).should == [nil] * 4 + ["waaah fail"] + [nil] * 3 + ["waaah fail"]
      end

      it "should try and make all posts even if two of the postings fail" do
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge! :publish_endpoint => "http://localhost/endpoint", :format_type => "test_format"
        grade_publishing_user
        @ase = @student_enrollments.find_all{|e| e.workflow_state == 'active'}
        Course.stubs(:valid_grade_export_types).returns({
            "test_format" => {
                :callback => lambda {|course, enrollments, publishing_user, publishing_pseudonym|
                  course.should == @course
                  enrollments.sort_by(&:id).should == @ase.sort_by(&:id)
                  publishing_pseudonym.should == @pseudonym
                  publishing_user.should == @user
                  return [
                      [[@ase[1].id, @ase[3].id],
                       "post1",
                       "test/mime1"],
                      [[@ase[4].id, @ase[7].id],
                       "post2",
                       "test/mime2"],
                      [[@ase[2].id, @ase[0].id],
                       "post3",
                       "test/mime3"]]
                }
              }
          })
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post1", "test/mime1").raises("waaah fail")
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post2", "test/mime2").raises("waaah fail")
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post3", "test/mime3")
        (lambda {@course.send_final_grades_to_endpoint(@user)}).should raise_error("waaah fail")
        @student_enrollments.map(&:reload).map(&:grade_publishing_status).should == ["published", "error", "published", "error", "error", "unpublishable", "unpublished", "unpublishable", "error"]
        @student_enrollments.map(&:grade_publishing_message).should == [nil, "waaah fail", nil, "waaah fail", "waaah fail", nil, nil, nil, "waaah fail"]
      end

      it "should fail gracefully when the posting generator fails" do
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge! :publish_endpoint => "http://localhost/endpoint", :format_type => "test_format"
        grade_publishing_user
        @ase = @student_enrollments.find_all{|e| e.workflow_state == 'active'}
        Course.stubs(:valid_grade_export_types).returns({
            "test_format" => {
                :callback => lambda {|course, enrollments, publishiing_user, publishing_pseudonym|
                  raise "waaah fail"
                }
              }
          })
        (lambda {@course.send_final_grades_to_endpoint(@user)}).should raise_error("waaah fail")
        @student_enrollments.map(&:reload).map(&:grade_publishing_status).should == ["error", "error", "error", "error", "error", "error", "unpublished", "error", "error"]
        @student_enrollments.map(&:grade_publishing_message).should == ["waaah fail"] * 6 + [nil] + ["waaah fail"] * 2
      end

    end
  
    context 'generate_grade_publishing_csv_output' do

      def add_pseudonym(enrollment, account, unique_id, sis_user_id)
        pseudonym = account.pseudonyms.build
        pseudonym.user = enrollment.user
        pseudonym.unique_id = unique_id
        pseudonym.sis_user_id = sis_user_id
        pseudonym.save!
      end

      it 'should generate valid csv without a grading standard' do
        make_student_enrollments
        grade_publishing_user
        @course.assignment_groups.create(:name => "Assignments")
        a1 = @course.assignments.create!(:title => "A1", :points_possible => 10)
        a2 = @course.assignments.create!(:title => "A2", :points_possible => 10)
        @course.enroll_teacher(@user).tap{|e| e.workflow_state = 'active'; e.save!}
        @ase = @student_enrollments.find_all(&:active?)
        a1.grade_student(@ase[0].user, { :grade => "9", :grader => @user })
        a2.grade_student(@ase[0].user, { :grade => "10", :grader => @user })
        a1.grade_student(@ase[1].user, { :grade => "6", :grader => @user })
        a2.grade_student(@ase[1].user, { :grade => "7", :grader => @user })
        a1.grade_student(@ase[7].user, { :grade => "8", :grader => @user })
        a2.grade_student(@ase[7].user, { :grade => "9", :grader => @user })

        add_pseudonym(@ase[2], Account.default, "student2", nil)
        add_pseudonym(@ase[3], Account.default, "student3", "student3")
        add_pseudonym(@ase[4], Account.default, "student4a", "student4a")
        add_pseudonym(@ase[4], Account.default, "student4b", "student4b")
        another_account = account_model
        add_pseudonym(@ase[5], another_account, "student5", nil)
        add_pseudonym(@ase[6], another_account, "student6", "student6")
        add_pseudonym(@ase[7], Account.default, "student7a", "student7a")
        add_pseudonym(@ase[7], Account.default, "student7b", "student7b")

        @course.recompute_student_scores_without_send_later
        @course.generate_grade_publishing_csv_output(@ase.map(&:reload), @user, @pseudonym).should == [
          [@ase.map(&:id),
               ("publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id," +
                "student_id,student_sis_id,enrollment_id,enrollment_status," +
                "score\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[0].course_section_id},,#{@ase[0].user.id},,#{@ase[0].id},active,95\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[1].course_section_id},,#{@ase[1].user.id},,#{@ase[1].id},active,65\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[2].course_section_id},,#{@ase[2].user.id},,#{@ase[2].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[3].course_section_id},,#{@ase[3].user.id},student3,#{@ase[3].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[4].course_section_id},,#{@ase[4].user.id},student4a,#{@ase[4].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[4].course_section_id},,#{@ase[4].user.id},student4b,#{@ase[4].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[5].course_section_id},,#{@ase[5].user.id},,#{@ase[5].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[6].course_section_id},,#{@ase[6].user.id},,#{@ase[6].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7a,#{@ase[7].id},active,85\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7b,#{@ase[7].id},active,85\n"),
           "text/csv"]
        ]
      end

      it 'should generate valid csv without a publishing pseudonym' do
        make_student_enrollments
        @user = user_model
        @course.assignment_groups.create(:name => "Assignments")
        a1 = @course.assignments.create!(:title => "A1", :points_possible => 10)
        a2 = @course.assignments.create!(:title => "A2", :points_possible => 10)
        @course.enroll_teacher(@user).tap{|e| e.workflow_state = 'active'; e.save!}
        @ase = @student_enrollments.find_all(&:active?)
        a1.grade_student(@ase[0].user, { :grade => "9", :grader => @user })
        a2.grade_student(@ase[0].user, { :grade => "10", :grader => @user })
        a1.grade_student(@ase[1].user, { :grade => "6", :grader => @user })
        a2.grade_student(@ase[1].user, { :grade => "7", :grader => @user })
        a1.grade_student(@ase[7].user, { :grade => "8", :grader => @user })
        a2.grade_student(@ase[7].user, { :grade => "9", :grader => @user })

        add_pseudonym(@ase[2], Account.default, "student2", nil)
        add_pseudonym(@ase[3], Account.default, "student3", "student3")
        add_pseudonym(@ase[4], Account.default, "student4a", "student4a")
        add_pseudonym(@ase[4], Account.default, "student4b", "student4b")
        another_account = account_model
        add_pseudonym(@ase[5], another_account, "student5", nil)
        add_pseudonym(@ase[6], another_account, "student6", "student6")
        add_pseudonym(@ase[7], Account.default, "student7a", "student7a")
        add_pseudonym(@ase[7], Account.default, "student7b", "student7b")

        @course.recompute_student_scores_without_send_later
        @course.generate_grade_publishing_csv_output(@ase.map(&:reload), @user, @pseudonym).should == [
          [@ase.map(&:id),
               ("publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id," +
                "student_id,student_sis_id,enrollment_id,enrollment_status," +
                "score\n" +
                "#{@user.id},,#{@course.id},,#{@ase[0].course_section_id},,#{@ase[0].user.id},,#{@ase[0].id},active,95\n" +
                "#{@user.id},,#{@course.id},,#{@ase[1].course_section_id},,#{@ase[1].user.id},,#{@ase[1].id},active,65\n" +
                "#{@user.id},,#{@course.id},,#{@ase[2].course_section_id},,#{@ase[2].user.id},,#{@ase[2].id},active,0\n" +
                "#{@user.id},,#{@course.id},,#{@ase[3].course_section_id},,#{@ase[3].user.id},student3,#{@ase[3].id},active,0\n" +
                "#{@user.id},,#{@course.id},,#{@ase[4].course_section_id},,#{@ase[4].user.id},student4a,#{@ase[4].id},active,0\n" +
                "#{@user.id},,#{@course.id},,#{@ase[4].course_section_id},,#{@ase[4].user.id},student4b,#{@ase[4].id},active,0\n" +
                "#{@user.id},,#{@course.id},,#{@ase[5].course_section_id},,#{@ase[5].user.id},,#{@ase[5].id},active,0\n" +
                "#{@user.id},,#{@course.id},,#{@ase[6].course_section_id},,#{@ase[6].user.id},,#{@ase[6].id},active,0\n" +
                "#{@user.id},,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7a,#{@ase[7].id},active,85\n" +
                "#{@user.id},,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7b,#{@ase[7].id},active,85\n"),
           "text/csv"]
        ]
      end

      it 'should generate valid csv with a section id' do
        @course_section.sis_source_id = "section1"
        @course_section.save!
        make_student_enrollments
        grade_publishing_user
        @course.assignment_groups.create(:name => "Assignments")
        a1 = @course.assignments.create!(:title => "A1", :points_possible => 10)
        a2 = @course.assignments.create!(:title => "A2", :points_possible => 10)
        @course.enroll_teacher(@user).tap{|e| e.workflow_state = 'active'; e.save!}
        @ase = @student_enrollments.find_all(&:active?)
        a1.grade_student(@ase[0].user, { :grade => "9", :grader => @user })
        a2.grade_student(@ase[0].user, { :grade => "10", :grader => @user })
        a1.grade_student(@ase[1].user, { :grade => "6", :grader => @user })
        a2.grade_student(@ase[1].user, { :grade => "7", :grader => @user })
        a1.grade_student(@ase[7].user, { :grade => "8", :grader => @user })
        a2.grade_student(@ase[7].user, { :grade => "9", :grader => @user })

        add_pseudonym(@ase[2], Account.default, "student2", nil)
        add_pseudonym(@ase[3], Account.default, "student3", "student3")
        add_pseudonym(@ase[4], Account.default, "student4a", "student4a")
        add_pseudonym(@ase[4], Account.default, "student4b", "student4b")
        another_account = account_model
        add_pseudonym(@ase[5], another_account, "student5", nil)
        add_pseudonym(@ase[6], another_account, "student6", "student6")
        add_pseudonym(@ase[7], Account.default, "student7a", "student7a")
        add_pseudonym(@ase[7], Account.default, "student7b", "student7b")

        @course.recompute_student_scores_without_send_later
        @course.generate_grade_publishing_csv_output(@ase.map(&:reload), @user, @pseudonym).should == [
          [@ase.map(&:id),
               ("publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id," +
                "student_id,student_sis_id,enrollment_id,enrollment_status," +
                "score\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[0].course_section_id},section1,#{@ase[0].user.id},,#{@ase[0].id},active,95\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[1].course_section_id},section1,#{@ase[1].user.id},,#{@ase[1].id},active,65\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[2].course_section_id},section1,#{@ase[2].user.id},,#{@ase[2].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[3].course_section_id},section1,#{@ase[3].user.id},student3,#{@ase[3].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[4].course_section_id},section1,#{@ase[4].user.id},student4a,#{@ase[4].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[4].course_section_id},section1,#{@ase[4].user.id},student4b,#{@ase[4].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[5].course_section_id},section1,#{@ase[5].user.id},,#{@ase[5].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[6].course_section_id},section1,#{@ase[6].user.id},,#{@ase[6].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},section1,#{@ase[7].user.id},student7a,#{@ase[7].id},active,85\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},section1,#{@ase[7].user.id},student7b,#{@ase[7].id},active,85\n"),
           "text/csv"]
        ]
      end

      it 'should generate valid csv with a grading standard' do
        make_student_enrollments
        grade_publishing_user
        @course.assignment_groups.create(:name => "Assignments")
        @course.grading_standard_id = 0
        @course.save!
        a1 = @course.assignments.create!(:title => "A1", :points_possible => 10)
        a2 = @course.assignments.create!(:title => "A2", :points_possible => 10)
        @course.enroll_teacher(@user).tap{|e| e.workflow_state = 'active'; e.save!}
        @ase = @student_enrollments.find_all(&:active?)
        a1.grade_student(@ase[0].user, { :grade => "9", :grader => @user })
        a2.grade_student(@ase[0].user, { :grade => "10", :grader => @user })
        a1.grade_student(@ase[1].user, { :grade => "6", :grader => @user })
        a2.grade_student(@ase[1].user, { :grade => "7", :grader => @user })
        a1.grade_student(@ase[7].user, { :grade => "8", :grader => @user })
        a2.grade_student(@ase[7].user, { :grade => "9", :grader => @user })

        add_pseudonym(@ase[2], Account.default, "student2", nil)
        add_pseudonym(@ase[3], Account.default, "student3", "student3")
        add_pseudonym(@ase[4], Account.default, "student4a", "student4a")
        add_pseudonym(@ase[4], Account.default, "student4b", "student4b")
        another_account = account_model
        add_pseudonym(@ase[5], another_account, "student5", nil)
        add_pseudonym(@ase[6], another_account, "student6", "student6")
        add_pseudonym(@ase[7], Account.default, "student7a", "student7a")
        add_pseudonym(@ase[7], Account.default, "student7b", "student7b")

        @course.recompute_student_scores_without_send_later
        @course.generate_grade_publishing_csv_output(@ase.map(&:reload), @user, @pseudonym).should == [
          [@ase.map(&:id),
               ("publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id," +
                "student_id,student_sis_id,enrollment_id,enrollment_status," +
                "score,grade\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[0].course_section_id},,#{@ase[0].user.id},,#{@ase[0].id},active,95,A\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[1].course_section_id},,#{@ase[1].user.id},,#{@ase[1].id},active,65,D\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[2].course_section_id},,#{@ase[2].user.id},,#{@ase[2].id},active,0,F\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[3].course_section_id},,#{@ase[3].user.id},student3,#{@ase[3].id},active,0,F\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[4].course_section_id},,#{@ase[4].user.id},student4a,#{@ase[4].id},active,0,F\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[4].course_section_id},,#{@ase[4].user.id},student4b,#{@ase[4].id},active,0,F\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[5].course_section_id},,#{@ase[5].user.id},,#{@ase[5].id},active,0,F\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[6].course_section_id},,#{@ase[6].user.id},,#{@ase[6].id},active,0,F\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7a,#{@ase[7].id},active,85,B\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7b,#{@ase[7].id},active,85,B\n"),
           "text/csv"]
        ]
      end

      it 'should generate valid csv and skip users with no computed final score' do
        make_student_enrollments
        grade_publishing_user
        @course.assignment_groups.create(:name => "Assignments")
        @course.grading_standard_id = 0
        @course.save!
        a1 = @course.assignments.create!(:title => "A1", :points_possible => 10)
        a2 = @course.assignments.create!(:title => "A2", :points_possible => 10)
        @course.enroll_teacher(@user).tap{|e| e.workflow_state = 'active'; e.save!}
        @ase = @student_enrollments.find_all(&:active?)
        a1.grade_student(@ase[0].user, { :grade => "9", :grader => @user })
        a2.grade_student(@ase[0].user, { :grade => "10", :grader => @user })
        a1.grade_student(@ase[1].user, { :grade => "6", :grader => @user })
        a2.grade_student(@ase[1].user, { :grade => "7", :grader => @user })
        a1.grade_student(@ase[7].user, { :grade => "8", :grader => @user })
        a2.grade_student(@ase[7].user, { :grade => "9", :grader => @user })

        add_pseudonym(@ase[2], Account.default, "student2", nil)
        add_pseudonym(@ase[3], Account.default, "student3", "student3")
        add_pseudonym(@ase[4], Account.default, "student4a", "student4a")
        add_pseudonym(@ase[4], Account.default, "student4b", "student4b")
        another_account = account_model
        add_pseudonym(@ase[5], another_account, "student5", nil)
        add_pseudonym(@ase[6], another_account, "student6", "student6")
        add_pseudonym(@ase[7], Account.default, "student7a", "student7a")
        add_pseudonym(@ase[7], Account.default, "student7b", "student7b")

        @course.recompute_student_scores_without_send_later
        @ase.map(&:reload)

        @ase[1].computed_final_score = nil
        @ase[3].computed_final_score = nil
        @ase[4].computed_final_score = nil

        @course.generate_grade_publishing_csv_output(@ase, @user, @pseudonym).should == [
          [@ase.map(&:id) - [@ase[1].id, @ase[3].id, @ase[4].id],
               ("publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id," +
                "student_id,student_sis_id,enrollment_id,enrollment_status," +
                "score,grade\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[0].course_section_id},,#{@ase[0].user.id},,#{@ase[0].id},active,95,A\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[2].course_section_id},,#{@ase[2].user.id},,#{@ase[2].id},active,0,F\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[5].course_section_id},,#{@ase[5].user.id},,#{@ase[5].id},active,0,F\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[6].course_section_id},,#{@ase[6].user.id},,#{@ase[6].id},active,0,F\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7a,#{@ase[7].id},active,85,B\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7b,#{@ase[7].id},active,85,B\n"),
           "text/csv"]
        ]
      end
    end

    context 'expire_pending_grade_publishing_statuses' do
      it 'should update the right enrollments' do
        make_student_enrollments
        first_time = Time.now.utc
        second_time = first_time + 2.seconds
        @student_enrollments.map(&:reload).map(&:grade_publishing_status).should == ["published", "error", "unpublishable", "error", "unpublishable", "unpublishable", "unpublished", "unpublished", "unpublished"]
        @student_enrollments[0].grade_publishing_status = "pending"
        @student_enrollments[0].last_publish_attempt_at = first_time
        @student_enrollments[1].grade_publishing_status = "publishing"
        @student_enrollments[1].last_publish_attempt_at = first_time
        @student_enrollments[2].grade_publishing_status = "pending"
        @student_enrollments[2].last_publish_attempt_at = second_time
        @student_enrollments[3].grade_publishing_status = "publishing"
        @student_enrollments[3].last_publish_attempt_at = second_time
        @student_enrollments[4].grade_publishing_status = "published"
        @student_enrollments[4].last_publish_attempt_at = first_time
        @student_enrollments[5].grade_publishing_status = "unpublished"
        @student_enrollments[5].last_publish_attempt_at = first_time
        @student_enrollments.map(&:save)
        @student_enrollments.map(&:reload).map(&:grade_publishing_status).should == ["pending", "publishing", "pending", "publishing", "published", "unpublished", "unpublished", "unpublished", "unpublished"]
        @course.expire_pending_grade_publishing_statuses(first_time)
        @student_enrollments.map(&:reload).map(&:grade_publishing_status).should == ["error", "error", "pending", "publishing", "published", "unpublished", "unpublished", "unpublished", "unpublished"]
      end
    end

    context 'grading_standard_enabled' do
      it 'should work for a number of boolean representations' do
        @course.grading_standard_enabled?.should be_false
        @course.grading_standard_enabled.should be_false
        [[false, false], [true, true], ["false", false], ["true", true],
            ["0", false], [0, false], ["1", true], [1, true], ["off", false],
            ["on", true], ["yes", true], ["no", false]].each do |val, enabled|
          @course.grading_standard_enabled = val
          @course.grading_standard_enabled?.should == enabled
          @course.grading_standard_enabled.should == enabled
          @course.grading_standard_id.should be_nil unless enabled
          @course.grading_standard_id.should_not be_nil if enabled
          @course.bool_res(val).should == enabled
        end
      end
    end
  end

  context 'integration suite' do
    def quick_sanity_check(user)
      Course.valid_grade_export_types["test_export"] = {
          :name => "test export",
          :callback => lambda {|course, enrollments, publishing_user, publishing_pseudonym|
            course.should == @course
            publishing_pseudonym.should == @pseudonym
            publishing_user.should == @user
            return [[[], "test-jt-data", "application/jtmimetype"]]
          },
          :requires_grading_standard => false, :requires_publishing_pseudonym => true}

      server, server_thread, post_lines = start_test_http_server

      @plugin = Canvas::Plugin.find!('grade_export')
      @ps = PluginSetting.new(:name => @plugin.id, :settings => @plugin.default_settings)
      @ps.posted_settings = @plugin.default_settings.merge({
          :format_type => "test_export",
          :wait_for_success => "no",
          :publish_endpoint => "http://localhost:#{server.addr[1]}/endpoint"
        })
      @ps.save!

      @course.grading_standard_id = 0
      @course.publish_final_grades(user)
      server_thread.join
      verify_post_matches(post_lines, [
          "POST /endpoint HTTP/1.1",
          "Accept: */*",
          "Content-Type: application/jtmimetype",
          "",
          "test-jt-data"])
    end

    it 'should pass a quick sanity check' do
      @user = user_with_pseudonym
      @pseudonym.account_id = @course.root_account_id
      @pseudonym.sis_user_id = "U1"
      @pseudonym.save!
      quick_sanity_check(@user)
    end

    it 'should not allow grade publishing for a user that is disallowed' do
      @user = User.new
      (lambda { quick_sanity_check(@user) }).should raise_error("publishing disallowed for this publishing user")
    end

    it 'should not allow grade publishing for a user with a pseudonym in the wrong account' do
      @user = user_with_pseudonym
      @pseudonym.account = account_model
      @pseudonym.sis_user_id = "U1"
      @pseudonym.save!
      (lambda { quick_sanity_check(@user) }).should raise_error("publishing disallowed for this publishing user")
    end

    it 'should not allow grade publishing for a user with a pseudonym without a sis id' do
      @user = user_with_pseudonym
      @pseudonym.account_id = @course.root_account_id
      @pseudonym.sis_user_id = nil
      @pseudonym.save!
      (lambda { quick_sanity_check(@user) }).should raise_error("publishing disallowed for this publishing user")
    end

    it 'should publish csv' do
      @user = user_with_pseudonym
      @pseudonym.sis_user_id = "U1"
      @pseudonym.account_id = @course.root_account_id
      @pseudonym.save!

      server, server_thread, post_lines = start_test_http_server

      @plugin = Canvas::Plugin.find!('grade_export')
      @ps = PluginSetting.new(:name => @plugin.id, :settings => @plugin.default_settings)
      @ps.posted_settings = @plugin.default_settings.merge({
          :format_type => "instructure_csv",
          :wait_for_success => "no",
          :publish_endpoint => "http://localhost:#{server.addr[1]}/endpoint"
        })
      @ps.save!

      @course.grading_standard_id = 0
      @course.publish_final_grades(@user)
      server_thread.join
      verify_post_matches(post_lines, [
          "POST /endpoint HTTP/1.1",
          "Accept: */*",
          "Content-Type: text/csv",
          "",
          "publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id,student_id," +
          "student_sis_id,enrollment_id,enrollment_status,score,grade\n"])
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

      server, server_thread, post_lines = start_test_http_server

      @plugin = Canvas::Plugin.find!('grade_export')
      @ps = PluginSetting.new(:name => @plugin.id, :settings => @plugin.default_settings)
      @ps.posted_settings = @plugin.default_settings.merge({
          :format_type => "instructure_csv",
          :wait_for_success => "no",
          :publish_endpoint => "http://localhost:#{server.addr[1]}/endpoint"
        })
      @ps.save!

      @course.publish_final_grades(teacher.user)
      server_thread.join
      verify_post_matches(post_lines, [
          "POST /endpoint HTTP/1.1",
          "Accept: */*",
          "Content-Type: text/csv",
          "",
          "publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id,student_id," +
          "student_sis_id,enrollment_id,enrollment_status,score\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{getsection("S1").id},S1,#{getpseudonym("S1").user.id},S1,#{getenroll("S1", "S1").id},active,70\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{getsection("S2").id},S2,#{getpseudonym("S2").user.id},S2,#{getenroll("S2", "S2").id},active,75\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{getsection("S2").id},S2,#{getpseudonym("S3").user.id},S3,#{getenroll("S3", "S2").id},active,80\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{getsection("S1").id},S1,#{getpseudonym("S4").user.id},S4,#{getenroll("S4", "S1").id},active,0\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{getsection("S3").id},S3,#{stud5.user.id},,#{Enrollment.find_by_user_id_and_course_section_id(stud5.user.id, getsection("S3").id).id},active,85\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{sec4.id},S4,#{stud6.user.id},,#{Enrollment.find_by_user_id_and_course_section_id(stud6.user.id, sec4.id).id},active,90\n"])

      @course.grading_standard_id = 0
      @course.save
      server, server_thread, post_lines = start_test_http_server
      @ps.posted_settings = @plugin.default_settings.merge({
          :publish_endpoint => "http://localhost:#{server.addr[1]}/endpoint"
        })
      @ps.save!
      @course.publish_final_grades(teacher.user)
      server_thread.join
      verify_post_matches(post_lines, [
          "POST /endpoint HTTP/1.1",
          "Accept: */*",
          "Content-Type: text/csv",
          "",
          "publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id,student_id," +
          "student_sis_id,enrollment_id,enrollment_status,score,grade\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{getsection("S1").id},S1,#{getpseudonym("S1").user.id},S1,#{getenroll("S1", "S1").id},active,70,C-\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{getsection("S2").id},S2,#{getpseudonym("S2").user.id},S2,#{getenroll("S2", "S2").id},active,75,C\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{getsection("S2").id},S2,#{getpseudonym("S3").user.id},S3,#{getenroll("S3", "S2").id},active,80,B-\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{getsection("S1").id},S1,#{getpseudonym("S4").user.id},S4,#{getenroll("S4", "S1").id},active,0,F\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{getsection("S3").id},S3,#{stud5.user.id},,#{Enrollment.find_by_user_id_and_course_section_id(stud5.user.id, getsection("S3").id).id},active,85,B\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{sec4.id},S4,#{stud6.user.id},,#{Enrollment.find_by_user_id_and_course_section_id(stud6.user.id, sec4.id).id},active,90,A-\n"])
      admin = user_model
      server, server_thread, post_lines = start_test_http_server
      @ps.posted_settings = @plugin.default_settings.merge({
          :publish_endpoint => "http://localhost:#{server.addr[1]}/endpoint"
        })
      @ps.save!
      @course.publish_final_grades(admin)
      server_thread.join
      verify_post_matches(post_lines, [
          "POST /endpoint HTTP/1.1",
          "Accept: */*",
          "Content-Type: text/csv",
          "",
          "publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id,student_id," +
          "student_sis_id,enrollment_id,enrollment_status,score,grade\n" +
          "#{admin.id},,#{@course.id},C1,#{getsection("S1").id},S1,#{getpseudonym("S1").user.id},S1,#{getenroll("S1", "S1").id},active,70,C-\n" +
          "#{admin.id},,#{@course.id},C1,#{getsection("S2").id},S2,#{getpseudonym("S2").user.id},S2,#{getenroll("S2", "S2").id},active,75,C\n" +
          "#{admin.id},,#{@course.id},C1,#{getsection("S2").id},S2,#{getpseudonym("S3").user.id},S3,#{getenroll("S3", "S2").id},active,80,B-\n" +
          "#{admin.id},,#{@course.id},C1,#{getsection("S1").id},S1,#{getpseudonym("S4").user.id},S4,#{getenroll("S4", "S1").id},active,0,F\n" +
          "#{admin.id},,#{@course.id},C1,#{getsection("S3").id},S3,#{stud5.user.id},,#{Enrollment.find_by_user_id_and_course_section_id(stud5.user.id, getsection("S3").id).id},active,85,B\n" +
          "#{admin.id},,#{@course.id},C1,#{sec4.id},S4,#{stud6.user.id},,#{Enrollment.find_by_user_id_and_course_section_id(stud6.user.id, sec4.id).id},active,90,A-\n"])
    end

  end


end

describe Course, 'tabs_available' do
  def new_exernal_tool(context)
    context.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :domain => "example.com")
  end
  
  it "should not include external tools if not configured for course navigation" do
    course_model
    tool = new_exernal_tool @course
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
    tool = new_exernal_tool @course
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
    tool = new_exernal_tool @account
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
    tool = new_exernal_tool @account.root_account
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
    tool = new_exernal_tool @course
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
    tool = new_exernal_tool @course
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
    tool = new_exernal_tool @course
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
    tool = new_exernal_tool @course
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

  it "should include courses the user is actively enrolled in as a designer" do
    course = Course.create
    user = user_with_pseudonym
    course.enroll_designer(user).accept

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

  it "should not include deleted courses the user was enrolled in" do
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

  context "appointment cancelation" do
    before do
      course_with_student(:active_all => true)
      @ag = AppointmentGroup.create!(:title => "test", :contexts => [@course], :new_appointments => [['2010-01-01 13:00:00', '2010-01-01 14:00:00'], ["#{Time.now.year + 1}-01-01 13:00:00", "#{Time.now.year + 1}-01-01 14:00:00"]])
      @ag.appointments.each do |a|
        a.reserve_for(@user, @user)
      end
    end

    it "should cancel all future appointments when concluding an enrollment" do
      @enrollment.conclude
      @ag.appointments_participants.size.should eql 1
      @ag.appointments_participants.current.size.should eql 0
    end

    it "should cancel all future appointments when concluding all enrollments" do
      @course.complete!
      @ag.appointments_participants.size.should eql 1
      @ag.appointments_participants.current.size.should eql 0
    end
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
    @course.enroll_user(@ta, "TaEnrollment", :limit_privileges_to_course_section => true)

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

    it "should return non-limited admins from other sections" do
      @course.enrollments_visible_to(@ta, :type => :teacher, :return_users => true).should eql [@teacher]
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

  it "should be marshal-able" do
    c = Course.new(:name => 'c1')
    Marshal.dump(c)
    c.save!
    Marshal.dump(c)
  end
end

describe Course, ".import_from_migration" do
  before do
    attachment_model(:uploaded_data => stub_file_data('test.m4v', 'asdf', 'video/mp4'))
    course_with_teacher
  end

  it "should wait for media objects on canvas cartridge import" do
    migration = mock(:migration_settings => { 'worker_class' => 'CC::Importer::Canvas::Converter' }.with_indifferent_access)
    MediaObject.expects(:add_media_files).with([@attachment], true)
    @course.import_media_objects([@attachment], migration)
  end

  it "should not wait for media objects on other import" do
    migration = mock(:migration_settings => { 'worker_class' => 'CC::Importer::Standard::Converter' }.with_indifferent_access)
    MediaObject.expects(:add_media_files).with([@attachment], false)
    @course.import_media_objects([@attachment], migration)
  end

  it "should know when it has open course imports" do
    # no course imports
    @course.should_not have_open_course_imports

    # created course import
    @course.course_imports.create!
    @course.should have_open_course_imports

    # started course import
    @course.course_imports.first.update_attribute(:workflow_state, 'started')
    @course.should have_open_course_imports

    # completed course import
    @course.course_imports.first.update_attribute(:workflow_state, 'completed')
    @course.should_not have_open_course_imports

    # failed course import
    @course.course_imports.first.update_attribute(:workflow_state, 'failed')
    @course.should_not have_open_course_imports
  end

  describe "setting storage quota" do
    before do
      course_with_teacher
      @course.storage_quota = 1
      @cm = ContentMigration.new(:context => @course, :user => @user, :copy_options => {:everything => "1"})
      @cm.user = @user
      @cm.save!
    end

    it "should not adjust for unauthorized user" do
      @course.import_settings_from_migration({:course=>{:storage_quota => 4}}, @cm)
      @course.storage_quota.should == 1
    end

    it "should adjust for authorized user" do
      account_admin_user(:user => @user)
      @course.import_settings_from_migration({:course=>{:storage_quota => 4}}, @cm)
      @course.storage_quota.should == 4
    end

    it "should be set for course copy" do
      @cm.source_course = @course
      @course.import_settings_from_migration({:course=>{:storage_quota => 4}}, @cm)
      @course.storage_quota.should == 4
    end
  end

end

describe Course, "enrollments" do
  it "should update enrollments' root_account_id when necessary" do
    a1 = Account.create!
    a2 = Account.create!

    course_with_student
    @course.root_account = a1
    @course.save!

    @course.student_enrollments.map(&:root_account_id).should eql [a1.id]

    @course.root_account = a2
    @course.save!
    @course.student_enrollments(true).map(&:root_account_id).should eql [a2.id]
  end
end

describe Course, "user_is_teacher?" do
  it "should be true for teachers" do
    course = Course.create
    teacher = user_with_pseudonym
    course.enroll_teacher(teacher).accept
    course.user_is_teacher?(teacher).should be_true
  end

  it "should be false for designers" do
    course = Course.create
    ta = user_with_pseudonym
    course.enroll_ta(ta).accept
    course.user_is_teacher?(ta).should be_true
  end

  it "should be false for designers" do
    course = Course.create
    designer = user_with_pseudonym
    course.enroll_designer(designer).accept
    course.user_is_teacher?(designer).should be_false
  end
end

describe Course, "user_has_been_teacher?" do
  it "should be true for teachers, past or present" do
    e = course_with_teacher(:active_all => true)
    @course.user_has_been_teacher?(@teacher).should be_true

    e.conclude
    e.reload.workflow_state.should == "completed"
    @course.user_has_been_teacher?(@teacher).should be_true

    @course.complete
    @course.user_has_been_teacher?(@teacher).should be_true
  end
end

describe Course, "user_has_been_student?" do
  it "should be true for students, past or present" do
    e = course_with_student(:active_all => true)
    @course.user_has_been_student?(@student).should be_true

    e.conclude
    e.reload.workflow_state.should == "completed"
    @course.user_has_been_student?(@student).should be_true

    @course.complete
    @course.user_has_been_student?(@student).should be_true
  end
end

describe Course, "student_view_student" do
  before(:each) do
    course_with_teacher(:active_all => true)
  end

  it "should create and return the student view student for a course" do
    expect { @course.student_view_student }.to change(User, :count).by(1)
  end

  it "should find and return the student view student on successive calls" do
    @course.student_view_student
    expect { @course.student_view_student }.to change(User, :count).by(0)
  end

  it "should create enrollments for each section" do
    @section2 = @course.course_sections.create!
    expect { @fake_student = @course.student_view_student }.to change(Enrollment, :count).by(2)
    @fake_student.enrollments.all?{|e| e.fake_student?}.should be_true
  end

  it "should sync enrollments after being created" do
    @course.student_view_student
    @section2 = @course.course_sections.create!
    expect { @course.student_view_student }.to change(Enrollment, :count).by(1)
  end

  it "should create a pseudonym for the fake student" do
    expect { @fake_student = @course.student_view_student }.to change(Pseudonym, :count).by(1)
    @fake_student.pseudonyms.should_not be_empty
  end

  it "should allow two different student view users for two different courses" do
    @course1 = @course
    @teacher1 = @teacher
    course_with_teacher(:active_all => true)
    @course2 = @course
    @teacher2 = @teacher

    @fake_student1 = @course1.student_view_student
    @fake_student2 = @course2.student_view_student

    @fake_student1.id.should_not eql @fake_student2.id
    @fake_student1.pseudonym.id.should_not eql @fake_student2.pseudonym.id
  end
end

describe Course do
  describe "user_list_search_mode_for" do
    it "should be open for anyone if open registration is turned on" do
      account = Account.default
      account.settings = { :open_registration => true }
      account.save!
      course
      @course.user_list_search_mode_for(nil).should == :open
      @course.user_list_search_mode_for(user).should == :open
    end

    it "should be preferred for account admins" do
      account = Account.default
      course
      @course.user_list_search_mode_for(nil).should == :closed
      @course.user_list_search_mode_for(user).should == :closed
      user
      account.add_user(@user)
      @course.user_list_search_mode_for(@user).should == :preferred
    end

    it "should be preferred if delegated authentication is configured" do
      account = Account.default
      account.settings = { :open_registration => true }
      account.account_authorization_configs.create!(:auth_type => 'cas')
      account.save!
      course
      @course.user_list_search_mode_for(nil).should == :preferred
      @course.user_list_search_mode_for(user).should == :preferred
    end
  end
end

describe Course do
  describe "self_enrollment" do
    it "should generate a unique code" do
      c1 = course()
      c1.self_enrollment_code.should be_nil # normally only set when self_enrollment is enabled
      c1.update_attribute(:self_enrollment, true)
      c1.self_enrollment_code.should_not be_nil
      c1.self_enrollment_code.should =~ /\A[A-Z0-9]{6}\z/

      c2 = course()
      c2.update_attribute(:self_enrollment, true)
      c2.self_enrollment_code.should =~ /\A[A-Z0-9]{6}\z/
      c1.self_enrollment_code.should_not == c2.self_enrollment_code
    end

    it "should generate a code on demand for existing self enrollment courses" do
      c1 = course()
      Course.update_all({:self_enrollment => true}, {:id => @course.id})
      c1.reload
      c1.read_attribute(:self_enrollment_code).should be_nil
      c1.self_enrollment_code.should_not be_nil
      c1.self_enrollment_code.should =~ /\A[A-Z0-9]{6}\z/
    end
  end
end