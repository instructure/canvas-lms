require File.expand_path(File.dirname(__FILE__) + '/common')

describe "course copy" do
  it_should_behave_like "in-process server selenium tests"

  def course_copy_helper(dont_submit_form=false)
    course_with_teacher_logged_in unless @course
    @second_course ||= Course.create!(:name => 'second course')
    @second_course.offer!
    5.times { |i| @second_course.wiki.wiki_pages.create!(:title => "hi #{i}", :body => "Whatever #{i}") }
    #add teacher as a user
    @second_course.enroll_teacher(@user).accept!
    @second_course.reload

    new_term = Account.default.enrollment_terms.create(:name => 'Test Term')
    third_course = Course.create!(:name => 'third course', :enrollment_term => new_term)
    third_course.enroll_teacher(@user).accept!

    get "/courses/#{@course.id}/details"

    wait_for_ajaximations
    f('.import_content').click
    f('.copy_from_another').click

    select_box = f('#copy_from_course')
    select_box.find_elements(:css, 'optgroup').length.should == 2
    optgroups = select_box.find_elements(:css, 'optgroup')
    optgroups.map { |og| og.attribute('label') }.sort.should eql ["Default Term", "Test Term"]
    optgroups.map { |og| og.find_elements(:css, 'option').length }.should eql [1, 1]

    click_option('#copy_from_course', 'second course')
    f('button[type="submit"]').click

    yield driver if block_given?
    return if dont_submit_form

    f('button[type="submit"]').click
    wait_for_ajaximations

    # since jobs aren't running
    ContentMigration.last.copy_course_without_send_later

    keep_trying_until { f('#copy_results > h2').should include_text('Copy Succeeded') }
    @course.reload
  end

  def upload_helper(import_quiz = false)
    if import_quiz
      expect_new_page_load { fj('.content-imports-instructions a:last').click }
      filename, fullpath, data = get_file('qti.zip')
      f('#export_file_input').send_keys(fullpath)
      submit_form('#qti_file_import_form')
      keep_trying_until { f('#file_uploaded').should include_text('Thank you!') }
    else
      expect_new_page_load { f('.content-imports-instructions a').click }
      filename, fullpath, data = get_file('attachments.zip')
      f('#zip_file').send_keys(fullpath)
      submit_form('#zip_file_import_form')
      keep_trying_until { Delayed::Job.count > 0 }
      Delayed::Job.last.invoke_job
      back_button = keep_trying_until do
        back_button = f('.back_to_course')
        back_button.should_not be_nil
        back_button
      end
      expect_new_page_load { back_button.click }
      folder = Folder.root_folders(@course).first
      folder.attachments.active.map(&:display_name).should == ["first_entry.txt"]
      folder.sub_folders.active.count.should == 1
      sub = folder.sub_folders.active.first
      sub.name.should == "adir"
      sub.attachments.active.map(&:display_name).should == ["second_entry.txt"]
    end
  end

  describe "course copy (through course 'copying')" do
    it "should copy the course" do
      course_with_admin_logged_in
      @course.syllabus_body = "<p>haha</p>"
      @course.tab_configuration = [{"id" => 0}, {"id" => 14}, {"id" => 8}, {"id" => 5}, {"id" => 6}, {"id" => 2}, {"id" => 3, "hidden" => true}]
      @course.default_view = 'modules'
      @course.wiki.wiki_pages.create!(:title => "hi", :body => "Whatever")
      @course.save!

      get "/courses/#{@course.id}/copy"
      expect_new_page_load { f('button[type="submit"]').click }
      f('#copy_everything').click
      wait_for_ajaximations
      submit_form('#copy_context_form')
      wait_for_ajaximations

      keep_trying_until { ContentMigration.last.copy_course_without_send_later }

      keep_trying_until { f('#copy_results > h2').should include_text('Copy Succeeded') }

      @new_course = Course.last
      @new_course.syllabus_body.should == nil
      @new_course.tab_configuration.should == []
      @new_course.default_view.should == 'feed'
    end

    it "should copy the course with different settings" do
      enable_cache do
        course_with_admin_logged_in
        5.times { |i| @course.wiki.wiki_pages.create!(:title => "hi #{i}", :body => "Whatever #{i}") }

        get "/courses/#{@course.id}/copy"
        expect_new_page_load { f('button[type="submit"]').click }
        submit_form('#copy_context_form')
        wait_for_ajaximations
        f('#copy_everything').click
        wait_for_ajaximations

        keep_trying_until { ContentMigration.last.copy_course_without_send_later }

        keep_trying_until { f('#copy_results > h2').should include_text('Copy Succeeded') }

        @new_course = Course.last
        get "/courses/#{@new_course.id}"
        f("#no_topics_message").should include_text("No Recent Messages")
        @new_course.wiki.wiki_pages.count.should == 5
      end
    end

    it "should set the course name and code correctly" do
      course_with_admin_logged_in

      get "/courses/#{@course.id}/copy"

      name = f('#course_name')
      name.clear
      name.send_keys("course name of testing")
      name = f('#course_course_code')
      name.clear
      name.send_keys("course code of testing")

      expect_new_page_load { f('button[type="submit"]').click }
      submit_form('#copy_context_form')
      wait_for_ajaximations

      new_course = Course.last
      new_course.name.should == "course name of testing"
      new_course.course_code.should == "course code of testing"
    end
  end

  describe "course copy (through course 'importing')" do
    it "should copy course content" do
      course_copy_helper
      @course.wiki.wiki_pages.count.should == 5
    end

    it "should copy content if things are unselected in hidden boxes" do
      course_copy_helper do
        f('#copy_everything').click
        wait_for_ajaximations
        f('#uncheck_everything').click
        f('#copy_everything').click
      end
      @course.wiki.wiki_pages.count.should == 5
    end

    it "should selectively copy content" do
      course_copy_helper do
        f('#copy_everything').click
        wait_for_ajaximations
        @second_course.wiki.wiki_pages[0..2].each do |page|
          f("#copy_wiki_pages_#{CC::CCHelper.create_key(page)}").click
        end
      end
      @course.wiki.wiki_pages.count.should == 3
    end

    it "should adjust due dates" do
      old_start = DateTime.parse("01 Jul 2012 06:00:00 UTC +00:00")
      new_start = DateTime.parse("05 Aug 2012 06:00:00 UTC +00:00")

      @second_course = Course.create!(:name => 'second course')

      @second_course.discussion_topics.create!(:title => "some topic",
                                               :message => "<p>some text</p>",
                                               :delayed_post_at => old_start + 3.days)
      @second_course.assignments.create!(:due_at => old_start)

      # Set the start/end dates to test that they are auto-filled on the copy content page
      @second_course.start_at = DateTime.parse("01 Jul 2012")
      @second_course.conclude_at = DateTime.parse("11 Jul 2012")
      @second_course.save!
      course_with_teacher_logged_in
      @course.start_at = DateTime.parse("05 Aug 2012")
      @course.conclude_at = DateTime.parse("15 Aug 2012")
      @course.save!

      course_copy_helper do
        f('#copy_shift_dates').click
        f('.add_substitution_link').click
        wait_for_animations
        click_option('.new_select .weekday_select', 'Monday')
      end

      new_disc = @course.discussion_topics.first
      new_disc.delayed_post_at.to_i.should == (new_start + 3.days).to_i
      new_assignment = @course.assignments.first
      new_assignment.due_at.to_i.should == (new_start + 1.day).to_i
    end

    it "should not copy course settings if not checked" do
      @second_course = Course.create!(:name => 'second course')
      @second_course.syllabus_body = "<p>haha</p>"
      @second_course.tab_configuration = [{"id" => 0}, {"id" => 14}, {"id" => 8}, {"id" => 5}, {"id" => 6}, {"id" => 2}, {"id" => 3, "hidden" => true}]
      @second_course.default_view = 'modules'

      course_copy_helper do
        f('#copy_everything').click
        wait_for_ajaximations
      end

      @course.syllabus_body.should == nil
      @course.tab_configuration.should == []
      @course.default_view.should == 'feed'
    end

    it "should correctly copy content from a completed course" do
      course_with_teacher_logged_in
      @course.wiki.wiki_pages.count.should == 0
      second_course = Course.create!(:name => 'completed course')
      5.times { |i| second_course.wiki.wiki_pages.create!(:title => "hi #{i}", :body => "Whatever #{i}") }
      second_course.enroll_teacher(@user).accept!
      second_course.offer!
      second_course.complete!
      get "/courses/#{@course.id}/imports"
      expect_new_page_load { f('.copy_from_another').click }
      f('#include_concluded_courses').click
      f('#course_autocomplete_id_lookup').send_keys(second_course.name)
      keep_trying_until do
        ui_auto_complete = f('.ui-autocomplete')
        ui_auto_complete.should be_displayed
      end
      fj('.ui-menu-item a').click
      f('#course_autocomplete_name').should include_text(second_course.name)
      f('button[type="submit"]').click
      submit_form('#copy_context_form')
      wait_for_ajaximations
      ContentMigration.last.copy_course_without_send_later
      keep_trying_until { f('#copy_results > h2').should include_text('Copy Succeeded') }
      @course.reload
      @course.wiki.wiki_pages.count.should == 5
    end

    it "should not list deleted attachments in the selection list" do
      @second_course ||= Course.create!(:name => 'second course')
      att1 = Attachment.create!(:filename => 'deleted.txt', :display_name => "deleted.txt", :uploaded_data => StringIO.new('deleted stuff'), :folder => Folder.root_folders(@second_course).first, :context => @second_course)
      att2 = Attachment.create!(:filename => 'active.txt', :display_name => "active.txt", :uploaded_data => StringIO.new('not deleted'), :folder => Folder.root_folders(@second_course).first, :context => @second_course)
      att1.destroy

      course_copy_helper(true) do
        f('#copy_everything').click
        wait_for_ajaximations
        f("#copy_attachments_#{CC::CCHelper.create_key(att1)}").should be_nil
        f("#copy_attachments_#{CC::CCHelper.create_key(att2)}").should_not be_nil
      end
    end
  end

  describe "course file imports" do
    before (:each) do
      course_with_teacher_logged_in
      @second_course = Course.create!(:name => 'second files course')
      @second_course.offer!
      @second_course.enroll_teacher(@user).accept!
      @second_course.reload
      get "/courses/#{@course.id}/imports"
    end

    it "should successfully import a zip file" do
      upload_helper
    end

    it "should successfully import a quiz" do
      upload_helper(true)
    end
  end
end