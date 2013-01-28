require File.expand_path(File.dirname(__FILE__) + '/helpers/outcome_specs')

describe "course outcomes" do
  it_should_behave_like "outcome tests"

  let(:who_to_login) { 'teacher' }
  let(:outcome_url) { "/courses/#{@course.id}/outcomes" }

  context "as a teacher" do

    describe "account level outcomes" do
      def goto_account_default_outcomes
        f('.find_outcome').click
        wait_for_ajaximations
        f(".ellipsis[title='Account Standards']").click
        wait_for_ajaximations
        f(".ellipsis[title='Default Account']").click
        wait_for_ajaximations
      end

      before do
        @account = Account.default
        account_outcome(1)
        get outcome_url
        wait_for_ajaximations
        goto_account_default_outcomes
      end

      it "should have account outcomes available for course" do
        f(".ellipsis[title='outcome 0']").should be_displayed
      end

      it "should add account outcomes to course" do
        f(".ellipsis[title='outcome 0']").click
        import_account_level_outcomes()
        f(".ellipsis[title='outcome 0']").should be_displayed
      end

      it "should remove account outcomes from course" do
        pending("no delete button when seeding, functionality should be available")
        f(".ellipsis[title='outcome 0']").click
        import_account_level_outcomes()
        f(".ellipsis[title='outcome 0']").click
        wait_for_ajaximations
        msg = "redmine bug on this functionality"
        msg.should == ""
      end
    end

    describe "find/import dialog" do
      it "should not allow importing top level groups" do
        get outcome_url
        wait_for_ajaximations

        f('.find_outcome').click
        wait_for_ajaximations
        groups = ff('.outcome-group')
        groups.size.should == 1
        groups.each do |g|
          g.click
          f('.ui-dialog-buttonpane .btn-primary').should_not be_displayed
        end
      end
    end

    describe "bulk groups and outcomes" do
      it "should load groups and then outcomes" do
        num = 2
        course_bulk_outcome_groups_course(num, num)
        course_outcome(num)
        get outcome_url
        wait_for_ajaximations
        keep_trying_until do
          ff(".outcome-level li").first.should have_class("outcome-group")
          ff(".outcome-level li").last.should have_class("outcome-link")
        end
      end

      it "should display 20 initial groups" do
        num = 21
        course_bulk_outcome_groups_course(num, num)
        get outcome_url
        wait_for_ajaximations
        keep_trying_until { ff(".outcome-group").count.should == 20 }
      end

      it "should display 20 initial associated outcomes in nested group" do
        num = 21
        course_bulk_outcome_groups_course(num, num)
        get outcome_url
        ff(".outcome-group")[0].click
        wait_for_ajaximations
        keep_trying_until { ff(".outcome-link").length.should == 20 }
      end
    end

    describe "instructions" do
      it "should display outcome instructions" do
        course_bulk_outcome_groups_course(2, 2)
        get outcome_url
        wait_for_ajaximations
        ff('.outcomes-content').first.text.should contain "Setting up Outcomes"
      end
    end

    describe "actions" do
      it "should not render an HTML-escaped title in outcome directory while editing" do
        title = 'escape & me <<->> if you dare'
        escaped_title = 'escape &amp; me &lt;&lt;-&gt;&gt; if you dare'

        who_to_login == 'teacher' ? @context = @course : @context = account
        outcome_model
        get outcome_url
        wait_for_ajaximations
        fj('.outcomes-sidebar .outcome-level:first li').click
        f('.edit_button').click

        # pass in the unescaped version of the title:
        replace_content f('.outcomes-content input[name=title]'), title
        f('.submit_button').click
        wait_for_ajaximations

        # the "readable" version should be rendered in directory browser
        li_el = fj('.outcomes-sidebar .outcome-level:first li:first')
        li_el.should be_true # should be present
        li_el.text.should == title

        # the "readable" version should be rendered in the view:
        f(".outcomes-content .title").text.should == title

        # and the escaped version should be stored!
        # LearningOutcome.find_by_short_description(escaped_title).should be_present
        # or not, looks like it isn't being escaped
        LearningOutcome.find_by_short_description(title).should be_present
      end
    end
  end

  context "as a student" do
    let(:who_to_login) { 'student' }

    describe "initial state" do
      it "should not display outcome instructions" do
        course_bulk_outcome_groups_course(2, 2)
        get outcome_url
        wait_for_ajaximations
        ff('.outcomes-content').first.text.should_not contain "Setting up Outcomes"
      end

      it "should select the first outcome from the list if there are no outcome groups" do
        course_outcome 2
        get outcome_url
        wait_for_ajaximations
        keep_trying_until { ff('.outcomes-content .title').first.text.should contain "outcome 0" }
      end

      it "should select the first outcome group from the list if there are outcome groups" do
        course_bulk_outcome_groups_course(2, 2)
        get outcome_url
        wait_for_ajaximations
        keep_trying_until { ff('.outcomes-content .title').first.text.should contain "group 0" }
      end
    end
  end
end