require File.expand_path(File.dirname(__FILE__) + '/helpers/speed_grader_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')

describe "speed grader" do
  include_context "in-process server selenium tests"

  before (:once) do
    stub_kaltura

    Account.default.allow_feature!(:moderated_grading)
    course(:active_all => true)
    @course.enable_feature!(:moderated_grading)
    outcome_with_rubric
    @assignment = @course.assignments.new(:name => 'assignment with rubric', :points_possible => 10)
    @assignment.moderated_grading = true
    @assignment.save!
    @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
    student_submission
  end

  shared_examples_for "moderated grading" do
    def add_rubric_assessment(score, comment)
      keep_trying_until do
        f('.toggle_full_rubric').click
        expect(f('#rubric_full')).to be_displayed
      end
      f('#rubric_full tr.learning_outcome_criterion .criterion_comments img').click

      f('textarea.criterion_comments').send_keys(comment)
      f('#rubric_criterion_comments_dialog .save_button').click
      f('#rubric_full input.criterion_points').send_keys(score.to_s)
      f('#rubric_full .save_rubric_button').click
      wait_for_ajaximations
    end

    it "should create provisional grades and submission comments" do
      @submission.find_or_create_provisional_grade!(scorer: @user, score: 7)
      @submission.add_comment(commenter: @user, comment: 'wat', provisional: true)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f('#grading-box-extended')).to have_attribute('value', '7')
      expect(f('#discussion span.comment').text).to be_include 'wat'

      replace_content f('#grading-box-extended'), "8"
      driver.execute_script '$("#grading-box-extended").change()'
      wait_for_ajaximations

      f('#speedgrader_comment_textarea').send_keys('srsly')
      f('#add_a_comment button[type="submit"]').click
      wait_for_ajaximations

      @submission.reload
      expect(@submission.score).to be_nil

      pg = @submission.provisional_grade(@user)
      expect(pg.score.to_i).to eql 8
      expect(pg.submission_comments.map(&:comment)).to be_include 'srsly'
    end

    it "should create rubric assessments for the provisional grade" do
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      comment = "some silly comment"
      add_rubric_assessment(3, comment)
      expect(f('#rubric_summary_container')).to include_text(@rubric.title)
      expect(f('#rubric_summary_container')).to include_text(comment)

      ra = @association.rubric_assessments.first
      expect(ra.artifact).to be_a(ModeratedGrading::ProvisionalGrade)
      expect(ra.artifact.score).to eq 3
      expect(ra.data[0][:comments]).to eq comment

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f('#rubric_summary_container')).to include_text(@rubric.title)
      expect(f('#rubric_summary_container')).to include_text(comment)
    end
  end

  context "as a moderator" do
    before do
      course_with_teacher_logged_in(:course => @course, :active_all => true)
      @is_moderator = true
    end

    include_examples "moderated grading"

    it "should be able to see a ta's provisional grade in read-only mode" do
      other_ta = course_with_ta(:course => @course, :active_all => true).user
      @submission.find_or_create_provisional_grade!(scorer: other_ta, score: 7)
      @submission.add_comment(commenter: other_ta, comment: 'wat', provisional: true)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      tab = f('#moderation_tabs li')
      expect(tab).to be_displayed
      expect(tab).to include_text("1st Mark")
      expect(tab).to include_text("7/8")

      expect(f('#moderation_tabs')).to_not include_text("New Mark")

      grade = f('#grading-box-extended')
      expect(grade['disabled']).to be_present
      expect(grade['value']).to eq "7"
      expect(f('#discussion span.comment').text).to be_include 'wat'
      expect(f('#add_a_comment')).to_not be_displayed
    end

    it "should be able to two ta's provisional grades in read-only mode" do
      @assignment.moderated_grading_selections.create!(:student => @student)

      other_ta1 = course_with_ta(:course => @course, :active_all => true).user
      pg1 = @submission.find_or_create_provisional_grade!(scorer: other_ta1, score: 7)
      @submission.add_comment(commenter: other_ta1, comment: 'wat', provisional: true)

      other_ta2 = course_with_ta(:course => @course, :active_all => true).user
      pg2 = @submission.find_or_create_provisional_grade!(scorer: other_ta2, score: 6)
      @submission.add_comment(commenter: other_ta2, comment: 'woo', provisional: true)

      get "/" # when run by itself this test works, but when run in conjunction with the others
      # if we don't navigate to speedgrader from a different page, the anchor won't work locally

      anchor_tag = CGI.escape("{\"student_id\":#{@student.id},\"provisional_grade_id\":#{pg2.id}}")
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}##{anchor_tag}"
      keep_trying_until { f('#speedgrader_iframe') }

      tab = f('#moderation_tabs li.ui-state-active')
      expect(tab).to be_displayed
      expect(tab).to include_text("2nd Mark")
      expect(tab).to include_text("6/8")

      expect(f('#moderation_tabs')).to_not include_text("New Mark")

      grade = f('#grading-box-extended')
      expect(grade['disabled']).to be_present
      expect(grade['value']).to eq "6"
      expect(f('#discussion span.comment').text).to be_include 'woo'
      expect(f('#add_a_comment')).to_not be_displayed

      f('#moderation_tabs li').click # switch to first tab
      wait_for_ajaximations
      tab = f('#moderation_tabs li.ui-state-active')
      expect(tab).to be_displayed
      expect(tab).to include_text("1st Mark")
      expect(tab).to include_text("7/8")

      expect(grade['value']).to eq "7"
      expect(f('#discussion span.comment').text).to be_include 'wat'
      expect(f('#discussion span.comment').text).to_not be_include 'woo'
    end

    it "should allow a second mark to be explicitly created by the moderator when student is selected for moderation" do
      other_ta = course_with_ta(:course => @course, :active_all => true).user
      @submission.find_or_create_provisional_grade!(scorer: other_ta, score: 7)
      @assignment.moderated_grading_selections.create!(:student => @student)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      new_mark_tab = ff('#moderation_tabs li').last
      expect(new_mark_tab).to be_displayed
      expect(new_mark_tab).to include_text("New Mark")
      new_mark_tab.click()
      wait_for_ajaximations

      # should be editable now
      expect(f('#grading-box-extended')['disabled']).to be_nil
      expect(f('#add_a_comment')).to be_displayed

      replace_content f('#grading-box-extended'), "8"
      driver.execute_script '$("#grading-box-extended").change()'

      wait_for_ajax_requests(500)
      f('#speedgrader_comment_textarea').send_keys('srsly')
      f('#add_a_comment button[type="submit"]').click
      wait_for_ajaximations

      @submission.reload
      expect(@submission.score).to be_nil

      pg = @submission.provisional_grade(@teacher)
      expect(pg.score.to_i).to eql 8
      expect(pg.submission_comments.map(&:comment)).to be_include 'srsly'

      tab = f('#moderation_tabs li.ui-state-active')
      expect(tab).to include_text("2nd Mark")
      expect(tab).to include_text("8/8") # should sync tab state

      ff('#moderation_tabs li')[0].click # switch from 1st to 2nd mark - should preserve new comments + grade
      wait_for_ajaximations
      ff('#moderation_tabs li')[1].click

      grade = f('#grading-box-extended')
      expect(grade['disabled']).to be_nil
      expect(grade['value']).to eq "8"
      expect(f('#discussion span.comment').text).to be_include 'srsly'
    end

    it "should work with new rubric assessments on a second mark" do
      other_ta = course_with_ta(:course => @course, :active_all => true).user
      @submission.find_or_create_provisional_grade!(scorer: other_ta, score: 7)
      @assignment.moderated_grading_selections.create!(:student => @student)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      new_mark_tab = ff('#moderation_tabs li').last
      new_mark_tab.click()
      wait_for_ajaximations

      comment = "some silly comment"
      add_rubric_assessment(2, comment)

      ra = @association.rubric_assessments.first
      expect(ra.artifact).to be_a(ModeratedGrading::ProvisionalGrade)
      expect(ra.artifact.score).to eq 2
      expect(ra.data[0][:comments]).to eq comment

      pg = @submission.provisional_grade(@teacher)
      expect(pg.score.to_i).to eql 2

      tab = f('#moderation_tabs li.ui-state-active')
      expect(tab).to include_text("2nd Mark")
      expect(tab).to include_text("2/8") # should sync tab state

      ff('#moderation_tabs li')[0].click # switch from 1st to 2nd mark - should preserve new comments + grade
      wait_for_ajaximations
      expect(f('#rubric_summary_container')).to_not include_text(comment)
      ff('#moderation_tabs li')[1].click
      wait_for_ajaximations

      grade = f('#grading-box-extended')
      expect(grade['disabled']).to be_nil
      expect(grade['value']).to eq "2"
      expect(f('#rubric_summary_container')).to include_text(comment)
    end
  end

  context "as a provisional grader" do
    before do
      course_with_ta_logged_in(:course => @course, :active_all => true)
      @is_moderator = false
    end

    include_examples "moderated grading"

    it "should not lock a provisional grader out if graded by self" do
      pg = @submission.find_or_create_provisional_grade!(scorer: @ta, score: 7)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f('#grading-box-extended')).to be_displayed
      expect(f('#not_gradeable_message')).to_not be_displayed
    end

    it "should lock a provisional grader out if graded by someone else (and not up for moderation)" do
      other_ta = course_with_ta(:course => @course, :active_all => true).user
      @submission.find_or_create_provisional_grade!(scorer: other_ta, score: 7)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f('#grading-box-extended')).to_not be_displayed
      expect(f('#not_gradeable_message')).to be_displayed
    end

    it "should lock a provisional grader out if graded by someone else while switching students" do
      original_sub = @submission
      student_submission

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      keep_trying_until { f('#speedgrader_iframe') }
      # not locked yet
      expect(f('#grading-box-extended')).to be_displayed
      expect(f('#not_gradeable_message')).to_not be_displayed

      # go to next student
      f('#gradebook_header a.next').click
      wait_for_ajaximations

      # create a mark for the first student
      other_ta = course_with_ta(:course => @course, :active_all => true).user
      original_sub.find_or_create_provisional_grade!(scorer: other_ta, score: 7)

      # go back
      f('#gradebook_header a.prev').click
      wait_for_ajaximations

      # should be locked now
      expect(f('#grading-box-extended')).to_not be_displayed
      expect(f('#not_gradeable_message')).to be_displayed
    end

    it "should not lock a provisional grader out if someone else graded but the student is selected for moderation" do
      @assignment.moderated_grading_selections.create!(:student => @student)
      other_ta = course_with_ta(:course => @course, :active_all => true).user
      @submission.find_or_create_provisional_grade!(scorer: other_ta, score: 7)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f('#grading-box-extended')).to be_displayed
      expect(f('#not_gradeable_message')).to_not be_displayed
    end

    it "should lock a provisional grader out the student is selected for moderation but two people have marked it" do
      @assignment.moderated_grading_selections.create!(:student => @student)
      other_ta1 = course_with_ta(:course => @course, :active_all => true).user
      @submission.find_or_create_provisional_grade!(scorer: other_ta1, score: 7)
      other_ta2 = course_with_ta(:course => @course, :active_all => true).user
      @submission.find_or_create_provisional_grade!(scorer: other_ta2, score: 6)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f('#grading-box-extended')).to_not be_displayed
      expect(f('#not_gradeable_message')).to be_displayed
    end
  end
end
