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
    @a.state.should eql(:available)
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
    AssignmentGroup.update_all({ :updated_at => 1.hour.ago }, { :id => group.id })
    orig_time = group.reload.updated_at.to_i
    a = @course.assignments.build(
                                          "title"=>"test",
                                          "external_tool_tag_attributes"=>{"url"=>"", "new_tab"=>""}
                                  )
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

  it "should be able to grade a submission" do
    setup_assignment_without_submission
    s = @assignment.grade_student(@user, :grade => "10")
    s.should be_is_a(Array)
    @assignment.reload
    @assignment.submissions.size.should eql(1)
    @submission = @assignment.submissions.first
    @submission.state.should eql(:graded)
    @submission.should eql(s[0])
    @submission.score.should eql(10.0)
    @submission.user_id.should eql(@user.id)
    @submission.versions.length.should eql(1)
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
      s = Assignment.find_or_create_submission(@assignment.id, @teacher.id)
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
      @user.enrollments.count(:conditions => "workflow_state = 'active'").should eql(3)
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
      @user.enrollments.count(:conditions => "workflow_state = 'active'").should eql(0)

      # enroll the user as a teacher, it should have no effect
      e4 = @course.enroll_teacher(@user)
      e4.accept
      @assignment.reload
      @assignment.needs_grading_count.should eql(0)
      @user.enrollments.count(:conditions => "workflow_state = 'active'").should eql(1)
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

  describe "infer_due_at" do
    it "should set to all_day" do
      assignment_model(:due_at => "Sep 3 2008 12:00am")
      @assignment.all_day.should eql(false)
      @assignment.infer_due_at
      @assignment.save!
      @assignment.all_day.should eql(true)
      @assignment.due_at.strftime("%H:%M").should eql("23:59")
      @assignment.all_day_date.should eql(Date.parse("Sep 3 2008"))
    end

    it "should not set to all_day without infer_due_at call" do
      assignment_model(:due_at => "Sep 3 2008 12:00am")
      @assignment.all_day.should eql(false)
      @assignment.due_at.strftime("%H:%M").should eql("00:00")
      @assignment.all_day_date.should eql(Date.parse("Sep 3 2008"))
    end
  end

  it "should treat 11:59pm as an all_day" do
    assignment_model(:due_at => "Sep 4 2008 11:59pm")
    @assignment.all_day.should eql(true)
    @assignment.due_at.strftime("%H:%M").should eql("23:59")
    @assignment.all_day_date.should eql(Date.parse("Sep 4 2008"))
  end

  it "should not be set to all_day if a time is specified" do
    assignment_model(:due_at => "Sep 4 2008 11:58pm")
    @assignment.all_day.should eql(false)
    @assignment.due_at.strftime("%H:%M").should eql("23:58")
    @assignment.all_day_date.should eql(Date.parse("Sep 4 2008"))
  end

  context "concurrent inserts" do
    def concurrent_inserts
      assignment_model
      user_model
      @course.enroll_student(@user).update_attribute(:workflow_state, 'accepted')
      @assignment.context.reload

      dummy_sub = Submission.new
      dummy_sub.assignment_id = @assignment.id
      dummy_sub.user_id = @user.id

      real_sub = Submission.new
      real_sub.assignment_id = @assignment.id
      real_sub.user_id = @user.id
      real_sub.save!

      Submission.expects(:find_or_initialize_by_assignment_id_and_user_id).
        twice.
        returns(dummy_sub).
        returns(real_sub)

      sub = nil
      lambda {
        sub = yield(@assignment, @user)
      }.should_not raise_error
      sub.should_not be_new_record
      sub.should_not eql dummy_sub
      sub.should eql real_sub
    end

    it "should handle them gracefully in find_or_create_submission" do
      concurrent_inserts do |assignment, user|
        Assignment.find_or_create_submission(assignment.id, user.id)
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

  context "publishing" do
    it "should publish automatically if set that way" do
      course_model(:publish_grades_immediately => true)
      @course.offer!
      @enr1 = @course.enroll_student(@stu1 = user)
      @enr2 = @course.enroll_student(@stu2 = user)
      @assignment = @course.assignments.create(:title => "asdf", :points_possible => 10)
      @assignment.should be_published
      @sub1 = @assignment.grade_student(@stu1, :grade => 9).first
      @sub1.score.should == 9.0
      @sub1.published_score.should == @sub1.score
    end

    it "should NOT publish automatically if set that way" do
      course_model(:publish_grades_immediately => false)
      @course.offer!
      @enr1 = @course.enroll_student(@stu1 = user)
      @enr2 = @course.enroll_student(@stu2 = user)
      @assignment = @course.assignments.create(:title => "asdf", :points_possible => 10)
      @assignment.should_not be_published
      @sub1 = @assignment.grade_student(@stu1, :grade => 9).first
      @sub1.score.to_f.should == 9.0
      @sub1.published_score.should == @sub1.score
      # Took this out until someone asks for it
      # @sub1.published_score.should_not == @sub1.score
    end

    it "should publish past submissions when the assignment is published" do
      course_model(:publish_grades_immediately => false)
      @course.offer!
      @enr1 = @course.enroll_student(@stu1 = user)
      @enr2 = @course.enroll_student(@stu2 = user)
      @assignment = @course.assignments.create(:title => "asdf", :points_possible => 10)
      @assignment.should_not be_published
      @sub1 = @assignment.grade_student(@stu1, :grade => 9).first
      @sub1.score.should == 9
      # Took this out until someone asks for it
      # @sub1.published_score.should_not == @sub1.score
      @sub1.published_score.should == @sub1.score
      @assignment.reload
      @assignment.submissions.should be_include(@sub1)
      @assignment.publish!
      @assignment.should be_published
      @sub1.reload
      @sub1.score.should == 9
      @sub1.published_score.should == @sub1.score
    end

    it "should re-publish correctly" do
      course_model(:publish_grades_immediately => false)
      @course.offer!
      @enr1 = @course.enroll_student(@stu1 = user)
      @enr2 = @course.enroll_student(@stu2 = user)
      @assignment = @course.assignments.create(:title => "asdf", :points_possible => 10)
      @assignment.should_not be_published
      @sub1 = @assignment.grade_student(@stu1, :grade => 9).first
      @sub1.score.should == 9
      @sub1.published_score.should == @sub1.score
      # Took this out until someone asks for it
      # @sub1.published_score.should_not == @sub1.score
      @assignment.reload
      @assignment.submissions.should be_include(@sub1)
      @assignment.publish!
      @assignment.should be_published
      @sub1.reload
      @sub1.score.should == 9
      @sub1.published_score.should == @sub1.score
      @assignment.unpublish!
      @assignment.should_not be_published
      @sub1 = @assignment.grade_student(@stu1, :grade => 8).first
      @sub1.score.should == 8
      @sub1.published_score.should == 8
      # Took this out until someone asks for it
      # @sub1.published_score.should == 9
      @sub2 = @assignment.grade_student(@stu2, :grade => 7).first
      @sub2.score.should == 7
      # Took this out until someone asks for it
      # @sub2.published_score.should == nil
      @sub2.published_score.should == 7
      @assignment.reload
      @assignment.submissions.should be_include(@sub2)
      @assignment.publish!
      @assignment.should be_published
      @sub1.reload
      @sub1.score.should == 8
      @sub1.published_score == 8
      @sub2.reload
      @sub2.score.should == 7
      @sub2.published_score.should == 7
    end

    it "should fire off assignment graded notification on first publish" do
      setup_unpublished_assignment_with_students
      @assignment.publish!
      @assignment.should be_published
      @assignment.messages_sent.should be_include("Assignment Graded")
      @sub1.messages_sent.should be_empty
    end

    it "should not fire off assignment graded notification on first publish if muted" do
      setup_unpublished_assignment_with_students
      @assignment.mute!
      @assignment.publish!
      @assignment.should be_muted
      @assignment.messages_sent.should_not be_include("Assignment Graded")
    end

    it "should fire off submission graded notifications if already published" do
      setup_unpublished_assignment_with_students
      @assignment.publish!
      @assignment.should be_published
      @sub2 = @assignment.grade_student(@stu2, :grade => 8).first
      @sub2.messages_sent.should be_include("Submission Graded")
      @sub2.messages_sent.should_not be_include("Submission Grade Changed")
      @sub2.update_attributes(:graded_at => Time.now - 60*60)
      @sub2 = @assignment.grade_student(@stu2, :grade => 9).first
      @sub2.messages_sent.should_not be_include("Submission Graded")
      @sub2.messages_sent.should be_include("Submission Grade Changed")
    end

    it "should not fire off submission graded notifications if already published but muted" do
      setup_unpublished_assignment_with_students
      @assignment.publish!
      @assignment.mute!
      @sub2 = @assignment.grade_student(@stu2, :grade => 8).first
      @sub2.messages_sent.should_not be_include("Submission Graded")
      @sub2.update_attributes(:graded_at => Time.now - 60*60)
      @sub2 = @assignment.grade_student(@stu2, :grade => 9).first
      @sub2.messages_sent.should_not be_include("Submission Grade Changed")
    end

    it "should not fire off assignment graded notification if started as published" do
      setup_assignment
      Notification.create!(:name => "Assignment Graded")
      @assignment2 = @course.assignments.create(:title => "new assignment")
      @assignment2.workflow_state = 'published'
      @assignment2.messages_sent.should_not be_include("Assignment Graded")
    end

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
      run_transaction_commit_callbacks
      @enrollment.reload.computed_current_score.should == 76

      @assignment.points_possible = 30
      @assignment.save!
      @sub.reload
      @sub.score.should eql(15.2)
      @sub.grade.should eql('F')
      run_transaction_commit_callbacks
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

    it "should not fire off assignment graded notification on second publish" do
      setup_unpublished_assignment_with_students
      @assignment.publish!
      @assignment.should be_published
      @assignment.messages_sent.should be_include("Assignment Graded")
      @assignment.clear_broadcast_messages
      @assignment.messages_sent.should be_empty
      @assignment.unpublish!
      @assignment.should be_available
      @assignment.messages_sent.should_not be_include("Assignment Graded")
      @assignment.publish!
      @assignment.should be_published
      @assignment.messages_sent.should_not be_include("Assignment Graded")
    end

    it "should not fire off submission graded notifications while unpublished" do
      setup_unpublished_assignment_with_students
      @assignment.publish!
      @assignment.should be_published
      @assignment.unpublish!
      @assignment.should be_available
      @sub2 = @assignment.grade_student(@stu2, :grade => 8).first
      @sub2.messages_sent.should be_empty
      @sub2.update_attributes(:graded_at => Time.now - 60*60)
      @sub2 = @assignment.grade_student(@stu2, :grade => 9).first
      @sub2.messages_sent.should be_empty
    end

    it" should fire off submission graded notifications on second publish" do
      setup_unpublished_assignment_with_students
      @assignment.publish!
      @assignment.should be_published
      @assignment.clear_broadcast_messages
      @assignment.unpublish!
      @assignment.should be_available
      @assignment.messages_sent.should be_empty
      @sub2 = @assignment.grade_student(@stu2, :grade => 8).first
      @sub2.messages_sent.should be_empty
      @sub2.update_attributes(:graded_at => Time.now - 60*60)
      @assignment.reload
      @assignment.publish!
      @assignment.should be_published
      @assignment.messages_sent.should_not be_include("Assignment Graded")
      @assignment.updated_submissions.should_not be_nil
      @assignment.updated_submissions.should_not be_empty
      @assignment.updated_submissions.sort_by(&:id).first.messages_sent.should be_empty
      @assignment.updated_submissions.sort_by(&:id).last.messages_sent.should be_include("Submission Grade Changed")
    end
  end

  context "to_json" do
    it "should include permissions if specified" do
      assignment_model
      @course.offer!
      @enr1 = @course.enroll_teacher(@teacher = user)
      @enr1.accept
      @assignment.to_json.should_not match(/permissions/)
      @assignment.to_json(:permissions => {:user => nil}).should match(/\"permissions\"\s*:\s*\{\}/)
      @assignment.grants_right?(@teacher, nil, :create).should eql(true)
      @assignment.to_json(:permissions => {:user => @teacher, :session => nil}).should match(/\"permissions\"\s*:\s*\{\"/)
      hash = ActiveSupport::JSON.decode(@assignment.to_json(:permissions => {:user => @teacher, :session => nil}))
      hash["assignment"].should_not be_nil
      hash["assignment"]["permissions"].should_not be_nil
      hash["assignment"]["permissions"].should_not be_empty
      hash["assignment"]["permissions"]["read"].should eql(true)
    end

    it "should serialize with roots included in nested elements" do
      course_model
      @course.assignments.create!(:title => "some assignment")
      hash = ActiveSupport::JSON.decode(@course.to_json(:include => :assignments))
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
      hash = ActiveSupport::JSON.decode(@course.to_json(:permissions => {:user => @teacher, :session => nil} ))
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
      hash = ActiveSupport::JSON.decode(@course.to_json(:include_root => false, :permissions => {:user => @teacher, :session => nil} ))
      hash["course"].should be_nil
      hash["name"].should eql(@course.name)
      hash["permissions"].should_not be_nil
      hash["permissions"].should_not be_empty
      hash["permissions"]["read"].should eql(true)
    end

    it "should include group_category" do
      assignment_model(:group_category => "Something")
      hash = ActiveSupport::JSON.decode(@assignment.to_json)
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
      ev.description.should == "This assignment is due December 16th. Plz discuss the reading.\n  \n\n\n Test."
      ev.x_alt_desc.should == html.strip
    end

    it ".to_ics should run the description through api_user_content to translate links" do
      html = %{<a href="/calendar">Click!</a>}
      assignment_model(:due_at => "Sep 3 2008 12:00am", :description => html)
      ev = @assignment.to_ics(false)
      ev.description.should == "[Click!](http://localhost/calendar)"
      ev.x_alt_desc.should == %{<a href="http://localhost/calendar">Click!</a>}
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
      @quiz = Quiz.find(@quiz.id)
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
      @quiz = Quiz.find(@quiz.id)
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

    it "should create a discussion_topic if none exists and specified" do
      assignment_model(:submission_types => "discussion_topic")
      @a.submission_types.should eql('discussion_topic')
      @a.discussion_topic.should_not be_nil
      @a.discussion_topic.assignment_id.should eql(@a.id)
      @a.due_at = Time.now
      @a.save
      @a.reload
      @a.discussion_topic.should_not be_nil
      @a.discussion_topic.assignment_id.should eql(@a.id)
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

    it "should clear the lock_at date when converted to a graded topic" do
      assignment_model
      @a.lock_at = 10.days.from_now
      @a.submission_types = "discussion_topic"
      @a.save!
      @a.lock_at.should be_nil
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
      it "should notify students when their grade is changed" do
        setup_unpublished_assignment_with_students
        @assignment.publish!
        @assignment.should be_published
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

      it "should not notify students when their grade is changed if muted" do
        setup_unpublished_assignment_with_students
        @assignment.publish!
        @assignment.mute!
        @assignment.should be_muted
        @sub2 = @assignment.grade_student(@stu2, :grade => 8).first
        @sub2.update_attributes(:graded_at => Time.now - 60*60)
        @sub2 = @assignment.grade_student(@stu2, :grade => 9).first
        @sub2.messages_sent.should be_empty
      end

      it "should not notify students of grade changes if unpublished" do
        setup_unpublished_assignment_with_students
        @assignment.publish!
        @assignment.should be_published
        @assignment.unpublish!
        @assignment.should be_available
        @sub2 = @assignment.grade_student(@stu2, :grade => 8).first
        @sub2.messages_sent.should be_empty
        @sub2.update_attributes(:graded_at => Time.now - 60*60)
        @sub2 = @assignment.grade_student(@stu2, :grade => 9).first
        @sub2.messages_sent.should be_empty
      end

      it "should notify affected students on a mass-grade change" do
        setup_unpublished_assignment_with_students
        @assignment.publish!
        @assignment.set_default_grade(:default_grade => 10)
        @assignment.messages_sent.should_not be_nil
        @assignment.messages_sent['Assignment Graded'].should_not be_nil
      end

      it "should not notify affected students on a mass-grade change if muted" do
        setup_unpublished_assignment_with_students
        @assignment.publish!
        @assignment.mute!
        @assignment.set_default_grade(:default_grade => 10)
        @assignment.messages_sent.should be_empty
      end

      it "should notify affected students of a grade change when the assignment is republished" do
        setup_unpublished_assignment_with_students
        @assignment.publish!
        @assignment.should be_published
        @assignment.unpublish!
        @assignment.should be_available
        @sub2 = @assignment.grade_student(@stu2, :grade => 8).first
        @sub2.messages_sent.should be_empty
        @sub2.update_attributes(:graded_at => Time.now - 60*60)
        @assignment.reload
        @assignment.publish!
        @subs = @assignment.updated_submissions
        @subs.should_not be_nil
        @subs.should_not be_empty
        @sub = @subs.detect{|s| s.user_id == @stu2.id }
        @sub.messages_sent.should_not be_nil
        @sub.messages_sent['Submission Grade Changed'].should_not be_nil
        @sub = @subs.detect{|s| s.user_id != @stu2.id }
        @sub.messages_sent.should_not be_nil
        @sub.messages_sent['Submission Grade Changed'].should be_nil
      end

      it "should not notify unaffected students of a grade change when the assignment is republished" do
        setup_unpublished_assignment_with_students
        @assignment.publish!
        @assignment.should be_published
        @assignment.unpublish!
        @assignment.should be_available
        @assignment.publish!
        @subs = @assignment.updated_submissions
        @subs.should_not be_nil
        @sub = @subs.first
        @sub.messages_sent.should_not be_nil
        @sub.messages_sent['Submission Grade Changed'].should be_nil
      end

      it "should include re-submitted submissions in the list of submissions needing grading" do
        setup_unpublished_assignment_with_students
        @enr1.accept!
        @assignment.publish!
        @assignment.should be_published
        @assignment.submissions.size.should == 1
        Assignment.need_grading_info(15, []).find_by_id(@assignment.id).should be_nil
        @assignment.submit_homework(@stu1, :body => "Changed my mind!")
        @sub1.reload
        @sub1.body.should == "Changed my mind!"
        Assignment.need_grading_info(15, []).find_by_id(@assignment.id).should_not be_nil
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

      # it "should NOT create a message when the content changes to an empty string" do
        # Notification.create(:name => 'Assignment Changed')
        # assignment_model(:name => 'Assignment with unstable due date')
        # @a.context.offer!
        # @a.description = ""
        # @a.created_at = Date.new
        # @a.save!
        # @a.messages_sent.should_not be_include('Assignment Changed')
      # end
    end

    context "assignment created" do
      # it "should create a message when an assigment is added to a course in process" do
      #   Notification.create(:name => 'Assignment Created')
      #   @course = Course.create
      #   @course.offer
      #   assignment_model(:context => @course)
      #   require 'rubygems'
      #   require 'ruby-debug'
      #   debugger
      #   @a.messages_sent.should be_include('Assignment Created')
      # end
    end

    context "assignment graded" do
      it "should create a message when an assignment is published" do
        setup_assignment
        Notification.create(:name => 'Assignment Graded')
        @user = User.create
        assignment_model
        @a.unpublish!
        @a.context.offer!
        @c.enroll_student(@user)
#        @students = [@user]
#        @a.stubs(:participants).returns(@students)
#        @a.participants.should be_include(@user)
        @a.previously_published = false
        @a.save
        @a.publish!
        @a.messages_sent.should be_include('Assignment Graded')
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
    end
    it "return the single submission if the user is not in a group" do
      setup_assignment_with_group
      res = @a.grade_student(@u3, :comment => "woot", :group_comment => "1")
      res.should_not be_nil
      res.should_not be_empty
      res.length.should eql(1)
      res.find{|s| s.user == @u3}.submission_comments.should_not be_empty
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
      data = ActiveSupport::JSON.decode(@assignment.to_json(:permissions => {:user => @user, :session => nil})) rescue nil
      data.should_not be_nil
      data['assignment'].should_not be_nil
      data['assignment']['permissions'].should_not be_nil
      data['assignment']['permissions'].should_not be_empty
    end
  end

  context "assignment reminders" do
    it "should generate reminders" do
      course_with_student
      d = Time.now
      @assignment = @course.assignments.create!(:title => "some assignment", :due_at => d + 1.week, :submission_types => "online_url")
      @assignment.generate_reminders!
      @assignment.assignment_reminders.should_not be_nil
      @assignment.assignment_reminders.length.should eql(1)
      @assignment.assignment_reminders[0].user_id.should eql(@user.id)
      @assignment.assignment_reminders[0].remind_at.should eql(@assignment.due_at - @user.reminder_time_for_due_dates)
    end
  end

  context "clone_for" do
    it "should clone for another course" do
      course_with_teacher
      @assignment = @course.assignments.create!(:title => "some assignment")
      @assignment.update_attribute(:needs_grading_count, 5)
      course
      @new_assignment = @assignment.clone_for(@course)
      @new_assignment.context.should_not eql(@assignment.context)
      @new_assignment.title.should eql(@assignment.title)
      @new_assignment.needs_grading_count.should == 0
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
        :internet_check => '2',
        :journal_check => '2',
        :exclude_biblio => '2',
        :exclude_quoted => '2',
        :exclude_type => '3',
        :exclude_value => 'asdf',
        :bogus => 'haha'
      }
      assignment.turnitin_settings.should eql({
        :originality_report_visibility => 'immediate',
        :s_paper_check => '0',
        :internet_check => '0',
        :journal_check => '0',
        :exclude_biblio => '0',
        :exclude_quoted => '0',
        :exclude_type => '0',
        :exclude_value => ''
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
    it "should infer_comment_context_from_filename" do
      setup_assignment_without_submission

      attachment = @user.attachments.new :filename => "homework.doc"
      attachment.content_type = "foo/bar"
      attachment.size = 10
      attachment.save!

      submission = @assignment.submit_homework @user, :submission_type => :online_upload, :attachments => [attachment]

      ignore_file = "/tmp/._why_macos_why.txt"
      @assignment.instance_variable_set :@ignored_files, []
      @assignment.send(:infer_comment_context_from_filename, ignore_file).should be_nil
      @assignment.instance_variable_get(:@ignored_files).should == [ignore_file]

      filename = [@user.last_name_first, @user.id, attachment.id, attachment.display_name].join("_")

      @assignment.send(:infer_comment_context_from_filename, filename).should == ({
        :user => @user,
        :submission => submission,
        :filename => filename,
        :display_name => attachment.display_name
      })
      @assignment.instance_variable_get(:@ignored_files).should == [ignore_file]
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

      it "should be frozen for teacher" do
        @asmnt.frozen_for_user?(@teacher).should == true
      end

      it "should not be frozen for admin" do
        @asmnt.frozen_for_user?(@admin).should == false
      end

      it "should not validate if saving without user" do
        @asmnt.description = "new description"
        @asmnt.save
        @asmnt.valid?.should == false
        @asmnt.errors["description"].should == "You don't have permission to edit the locked attribute description"
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
        @asmnt.errors["description"].should == "You don't have permission to edit the locked attribute description"

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

  context "not_locked named_scope" do
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

def setup_unpublished_assignment_with_students
  Notification.create!(:name => "Assignment Graded")
  Notification.create!(:name => "Submission Graded")
  Notification.create!(:name => "Submission Grade Changed")
  course_model(:publish_grades_immediately => false)
  @course.offer!
  @enr1 = @course.enroll_student(@stu1 = user)
  @enr2 = @course.enroll_student(@stu2 = user)
  @assignment = @course.assignments.create(:title => "asdf", :points_possible => 10)
  @assignment.should_not be_published
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
