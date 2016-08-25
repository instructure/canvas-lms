require File.expand_path(File.dirname(__FILE__) + '/common')

describe "course copy" do
  include_context "in-process server selenium tests"

  def validate_course_main_page
    header = f('#breadcrumbs .home + li a')
    expect(header).to be_displayed
    expect(header.text).to eq @course.course_code
  end

  describe "course copy through course copying" do
    it "should copy the course" do
      course_with_admin_logged_in
      @course.syllabus_body = "<p>haha</p>"
      @course.tab_configuration = [{"id" => 0}, {"id" => 14}, {"id" => 8}, {"id" => 5}, {"id" => 6}, {"id" => 2}, {"id" => 3, "hidden" => true}]
      @course.default_view = 'modules'
      @course.wiki.wiki_pages.create!(:title => "hi", :body => "Whatever")
      @course.save!

      get "/courses/#{@course.id}/copy"
      expect_new_page_load { f('button[type="submit"]').click }
      run_jobs
      expect(f('div.progressStatus span')).to include_text 'Completed'

      @new_course = Course.last
      expect(@new_course.syllabus_body).to eq @course.syllabus_body
      expect(@new_course.tab_configuration).to eq @course.tab_configuration
      expect(@new_course.default_view).to eq @course.default_view
      expect(@new_course.wiki.wiki_pages.count).to eq 1
    end

    # TODO reimplement per CNVS-29604, but make sure we're testing at the right level
    it "should copy the course with different settings"

    it "should set the course name and code correctly" do
      course_with_admin_logged_in

      get "/courses/#{@course.id}/copy"

      name = f('#course_name')
      replace_content(name, "course name of testing")
      name = f('#course_course_code')
      replace_content(name, "course code of testing")

      expect_new_page_load { f('button[type="submit"]').click }

      new_course = Course.last
      expect(new_course.name).to eq "course name of testing"
      expect(new_course.course_code).to eq "course code of testing"
    end

    it "should adjust the dates" do
      course_with_admin_logged_in

      get "/courses/#{@course.id}/copy"

      f('#dateAdjustCheckbox').click

      f('#oldStartDate').clear
      f('#oldStartDate').send_keys('7/1/2012')
      f('#oldEndDate').send_keys('Jul 11, 2012')
      f('#newStartDate').clear
      f('#newStartDate').send_keys('8-5-2012')
      f('#newEndDate').send_keys('Aug 15, 2012')

      f('#addDaySubstitution').click
      click_option('#daySubstitution ul > div:nth-child(1) .currentDay', "1", :value)
      click_option('#daySubstitution ul > div:nth-child(1) .subDay', "2", :value)

      expect_new_page_load { f('button[type="submit"]').click }

      opts = ContentMigration.last.migration_settings["date_shift_options"]
      expect(opts['shift_dates']).to eq '1'
      expect(opts['day_substitutions']).to eq({"1" => "2"})
      expected = {
          "old_start_date" => "Jul 1, 2012", "old_end_date" => "Jul 11, 2012",
          "new_start_date" => "Aug 5, 2012", "new_end_date" => "Aug 15, 2012"
      }
      expected.each do |k, v|
        expect(Date.parse(opts[k].to_s)).to eq Date.parse(v)
      end
    end

    it "should remove dates" do
      course_with_admin_logged_in

      get "/courses/#{@course.id}/copy"

      f('#dateAdjustCheckbox').click
      f('#dateRemoveOption').click
      expect_new_page_load { f('button[type="submit"]').click }

      opts = ContentMigration.last.migration_settings["date_shift_options"]
      expect(opts['remove_dates']).to eq '1'
    end

    it "should create the new course in the same sub-account" do
      account_model
      subaccount = @account.sub_accounts.create!(:name => "subadubdub")
      course_with_admin_logged_in(:account => subaccount)
      @course.syllabus_body = "<p>haha</p>"
      @course.save!

      get "/courses/#{@course.id}/settings"
      link = f('.copy_course_link')
      expect(link).to be_displayed

      expect_new_page_load { link.click }

      expect_new_page_load { f('button[type="submit"]').click }
      run_jobs
      expect(f('div.progressStatus span')).to include_text 'Completed'

      @new_course = subaccount.courses.where("id <>?", @course.id).last
      expect(@new_course.syllabus_body).to eq @course.syllabus_body
    end

    it "should create the new course with the default enrollment term if needed" do
      account_model
      @account.settings[:teachers_can_create_courses] = true
      @account.save!

      term = @account.enrollment_terms.create!
      term.set_overrides(@account, 'TeacherEnrollment' => {:end_at => 3.days.ago})

      course_with_teacher_logged_in(:account => @account, :active_all => true)
      @course.enrollment_term = term
      @course.syllabus_body = "<p>haha</p>"
      @course.save!

      get "/courses/#{@course.id}/settings"
      link = f('.copy_course_link')
      expect(link).to be_displayed

      expect_new_page_load { link.click }

      expect_new_page_load { f('button[type="submit"]').click }
      run_jobs
      expect(f('div.progressStatus span')).to include_text 'Completed'

      @new_course = @account.courses.where("id <>?", @course.id).last
      expect(@new_course.enrollment_term).to eq @account.default_enrollment_term
      expect(@new_course.syllabus_body).to eq @course.syllabus_body
    end

    it "should not be able to submit invalid course dates" do
      course_with_admin_logged_in

      get "/courses/#{@course.id}/copy"

      replace_content(f('#course_start_at'), 'Aug 15, 2012')
      replace_content(f('#course_conclude_at'), 'Jul 11, 2012', :tab_out => true)

      button = f('button.btn-primary')
      expect(button).to be_disabled

      replace_content(f('#course_conclude_at'), 'Aug 30, 2012', :tab_out => true)

      expect(button).not_to be_disabled
    end
  end
end
