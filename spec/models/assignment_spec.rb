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

describe Assignment do
  it "should create a new instance given valid attributes" do
    setup_assignment
    @c.assignments.create!(assignment_valid_attributes)
  end

  it "should have a useful state machine" do
    assignment_model
    @a.state.should eql(:published)
    @a.unpublish
    @a.state.should eql(:unpublished)
  end

  it "should always be associated with a group" do
    assignment_model
    @assignment.save!
    @assignment.assignment_group.should_not be_nil
  end

  it "should be associated with a group when the course has no active groups" do
    course_model
    @course.require_assignment_group
    @course.assignment_groups.first.destroy
    @course.assignment_groups.size.should == 1
    @course.assignment_groups.active.size.should == 0
    @assignment = assignment_model(:course => @course)
    @assignment.assignment_group.should_not be_nil
  end

  it "should touch assignment group on create/save" do
    course
    group = @course.assignment_groups.create!(:name => "Assignments")
    AssignmentGroup.where(:id => group).update_all(:updated_at => 1.hour.ago)
    orig_time = group.reload.updated_at.to_i
    a = @course.assignments.build("title"=>"test")
    a.assignment_group = group
    a.save!
    @course.assignments.count.should == 1
    group.reload
    group.updated_at.to_i.should_not == orig_time
  end

  it "should be able to submit homework" do
    setup_assignment_with_homework
    @assignment.submissions.size.should eql(1)
    @submission = @assignment.submissions.first
    @submission.user_id.should eql(@user.id)
    @submission.versions.length.should eql(1)
  end

  describe "#has_student_submissions?" do
    before do
      setup_assignment_with_students
      @assignment.context.root_account.enable_feature!(:draft_state)
    end

    it "does not allow itself to be unpublished if it has student submissions" do
      @assignment.submit_homework @stu1, :submission_type => "online_text_entry"
      @assignment.should_not be_can_unpublish
      @assignment.unpublish
      @assignment.should_not be_valid
      @assignment.errors['workflow_state'].should == ["Can't unpublish if there are student submissions"]
    end

    it "does allow itself to be unpublished if it has nil submissions" do
      @assignment.submit_homework @stu1, :submission_type => nil
      @assignment.should be_can_unpublish
      @assignment.unpublish
      @assignment.workflow_state.should == "unpublished"
    end
  end

  describe '#grade_student' do
    before { setup_assignment_without_submission }

    describe 'with a valid student' do
      before do
        @result = @assignment.grade_student(@user, :grade => "10")
        @assignment.reload
      end

      it 'returns an array' do
        @result.should be_is_a(Array)
      end

      it 'now has a submission' do
        @assignment.submissions.size.should eql(1)
      end

      describe 'the submission after grading' do
        subject { @assignment.submissions.first }

        its(:state) { should eql(:graded) }
        it { should == @result[0] }
        its(:score) { should == 10.0 }
        its(:user_id) { should == @user.id }
        specify { subject.versions.length.should == 1 }
      end
    end

    it 'raises an error if there is no student' do
      lambda { @assignment.grade_student(nil) }.should raise_error(StandardError, 'Student is required')
    end

    it 'will not continue if the student does not belong here' do
      lambda { @assignment.grade_student(User.new) }.should raise_error(StandardError, 'Student must be enrolled in the course as a student to be graded')
    end
  end

  it "should update a submission's graded_at when grading it" do
    setup_assignment_with_homework
    @assignment.grade_student(@user, :grade => 1)
    @submission = @assignment.submissions.first
    original_graded_at = @submission.graded_at
    new_time = Time.now + 1.hour
    Time.stubs(:now).returns(new_time)
    @assignment.grade_student(@user, :grade => 2)
    @submission.reload
    @submission.graded_at.should_not eql original_graded_at
  end

  context "needs_grading_count" do
    it "should update when submissions transition state" do
      setup_assignment_with_homework
      @assignment.needs_grading_count.should eql(1)
      @assignment.grade_student(@user, :grade => "0")
      @assignment.reload
      @assignment.needs_grading_count.should eql(0)
    end

    it "should not update when non-student submissions transition state" do
      assignment_model
      s = @assignment.find_or_create_submission(@teacher)
      s.submission_type = 'online_quiz'
      s.workflow_state = 'submitted'
      s.save!
      @assignment.needs_grading_count.should eql(0)
      s.workflow_state = 'graded'
      s.save!
      @assignment.reload
      @assignment.needs_grading_count.should eql(0)
    end
  
    it "should update when enrollment changes" do
      setup_assignment_with_homework
      @assignment.needs_grading_count.should eql(1)
      @course.offer!
      @course.enrollments.find_by_user_id(@user.id).destroy
      @assignment.reload
      @assignment.needs_grading_count.should eql(0)
      e = @course.enroll_student(@user)
      e.invite
      e.accept
      @assignment.reload
      @assignment.needs_grading_count.should eql(1)
  
      # multiple enrollments should not cause double-counting (either by creating as or updating into "active")
      section2 = @course.course_sections.create!(:name => 's2')
      e2 = @course.enroll_student(@user, 
                                  :enrollment_state => 'invited',
                                  :section => section2,
                                  :allow_multiple_enrollments => true)
      e2.accept
      section3 = @course.course_sections.create!(:name => 's2')
      e3 = @course.enroll_student(@user, 
                                  :enrollment_state => 'active', 
                                  :section => section3,
                                  :allow_multiple_enrollments => true)
      @user.enrollments.where(:workflow_state => 'active').count.should eql(3)
      @assignment.reload
      @assignment.needs_grading_count.should eql(1)
  
      # and as long as one enrollment is still active, the count should not change
      e2.destroy
      e3.complete
      @assignment.reload
      @assignment.needs_grading_count.should eql(1)
  
      # ok, now gone for good
      e.destroy
      @assignment.reload
      @assignment.needs_grading_count.should eql(0)
      @user.enrollments.where(:workflow_state => 'active').count.should eql(0)

      # enroll the user as a teacher, it should have no effect
      e4 = @course.enroll_teacher(@user)
      e4.accept
      @assignment.reload
      @assignment.needs_grading_count.should eql(0)
      @user.enrollments.where(:workflow_state => 'active').count.should eql(1)
    end

    it "updated_at should be set when needs_grading_count changes due to a submission" do
      setup_assignment_with_homework
      @assignment.needs_grading_count.should eql(1)
      old_timestamp = Time.now.utc - 1.minute
      Assignment.where(:id => @assignment).update_all(:updated_at => old_timestamp)
      @assignment.grade_student(@user, :grade => "0")
      @assignment.reload
      @assignment.needs_grading_count.should eql(0)
      @assignment.updated_at.should > old_timestamp
    end

    it "updated_at should be set when needs_grading_count changes due to an enrollment change" do
      setup_assignment_with_homework
      old_timestamp = Time.now.utc - 1.minute
      @assignment.needs_grading_count.should eql(1)
      Assignment.where(:id => @assignment).update_all(:updated_at => old_timestamp)
      @course.offer!
      @course.enrollments.find_by_user_id(@user.id).destroy
      @assignment.reload
      @assignment.needs_grading_count.should eql(0)
      @assignment.updated_at.should > old_timestamp
    end
  end

  context "needs_grading_count_for_user" do
    it "should only count submissions in the user's visible section(s)" do
      course_with_teacher(:active_all => true)
      @section = @course.course_sections.create!(:name => 'section 2')
      @user2 = user_with_pseudonym(:active_all => true, :name => 'Student2', :username => 'student2@instructure.com')
      @section.enroll_user(@user2, 'StudentEnrollment', 'active')
      @user1 = user_with_pseudonym(:active_all => true, :name => 'Student1', :username => 'student1@instructure.com')
      @course.enroll_student(@user1).update_attribute(:workflow_state, 'active')

      # enroll a section-limited TA
      @ta = user_with_pseudonym(:active_all => true, :name => 'TA1', :username => 'ta1@instructure.com')
      ta_enrollment = @course.enroll_ta(@ta)
      ta_enrollment.limit_privileges_to_course_section = true
      ta_enrollment.workflow_state = 'active'
      ta_enrollment.save!

      # make a submission in each section
      @assignment = @course.assignments.create(:title => "some assignment", :submission_types => ['online_text_entry'])
      @assignment.submit_homework @user1, :submission_type => "online_text_entry", :body => "o hai"
      @assignment.submit_homework @user2, :submission_type => "online_text_entry", :body => "haldo"
      @assignment.reload

      # check the teacher sees both, the TA sees one
      @assignment.needs_grading_count_for_user(@teacher).should eql(2)
      @assignment.needs_grading_count_for_user(@ta).should eql(1)

      # grade an assignment
      @assignment.grade_student(@user1, :grade => "1")
      @assignment.reload

      # check that the numbers changed
      @assignment.needs_grading_count_for_user(@teacher).should eql(1)
      @assignment.needs_grading_count_for_user(@ta).should eql(0)

      # test limited enrollment in multiple sections
      @course.enroll_user(@ta, 'TaEnrollment', :enrollment_state => 'active', :section => @section,
                          :allow_multiple_enrollments => true, :limit_privileges_to_course_section => true)
      @assignment.reload
      @assignment.needs_grading_count_for_user(@ta).should eql(1)
    end
  end

  it "should preserve pass/fail with zero points possible" do
    setup_assignment_without_submission
    @assignment.grading_type = 'pass_fail'
    @assignment.points_possible = 0.0
    @assignment.save
    s = @assignment.grade_student(@user, :grade => 'pass')
    s.should be_is_a(Array)
    @assignment.reload
    @assignment.submissions.size.should eql(1)
    @submission = @assignment.submissions.first
    @submission.state.should eql(:graded)
    @submission.should eql(s[0])
    @submission.score.should eql(0.0)
    @submission.grade.should eql('complete')
    @submission.user_id.should eql(@user.id)

    @assignment.grade_student(@user, :grade => 'fail')
    @assignment.reload
    @assignment.submissions.size.should eql(1)
    @submission = @assignment.submissions.first
    @submission.state.should eql(:graded)
    @submission.should eql(s[0])
    @submission.score.should eql(0.0)
    @submission.grade.should eql('incomplete')
    @submission.user_id.should eql(@user.id)
  end

  it "should preserve pass/fail with no points possible" do
    setup_assignment_without_submission
    @assignment.grading_type = 'pass_fail'
    @assignment.points_possible = nil
    @assignment.save
    s = @assignment.grade_student(@user, :grade => 'pass')
    s.should be_is_a(Array)
    @assignment.reload
    @assignment.submissions.size.should eql(1)
    @submission = @assignment.submissions.first
    @submission.state.should eql(:graded)
    @submission.should eql(s[0])
    @submission.score.should eql(0.0)
    @submission.grade.should eql('complete')
    @submission.user_id.should eql(@user.id)

    @assignment.grade_student(@user, :grade => 'fail')
    @assignment.reload
    @assignment.submissions.size.should eql(1)
    @submission = @assignment.submissions.first
    @submission.state.should eql(:graded)
    @submission.should eql(s[0])
    @submission.score.should eql(0.0)
    @submission.grade.should eql('incomplete')
    @submission.user_id.should eql(@user.id)
  end

  it "should preserve letter grades with zero points possible" do
    setup_assignment_without_submission
    @assignment.grading_type = 'letter_grade'
    @assignment.points_possible = 0.0
    @assignment.save!

    s = @assignment.grade_student(@user, :grade => 'C')
    s.should be_is_a(Array)
    @assignment.reload
    @assignment.submissions.size.should eql(1)
    @submission = @assignment.submissions.first
    @submission.state.should eql(:graded)
    @submission.score.should eql(0.0)
    @submission.grade.should eql('C')
    @submission.user_id.should eql(@user.id)
  end

  it "should preserve letter grades with no points possible" do
    setup_assignment_without_submission
    @assignment.grading_type = 'letter_grade'
    @assignment.points_possible = nil
    @assignment.save!

    s = @assignment.grade_student(@user, :grade => 'C')
    s.should be_is_a(Array)
    @assignment.reload
    @assignment.submissions.size.should eql(1)
    @submission = @assignment.submissions.first
    @submission.state.should eql(:graded)
    @submission.score.should eql(0.0)
    @submission.grade.should eql('C')
    @submission.user_id.should eql(@user.id)
  end

  it "should give a grade to extra credit assignments" do
    setup_assignment_without_submission
    @assignment.grading_type = 'points'
    @assignment.points_possible = 0.0
    @assignment.save
    s = @assignment.grade_student(@user, :grade => "1")
    s.should be_is_a(Array)
    @assignment.reload
    @assignment.submissions.size.should eql(1)
    @submission = @assignment.submissions.first
    @submission.state.should eql(:graded)
    @submission.should eql(s[0])
    @submission.score.should eql(1.0)
    @submission.grade.should eql("1")
    @submission.user_id.should eql(@user.id)

    @submission.score = 2.0
    @submission.save
    @submission.reload
    @submission.grade.should eql("2")
  end

  it "should be able to grade an already-existing submission" do
    setup_assignment_without_submission

    s = @a.submit_homework(@user)
    s2 = @a.grade_student(@user, :grade => "10")
    s.reload
    s.should eql(s2[0])
    # there should only be one version, even though the grade changed
    s.versions.length.should eql(1)
    s2[0].state.should eql(:graded)
  end

  it "should not mark as submitted if no submission" do
    setup_assignment_without_submission

    s = @a.submit_homework(@user)
    s.workflow_state.should == "unsubmitted"
  end

  describe  "interpret_grade" do
    it "should return nil when no grade was entered and assignment uses a grading standard (letter grade)" do
      Assignment.interpret_grade("", 20, GradingStandard.default_grading_standard).should be_nil
    end

    it "should allow grading an assignment with nil points_possible as percent" do
      Assignment.interpret_grade("100%", nil).should == 0
    end

    it "should not round scores" do
      Assignment.interpret_grade("88.75%", 15).should == 13.3125
    end
  end

  it "should create a new version for each submission" do
    setup_assignment_without_submission
    @a.submit_homework(@user)
    @a.submit_homework(@user)
    @a.submit_homework(@user)
    @a.reload
    @a.submissions.first.versions.length.should eql(3)
  end

  it "should default to unmuted" do
    assignment_model
    @assignment.muted?.should eql false
  end

  it "should be mutable" do
    assignment_model
    @assignment.respond_to?(:mute!).should eql true
    @assignment.mute!
    @assignment.muted?.should eql true
  end

  it "should be unmutable" do
    assignment_model
    @assignment.respond_to?(:unmute!).should eql true
    @assignment.mute!
    @assignment.unmute!
    @assignment.muted?.should eql false
  end

  describe "infer_times" do
    it "should set to all_day" do
      assignment_model(:due_at => "Sep 3 2008 12:00am",
                      :lock_at => "Sep 3 2008 12:00am",
                      :unlock_at => "Sep 3 2008 12:00am")
      @assignment.all_day.should eql(false)
      @assignment.infer_times
      @assignment.save!
      @assignment.all_day.should eql(true)
      @assignment.due_at.strftime("%H:%M").should eql("23:59")
      @assignment.lock_at.strftime("%H:%M").should eql("23:59")
      @assignment.unlock_at.strftime("%H:%M").should eql("00:00")
      @assignment.all_day_date.should eql(Date.parse("Sep 3 2008"))
    end

    it "should not set to all_day without infer_times call" do
      assignment_model(:due_at => "Sep 3 2008 12:00am")
      @assignment.all_day.should eql(false)
      @assignment.due_at.strftime("%H:%M").should eql("00:00")
      @assignment.all_day_date.should eql(Date.parse("Sep 3 2008"))
    end
  end

  describe "all_day and all_day_date from due_at" do
    def fancy_midnight(opts={})
      zone = opts[:zone] || Time.zone
      Time.use_zone(zone) do
        time = opts[:time] || Time.zone.now
        time.in_time_zone.midnight + 1.day - 1.minute
      end
    end

    before :each do
      @assignment = assignment_model
    end

    it "should interpret 11:59pm as all day with no prior value" do
      @assignment.due_at = fancy_midnight(:zone => 'Alaska')
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      @assignment.all_day.should == true
    end

    it "should interpret 11:59pm as all day with same-tz all-day prior value" do
      @assignment.due_at = fancy_midnight(:zone => 'Alaska') + 1.day
      @assignment.save!
      @assignment.due_at = fancy_midnight(:zone => 'Alaska')
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      @assignment.all_day.should == true
    end

    it "should interpret 11:59pm as all day with other-tz all-day prior value" do
      @assignment.due_at = fancy_midnight(:zone => 'Baghdad')
      @assignment.save!
      @assignment.due_at = fancy_midnight(:zone => 'Alaska')
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      @assignment.all_day.should == true
    end

    it "should interpret 11:59pm as all day with non-all-day prior value" do
      @assignment.due_at = fancy_midnight(:zone => 'Alaska') + 1.hour
      @assignment.save!
      @assignment.due_at = fancy_midnight(:zone => 'Alaska')
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      @assignment.all_day.should == true
    end

    it "should not interpret non-11:59pm as all day no prior value" do
      @assignment.due_at = fancy_midnight(:zone => 'Alaska').in_time_zone('Baghdad')
      @assignment.time_zone_edited = 'Baghdad'
      @assignment.save!
      @assignment.all_day.should == false
    end

    it "should not interpret non-11:59pm as all day with same-tz all-day prior value" do
      @assignment.due_at = fancy_midnight(:zone => 'Alaska')
      @assignment.save!
      @assignment.due_at = fancy_midnight(:zone => 'Alaska') + 1.hour
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      @assignment.all_day.should == false
    end

    it "should not interpret non-11:59pm as all day with other-tz all-day prior value" do
      @assignment.due_at = fancy_midnight(:zone => 'Baghdad')
      @assignment.save!
      @assignment.due_at = fancy_midnight(:zone => 'Alaska') + 1.hour
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      @assignment.all_day.should == false
    end

    it "should not interpret non-11:59pm as all day with non-all-day prior value" do
      @assignment.due_at = fancy_midnight(:zone => 'Alaska') + 1.hour
      @assignment.save!
      @assignment.due_at = fancy_midnight(:zone => 'Alaska') + 2.hour
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      @assignment.all_day.should == false
    end

    it "should preserve all-day when only changing time zone" do
      @assignment.due_at = fancy_midnight(:zone => 'Alaska')
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      @assignment.due_at = fancy_midnight(:zone => 'Alaska').in_time_zone('Baghdad')
      @assignment.time_zone_edited = 'Baghdad'
      @assignment.save!
      @assignment.all_day.should == true
    end

    it "should preserve non-all-day when only changing time zone" do
      @assignment.due_at = fancy_midnight(:zone => 'Alaska').in_time_zone('Baghdad')
      @assignment.save!
      @assignment.due_at = fancy_midnight(:zone => 'Alaska')
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      @assignment.all_day.should == false
    end

    it "should determine date from due_at's timezone" do
      @assignment.due_at = Date.today.in_time_zone('Baghdad') + 1.hour # 01:00:00 AST +03:00 today
      @assignment.time_zone_edited = 'Baghdad'
      @assignment.save!
      @assignment.all_day_date.should == Date.today

      @assignment.due_at = @assignment.due_at.in_time_zone('Alaska') - 2.hours # 12:00:00 AKDT -08:00 previous day
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      @assignment.all_day_date.should == Date.today - 1.day
    end

    it "should preserve all-day date when only changing time zone" do
      @assignment.due_at = Date.today.in_time_zone('Baghdad') # 00:00:00 AST +03:00 today
      @assignment.time_zone_edited = 'Baghdad'
      @assignment.save!
      @assignment.due_at = @assignment.due_at.in_time_zone('Alaska') # 13:00:00 AKDT -08:00 previous day
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      @assignment.all_day_date.should == Date.today
    end

    it "should preserve non-all-day date when only changing time zone" do
      @assignment.due_at = Date.today.in_time_zone('Alaska') - 11.hours # 13:00:00 AKDT -08:00 previous day
      @assignment.save!
      @assignment.due_at = @assignment.due_at.in_time_zone('Baghdad') # 00:00:00 AST +03:00 today
      @assignment.time_zone_edited = 'Baghdad'
      @assignment.save!
      @assignment.all_day_date.should == Date.today - 1.day
    end
  end

  it "should destroy group overrides when the group category changes" do
    @assignment = assignment_model
    @assignment.group_category = group_category(context: @assignment.context)
    @assignment.save!

    overrides = 5.times.map do
      override = @assignment.assignment_overrides.build
      override.set = @assignment.group_category.groups.create!(context: @assignment.context)
      override.save!

      override.workflow_state.should == 'active'
      override
    end

    @assignment.group_category = group_category(context: @assignment.context, name: "bar")
    @assignment.save!

    overrides.each do |override|
      override.reload

      override.workflow_state.should == 'deleted'
      override.versions.size.should == 2
      override.assignment_version.should == @assignment.version_number
    end
  end

  context "concurrent inserts" do
    def concurrent_inserts
      assignment_model
      user_model
      @course.enroll_student(@user).update_attribute(:workflow_state, 'accepted')
      @assignment.context.reload

      @assignment.submissions.scoped.delete_all
      real_sub = @assignment.submissions.build(user: @user)

      @assignment.submissions.expects(:where).once.returns(Submission.none)
      @assignment.submissions.expects(:build).once.returns(real_sub)

      sub = nil
      lambda {
        sub = yield(@assignment, @user)
      }.should_not raise_error
      
      sub.should_not be_new_record
      sub.should eql real_sub
    end

    it "should handle them gracefully in find_or_create_submission" do
      concurrent_inserts do |assignment, user|
        assignment.find_or_create_submission(user)
      end
    end

    it "should handle them gracefully in submit_homework" do
      concurrent_inserts do |assignment, user|
        assignment.submit_homework(user, :body => "test")
      end
    end
  end

  context "peer reviews" do
    it "should assign peer reviews" do
      setup_assignment
      assignment_model

      @submissions = []
      users = []
      10.times do |i|
        users << User.create(:name => "user #{i}")
      end
      users.each do |u|
        @c.enroll_user(u)
      end
      @a.reload
      users.each do |u|
        @submissions << @a.submit_homework(u, :submission_type => "online_url", :url => "http://www.google.com")
      end
      @a.peer_review_count = 1
      res = @a.assign_peer_reviews
      res.length.should eql(@submissions.length)
      @submissions.each do |s|
        res.map{|a| a.asset}.should be_include(s)
        res.map{|a| a.assessor_asset}.should be_include(s)
      end
    end

    it "should assign when already graded" do
      setup_assignment
      assignment_model

      @submissions = []
      users = []
      10.times do |i|
        users << User.create(:name => "user #{i}")
      end
      users.each do |u|
        @c.enroll_user(u)
      end
      @a.reload
      users.each do |u|
        @submissions << @a.submit_homework(u, :submission_type => "online_url", :url => "http://www.google.com")
        @a.grade_student(u, :grader => @teacher, :grade => '100')
      end
      @a.peer_review_count = 1
      res = @a.assign_peer_reviews
      res.length.should eql(@submissions.length)
      @submissions.each do |s|
        res.map{|a| a.asset}.should be_include(s)
        res.map{|a| a.assessor_asset}.should be_include(s)
      end
    end

    it "should allow setting peer_reviews_assign_at" do
      setup_assignment
      assignment_model
      now = Time.now
      @assignment.peer_reviews_assign_at = now
      @assignment.peer_reviews_assign_at.should == now
    end

    it "should assign multiple peer reviews" do
      setup_assignment
      assignment_model
      @a.reload
      @submissions = []
      3.times do |i|
        e = @c.enroll_user(User.create(:name => "user #{i}"))
        @submissions << @a.submit_homework(e.user, :submission_type => "online_url", :url => "http://www.google.com")
      end
      @a.peer_review_count = 2
      res = @a.assign_peer_reviews
      res.length.should eql(@submissions.length * 2)
      @submissions.each do |s|
        assets = res.select{|a| a.asset == s}
        assets.length.should be > 0 #eql(2)
        assets.map{|a| a.assessor_id}.uniq.length.should eql(assets.length)

        assessors = res.select{|a| a.assessor_asset == s}
        assessors.length.should eql(2)
        assessors[0].asset_id.should_not eql(assessors[1].asset_id)
      end
    end

    it "should assign late peer reviews" do
      setup_assignment
      assignment_model

      @submissions = []
      5.times do |i|
        e = @c.enroll_user(User.create(:name => "user #{i}"))
        @a.context.reload
        @submissions << @a.submit_homework(e.user, :submission_type => "online_url", :url => "http://www.google.com")
      end
      @a.peer_review_count = 2
      res = @a.assign_peer_reviews
      res.length.should eql(@submissions.length * 2)
      # @submissions.each do |s|
        # # This user should have two unique assessors assigned
        # assets = res.select{|a| a.asset == s}
        # assets.length.should be > 0 #eql(2)
        # assets.map{|a| a.assessor_id}.uniq.length.should eql(assets.length)

        # # This user should be assigned two unique submissions to assess
        # assessors = res.select{|a| a.assessor_asset == s}
        # assessors.length.should eql(2)
        # assessors[0].asset_id.should_not eql(assessors[1].asset_id)
      # end
      e = @c.enroll_user(User.create(:name => "new user"))
      @a.reload
      s = @a.submit_homework(e.user, :submission_type => "online_url", :url => "http://www.google.com")
      res = @a.assign_peer_reviews
      res.length.should >= 2
      res.any?{|a| a.assessor_asset == s}.should eql(true)
    end

    it "should assign late peer reviews to each other if there is more than one" do
      setup_assignment
      assignment_model
      @a.reload
      @submissions = []
      10.times do |i|
        e = @c.enroll_user(User.create(:name => "user #{i}"))
        @submissions << @a.submit_homework(e.user, :submission_type => "online_url", :url => "http://www.google.com")
      end
      @a.peer_review_count = 2
      res = @a.assign_peer_reviews
      res.length.should eql(@submissions.length * 2)
      # @submissions.each do |s|
        # assets = res.select{|a| a.asset == s}
        # assets.length.should be > 0 #eql(2)
        # assets.map{|a| a.assessor_id}.uniq.length.should eql(assets.length)

        # assessors = res.select{|a| a.assessor_asset == s}
        # assessors.length.should eql(2)
        # assessors[0].asset_id.should_not eql(assessors[1].asset_id)
      # end

      @late_submissions = []
      3.times do |i|
        e = @c.enroll_user(User.create(:name => "new user #{i}"))
        @a.reload
        @late_submissions << @a.submit_homework(e.user, :submission_type => "online_url", :url => "http://www.google.com")
      end
      res = @a.assign_peer_reviews
      res.length.should >= 6
      ids = @late_submissions.map{|s| s.user_id}
      # @late_submissions.each do |s|
        # assets = res.select{|a| a.asset == s}
        # assets.length.should be > 0 #eql(2)
        # assets.all?{|a| a.assessor_id != s.user_id && ids.include?(a.assessor_id) }.should eql(true)

        # assessor_assets = res.select{|a| a.assessor_asset == s}
        # assessor_assets.length.should eql(2)
        # assets.all?{|a| a.assessor_id != s.user_id && ids.include?(a.assessor_id) }.should eql(true)
      # end
    end
  end

  context "grading" do
    it "should update grades when assignment changes" do
      setup_assignment_without_submission
      @a.update_attributes(:grading_type => 'letter_grade', :points_possible => 20)
      @teacher = @a.context.enroll_user(User.create(:name => "user 1"), 'TeacherEnrollment').user
      @student = @a.context.enroll_user(User.create(:name => "user 1"), 'StudentEnrollment').user
      @enrollment = @student.enrollments.first
      @assignment.reload
      @sub = @assignment.grade_student(@student, :grader => @teacher, :grade => 'C').first
      @sub.grade.should eql('C')
      @sub.score.should eql(15.2)
      @enrollment.reload.computed_current_score.should == 76

      @assignment.points_possible = 30
      @assignment.save!
      @sub.reload
      @sub.score.should eql(15.2)
      @sub.grade.should eql('F')
      @enrollment.reload.computed_current_score.should == 50.7
    end

    it "should accept lowercase letter grades" do
      setup_assignment_without_submission
      @a.update_attributes(:grading_type => 'letter_grade', :points_possible => 20)
      @teacher = @a.context.enroll_user(User.create(:name => "user 1"), 'TeacherEnrollment').user
      @student = @a.context.enroll_user(User.create(:name => "user 1"), 'StudentEnrollment').user
      @assignment.reload
      @sub = @assignment.grade_student(@student, :grader => @teacher, :grade => 'c').first
      @sub.grade.should eql('C')
      @sub.score.should eql(15.2)
    end
  end

  context "as_json" do
    it "should include permissions if specified" do
      assignment_model
      @course.offer!
      @enr1 = @course.enroll_teacher(@teacher = user)
      @enr1.accept
      @assignment.to_json.should_not match(/permissions/)
      @assignment.to_json(:permissions => {:user => nil}).should match(/\"permissions\"\s*:\s*\{\}/)
      @assignment.grants_right?(@teacher, nil, :create).should eql(true)
      @assignment.to_json(:permissions => {:user => @teacher, :session => nil}).should match(/\"permissions\"\s*:\s*\{\"/)
      hash = @assignment.as_json(:permissions => {:user => @teacher, :session => nil})
      hash["assignment"].should_not be_nil
      hash["assignment"]["permissions"].should_not be_nil
      hash["assignment"]["permissions"].should_not be_empty
      hash["assignment"]["permissions"]["read"].should eql(true)
    end

    it "should serialize with roots included in nested elements" do
      course_model
      @course.assignments.create!(:title => "some assignment")
      hash = @course.as_json(:include => :assignments)
      hash["course"].should_not be_nil
      hash["course"]["assignments"].should_not be_empty
      hash["course"]["assignments"][0].should_not be_nil
      hash["course"]["assignments"][0]["assignment"].should_not be_nil
    end

    it "should serialize with permissions" do
      assignment_model
      @course.offer!
      @enr1 = @course.enroll_teacher(@teacher = user)
      @enr1.accept
      hash = @course.as_json(:permissions => {:user => @teacher, :session => nil} )
      hash["course"].should_not be_nil
      hash["course"]["permissions"].should_not be_nil
      hash["course"]["permissions"].should_not be_empty
      hash["course"]["permissions"]["read"].should eql(true)
    end

    it "should exclude root" do
      assignment_model
      @course.offer!
      @enr1 = @course.enroll_teacher(@teacher = user)
      @enr1.accept
      hash = @course.as_json(:include_root => false, :permissions => {:user => @teacher, :session => nil} )
      hash["course"].should be_nil
      hash["name"].should eql(@course.name)
      hash["permissions"].should_not be_nil
      hash["permissions"].should_not be_empty
      hash["permissions"]["read"].should eql(true)
    end

    it "should include group_category" do
      assignment_model(:group_category => "Something")
      hash = @assignment.as_json
      hash["assignment"]["group_category"].should == "Something"
    end
  end

  context "ical" do
    it ".to_ics should not fail for null due dates" do
      assignment_model(:due_at => "")
      res = @assignment.to_ics
      res.should_not be_nil
      res.match(/DTSTART/).should be_nil
    end

    it ".to_ics should not return data for null due dates" do
      assignment_model(:due_at => "")
      res = @assignment.to_ics(false)
      res.should be_nil
    end

    it ".to_ics should return string data for assignments with due dates" do
      Time.zone = 'UTC'
      assignment_model(:due_at => "Sep 3 2008 11:55am")
      # force known value so we can check serialization
      @assignment.updated_at = Time.at(1220443500) # 3 Sep 2008 12:05pm (UTC)
      res = @assignment.to_ics
      res.should_not be_nil
      res.match(/DTEND:20080903T115500Z/).should_not be_nil
      res.match(/DTSTART:20080903T115500Z/).should_not be_nil
      res.match(/DTSTAMP:20080903T120500Z/).should_not be_nil
    end

    it ".to_ics should return string data for assignments with due dates in correct tz" do
      Time.zone = 'Alaska' # -0800
      assignment_model(:due_at => "Sep 3 2008 11:55am")
      # force known value so we can check serialization
      @assignment.updated_at = Time.at(1220472300) # 3 Sep 2008 12:05pm (AKDT)
      res = @assignment.to_ics
      res.should_not be_nil
      res.match(/DTEND:20080903T195500Z/).should_not be_nil
      res.match(/DTSTART:20080903T195500Z/).should_not be_nil
      res.match(/DTSTAMP:20080903T200500Z/).should_not be_nil
    end

    it ".to_ics should return data for assignments with due dates" do
      Time.zone = 'UTC'
      assignment_model(:due_at => "Sep 3 2008 11:55am")
      # force known value so we can check serialization
      @assignment.updated_at = Time.at(1220443500) # 3 Sep 2008 12:05pm (UTC)
      res = @assignment.to_ics(false)
      res.should_not be_nil
      res.start.icalendar_tzid.should == 'UTC'
      res.start.strftime('%Y-%m-%dT%H:%M:%S').should == Time.zone.parse("Sep 3 2008 11:55am").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
      res.end.icalendar_tzid.should == 'UTC'
      res.end.strftime('%Y-%m-%dT%H:%M:%S').should == Time.zone.parse("Sep 3 2008 11:55am").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
      res.dtstamp.icalendar_tzid.should == 'UTC'
      res.dtstamp.strftime('%Y-%m-%dT%H:%M:%S').should == Time.zone.parse("Sep 3 2008 12:05pm").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
    end

    it ".to_ics should return data for assignments with due dates in correct tz" do
      Time.zone = 'Alaska' # -0800
      assignment_model(:due_at => "Sep 3 2008 11:55am")
      # force known value so we can check serialization
      @assignment.updated_at = Time.at(1220472300) # 3 Sep 2008 12:05pm (AKDT)
      res = @assignment.to_ics(false)
      res.should_not be_nil
      res.start.icalendar_tzid.should == 'UTC'
      res.start.strftime('%Y-%m-%dT%H:%M:%S').should == Time.zone.parse("Sep 3 2008 11:55am").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
      res.end.icalendar_tzid.should == 'UTC'
      res.end.strftime('%Y-%m-%dT%H:%M:%S').should == Time.zone.parse("Sep 3 2008 11:55am").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
      res.dtstamp.icalendar_tzid.should == 'UTC'
      res.dtstamp.strftime('%Y-%m-%dT%H:%M:%S').should == Time.zone.parse("Sep 3 2008 12:05pm").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
    end

    it ".to_ics should return string dates for all_day events" do
      Time.zone = 'UTC'
      assignment_model(:due_at => "Sep 3 2008 11:59pm")
      @assignment.all_day.should eql(true)
      res = @assignment.to_ics
      res.match(/DTSTART;VALUE=DATE:20080903/).should_not be_nil
      res.match(/DTEND;VALUE=DATE:20080903/).should_not be_nil
    end

    it ".to_ics should return a plain-text description and alt html description" do
      html = %{<div>
        This assignment is due December 16th. Plz discuss the reading.
        <p> </p>
        <p>Test.</p>
      </div>}
      assignment_model(:due_at => "Sep 3 2008 12:00am", :description => html)
      ev = @assignment.to_ics(false)
      pending("assignment description disabled") do
        ev.description.should == "This assignment is due December 16th. Plz discuss the reading.\n  \n\n\n Test."
        ev.x_alt_desc.should == html.strip
      end
    end

    it ".to_ics should run the description through api_user_content to translate links" do
      html = %{<a href="/calendar">Click!</a>}
      assignment_model(:due_at => "Sep 3 2008 12:00am", :description => html)
      ev = @assignment.to_ics(false)
      pending("assignment description disabled") do
        ev.description.should == "[Click!](http://localhost/calendar)"
        ev.x_alt_desc.should == %{<a href="http://localhost/calendar">Click!</a>}
      end
    end

    it ".to_ics should populate uid and summary fields" do
      Time.zone = 'UTC'
      assignment_model(:due_at => "Sep 3 2008 11:55am", :title => "assignment title")
      ev = @a.to_ics(false)
      ev.uid.should == "event-assignment-#{@a.id}"
      ev.summary.should == "#{@a.title} [#{@a.context.course_code}]"
      # TODO: ev.url.should == ?
    end

    it ".to_ics should apply due_at override information" do
      Time.zone = 'UTC'
      assignment_model(:due_at => "Sep 3 2008 11:55am", :title => "assignment title")
      @override = @a.assignment_overrides.build
      @override.set = @c.default_section
      @override.override_due_at(Time.zone.parse("Sep 28 2008 11:55am"))
      @override.save!

      assignment = AssignmentOverrideApplicator.assignment_with_overrides(@a, [@override])
      ev = assignment.to_ics(false)
      ev.uid.should == "event-assignment-override-#{@override.id}"
      ev.summary.should == "#{@a.title} (#{@override.title}) [#{assignment.context.course_code}]"
      #TODO: ev.url.should == ?
    end

    it ".to_ics should not apply non-due_at override information" do
      Time.zone = 'UTC'
      assignment_model(:due_at => "Sep 3 2008 11:55am", :title => "assignment title")
      @override = @a.assignment_overrides.build
      @override.set = @c.default_section
      @override.override_lock_at(Time.zone.parse("Sep 28 2008 11:55am"))
      @override.save!

      assignment = AssignmentOverrideApplicator.assignment_with_overrides(@a, [@override])
      ev = assignment.to_ics(false)
      ev.uid.should == "event-assignment-#{@a.id}"
      ev.summary.should == "#{@a.title} [#{@a.context.course_code}]"
    end

  end

  context "quizzes and topics" do
    it "should create a quiz if none exists and specified" do
      assignment_model(:submission_types => "online_quiz")
      @a.reload
      @a.submission_types.should eql('online_quiz')
      @a.quiz.should_not be_nil
      @a.quiz.assignment_id.should eql(@a.id)
      @a.due_at = Time.now
      @a.save
      @a.reload
      @a.quiz.should_not be_nil
      @a.quiz.assignment_id.should eql(@a.id)
    end

    it "should delete a quiz if no longer specified" do
      assignment_model(:submission_types => "online_quiz")
      @a.reload
      @a.submission_types.should eql('online_quiz')
      @a.quiz.should_not be_nil
      @a.quiz.assignment_id.should eql(@a.id)
      @a.submission_types = 'on_paper'
      @a.save!
      @a.reload
      @a.quiz.should be_nil
    end

    it "should not delete the assignment when unlinked from a quiz" do
      assignment_model(:submission_types => "online_quiz")
      @a.reload
      @a.submission_types.should eql('online_quiz')
      @quiz = @a.quiz
      @quiz.should_not be_nil
      @quiz.state.should eql(:created)
      @quiz.assignment_id.should eql(@a.id)
      @a.submission_types = 'on_paper'
      @a.save!
      @quiz = Quizzes::Quiz.find(@quiz.id)
      @quiz.assignment_id.should eql(nil)
      @quiz.state.should eql(:deleted)
      @a.reload
      @a.quiz.should be_nil
      @a.state.should eql(:published)
    end

    it "should not delete the quiz if non-empty when unlinked" do
      assignment_model(:submission_types => "online_quiz")
      @a.reload
      @a.submission_types.should eql('online_quiz')
      @quiz = @a.quiz
      @quiz.should_not be_nil
      @quiz.assignment_id.should eql(@a.id)
      @quiz.quiz_questions.create!()
      @quiz.generate_quiz_data
      @quiz.save!
      @a.quiz.reload
      @quiz.root_entries.should_not be_empty
      @a.submission_types = 'on_paper'
      @a.save!
      @a.reload
      @a.quiz.should be_nil
      @a.state.should eql(:published)
      @quiz = Quizzes::Quiz.find(@quiz.id)
      @quiz.assignment_id.should eql(nil)
      @quiz.state.should eql(:created)
    end

    it "should grab the original quiz if unlinked and relinked" do
      assignment_model(:submission_types => "online_quiz")
      @a.reload
      @a.submission_types.should eql('online_quiz')
      @quiz = @a.quiz
      @quiz.should_not be_nil
      @quiz.assignment_id.should eql(@a.id)
      @a.quiz.reload
      @a.submission_types = 'on_paper'
      @a.save!
      @a.submission_types = 'online_quiz'
      @a.save!
      @a.reload
      @a.quiz.should eql(@quiz)
      @a.state.should eql(:published)
      @quiz.reload
      @quiz.state.should eql(:created)
    end

    it "updates the draft state of its associated quiz" do
      assignment_model(:course => @course, :submission_types => "online_quiz")
      Account.default.enable_feature!(:draft_state)
      @a.reload
      @a.publish
      @a.save!
      @a.quiz.reload.should be_published
      @a.unpublish
      @a.quiz.reload.should_not be_published
    end

    it "should create a discussion_topic if none exists and specified" do
      course_model()
      assignment_model(:course => @course, :submission_types => "discussion_topic", :updating_user => @teacher)
      @a.submission_types.should eql('discussion_topic')
      @a.discussion_topic.should_not be_nil
      @a.discussion_topic.assignment_id.should eql(@a.id)
      @a.discussion_topic.user_id.should eql(@teacher.id)
      @a.due_at = Time.now
      @a.save
      @a.reload
      @a.discussion_topic.should_not be_nil
      @a.discussion_topic.assignment_id.should eql(@a.id)
      @a.discussion_topic.user_id.should eql(@teacher.id)
    end

    it "should delete a discussion_topic if no longer specified" do
      assignment_model(:submission_types => "discussion_topic")
      @a.submission_types.should eql('discussion_topic')
      @a.discussion_topic.should_not be_nil
      @a.discussion_topic.assignment_id.should eql(@a.id)
      @a.submission_types = 'on_paper'
      @a.save!
      @a.reload
      @a.discussion_topic.should be_nil
    end

    it "should not delete the assignment when unlinked from a topic" do
      assignment_model(:submission_types => "discussion_topic")
      @a.submission_types.should eql('discussion_topic')
      @topic = @a.discussion_topic
      @topic.should_not be_nil
      @topic.state.should eql(:active)
      @topic.assignment_id.should eql(@a.id)
      @a.submission_types = 'on_paper'
      @a.save!
      @topic = DiscussionTopic.find(@topic.id)
      @topic.assignment_id.should eql(nil)
      @topic.state.should eql(:deleted)
      @a.reload
      @a.discussion_topic.should be_nil
      @a.state.should eql(:published)
    end

    it "should not delete the topic if non-empty when unlinked" do
      assignment_model(:submission_types => "discussion_topic")
      @a.submission_types.should eql('discussion_topic')
      @topic = @a.discussion_topic
      @topic.should_not be_nil
      @topic.assignment_id.should eql(@a.id)
      @topic.discussion_entries.create!(:user => @user, :message => "testing")
      @a.discussion_topic.reload
      @a.submission_types = 'on_paper'
      @a.save!
      @a.reload
      @a.discussion_topic.should be_nil
      @a.state.should eql(:published)
      @topic = DiscussionTopic.find(@topic.id)
      @topic.assignment_id.should eql(nil)
      @topic.state.should eql(:active)
    end

    it "should grab the original topic if unlinked and relinked" do
      assignment_model(:submission_types => "discussion_topic")
      @a.submission_types.should eql('discussion_topic')
      @topic = @a.discussion_topic
      @topic.should_not be_nil
      @topic.assignment_id.should eql(@a.id)
      @topic.discussion_entries.create!(:user => @user, :message => "testing")
      @a.discussion_topic.reload
      @a.submission_types = 'on_paper'
      @a.save!
      @a.submission_types = 'discussion_topic'
      @a.save!
      @a.reload
      @a.discussion_topic.should eql(@topic)
      @a.state.should eql(:published)
      @topic.reload
      @topic.state.should eql(:active)
    end
  end

  context "broadcast policy" do
    context "due date changed" do
      it "should create a message when an assignment due date has changed" do
        Notification.create(:name => 'Assignment Due Date Changed')
        assignment_model(:title => 'Assignment with unstable due date')
        @a.context.offer!
        @a.created_at = 1.month.ago
        @a.due_at = Time.now + 60
        @a.save!
        @a.messages_sent.should be_include('Assignment Due Date Changed')
      end

      it "should NOT create a message when everything but the assignment due date has changed" do
        Notification.create(:name => 'Assignment Due Date Changed')
        t = Time.parse("Sep 1, 2009 5:00pm")
        assignment_model(:title => 'Assignment with unstable due date', :due_at => t)
        @a.due_at.should eql(t)
        @a.context.offer!
        @a.submission_types = "online_url"
        @a.title = "New Title"
        @a.due_at = t + 1
        @a.description = "New description"
        @a.points_possible = 50
        @a.save!
        @a.messages_sent.should_not be_include('Assignment Due Date Changed')
      end
    end

    context "assignment graded" do
      before { setup_assignment_with_students }

      specify { @assignment.should be_published }

      it "should notify students when their grade is changed" do
        @sub2 = @assignment.grade_student(@stu2, :grade => 8).first
        @sub2.messages_sent.should_not be_empty
        @sub2.messages_sent['Submission Graded'].should_not be_nil
        @sub2.messages_sent['Submission Grade Changed'].should be_nil
        @sub2.update_attributes(:graded_at => Time.now - 60*60)
        @sub2 = @assignment.grade_student(@stu2, :grade => 9).first
        @sub2.messages_sent.should_not be_empty
        @sub2.messages_sent['Submission Graded'].should be_nil
        @sub2.messages_sent['Submission Grade Changed'].should_not be_nil
      end

      it "should notify affected students on a mass-grade change" do
        pending "CNVS-5969 - Setting a default grade should send a 'Submission Graded' notification"
        @assignment.set_default_grade(:default_grade => 10)
        msg_sub1 = @assignment.submissions.detect{|s| s.id = @sub1.id}
        msg_sub1.messages_sent.should_not be_nil
        msg_sub1.messages_sent['Submission Grade Changed'].should_not be_nil
        msg_sub2 = @assignment.submissions.detect{|s| s.id = @sub2.id}
        msg_sub2.messages_sent.should_not be_nil
        msg_sub2.messages_sent['Submission Graded'].should_not be_nil
      end

      describe 'while they are muted' do
        before { @assignment.mute! }

        specify { @assignment.should be_muted }

        it "should not notify affected students on a mass-grade change if muted" do
          pending "CNVS-5969 - Setting a default grade should send a 'Submission Graded' notification"
          @assignment.set_default_grade(:default_grade => 10)
          @assignment.messages_sent.should be_empty
        end

        it "should not notify students when their grade is changed if muted" do
          @sub2 = @assignment.grade_student(@stu2, :grade => 8).first
          @sub2.update_attributes(:graded_at => Time.now - 60*60)
          @sub2 = @assignment.grade_student(@stu2, :grade => 9).first
          @sub2.messages_sent.should be_empty
        end
      end

      it "should include re-submitted submissions in the list of submissions needing grading" do
        @enr1.accept!
        @assignment.should be_published
        @assignment.submissions.size.should == 1
        Assignment.need_grading_info(15).find_by_id(@assignment.id).should be_nil
        @assignment.submit_homework(@stu1, :body => "Changed my mind!")
        @sub1.reload
        @sub1.body.should == "Changed my mind!"
        Assignment.need_grading_info(15).find_by_id(@assignment.id).should_not be_nil
      end
    end

    context "assignment changed" do
      it "should create a message when an assigment changes after it's been published" do
        Notification.create(:name => 'Assignment Changed')
        assignment_model
        @a.context.offer!
        @a.created_at = Time.parse("Jan 2 2000")
        @a.description = "something different"
        @a.notify_of_update = true
        @a.save
        @a.messages_sent.should be_include('Assignment Changed')
      end

      it "should NOT create a message when an assigment changes SHORTLY AFTER it's been created" do
        Notification.create(:name => 'Assignment Changed')
        assignment_model
        @a.context.offer!
        @a.description = "something different"
        @a.save
        @a.messages_sent.should_not be_include('Assignment Changed')
      end

      it "should not create a message when a muted assignment changes" do
        assignment_model
        @a.mute!
        Notification.create :name => "Assignment Changed"
        @a.context.offer!
        @a.description = "something different"
        @a.save
        @a.messages_sent.should be_empty
      end
    end

    context "assignment created" do
      it "should create a message when an assigment is added to a course in process" do
        Notification.create(:name => 'Assignment Created')
        course_with_teacher(:active_all => true)
        assignment_model(:context => @course)
        @a.messages_sent.should be_include('Assignment Created')
      end

      it "should not create a message in an unpublished course" do
        Notification.create(:name => 'Assignment Created')
        course_with_teacher(:active_user => true)
        assignment_model(:context => @course)
        @a.messages_sent.should_not be_include('Assignment Created')
      end
    end

    context "varied due date notifications" do
      before do
        course_with_teacher(:active_all => true)
        @teacher.communication_channels.create(:path => "teacher@instructure.com").confirm!

        @studentA = user_with_pseudonym(:active_all => true, :name => 'StudentA', :username => 'studentA@instructure.com')
        @studentA.communication_channels.create(:path => "studentA@instructure.com").confirm!
        @ta = user_with_pseudonym(:active_all => true, :name => 'TA1', :username => 'ta1@instructure.com')
        @ta.communication_channels.create(:path => "ta1@instructure.com").confirm!
        @course.enroll_student(@studentA).update_attribute(:workflow_state, 'active')
        @course.enroll_user(@ta, 'TaEnrollment', :enrollment_state => 'active', :limit_privileges_to_course_section => true)

        @section2 = @course.course_sections.create!(:name => 'section 2')
        @studentB = user_with_pseudonym(:active_all => true, :name => 'StudentB', :username => 'studentB@instructure.com')
        @studentB.communication_channels.create(:path => "studentB@instructure.com").confirm!
        @ta2 = user_with_pseudonym(:active_all => true, :name => 'TA2', :username => 'ta2@instructure.com')
        @ta2.communication_channels.create(:path => "ta2@instructure.com").confirm!
        @section2.enroll_user(@studentB, 'StudentEnrollment', 'active')
        @course.enroll_user(@ta2, 'TaEnrollment', :section => @section2, :enrollment_state => 'active', :limit_privileges_to_course_section => true)

        Time.zone = 'Alaska'
        default_due = DateTime.parse("01 Jan 2011 14:00 AKST")
        section_2_due = DateTime.parse("02 Jan 2011 14:00 AKST")
        @assignment = @course.assignments.build(:title => "some assignment", :due_at => default_due, :submission_types => ['online_text_entry'])
        @assignment.save_without_broadcasting!
        override = @assignment.assignment_overrides.build
        override.set = @section2
        override.override_due_at(section_2_due)
        override.save!
      end

      context "assignment created" do
        before do
          Notification.create(:name => 'Assignment Created')
        end

        it "should notify of the correct due date for the recipient, or 'multiple'" do
          @assignment.do_notifications!

          messages_sent = @assignment.messages_sent['Assignment Created']
          messages_sent.detect{|m|m.user_id == @teacher.id}.body.should be_include "Multiple Dates"
          messages_sent.detect{|m|m.user_id == @studentA.id}.body.should be_include "Jan 1, 2011"
          messages_sent.detect{|m|m.user_id == @ta.id}.body.should be_include "Jan 1, 2011"
          messages_sent.detect{|m|m.user_id == @studentB.id}.body.should be_include "Jan 2, 2011"
          messages_sent.detect{|m|m.user_id == @ta2.id}.body.should be_include "Multiple Dates"
        end

        it "should collapse identical instructor due dates" do
          # change the override to match the default due date
          override = @assignment.assignment_overrides.first
          override.override_due_at(@assignment.due_at)
          override.save!
          @assignment.do_notifications!

          # when the override matches the default, show the default and not "Multiple"
          messages_sent = @assignment.messages_sent['Assignment Created']
          messages_sent.each{|m| m.body.should be_include "Jan 1, 2011"}
        end
      end

      context "assignment due date changed" do
        before do
          Notification.create(:name => 'Assignment Due Date Changed')
          Notification.create(:name => 'Assignment Due Date Override Changed')
        end

        it "should notify appropriate parties when the default due date changes" do
          @assignment.update_attribute(:created_at, 1.day.ago)

          @assignment.due_at = DateTime.parse("09 Jan 2011 14:00 AKST")
          @assignment.save!

          messages_sent = @assignment.messages_sent['Assignment Due Date Changed']
          messages_sent.detect{|m|m.user_id == @teacher.id}.body.should be_include "Jan 9, 2011"
          messages_sent.detect{|m|m.user_id == @studentA.id}.body.should be_include "Jan 9, 2011"
          messages_sent.detect{|m|m.user_id == @ta.id}.body.should be_include "Jan 9, 2011"
          messages_sent.detect{|m|m.user_id == @studentB.id}.should be_nil
          messages_sent.detect{|m|m.user_id == @ta2.id}.body.should be_include "Jan 9, 2011"
        end

        it "should notify appropriate parties when an override due date changes" do
          @assignment.update_attribute(:created_at, 1.day.ago)

          override = @assignment.assignment_overrides.first.reload
          override.override_due_at(DateTime.parse("11 Jan 2011 11:11 AKST"))
          override.save!

          messages_sent = override.messages_sent['Assignment Due Date Changed']
          messages_sent.detect{|m|m.user_id == @studentA.id}.should be_nil
          messages_sent.detect{|m|m.user_id == @studentB.id}.body.should be_include "Jan 11, 2011"

          messages_sent = override.messages_sent['Assignment Due Date Override Changed']
          messages_sent.detect{|m|m.user_id == @ta.id}.should be_nil
          messages_sent.detect{|m|m.user_id == @teacher.id}.body.should be_include "Jan 11, 2011"
          messages_sent.detect{|m|m.user_id == @ta2.id}.body.should be_include "Jan 11, 2011"
        end
      end

      context "assignment submitted late" do
        before do
          Notification.create(:name => 'Assignment Submitted')
          Notification.create(:name => 'Assignment Submitted Late')
        end

        it "should send a late submission notification iff the submit date is late for the submitter" do
          fake_submission_time = Time.parse "Jan 01 17:00:00 -0900 2011"
          Time.stubs(:now).returns(fake_submission_time)
          subA = @assignment.submit_homework @studentA, :submission_type => "online_text_entry", :body => "ooga"
          subB = @assignment.submit_homework @studentB, :submission_type => "online_text_entry", :body => "booga"
          Time.unstub(:now)

          subA.messages_sent["Assignment Submitted Late"].should_not be_nil
          subB.messages_sent["Assignment Submitted Late"].should be_nil
        end
      end

      context "group assignment submitted late" do
        before do
          Notification.create(:name => 'Group Assignment Submitted Late')
        end

        it "should send a late submission notification iff the submit date is late for the group" do
          @a = assignment_model(:course => @course, :group_category => "Study Groups", :due_at => Time.parse("Jan 01 17:00:00 -0900 2011"), :submission_types => ["online_text_entry"])
          @group1 = @a.context.groups.create!(:name => "Study Group 1", :group_category => @a.group_category)
          @group1.add_user(@studentA)
          @group2 = @a.context.groups.create!(:name => "Study Group 2", :group_category => @a.group_category)
          @group2.add_user(@studentB)
          override = @a.assignment_overrides.new
          override.set = @group2
          override.override_due_at(Time.parse("Jan 03 17:00:00 -0900 2011"))
          override.save!
          fake_submission_time = Time.parse("Jan 02 17:00:00 -0900 2011")
          Time.stubs(:now).returns(fake_submission_time)
          subA = @assignment.submit_homework @studentA, :submission_type => "online_text_entry", :body => "eenie"
          subB = @assignment.submit_homework @studentB, :submission_type => "online_text_entry", :body => "meenie"
          Time.unstub(:now)

          subA.messages_sent["Group Assignment Submitted Late"].should_not be_nil
          subB.messages_sent["Group Assignment Submitted Late"].should be_nil
        end
      end
    end
  end

  context "group assignment" do
    it "should submit the homework for all students in the same group" do
      setup_assignment_with_group
      sub = @a.submit_homework(@u1, :submission_type => "online_text_entry", :body => "Some text for you")
      sub.user_id.should eql(@u1.id)
      @a.reload
      subs = @a.submissions
      subs.length.should eql(2)
      subs.map(&:group_id).uniq.should eql([@group.id])
      subs.map(&:submission_type).uniq.should eql(['online_text_entry'])
      subs.map(&:body).uniq.should eql(['Some text for you'])
    end

    it "should submit the homework for all students in the group if grading them individually" do
      setup_assignment_with_group
      @a.update_attribute(:grade_group_students_individually, true)
      res = @a.submit_homework(@u1, :submission_type => "online_text_entry", :body => "Test submission")
      @a.reload
      submissions = @a.submissions
      submissions.length.should eql 2
      submissions.map(&:group_id).uniq.should eql [@group.id]
      submissions.map(&:submission_type).uniq.should eql ["online_text_entry"]
      submissions.map(&:body).uniq.should eql ["Test submission"]
    end

    it "should update submission for all students in the same group" do
      setup_assignment_with_group
      res = @a.grade_student(@u1, :grade => "10")
      res.should_not be_nil
      res.should_not be_empty
      res.length.should eql(2)
      res.map{|s| s.user}.should be_include(@u1)
      res.map{|s| s.user}.should be_include(@u2)
    end

    it "should create an initial submission comment for only the submitter by default" do
      setup_assignment_with_group
      sub = @a.submit_homework(@u1, :submission_type => "online_text_entry", :body => "Some text for you", :comment => "hey teacher, i hate my group. i did this entire project by myself :(")
      sub.user_id.should eql(@u1.id)
      sub.submission_comments.size.should eql 1
      @a.reload
      other_sub = (@a.submissions - [sub])[0]
      other_sub.submission_comments.size.should eql 0
    end

    it "should add a submission comment for only the specified user by default" do
      setup_assignment_with_group
      res = @a.grade_student(@u1, :comment => "woot")
      res.should_not be_nil
      res.should_not be_empty
      res.length.should eql(1)
      res.find{|s| s.user == @u1}.submission_comments.should_not be_empty
      res.find{|s| s.user == @u2}.should be_nil #.submission_comments.should be_empty
    end

    it "should update submission for only the individual student if set thay way" do
      setup_assignment_with_group
      @a.update_attribute(:grade_group_students_individually, true)
      res = @a.grade_student(@u1, :grade => "10")
      res.should_not be_nil
      res.should_not be_empty
      res.length.should eql(1)
      res[0].user.should eql(@u1)
    end

    it "should create an initial submission comment for all group members if specified" do
      setup_assignment_with_group
      sub = @a.submit_homework(@u1, :submission_type => "online_text_entry", :body => "Some text for you", :comment => "ohai teacher, we had so much fun working together", :group_comment => "1")
      sub.user_id.should eql(@u1.id)
      sub.submission_comments.size.should eql 1
      @a.reload
      other_sub = (@a.submissions - [sub])[0]
      other_sub.submission_comments.size.should eql 1
    end

    it "should add a submission comment for all group members if specified" do
      setup_assignment_with_group
      res = @a.grade_student(@u1, :comment => "woot", :group_comment => "1")
      res.should_not be_nil
      res.should_not be_empty
      res.length.should eql(2)
      res.find{|s| s.user == @u1}.submission_comments.should_not be_empty
      res.find{|s| s.user == @u2}.submission_comments.should_not be_empty
      # all the comments should have the same group_comment_id, for deletion
      comments = SubmissionComment.for_assignment_id(@a.id).all
      comments.size.should == 2
      group_comment_id = comments[0].group_comment_id
      group_comment_id.should be_present
      comments.all? { |c| c.group_comment_id == group_comment_id }.should be_true
    end

    it "return the single submission if the user is not in a group" do
      setup_assignment_with_group
      res = @a.grade_student(@u3, :comment => "woot", :group_comment => "1")
      res.should_not be_nil
      res.should_not be_empty
      res.length.should eql(1)
      comments = res.find{|s| s.user == @u3}.submission_comments
      comments.size.should == 1
      comments[0].group_comment_id.should be_nil
    end

    it "associates attachments with all submissions" do
      setup_assignment_with_group
      @a.update_attribute :submission_types, "online_upload"
      f = @u1.attachments.create! uploaded_data: StringIO.new('blah'),
        context: @u1,
        filename: 'blah.txt'
      @a.submit_homework(@u1, attachments: [f])
      @a.submissions.reload.each { |s|
        s.attachments.should == [f]
      }
    end
  end

  context "adheres_to_policy" do
    it "should return the same grants_right? with nil parameters" do
      course_with_teacher(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment")
      rights = @assignment.grants_rights?(@user)
      rights.should_not be_empty
      rights.should == @assignment.grants_rights?(@user, nil)
      rights.should == @assignment.grants_rights?(@user, nil, nil)
    end

    it "should serialize permissions" do
      course_with_teacher(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment")
      data = @assignment.as_json(:permissions => {:user => @user, :session => nil}) rescue nil
      data.should_not be_nil
      data['assignment'].should_not be_nil
      data['assignment']['permissions'].should_not be_nil
      data['assignment']['permissions'].should_not be_empty
    end
  end

  context "modules" do
    it "should be locked when part of a locked module" do
      course :active_all => true
      student_in_course
      ag = @course.assignment_groups.create!
      a1 = ag.assignments.create!(:context => course)
      a1.locked_for?(@user).should be_false

      m = @course.context_modules.create!
      ct = ContentTag.new
      ct.content_id = a1.id
      ct.content_type = 'Assignment'
      ct.context_id = course.id
      ct.context_type = 'Course'
      ct.title = "Assignment"
      ct.tag_type = "context_module"
      ct.context_module_id = m.id
      ct.context_code = "course_#{@course.id}"
      ct.save!

      m.unlock_at = Time.now.in_time_zone + 1.day
      m.save
      a1.reload
      a1.locked_for?(@user).should be_true
    end

    it "should be locked when associated discussion topic is part of a locked module" do
      course :active_all => true
      student_in_course
      a1 = assignment_model(:course => @course, :submission_types => "discussion_topic")
      a1.reload
      a1.locked_for?(@user).should be_false

      m = @course.context_modules.create!
      m.add_item(:id => a1.discussion_topic.id, :type => 'discussion_topic')

      m.unlock_at = Time.now.in_time_zone + 1.day
      m.save
      a1.reload
      a1.locked_for?(@user).should be_true
    end

    it "should be locked when associated quiz is part of a locked module" do
      course :active_all => true
      student_in_course
      a1 = assignment_model(:course => @course, :submission_types => "online_quiz")
      a1.reload
      a1.locked_for?(@user).should be_false

      m = @course.context_modules.create!
      m.add_item(:id => a1.quiz.id, :type => 'quiz')

      m.unlock_at = Time.now.in_time_zone + 1.day
      m.save
      a1.reload
      a1.locked_for?(@user).should be_true
    end
  end

  context "group_students" do
    it "should return [nil, [student]] unless the assignment has a group_category" do
      @assignment = assignment_model
      @student = user_model
      @assignment.group_students(@student).should == [nil, [@student]]
    end

    it "should return [nil, [student]] if the context doesn't have any active groups in the same category" do
      @assignment = assignment_model(:group_category => "Fake Category")
      @student = user_model
      @assignment.group_students(@student).should == [nil, [@student]]
    end

    it "should return [nil, [student]] if the student isn't in any of the candidate groups" do
      @assignment = assignment_model(:group_category => "Category")
      @group = @course.groups.create(:name => "Group", :group_category => @assignment.group_category)
      @student = user_model
      @assignment.group_students(@student).should == [nil, [@student]]
    end

    it "should return [group, [students from group]] if the student is in one of the candidate groups" do
      @assignment = assignment_model(:group_category => "Category")
      @course.enroll_student(@student1 = user_model)
      @course.enroll_student(@student2 = user_model)
      @course.enroll_student(@student3 = user_model)
      @group1 = @course.groups.create(:name => "Group 1", :group_category => @assignment.group_category)
      @group1.add_user(@student1)
      @group1.add_user(@student2)
      @group2 = @course.groups.create(:name => "Group 2", :group_category => @assignment.group_category)
      @group2.add_user(@student3)

      # have to reload because the enrolled students above don't show up in
      # Course#students until the course has been reloaded
      result = @assignment.reload.group_students(@student1)
      result.first.should == @group1
      result.last.map{ |u| u.id }.sort.should == [@student1, @student2].map{ |u| u.id }.sort
    end

    it "returns distinct users" do
      s1, s2 = n_students_in_course(2)

      section = @course.course_sections.create! name: "some section"
      e = @course.enroll_user s1, 'StudentEnrollment',
                              section: section,
                              allow_multiple_enrollments: true
      e.update_attribute :workflow_state, 'active'

      gc = @course.group_categories.create! name: "Homework Groups"
      group = gc.groups.create! name: "Group 1", context: @course
      group.add_user(s1)
      group.add_user(s2)

      a = @course.assignments.create! name: "Group Assignment",
                                      group_category_id: gc.id
      g, students = a.group_students(s1)
      g.should == group
      students.sort_by(&:id).should == [s1, s2]
    end
  end

  it "should maintain the deprecated group_category attribute" do
    assignment = assignment_model
    assignment.read_attribute(:group_category).should be_nil
    assignment.group_category = assignment.context.group_categories.create(:name => "my category")
    assignment.save
    assignment.reload
    assignment.read_attribute(:group_category).should eql("my category")
    assignment.group_category = nil
    assignment.save
    assignment.reload
    assignment.read_attribute(:group_category).should be_nil
  end

  it "should provide has_group_category?" do
    assignment = assignment_model
    assignment.has_group_category?.should be_false
    assignment.group_category = assignment.context.group_categories.create(:name => "my category")
    assignment.has_group_category?.should be_true
    assignment.group_category = nil
    assignment.has_group_category?.should be_false
  end

  context "turnitin settings" do
    it "should sanitize bad data" do
      assignment = assignment_model
      assignment.turnitin_settings = {
        :originality_report_visibility => 'invalid',
        :s_paper_check => '2',
        :internet_check => 1,
        :journal_check => 0,
        :exclude_biblio => true,
        :exclude_quoted => false,
        :exclude_type => '3',
        :exclude_value => 'asdf',
        :bogus => 'haha'
      }
      assignment.turnitin_settings.should eql({
        :originality_report_visibility => 'immediate',
        :s_paper_check => '1',
        :internet_check => '1',
        :journal_check => '0',
        :exclude_biblio => '1',
        :exclude_quoted => '0',
        :exclude_type => '0',
        :exclude_value => '',
        :s_view_report => '1'
      })
    end

    it "should persist :created across changes" do
      assignment = assignment_model
      assignment.turnitin_settings = Turnitin::Client.default_assignment_turnitin_settings
      assignment.save
      assignment.turnitin_settings[:created] = true
      assignment.save
      assignment.reload
      assignment.turnitin_settings[:created].should be_true

      assignment.turnitin_settings = Turnitin::Client.default_assignment_turnitin_settings.merge(:s_paper_check => '0')
      assignment.save
      assignment.reload
      assignment.turnitin_settings[:created].should be_true
    end

    it "should clear out :current" do
      assignment = assignment_model
      assignment.turnitin_settings = Turnitin::Client.default_assignment_turnitin_settings
      assignment.save
      assignment.turnitin_settings[:current] = true
      assignment.save
      assignment.reload
      assignment.turnitin_settings[:current].should be_true

      assignment.turnitin_settings = Turnitin::Client.default_assignment_turnitin_settings.merge(:s_paper_check => '0')
      assignment.save
      assignment.reload
      assignment.turnitin_settings[:current].should be_nil
    end
  end

  context "generate comments from submissions" do
    def create_and_submit
      setup_assignment_without_submission

      @attachment = @user.attachments.new :filename => "homework.doc"
      @attachment.content_type = "foo/bar"
      @attachment.size = 10
      @attachment.save!

      @submission = @assignment.submit_homework @user, :submission_type => :online_upload, :attachments => [@attachment]
    end

    it "should infer_comment_context_from_filename" do
      create_and_submit
      ignore_file = "/tmp/._why_macos_why.txt"
      @assignment.instance_variable_set :@ignored_files, []
      @assignment.send(:infer_comment_context_from_filename, ignore_file).should be_nil
      @assignment.instance_variable_get(:@ignored_files).should == [ignore_file]

      filename = [@user.last_name_first, @user.id, @attachment.id, @attachment.display_name].join("_")

      @assignment.send(:infer_comment_context_from_filename, filename).should == ({
        :user => @user,
        :submission => @submission,
        :filename => filename,
        :display_name => @attachment.display_name
      })
      @assignment.instance_variable_get(:@ignored_files).should == [ignore_file]
    end

    it "should mark comments as hidden for submission zip uploads" do
      course_with_teacher
      student_in_course

      @assignment = @course.assignments.create! name: "Mute Comment Test",
                                                submission_types: %w(online_upload)
      @assignment.update_attribute :muted, true
      submit_homework(@student)

      zip = zip_submissions

      @assignment.generate_comments_from_files(zip.open.path, @user)

      submission = @assignment.submission_for_student(@student)
      submission.submission_comments.last.hidden.should == true
    end
  end

  context "attribute freezing" do
    before do
      course
      @asmnt = @course.assignments.create!(:title => 'lock locky')
      @att_map = {"lock_at" => "yes",
                  "assignment_group" => "no",
                  "title" => "no",
                  "assignment_group_id" => "no",
                  "submission_types" => "yes",
                  "points_possible" => "yes",
                  "description" => "yes",
                  "grading_type" => "yes"}
    end

    def stub_plugin
      PluginSetting.stubs(:settings_for_plugin).returns(@att_map)
    end

    it "should not be frozen if not copied" do
      stub_plugin
      @asmnt.freeze_on_copy = true
      @asmnt.frozen?.should == false
      @att_map.each_key{|att| @asmnt.att_frozen?(att).should == false}
    end

    it "should not be frozen if copied but not frozen set" do
      stub_plugin
      @asmnt.copied = true
      @asmnt.frozen?.should == false
      @att_map.each_key{|att| @asmnt.att_frozen?(att).should == false}
    end

    it "should not be frozen if plugin not enabled" do
      @asmnt.copied = true
      @asmnt.freeze_on_copy = true
      @asmnt.frozen?.should == false
      @att_map.each_key{|att| @asmnt.att_frozen?(att).should == false}
    end

    context "assignments are frozen" do
      append_before (:each) do
        stub_plugin
        @asmnt.copied = true
        @asmnt.freeze_on_copy = true
        @admin = account_admin_user(opts={})
        teacher_in_course(:course => @course)
      end

      it "should be frozen" do
        @asmnt.frozen?.should == true
      end

      it "should flag specific attributes as frozen for no user" do
        @att_map.each_pair do |att, setting|
          @asmnt.att_frozen?(att).should == (setting == "yes")
        end
      end

      it "should flag specific attributes as frozen for teacher" do
        @att_map.each_pair do |att, setting|
          @asmnt.att_frozen?(att, @teacher).should == (setting == "yes")
        end
      end

      it "should not flag attributes as frozen for admin" do
        @att_map.each_pair do |att, setting|
          @asmnt.att_frozen?(att, @admin).should == false
        end
      end

      it "should be frozen for nil user" do
        @asmnt.frozen_for_user?(nil).should == true
      end

      it "should not be frozen for admin" do
        @asmnt.frozen_for_user?(@admin).should == false
      end

      it "should not validate if saving without user" do
        @asmnt.description = "new description"
        @asmnt.save
        @asmnt.valid?.should == false
        @asmnt.errors["description"].should == ["You don't have permission to edit the locked attribute description"]
      end

      it "should allow teacher to edit unlocked attributes" do
        @asmnt.title = "new title"
        @asmnt.updating_user = @teacher
        @asmnt.save!

        @asmnt.reload
        @asmnt.title.should == "new title"
      end

      it "should not allow teacher to edit locked attributes" do
        @asmnt.description = "new description"
        @asmnt.updating_user = @teacher
        @asmnt.save

        @asmnt.valid?.should == false
        @asmnt.errors["description"].should == ["You don't have permission to edit the locked attribute description"]

        @asmnt.reload
        @asmnt.description.should_not == "new title"
      end

      it "should allow admin to edit unlocked attributes" do
        @asmnt.description = "new description"
        @asmnt.updating_user = @admin
        @asmnt.save!

        @asmnt.reload
        @asmnt.description.should == "new description"
      end

    end

  end

  context "not_locked scope" do
    before :each do
      course_with_student_logged_in(:active_all => true)
      assignment_quiz([], :course => @course, :user => @user)
      # Setup default values for tests (leave unsaved for easy changes)
      @quiz.unlock_at = nil
      @quiz.lock_at = nil
      @quiz.due_at = 2.days.from_now
    end
    it "should include assignments with no locks" do
      @quiz.save!
      list = Assignment.not_locked.all
      list.size.should eql 1
      list.first.title.should eql 'Test Assignment'
    end
    it "should include assignments with unlock_at in the past" do
      @quiz.unlock_at = 1.day.ago
      @quiz.save!
      list = Assignment.not_locked.all
      list.size.should eql 1
      list.first.title.should eql 'Test Assignment'
    end
    it "should include assignments where lock_at is future" do
      @quiz.lock_at = 1.day.from_now
      @quiz.save!
      list = Assignment.not_locked.all
      list.size.should eql 1
      list.first.title.should eql 'Test Assignment'
    end
    it "should include assignments where unlock_at is in the past and lock_at is future" do
      @quiz.unlock_at = 1.day.ago
      @quiz.lock_at = 1.day.from_now
      @quiz.save!
      list = Assignment.not_locked.all
      list.size.should eql 1
      list.first.title.should eql 'Test Assignment'
    end
    it "should not include assignments where unlock_at is in future" do
      @quiz.unlock_at = 1.hour.from_now
      @quiz.save!
      Assignment.not_locked.count.should == 0
    end
    it "should not include assignments where lock_at is in past" do
      @quiz.lock_at = 1.hours.ago
      @quiz.save!
      Assignment.not_locked.count.should == 0
    end
  end

  context "due_between_with_overrides" do
    before(:each) do
      course_model
      @assignment = @course.assignments.create!(:title => 'assignment', :due_at => Time.now)
      @overridden_assignment = @course.assignments.create!(:title => 'overridden_assignment', :due_at => Time.now)

      override = @assignment.assignment_overrides.build
      override.due_at = Time.now
      override.title = 'override'
      override.save!

      @results = @course.assignments.due_between_with_overrides(Time.now - 1.day, Time.now + 1.day)
    end

    it 'should return assignments between the given dates' do
      @results.should include(@assignment)
    end

    it 'should return overridden assignments that are due between the given dates' do
      @results.should include(@overridden_assignment)
    end
  end

  context "destroy" do
    it "should destroy the associated discussion topic" do
      group_discussion_assignment
      @assignment.destroy
      @topic.reload.should be_deleted
      @assignment.reload.should be_deleted
    end

    it "should not revive the discussion if touched after destroyed" do
      group_discussion_assignment
      @assignment.destroy
      @topic.reload.should be_deleted
      @assignment.touch
      @topic.reload.should be_deleted
    end
  end

  describe "speed_grader_json" do
    it "should include comments' created_at" do
      setup_assignment_with_homework
      @submission = @assignment.submissions.first
      @comment = @submission.add_comment(:comment => 'comment')
      json = @assignment.speed_grader_json(@user)
      json[:submissions].first[:submission_comments].first[:created_at].to_i.should eql @comment.created_at.to_i
    end

    it "should return submission lateness" do
      # Set up
      course_with_teacher(:active_all => true)
      section_1 = @course.course_sections.create!(:name => 'Section one')
      section_2 = @course.course_sections.create!(:name => 'Section two')

      assignment = @course.assignments.create!(:title => 'Overridden assignment', :due_at => Time.now - 5.days)

      student_1 = user_with_pseudonym(:active_all => true, :username => 'student1@example.com')
      student_2 = user_with_pseudonym(:active_all => true, :username => 'student2@example.com')

      @course.enroll_student(student_1, :section => section_1).accept!
      @course.enroll_student(student_2, :section => section_2).accept!

      o1 = assignment.assignment_overrides.build
      o1.due_at = Time.now - 2.days
      o1.due_at_overridden = true
      o1.set = section_1
      o1.save!

      o2 = assignment.assignment_overrides.build
      o2.due_at = Time.now + 2.days
      o2.due_at_overridden = true
      o2.set = section_2
      o2.save!

      submission_1 = assignment.submit_homework(student_1, :submission_type => 'online_text_entry', :body => 'blah')
      submission_2 = assignment.submit_homework(student_2, :submission_type => 'online_text_entry', :body => 'blah')

      # Test
      json = assignment.speed_grader_json(@teacher)
      json[:submissions].each do |submission|
        user = [student_1, student_2].detect { |s| s.id == submission[:user_id] }
        submission[:late].should == user.submissions.first.late?
      end
    end

    it "should include inline view pingback url for files" do
      course_with_teacher :active_all => true
      student_in_course :active_all => true
      assignment = @course.assignments.create! :submission_types => ['online_upload']
      attachment = @student.attachments.create! :uploaded_data => dummy_io, :filename => 'doc.doc', :display_name => 'doc.doc', :context => @student
      submission = assignment.submit_homework @student, :submission_type => :online_upload, :attachments => [attachment]
      json = assignment.speed_grader_json @teacher
      attachment_json = json['submissions'][0]['submission_history'][0]['submission']['versioned_attachments'][0]['attachment']
      attachment_json['view_inline_ping_url'].should match %r{/users/#{@student.id}/files/#{attachment.id}/inline_view\z}
    end

    context "group assignments" do
      before do
        course_with_teacher active_all: true
        gc = @course.group_categories.create! name: "Assignment Groups"
        @groups = 2.times.map { |i| gc.groups.create! name: "Group #{i}", context: @course }
        students = 4.times.map { student_in_course(active_all: true); @student }
        students.each_with_index { |s, i| @groups[i % @groups.size].add_user(s) }
        @assignment = @course.assignments.create!(
          group_category_id: gc.id,
          grade_group_students_individually: false,
          submission_types: %w(text_entry)
        )
      end

      it "should not be in group mode for non-group assignments" do
        setup_assignment_with_homework
        json = @assignment.speed_grader_json(@teacher)
        json["GROUP_GRADING_MODE"].should_not be_true
      end

      it 'returns "groups" instead of students' do
        json = @assignment.speed_grader_json(@teacher)
        @groups.each do |group|
          j = json["context"]["students"].find { |g| g["name"] == group.name }
          group.users.map(&:id).should include j["id"]
        end
        json["GROUP_GRADING_MODE"].should be_true
      end

      it 'chooses the student with turnitin data to represent' do
        turnitin_submissions = @groups.map do |group|
          rep = group.users.shuffle.first
          turnitin_submission, *others = @assignment.grade_student(rep, grade: 10)
          turnitin_submission.update_attribute :turnitin_data, {blah: 1}
          turnitin_submission
        end

        @assignment.update_attribute :turnitin_enabled, true
        json = @assignment.speed_grader_json(@teacher)

        json["submissions"].map { |s|
          s["id"]
        }.sort.should == turnitin_submissions.map(&:id).sort
      end

      it 'prefers people with submissions' do
        g1, _ = @groups
        @assignment.grade_student(g1.users.first, score: 10)
        g1rep = g1.users.shuffle.first
        s = @assignment.submission_for_student(g1rep)
        s.update_attribute :submission_type, 'online_upload'
        @assignment.representatives(@teacher).should include g1rep
      end
    end

    it "works for quizzes without quiz_submissions" do
      course_with_teacher(:active_all => true)
      student_in_course
      quiz = @course.quizzes.create! :title => "Final",
                                     :quiz_type => "assignment"
      quiz.did_edit
      quiz.offer

      assignment = quiz.assignment
      assignment.grade_student(@student, grade: 1)
      json = assignment.speed_grader_json(@teacher)
      json[:submissions].all? { |s|
        s.has_key? 'submission_history'
      }.should be_true
    end

    it "doesn't include quiz_submissions when there are too many attempts" do
      course_with_teacher :active_all => true
      student_in_course
      quiz_with_graded_submission [], :course => @course, :user => @student
      Setting.set('too_many_quiz_submission_versions', 3)
      3.times {
        @quiz_submission.versions.create!
      }
      json = @quiz.assignment.speed_grader_json(@teacher)
      json[:submissions].all? { |s| s["submission_history"].size.should == 1 }
    end

    it "returns quiz lateness correctly" do
      course_with_teacher(:active_all => true)
      student_in_course
      quiz_with_graded_submission([], { :course => @course, :user => @student })
      @quiz.time_limit = 10
      @quiz.save!

      json = @assignment.speed_grader_json(@teacher)
      json[:submissions].first['submission_history'].first[:submission]['late'].should be_false

      @quiz.due_at = 1.day.ago
      @quiz.save!

      json = @assignment.speed_grader_json(@teacher)
      json[:submissions].first['submission_history'].first[:submission]['late'].should be_true
    end
  end

  describe "update_student_submissions" do
    it "should save a version when changing grades" do
      setup_assignment_without_submission
      s = @assignment.grade_student(@user, :grade => "10").first
      @assignment.points_possible = 5
      @assignment.save!
      s.reload.version_number.should == 2
    end
  end

  describe '#graded_count' do
    before do
      setup_assignment_without_submission
      @assignment.grade_student(@user, :grade => 1)
    end

    it 'counts the submissions that have been graded' do
      @assignment.graded_count.should == 1
    end

    it 'returns the cached value if present' do
      @assignment.write_attribute(:graded_count, 50)
      @assignment.graded_count.should == 50
    end
  end

  describe '#submitted_count' do
    before do
      setup_assignment_without_submission
      @assignment.grade_student(@user, :grade => 1)
      @assignment.submissions.first.update_attribute(:submission_type, 'online_url')
    end

    it 'counts the submissions that have submission types' do
      @assignment.submitted_count.should == 1
    end

    it 'returns the cached value if present' do
      @assignment.write_attribute(:submitted_count, 50)
      @assignment.submitted_count.should == 50
    end
  end

  describe "linking overrides with quizzes" do
    let(:course) { course_model }
    let(:assignment) { assignment_model(:course => course, :due_at => 5.days.from_now).reload }
    let(:override) { assignment_override_model(:assignment => assignment) }
    let(:override_student) { override.assignment_override_students.build }

    before do
      override.override_due_at(7.days.from_now)
      override.save!

      student_in_course(:course => course)
      override_student.user = @student
      override_student.save!
    end

    context "before the assignment has a quiz" do
      context "override" do
        it "has a nil quiz" do
          override.quiz.should be_nil
        end

        it "has an assignment" do
          override.assignment.should == assignment
        end
      end

      context "override student" do
        it "has a nil quiz" do
          override_student.quiz.should be_nil
        end

        it "has an assignment" do
          override_student.assignment.should == assignment
        end
      end
    end

    context "once the assignment changes to a quiz submission" do
      before do
        assignment.submission_types = "online_quiz"
        assignment.save
        assignment.reload
        override.reload
        override_student.reload
      end

      it "has a quiz" do
        assignment.quiz.should be_present
      end

      context "override" do
        it "has an assignment" do
          override.assignment.should == assignment
        end

        it "has the assignment's quiz" do
          override.quiz.should == assignment.quiz
        end
      end

      context "override student" do
        it "has an assignment" do
          override_student.assignment.should == assignment
        end

        it "has the assignment's quiz" do
          override_student.quiz.should == assignment.quiz
        end
      end
    end
  end

  describe "updating cached due dates" do
    before do
      @assignment = assignment_model
      @assignment.due_at = 2.weeks.from_now
      @assignment.save
    end

    it "triggers when assignment is created" do
      new_assignment = @course.assignments.build
      DueDateCacher.expects(:recompute).with(new_assignment)
      new_assignment.save
    end

    it "triggers when due_at changes" do
      DueDateCacher.expects(:recompute).with(@assignment)
      @assignment.due_at = 1.week.from_now
      @assignment.save
    end

    it "triggers when due_at changes to nil" do
      DueDateCacher.expects(:recompute).with(@assignment)
      @assignment.due_at = nil
      @assignment.save
    end

    it "triggers when assignment deleted" do
      DueDateCacher.expects(:recompute).with(@assignment)
      @assignment.destroy
    end

    it "does not trigger when nothing changed" do
      DueDateCacher.expects(:recompute).never
      @assignment.save
    end
  end

  describe "#title_slug" do
    before :each do
      @assignment = assignment_model
    end

    it "should hard truncate at 30 characters" do
      @assignment.title = "a" * 31
      @assignment.title.length.should == 31
      @assignment.title_slug.length.should == 30
      @assignment.title.should =~ /^#{@assignment.title_slug}/
    end

    it "should not change the title" do
      title = "a" * 31
      @assignment.title = title
      @assignment.title_slug.should_not == @assignment.title
      @assignment.title.should == title
    end

    it "should leave short titles alone" do
      @assignment.title = 'short title'
      @assignment.title_slug.should == @assignment.title
    end
  end

  describe "external_tool_tag" do
    it "should update the existing tag when updating the assignment" do
      course
      a = @course.assignments.create!(title: "test",
                                      submission_types: 'external_tool',
                                      external_tool_tag_attributes: {url: "http://example.com/launch"})
      tag = a.external_tool_tag
      tag.should_not be_new_record

      a = Assignment.find(a.id)
      a.attributes = {external_tool_tag_attributes: {url: "http://example.com/launch2"}}
      a.save!
      a.external_tool_tag.url.should == "http://example.com/launch2"
      a.external_tool_tag.should == tag
    end
  end

  describe "allowed_extensions=" do
    it "should accept a string as input" do
      a = Assignment.new
      a.allowed_extensions = "doc,xls,txt"
      a.allowed_extensions.should == ["doc", "xls", "txt"]
    end

    it "should accept an array as input" do
      a = Assignment.new
      a.allowed_extensions = ["doc", "xls", "txt"]
      a.allowed_extensions.should == ["doc", "xls", "txt"]
    end

    it "should sanitize the string" do
      a = Assignment.new
      a.allowed_extensions = ".DOC, .XLS, .TXT"
      a.allowed_extensions.should == ["doc", "xls", "txt"]
    end

    it "should sanitize the array" do
      a = Assignment.new
      a.allowed_extensions = [".DOC", " .XLS", " .TXT"]
      a.allowed_extensions.should == ["doc", "xls", "txt"]
    end
  end

  describe '#generate_comments_from_files' do
    before do
      course_with_teacher
      @students = 3.times.map { student_in_course; @student }

      @assignment = @course.assignments.create! :name => "zip upload test",
                                                :submission_types => %w(online_upload)
    end

    it "should work for individuals" do
      s1 = @students.first
      submit_homework(s1)

      zip = zip_submissions

      comments, ignored = @assignment.generate_comments_from_files(
        zip.open.path,
        @teacher)

      comments.map { |g| g.map { |c| c.submission.user } }.should == [[s1]]
      ignored.should be_empty
    end

    it "should work for groups" do
      s1, s2 = @students

      gc = @course.group_categories.create! name: "Homework Groups"
      @assignment.update_attributes group_category_id: gc.id,
                                    grade_group_students_individually: false
      g1, g2 = 2.times.map { |i| gc.groups.create! name: "Group #{i}", context: @course }
      g1.add_user(s1)
      g1.add_user(s2)

      submit_homework(s1)
      zip = zip_submissions

      comments, _ = @assignment.generate_comments_from_files(
        zip.open.path,
        @teacher)

      comments.map { |g|
        g.map { |c| c.submission.user }.sort_by(&:id)
      }.should == [[s1, s2]]
    end
  end

  describe "restore" do
    it "should restore to unpublished state if draft_state is enabled" do
      course(draft_state: true)
      assignment_model course: @course
      @a.destroy
      @a.restore
      @a.reload.should be_unpublished
    end
  end

  describe '#readable_submission_type' do
    it "should work for on paper assignments" do
      assignment_model(:submission_types => 'on_paper')
      @assignment.readable_submission_types.should == 'on paper'
    end
  end

  describe '#update_grades_if_details_changed' do
    before do
      assignment_model
    end

    it "should update grades if points_possible changes" do
      @assignment.context.expects(:recompute_student_scores).once
      @assignment.points_possible = 3
      @assignment.save!
    end

    it "should update grades if muted changes" do
      @assignment.context.expects(:recompute_student_scores).once
      @assignment.muted = true
      @assignment.save!
    end

    it "should update grades if workflow_state changes" do
      @assignment.context.expects(:recompute_student_scores).once
      @assignment.unpublish
    end

    it "should not update grades otherwise" do
      @assignment.context.expects(:recompute_student_scores).never
      @assignment.title = 'hi'
      @assignment.due_at = 1.hour.ago
      @assignment.description = 'blah'
      @assignment.save!
    end
  end
end

def setup_assignment_with_group
  assignment_model(:group_category => "Study Groups")
  @group = @a.context.groups.create!(:name => "Study Group 1", :group_category => @a.group_category)
  @u1 = @a.context.enroll_user(User.create(:name => "user 1")).user
  @u2 = @a.context.enroll_user(User.create(:name => "user 2")).user
  @u3 = @a.context.enroll_user(User.create(:name => "user 3")).user
  @group.add_user(@u1)
  @group.add_user(@u2)
  @assignment.reload
end

def setup_assignment_without_submission
  # Established course too, as a context
  assignment_model
  user_model
  e = @course.enroll_student(@user)
  e.invite
  e.accept
  @assignment.reload
end

def setup_assignment_with_homework
  setup_assignment_without_submission
  res = @assignment.submit_homework(@user, {:submission_type => 'online_text_entry', :body => 'blah'})
  res.should_not be_nil
  res.should be_is_a(Submission)
  @assignment.reload
end

def setup_assignment_with_students
  @graded_notify = Notification.create!(:name => "Submission Graded")
  @grade_change_notify = Notification.create!(:name => "Submission Grade Changed")
  course_model
  @course.offer!
  @enr1 = @course.enroll_student(@stu1 = user)
  @enr2 = @course.enroll_student(@stu2 = user)
  @assignment = @course.assignments.create(:title => "asdf", :points_possible => 10)
  @sub1 = @assignment.grade_student(@stu1, :grade => 9).first
  @sub1.score.should == 9
  # Took this out until it is asked for
  # @sub1.published_score.should_not == @sub1.score
  @sub1.published_score.should == @sub1.score
  @assignment.reload
  @assignment.submissions.should be_include(@sub1)
end

def setup_assignment
  @u = factory_with_protected_attributes(User, :name => "some user", :workflow_state => "registered")
  @c = course_model(:workflow_state => "available")
  @c.enroll_student(@u)
end

def submit_homework(student)
  a = Attachment.create! context: student,
                         filename: "homework.pdf",
                         uploaded_data: StringIO.new("blah blah blah")
  @assignment.submit_homework(student, attachments: [a],
                                       submission_type: "online_upload")
  a
end

def zip_submissions
  zip = Attachment.new filename: 'submissions.zip'
  zip.user = @teacher
  zip.workflow_state = 'to_be_zipped'
  zip.context = @assignment
  zip.save!
  ContentZipper.process_attachment(zip, @teacher)
  raise "zip failed" if zip.workflow_state != "zipped"
  zip
end

