require File.expand_path(File.dirname(__FILE__) + '/common')

describe "course copy" do
  include_examples "in-process server selenium tests"

  def validate_course_main_page
    header = f('#section-tabs-header')
    expect(header).to be_displayed
    expect(header.text).to eq @course.course_code
  end

  def upload_helper
    filename, fullpath, data = get_file('attachments.zip')
    f('#zip_file').send_keys(fullpath)
    submit_form('#zip_file_import_form')
    keep_trying_until { Delayed::Job.count > 0 }
    expect_new_page_load { Delayed::Job.last.invoke_job }
    validate_course_main_page
    folder = Folder.root_folders(@course).first
    expect(folder.attachments.active.map(&:display_name)).to eq ["first_entry.txt"]
    expect(folder.sub_folders.active.count).to eq 1
    sub = folder.sub_folders.active.first
    expect(sub.name).to eq "adir"
    expect(sub.attachments.active.map(&:display_name)).to eq ["second_entry.txt"]
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
      keep_trying_until { f('div.progressStatus span').text == 'Completed' }

      @new_course = Course.last
      expect(@new_course.syllabus_body).to eq @course.syllabus_body
      expect(@new_course.tab_configuration).to eq @course.tab_configuration
      expect(@new_course.default_view).to eq @course.default_view
      expect(@new_course.wiki.wiki_pages.count).to eq 1
    end

    it "should copy the course with different settings" do
      skip("killing thread with intermittent failures")
      enable_cache do
        course_with_admin_logged_in
        5.times { |i| @course.wiki.wiki_pages.create!(:title => "hi #{i}", :body => "Whatever #{i}") }

        get "/courses/#{@course.id}/copy"
        expect_new_page_load { f('button[type="submit"]').click }
        submit_form('#copy_context_form')
        wait_for_ajaximations
        f('#copy_everything').click
        wait_for_ajaximations

        keep_trying_until { Canvas::Migration::Worker::CourseCopyWorker.new.perform(ContentMigration.last)}

        keep_trying_until { expect(f('#copy_results > h2')).to include_text('Copy Succeeded') }

        @new_course = Course.last
        get "/courses/#{@new_course.id}"
        expect(f(".no-recent-messages")).to include_text("No Recent Messages")
        expect(@new_course.wiki.wiki_pages.count).to eq 5
      end
    end

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

      get "/courses/#{@course.id}/copy"

      expect_new_page_load { f('button[type="submit"]').click }
      run_jobs
      keep_trying_until { f('div.progressStatus span').text == 'Completed' }

      @new_course = subaccount.courses.where("id <>?", @course.id).last
      expect(@new_course.syllabus_body).to eq @course.syllabus_body
    end
  end

  describe "course file imports" do

    before (:each) do
      skip('193')
      course_with_teacher_logged_in(:course_code => 'first files course')
      @second_course = Course.create!(:name => 'second files course')
      @second_course.offer!
      @second_course.enroll_teacher(@user).accept!
      @second_course.reload
      get "/courses/#{@course.id}/imports/files"
    end

    it "should successfully import a zip file" do
      upload_helper
    end

  end
end
