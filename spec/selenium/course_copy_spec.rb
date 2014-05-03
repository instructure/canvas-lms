require File.expand_path(File.dirname(__FILE__) + '/common')

describe "course copy" do
  include_examples "in-process server selenium tests"

  def validate_course_main_page
    header = f('#section-tabs-header')
    header.should be_displayed
    header.text.should == @course.course_code
  end

  def upload_helper
    filename, fullpath, data = get_file('attachments.zip')
    f('#zip_file').send_keys(fullpath)
    submit_form('#zip_file_import_form')
    keep_trying_until { Delayed::Job.count > 0 }
    expect_new_page_load { Delayed::Job.last.invoke_job }
    validate_course_main_page
    folder = Folder.root_folders(@course).first
    folder.attachments.active.map(&:display_name).should == ["first_entry.txt"]
    folder.sub_folders.active.count.should == 1
    sub = folder.sub_folders.active.first
    sub.name.should == "adir"
    sub.attachments.active.map(&:display_name).should == ["second_entry.txt"]
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
      @new_course.syllabus_body.should == @course.syllabus_body
      @new_course.tab_configuration.should == @course.tab_configuration
      @new_course.default_view.should == @course.default_view
      @new_course.wiki.wiki_pages.count.should == 1
    end

    it "should copy the course with different settings" do
      pending("killing thread with intermittent failures")
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

        keep_trying_until { f('#copy_results > h2').should include_text('Copy Succeeded') }

        @new_course = Course.last
        get "/courses/#{@new_course.id}"
        f(".no-recent-messages").should include_text("No Recent Messages")
        @new_course.wiki.wiki_pages.count.should == 5
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
      new_course.name.should == "course name of testing"
      new_course.course_code.should == "course code of testing"
    end

    it "should adjust the dates" do
      course_with_admin_logged_in

      get "/courses/#{@course.id}/copy"

      f('#dateShiftCheckbox').click

      f('#oldStartDate').clear
      f('#oldStartDate').send_keys('7/1/2012')
      f('#oldEndDate').send_keys('Jul 11, 2012')
      f('#newStartDate').clear
      f('#newStartDate').send_keys('8-5-2012')
      f('#newEndDate').send_keys('Aug 15, 2012')

      expect_new_page_load { f('button[type="submit"]').click }

      opts = ContentMigration.last.migration_settings["date_shift_options"]
      expected = {
          "old_start_date" => "Jul 1, 2012", "old_end_date" => "Jul 11, 2012",
          "new_start_date" => "Aug 5, 2012", "new_end_date" => "Aug 15, 2012"
      }
      expected.each do |k, v|
        Date.parse(opts[k].to_s).should == Date.parse(v)
      end
    end
  end

  describe "course file imports" do

    before (:each) do
      pending('193')
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
