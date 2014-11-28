require File.expand_path(File.dirname(__FILE__) + '/helpers/outcome_common')

describe "outcomes" do
  include_examples "in-process server selenium tests"
  let(:who_to_login) { 'teacher' }
  let(:outcome_url) { "/courses/#{@course.id}/outcomes" }

  describe "course outcomes" do
    before (:each) do
      course_with_teacher_logged_in
    end

    context "create/edit/delete outcomes" do

      it "should create a learning outcome with a new rating (root level)" do
        should_create_a_learning_outcome_with_a_new_rating_root_level
      end

      it "should create a learning outcome (nested)" do
        should_create_a_learning_outcome_nested
      end

      it "should edit a learning outcome and delete a rating" do
        should_edit_a_learning_outcome_and_delete_a_rating
      end

      it "should delete a learning outcome" do
        should_delete_a_learning_outcome
      end

      it "should validate mastery points" do
        should_validate_mastery_points
      end

      it "should require a title" do
        should_validate_short_description_presence
      end

      it "should require a title less than 255 chars" do
        should_validate_short_description_length
      end
    end

    context "create/edit/delete outcome groups" do

      it "should create an outcome group (root level)" do
        should_create_an_outcome_group_root_level
      end

      it "should create a learning outcome with a new rating (nested)" do
        should_create_a_learning_outcome_with_a_new_rating_nested
      end

      it "should edit an outcome group" do
        should_edit_an_outcome_group
      end

      it "should delete an outcome group" do
        should_delete_an_outcome_group
      end
    end

    context "actions" do
      it "should not render an HTML-escaped title in outcome directory while editing" do
        title = 'escape & me <<->> if you dare'
        escaped_title = 'escape &amp; me &lt;&lt;-&gt;&gt; if you dare'
        who_to_login == 'teacher' ? @context = @course : @context = account
        outcome_model
        get outcome_url
        wait_for_ajaximations
        fj('.outcomes-sidebar .outcome-level:first li').click
        wait_for_ajaximations
        f('.edit_button').click

        # pass in the unescaped version of the title:
        replace_content f('.outcomes-content input[name=title]'), title
        f('.submit_button').click
        wait_for_ajaximations

        # the "readable" version should be rendered in directory browser
        li_el = fj('.outcomes-sidebar .outcome-level:first li:first')
        expect(li_el).to be_truthy # should be present
        expect(li_el.text).to eq title

        # the "readable" version should be rendered in the view:
        expect(f(".outcomes-content .title").text).to eq title

        # and the escaped version should be stored!
        # LearningOutcome.find_by_short_description(escaped_title).should be_present
        # or not, looks like it isn't being escaped
        expect(LearningOutcome.find_by_short_description(title)).to be_present
      end
    end

    context "#show" do
      it "should show rubrics as aligned items" do
        outcome_with_rubric

        get "/courses/#{@course.id}/outcomes/#{@outcome.id}"
        wait_for_ajaximations

        expect(f('#alignments').text).to match(/#{@rubric.title}/)
      end
    end
  end

  describe "as a teacher" do


    def goto_account_default_outcomes
      f('.find_outcome').click
      wait_for_ajaximations
      f(".ellipsis[title='Account Standards']").click
      wait_for_ajaximations
      f(".ellipsis[title='Default Account']").click
      wait_for_ajaximations
    end

    context "account level outcomes" do

      before do
        course_with_teacher_logged_in
        @account = Account.default
        account_outcome(1)
        get outcome_url
        wait_for_ajaximations
        goto_account_default_outcomes
      end

      it "should have account outcomes available for course" do
        expect(f(".ellipsis[title='outcome 0']")).to be_displayed
      end

      it "should add account outcomes to course" do
        f(".ellipsis[title='outcome 0']").click
        import_account_level_outcomes()
        expect(f(".ellipsis[title='outcome 0']")).to be_displayed
      end

      it "should remove account outcomes from course" do
        skip("no delete button when seeding, functionality should be available")
        f(".ellipsis[title='outcome 0']").click
        import_account_level_outcomes()
        f(".ellipsis[title='outcome 0']").click
        wait_for_ajaximations
        msg = "redmine bug on this functionality"
        expect(msg).to eq ""
      end

      context "find/import dialog" do
        it "should not allow importing top level groups" do
          get outcome_url
          wait_for_ajaximations

          f('.find_outcome').click
          wait_for_ajaximations
          groups = ff('.outcome-group')
          expect(groups.size).to eq 1
          groups.each do |g|
            g.click
            expect(f('.ui-dialog-buttonpane .btn-primary')).not_to be_displayed
          end
        end
      end
    end

    context "bulk groups and outcomes" do
      before(:each) do
        course_with_teacher_logged_in
      end

      it "should load groups and then outcomes" do
        num = 2
        course_bulk_outcome_groups_course(num, num)
        course_outcome(num)
        get outcome_url
        wait_for_ajaximations
        keep_trying_until do
          expect(ff(".outcome-level li").first).to have_class("outcome-group")
          expect(ff(".outcome-level li").last).to have_class("outcome-link")
        end
      end

      it "should display 20 initial groups" do
        num = 21
        course_bulk_outcome_groups_course(num, num)
        get outcome_url
        wait_for_ajaximations
        keep_trying_until { expect(ff(".outcome-group").count).to eq 20 }
      end

      it "should display 20 initial associated outcomes in nested group" do
        num = 21
        course_bulk_outcome_groups_course(num, num)
        get outcome_url
        ff(".outcome-group")[0].click
        wait_for_ajaximations
        keep_trying_until { expect(ff(".outcome-link").length).to eq 20 }
      end

      context "instructions" do
        it "should display outcome instructions" do
          course_bulk_outcome_groups_course(2, 2)
          get outcome_url
          wait_for_ajaximations
          expect(ff('.outcomes-content').first.text).to include "Setting up Outcomes"
        end
      end
    end
  end

  describe "as a student" do

    let(:who_to_login) { 'student' }

    before(:each) do
      course_with_student_logged_in
    end

    context "initial state" do
      it "should not display outcome instructions" do
        course_bulk_outcome_groups_course(2, 2)
        get outcome_url
        wait_for_ajaximations
        expect(ff('.outcomes-content').first.text).not_to include "Setting up Outcomes"
      end

      it "should select the first outcome from the list if there are no outcome groups" do
        course_outcome 2
        get outcome_url
        wait_for_ajaximations
        keep_trying_until { expect(ff('.outcomes-content .title').first.text).to include "outcome 0" }
      end

      it "should select the first outcome group from the list if there are outcome groups" do
        course_bulk_outcome_groups_course(2, 2)
        get outcome_url
        wait_for_ajaximations
        keep_trying_until { expect(ff('.outcomes-content .title').first.text).to include "group 0" }
      end
    end
  end
end
