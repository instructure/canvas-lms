require_relative '../../helpers/speed_grader_common'
require_relative '../../helpers/gradebook2_common'

describe "speed grader" do
  include_context "in-process server selenium tests"
  include Gradebook2Common
  include SpeedGraderCommon

  before(:once) do
    stub_kaltura

    course(:active_all => true)
    outcome_with_rubric
    @assignment = @course.assignments.new(:name => 'assignment with rubric', :points_possible => 10)
    @assignment.moderated_grading = true
    @assignment.save!
    @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
    student_submission
  end

  shared_examples_for "moderated grading" do
    def add_rubric_assessment(score, comment)
      scroll_into_view('.toggle_full_rubric')
      f('.toggle_full_rubric').click
      expect(f('#rubric_full')).to be_displayed
      expand_right_pane
      f('#rubric_full tr.learning_outcome_criterion .criterion_comments img').click

      f('textarea.criterion_comments').send_keys(comment)
      f('#rubric_criterion_comments_dialog .save_button').click
      f('#rubric_full input.criterion_points').send_keys(score.to_s)
      scroll_into_view('.save_rubric_button')
      f('#rubric_full .save_rubric_button').click
      wait_for_ajaximations
    end

    it "should create provisional grades and submission comments" do
      @submission.find_or_create_provisional_grade!(@user, score: 7)
      @submission.add_comment(commenter: @user, comment: 'wat', provisional: true)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f('#grading-box-extended')).to have_attribute('value', '7')
      expect(f('#discussion span.comment').text).to be_include 'wat'

      time = 5.minutes.from_now
      Timecop.freeze(time) do
        replace_content f('#grading-box-extended'), "8", tab_out: true
        wait_for_ajaximations
      end
      @submission.reload
      expect(@submission.updated_at.to_i).to eq time.to_i # should get touched

      time2 = 10.minutes.from_now
      Timecop.freeze(time2) do
        submit_comment "srsly"
      end
      @submission.reload
      expect(@submission.updated_at.to_i).to eq time2.to_i

      @submission.reload
      expect(@submission.score).to be_nil

      pg = @submission.provisional_grade(@user)
      expect(pg.score.to_i).to eql 8
      expect(pg.submission_comments.map(&:comment)).to be_include 'srsly'
    end

    it "should create rubric assessments for the provisional grade" do
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      comment = "some silly comment"
      time = 5.minutes.from_now
      Timecop.freeze(time) do
        add_rubric_assessment(3, comment)
        expect(f('#rubric_summary_container')).to include_text(@rubric.title)
        expect(f('#rubric_summary_container')).to include_text(comment)
      end

      @submission.reload
      expect(@submission.updated_at.to_i).to eq time.to_i # should get touched

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
      @moderator = @teacher
      @is_moderator = true
    end

    include_examples "moderated grading"

    it "should be able to see a ta's provisional grade in read-only mode" do
      other_ta = course_with_ta(:course => @course, :active_all => true).user
      @submission.find_or_create_provisional_grade!(other_ta, score: 7)
      @submission.add_comment(commenter: other_ta, comment: 'wat', provisional: true)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      tab = f('#moderation_tabs li')
      expect(tab).to be_displayed
      expect(tab).to include_text("1st Reviewer")
      expect(tab).to include_text("7/8")

      expect(f('#moderation_tabs')).to_not include_text("Add Review")

      grade = f('#grading-box-extended')
      expect(grade['readonly']).to be_present
      expect(grade['value']).to eq "7"
      expect(f('#discussion span.comment').text).to be_include 'wat'
      expect(f('#add_a_comment')).to_not be_displayed
    end

    it "should be able to two ta's provisional grades in read-only mode" do
      @assignment.moderated_grading_selections.create!(:student => @student)

      other_ta1 = course_with_ta(:course => @course, :active_all => true).user
      @submission.find_or_create_provisional_grade!(other_ta1, score: 7)
      @submission.add_comment(commenter: other_ta1, comment: 'wat', provisional: true)

      other_ta2 = course_with_ta(:course => @course, :active_all => true).user
      pg2 = @submission.find_or_create_provisional_grade!(other_ta2, score: 6)
      @submission.add_comment(commenter: other_ta2, comment: 'woo', provisional: true)

      get "/" # when run by itself this test works, but when run in conjunction with the others
      # if we don't navigate to speedgrader from a different page, the anchor won't work locally

      anchor_tag = CGI.escape("{\"student_id\":#{@student.id},\"provisional_grade_id\":#{pg2.id}}")
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}##{anchor_tag}"
      f('#speedgrader_iframe')

      tab = f('#moderation_tabs li.ui-state-active')
      expect(tab).to be_displayed
      expect(tab).to include_text("2nd Reviewer")
      expect(tab).to include_text("6/8")

      #open dropdown, make sure that the "Create 2nd Mark" link is not shown
      f('#moderation_bar #new_mark_dropdown_link').click
      wait_for_ajaximations
      expect(f('#new_mark_link')).to_not be_displayed

      grade = f('#grading-box-extended')
      expect(grade['readonly']).to be_present
      expect(grade['value']).to eq "6"
      expect(f('#discussion span.comment').text).to be_include 'woo'
      expect(f('#add_a_comment')).to_not be_displayed

      f('#moderation_tabs li').click # switch to first tab
      wait_for_ajaximations
      tab = f('#moderation_tabs li.ui-state-active')
      expect(tab).to be_displayed
      expect(tab).to include_text("1st Reviewer")
      expect(tab).to include_text("7/8")

      expect(grade['value']).to eq "7"
      expect(f('#discussion span.comment').text).to be_include 'wat'
      expect(f('#discussion span.comment').text).to_not be_include 'woo'
    end

    it "should allow a second mark to be explicitly created by the moderator when student is selected for moderation" do
      other_ta = course_with_ta(:course => @course, :active_all => true).user
      @submission.find_or_create_provisional_grade!(other_ta, score: 7)
      @assignment.moderated_grading_selections.create!(:student => @student)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f("#students_selectmenu-button")).to have_class("not_graded")

      new_mark_dd = f('#moderation_bar #new_mark_dropdown_link')
      expect(new_mark_dd).to include_text("Add Review")
      new_mark_dd.click
      wait_for_ajaximations

      new_mark_link = f('#new_mark_link')
      expect(new_mark_link).to be_displayed
      expect(new_mark_link).to include_text("Add 2nd Review")
      new_mark_link.click

      wait_for_ajaximations

      # should be editable now
      expect(f('#grading-box-extended')['disabled']).to be_nil
      expect(f('#add_a_comment')).to be_displayed

      replace_content f('#grading-box-extended'), "8", tab_out: true

      submit_comment "srsly"

      @submission.reload
      expect(@submission.score).to be_nil

      pg = @submission.provisional_grade(@teacher)
      expect(pg.score.to_i).to eql 8
      expect(pg.submission_comments.map(&:comment)).to be_include 'srsly'

      tab = f('#moderation_tabs li.ui-state-active')
      expect(tab).to include_text("2nd Reviewer")
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
      @submission.find_or_create_provisional_grade!(other_ta, score: 7)
      @assignment.moderated_grading_selections.create!(:student => @student)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      f('#moderation_bar #new_mark_dropdown_link').click
      wait_for_ajaximations
      f('#new_mark_link').click
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
      expect(tab).to include_text("2nd Reviewer")
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

    it "should be able to see and edit a final mark given by another teacher" do
      other_ta = course_with_ta(:course => @course, :active_all => true).user
      @submission.find_or_create_provisional_grade!(other_ta, score: 7)
      @assignment.moderated_grading_selections.create!(:student => @student)

      other_teacher = course_with_teacher(:course => @course, :active_all => true).user
      final_pg = @submission.find_or_create_provisional_grade!(other_teacher, score: 3, final: true)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      tabs = ff('#moderation_tabs > ul > li')
      expect(tabs[1]).to_not be_displayed # no second mark
      expect(tabs[1]).to have_class 'ui-state-disabled'
      final_tab = tabs[2]
      expect(final_tab).to be_displayed
      expect(final_tab).to include_text("Moderator")
      expect(final_tab).to include_text("3/8")
      final_tab.click
      wait_for_ajaximations

      grade = f('#grading-box-extended')
      expect(grade['disabled']).to be_nil
      expect(grade['value']).to eq "3"
      replace_content grade, "8", tab_out: true

      submit_comment "srsly"

      @submission.reload
      expect(@submission.score).to be_nil

      # shouldn't have created a prov grade for teacher
      expect(@submission.provisional_grade(@moderator)).to be_a(ModeratedGrading::NullProvisionalGrade)

      final_pg.reload
      expect(final_pg.score.to_i).to eql 8
      expect(final_pg.submission_comments.map(&:comment)).to be_include 'srsly'
      wait_for_ajax_requests(150)
      expect(final_tab).to include_text("8/8") # should sync tab state
    end

    it "should be able to add a rubric assessment to a final mark given by another teacher" do
      other_ta = course_with_ta(:course => @course, :active_all => true).user
      @submission.find_or_create_provisional_grade!(other_ta, score: 7)
      @assignment.moderated_grading_selections.create!(:student => @student)

      other_teacher = course_with_teacher(:course => @course, :active_all => true).user
      final_pg = @submission.find_or_create_provisional_grade!(other_teacher, score: 2, final: true)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      tabs = ff('#moderation_tabs > ul > li')
      final_tab = tabs[2]
      final_tab.click
      wait_for_ajaximations

      comment = "some silly comment"
      add_rubric_assessment(3, comment)

      @submission.reload
      expect(@submission.score).to be_nil

      # shouldn't have created a prov grade for teacher
      expect(@submission.provisional_grade(@moderator)).to be_a(ModeratedGrading::NullProvisionalGrade)

      final_pg.reload
      expect(final_pg.score.to_i).to eql 3
      expect(final_tab).to include_text("3/8") # should sync tab state

      ra = @association.rubric_assessments.first
      expect(ra.artifact).to eq final_pg
      expect(ra.data[0][:comments]).to eq comment
    end

    it "should be able to create a new final mark" do
      other_ta = course_with_ta(:course => @course, :active_all => true).user
      @submission.find_or_create_provisional_grade!(other_ta, score: 7)
      @assignment.moderated_grading_selections.create!(:student => @student)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      f('#moderation_bar #new_mark_dropdown_link').click
      wait_for_ajaximations
      new_mark_final = f('#new_mark_final_link')
      expect(new_mark_final).to be_displayed
      new_mark_final.click
      wait_for_ajaximations

      comment = "some silly comment"
      add_rubric_assessment(3, comment)

      @submission.reload
      expect(@submission.score).to be_nil

      # shouldn't have created a prov grade for teacher
      expect(@submission.provisional_grade(@moderator)).to be_a(ModeratedGrading::NullProvisionalGrade)

      final_pg = @submission.find_or_create_provisional_grade!(@moderator, final: true)
      expect(final_pg.score.to_i).to eql 3
      expect(ff('#moderation_tabs > ul > li')[2]).to include_text("3/8") # should sync tab state

      ra = @association.rubric_assessments.first
      expect(ra.artifact).to eq final_pg
      expect(ra.data[0][:comments]).to eq comment
    end

    it "should be able to copy a 1st mark to the final mark" do
      other_ta = course_with_ta(:course => @course, :active_all => true).user
      @submission.find_or_create_provisional_grade!(other_ta, score: 7)
      @assignment.moderated_grading_selections.create!(:student => @student)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      f('#moderation_bar #new_mark_dropdown_link').click
      wait_for_ajaximations
      expect(f('#new_mark_copy_link2')).to_not be_displayed # since there is no 2nd mark to copy yet
      copy_link = f('#new_mark_copy_link1')
      expect(copy_link).to be_displayed
      copy_link.click
      wait_for_ajaximations

      @submission.reload
      expect(@submission.score).to be_nil
      expect(@submission.provisional_grade(@moderator)).to be_a(ModeratedGrading::NullProvisionalGrade)

      final_pg = @submission.find_or_create_provisional_grade!(@moderator, final: true)
      expect(final_pg.score.to_i).to eql 7
      expect(ff('#moderation_tabs > ul > li')[2]).to include_text("7/8")
    end

    it "should be able to copy a 2nd mark to the final mark" do
      other_ta = course_with_ta(:course => @course, :active_all => true).user
      @submission.find_or_create_provisional_grade!(other_ta, score: 7)
      @assignment.moderated_grading_selections.create!(:student => @student)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      f('#moderation_bar #new_mark_dropdown_link').click
      wait_for_ajaximations
      # make a 2nd mark to copy with a rubric assessment and comments - make sure they get copied
      f('#new_mark_link').click
      wait_for_ajaximations

      comment = "some silly comment"
      add_rubric_assessment(3, comment)

      f('#speedgrader_comment_textarea').send_keys('srsly')
      f('#add_a_comment button[type="submit"]').click
      wait_for_ajaximations

      f('#moderation_bar #new_mark_dropdown_link').click
      wait_for_ajaximations
      f('#new_mark_copy_link2').click
      wait_for_ajaximations

      final_tab = f('#moderation_tabs li.ui-state-active') # should be active tab
      expect(final_tab).to include_text("Moderator")
      expect(final_tab).to include_text("3/8") # should sync tab state

      expect(f('#rubric_summary_container')).to include_text(@rubric.title)
      expect(f('#rubric_summary_container')).to include_text(comment)

      final_pg = @submission.find_or_create_provisional_grade!(@moderator, final: true)
      expect(final_pg.score.to_i).to eql 3
      expect(final_pg.submission_comments.map(&:comment)).to be_include 'srsly'

      ra = @association.rubric_assessments.detect{|ra_local| ra_local.artifact == final_pg}
      expect(ra.data[0][:comments]).to eq comment
    end

    it "should be able to re-copy a mark to the final mark" do
      other_ta = course_with_ta(:course => @course, :active_all => true).user
      @submission.find_or_create_provisional_grade!(other_ta, score: 7)
      @assignment.moderated_grading_selections.create!(:student => @student)

      other_teacher = course_with_teacher(:course => @course, :active_all => true).user
      final_pg = @submission.find_or_create_provisional_grade!(other_teacher, score: 2, final: true)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      f('#moderation_bar #new_mark_dropdown_link').click
      wait_for_ajaximations
      f('#new_mark_copy_link1').click
      driver.switch_to.alert.accept # should get a warning that it will overwrite the current final mark
      wait_for_ajaximations

      @submission.reload
      expect(@submission.score).to be_nil
      expect(@submission.provisional_grade(@moderator)).to be_a(ModeratedGrading::NullProvisionalGrade)

      final_pg.reload
      expect(final_pg.score.to_i).to eql 7
      expect(ff('#moderation_tabs > ul > li')[2]).to include_text("7/8")
    end

    context "grade reloading" do
      it "should load the current provisional grades while switching students if it changed in the background" do
        other_ta = course_with_ta(:course => @course, :active_all => true).user
        original_sub = @submission
        student_submission

        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
        f('#speedgrader_iframe')

        # doesn't show any tabs because there are no marks
        expect(f('#moderation_tabs')).to_not be_displayed

        # go to next student
        f('#next-student-button').click
        wait_for_ajaximations

        Timecop.freeze(original_sub.updated_at) do
          # create a mark for the first student, but don't cause the submission's updated_at to change just yet
          original_sub.find_or_create_provisional_grade!(other_ta, score: 7)
        end

        # go back
        f('#prev-student-button').click
        wait_for_ajaximations

        # should still not have loaded the new provisional grades
        expect(f('#moderation_tabs')).to_not be_displayed

        f('#next-student-button').click
        wait_for_ajaximations

        Timecop.freeze(5.minutes.from_now) do
          original_sub.touch # now touch the submission as it would have been in the first place
        end

        f('#prev-student-button').click
        wait_for_ajaximations

        expect(f('#moderation_tabs')).to be_displayed

        tab = f('#moderation_tabs li.ui-state-active')
        expect(tab).to include_text("1st Reviewer")
        expect(tab).to include_text("7/8")

        grade = f('#grading-box-extended')
        expect(grade['readonly']).to be_present
        expect(grade['value']).to eq "7"
      end

      it "should load the current provisional grades selection while switching students if it changed in the background" do
        @other_ta = course_with_ta(:course => @course, :active_all => true).user
        @pg1 = @submission.find_or_create_provisional_grade!(@other_ta, score: 7)
        @selection = @assignment.moderated_grading_selections.create!(:student => @student)

        @other_ta2 = course_with_ta(:course => @course, :active_all => true).user
        @pg2 = @submission.find_or_create_provisional_grade!(@other_ta2, score: 6)

        @final_pg = @submission.find_or_create_provisional_grade!(@moderator, score: 2, final: true)

        @selection.provisional_grade = @pg1
        @selection.save!

        original_sub = @submission
        student_submission

        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
        f('#speedgrader_iframe')

        icons = ff('#moderation_tabs .selected_icon')
        expect(icons[0]).to be_displayed
        expect(icons[1]).to_not be_displayed
        expect(icons[2]).to_not be_displayed

        f('#next-student-button').click
        wait_for_ajaximations

        Timecop.freeze(5.minutes.from_now) do
          @selection.provisional_grade = @pg2
          @selection.save!
          original_sub.touch
        end

        f('#prev-student-button').click
        wait_for_ajaximations

        expect(icons[0]).to_not be_displayed
        expect(icons[1]).to be_displayed
        expect(icons[2]).to_not be_displayed
      end

      it "should load the current provisional grade while switching students even if its from the same moderator" do
        # why am I doing this... I guess just because I can
        other_student = course_with_student(:course => @course, :active_all => true).user

        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
        f('#speedgrader_iframe')

        f('#next-student-button').click
        wait_for_ajaximations

        expect(f('#this_student_does_not_have_a_submission')).to be_displayed

        f('#prev-student-button').click
        wait_for_ajaximations

        @assignment.grade_student(other_student, grade: 5, grader: @moderator, provisional: true)

        f('#next-student-button').click
        wait_for_ajaximations

        expect(f('#moderation_tabs')).to_not be_displayed # still should not show any tabs, since they own the one grade
        grade = f('#grading-box-extended')
        expect(grade['disabled']).to be_blank
        expect(grade['value']).to eq "5"
      end
    end

    context "moderated grade selection" do
      before :once do
        @other_ta = course_with_ta(:course => @course, :active_all => true).user
        @pg1 = @submission.find_or_create_provisional_grade!(@other_ta, score: 7)
        @selection = @assignment.moderated_grading_selections.create!(:student => @student)
      end

      it "should be able to select a provisional grade" do
        @other_ta2 = course_with_ta(:course => @course, :active_all => true).user
        @pg2 = @submission.find_or_create_provisional_grade!(@other_ta2, score: 6)

        @final_pg = @submission.find_or_create_provisional_grade!(@moderator, score: 2, final: true)

        @selection.provisional_grade = @pg1
        @selection.save!

        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

        tabs = ff('#moderation_tabs > ul > li')
        icons = ff('#moderation_tabs .selected_icon')
        buttons = ff('#moderation_tabs button')

        # should show the 1st mark as selected on load
        expect(icons[0]).to be_displayed
        expect(icons[1]).to_not be_displayed
        expect(icons[2]).to_not be_displayed

        expect(buttons[0]).to_not be_displayed # don't show the select button if already selected
        expect(buttons[1]).to_not be_displayed

        tabs[2].click # show the final mark
        wait_for_ajaximations

        expect(buttons[2]).to be_displayed
        buttons[2].click
        wait_for_ajaximations
        check_element_has_focus(tabs[2])

        expect(buttons[2]).to_not be_displayed
        expect(icons[0]).to_not be_displayed
        expect(icons[2]).to be_displayed # should show the final mark as selected

        @selection.reload
        expect(@selection.provisional_grade).to eq @final_pg # should actually be selected

        # now repeat for the 2nd mark
        tabs[1].click
        wait_for_ajaximations

        expect(buttons[1]).to be_displayed
        buttons[1].click
        wait_for_ajaximations

        expect(buttons[1]).to_not be_displayed
        expect(icons[0]).to_not be_displayed
        expect(icons[1]).to be_displayed
        expect(icons[2]).to_not be_displayed

        @selection.reload
        expect(@selection.provisional_grade).to eq @pg2 # should actually be selected
      end

      it "should be able to select a newly created provisional grade (once it's saved)" do
        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
        f('#moderation_bar #new_mark_dropdown_link').click
        wait_for_ajaximations
        f('#new_mark_link').click
        wait_for_ajaximations

        # should not show the select button until we have a real provisional grade
        mark_tab2 = ff('#moderation_tabs > ul > li')[1]
        mark_tab2_button = mark_tab2.find('button')
        expect(mark_tab2_button).to_not be_displayed

        replace_content f('#grading-box-extended'), "8", tab_out: true
        wait_for_ajaximations

        expect(mark_tab2_button).to be_displayed
        mark_tab2_button.click # select the provisional grade
        wait_for_ajaximations

        expect(mark_tab2_button).to_not be_displayed
        expect(mark_tab2.find('.selected_icon')).to be_displayed

        @selection.reload
        expect(@selection.provisional_grade).to eq @submission.provisional_grade(@moderator)
      end

      it "should automatically select the copied final grade" do
        @selection.provisional_grade = @pg1
        @selection.save!

        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

        f('#moderation_bar #new_mark_dropdown_link').click
        wait_for_ajaximations
        f('#new_mark_copy_link1').click
        wait_for_ajaximations

        @selection.reload
        expect(@selection.provisional_grade).to eq @submission.provisional_grade(@moderator, final: true)

        icons = ff('#moderation_tabs .selected_icon')
        expect(icons[0]).to_not be_displayed
        expect(icons[2]).to be_displayed
      end
    end
  end

  context "as a provisional grader" do
    before do
      course_with_ta_logged_in(:course => @course, :active_all => true)
      @is_moderator = false
    end

    include_examples "moderated grading"

    it "should not lock a provisional grader out if graded by self" do
      @submission.find_or_create_provisional_grade!(@ta, score: 7)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f('#grading-box-extended')).to be_displayed
      expect(f('#not_gradeable_message')).to_not be_displayed
    end

    it "should lock a provisional grader out if graded by someone else (and not up for moderation)" do
      other_ta = course_with_ta(:course => @course, :active_all => true).user
      @submission.find_or_create_provisional_grade!(other_ta, score: 7)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f('#grading-box-extended')).to_not be_displayed
      expect(f('#not_gradeable_message')).to be_displayed
    end

    it "should lock a provisional grader out if graded by someone else while switching students" do
      other_ta = course_with_ta(:course => @course, :active_all => true).user
      original_sub = @submission
      student_submission

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      f('#speedgrader_iframe')
      # not locked yet
      expect(f('#grading-box-extended')).to be_displayed
      expect(f('#not_gradeable_message')).to_not be_displayed

      # go to next student
      f('#next-student-button').click
      wait_for_ajaximations

      # create a mark for the first student
      original_sub.find_or_create_provisional_grade!(other_ta, score: 7)

      # go back
      f('#prev-student-button').click
      wait_for_ajaximations

      # should be locked now
      expect(f('#grading-box-extended')).to_not be_displayed
      expect(f('#not_gradeable_message')).to be_displayed
    end

    it "should not lock a provisional grader out if someone else graded but the student is selected for moderation" do
      @assignment.moderated_grading_selections.create!(:student => @student)
      other_ta = course_with_ta(:course => @course, :active_all => true).user
      @submission.find_or_create_provisional_grade!(other_ta, score: 7)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f('#grading-box-extended')).to be_displayed
      expect(f('#not_gradeable_message')).to_not be_displayed
    end

    it "should lock a provisional grader out the student is selected for moderation but two people have marked it" do
      @assignment.moderated_grading_selections.create!(:student => @student)
      other_ta1 = course_with_ta(:course => @course, :active_all => true).user
      @submission.find_or_create_provisional_grade!(other_ta1, score: 7)
      other_ta2 = course_with_ta(:course => @course, :active_all => true).user
      @submission.find_or_create_provisional_grade!(other_ta2, score: 6)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f('#grading-box-extended')).to_not be_displayed
      expect(f('#not_gradeable_message')).to be_displayed
    end
  end
end
