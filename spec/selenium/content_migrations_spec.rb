require File.expand_path(File.dirname(__FILE__) + '/common')

describe "external migrations" do
  it_should_behave_like "forked server selenium tests"

  append_after(:all) do
    Setting.remove("file_storage_test_override")
  end

  before(:each) do
    @password = "asdfasdf"
    @teacher = user_with_pseudonym :active_user => true,
                                   :username => "teacher@example.com",
                                   :password => @password
    @teacher.save!

    @course = course :active_course => true
    @course.enroll_teacher(@teacher).accept!
    @course.reload
  end
  
  after(:each) do
    if @migration
      [@migration.attachment, @migration.overview_attachment, @migration.exported_attachment].each do |att|
        next unless att && att.respond_to?(:full_filename)
        filename = att.full_filename
        if File.exists?(filename)
          begin
            FileUtils::rm_rf(filename)
          rescue
            Rails.logger.warn "Couldn't delete #{filename} for content_migration selenium spec"
          end
        end
      end
    end
  end

  def run_import(file)
    login_as(@teacher.email, @password)

    get "/courses/#{@course.id}/imports/migrate"

    filename, fullpath, data = get_file(file)

    click_option('#choose_migration_system', 'Common Cartridge 1.0/1.1/1.2 Package')
    driver.find_element(:css, '#config_options').find_element(:name, 'export_file').send_keys(fullpath)
    submit_form('#config_options')
    keep_trying_until { driver.find_element(:css, '#file_uploaded').displayed? }

    ContentMigration.for_context(@course).count.should == 1
    @migration = ContentMigration.for_context(@course).first
    @migration.attachment.should_not be_nil
    job = @migration.export_content
    job.invoke_job

    @migration.reload
    @migration.workflow_state.should == 'exported'

    get "/courses/#{@course.id}/imports/migrate/#{@migration.id}"
    wait_for_ajaximations
    keep_trying_until { find_with_jquery("#copy_everything").should be_displayed }

    yield driver if block_given?

    expect_new_page_load {
      submit_form('#copy_context_form')
      wait_for_ajaximations

      # since jobs aren't running
      @migration.reload
      @migration.import_content_without_send_later
    }

    driver.current_url.ends_with?("/courses/#{@course.id}").should == true
    @course.reload
  end
  
  it "should import a common cartridge" do
    run_import("cc_full_test.zip") do |driver|
      driver.find_element(:id, 'copy_everything').click
      driver.find_element(:id, 'copy_all_quizzes').click if Qti.migration_executable
      driver.find_element(:id, 'copy_folders_I_00001_R_').click
      driver.find_element(:id, 'copy_folders_I_00006_Media_').click
      driver.find_element(:id, 'copy_folders_I_media_R_').click
      driver.find_element(:id, 'copy_modules_I_00000_').click
      driver.find_element(:id, 'copy_topics_I_00009_R_').click
      driver.find_element(:id, 'copy_topics_I_00006_R_').click
      driver.find_element(:id, 'copy_external_tools_I_00010_R_').click
    end
    
    @course.discussion_topics.count.should == 2
    @course.quizzes.count.should == 1 if Qti.migration_executable
    @course.attachments.count.should == 3
    @course.context_modules.count.should == 1
    @course.context_external_tools.count.should == 1
    @course.folders.count.should == 4
  end

  it "should selectively import a common cartridge" do
    run_import("cc_ark_test.zip") do |driver|
      driver.find_element(:id, 'copy_everything').click
      driver.find_element(:id, 'copy_assignments_i183e1527a34b34e8151ffc6dec6cd140_').click
      driver.find_element(:id, 'copy_quizzes_i2da11ea691f704f9b32ed3fa563af30e_').click
      driver.find_element(:id, 'copy_files_i6d69d81475a73c4214327e7d4ad5630f_').click
      driver.find_element(:id, 'copy_modules_i2410bad2b8623a94d9b662ced95406e0_').click
      driver.find_element(:id, 'copy_topics_icdbdc4aab17bdd59c6b07f0336de1ce0_').click
      driver.find_element(:id, 'copy_topics_ie28afa86290a7c5dfbe78453cc9b8d28_').click
      driver.find_element(:id, 'copy_assignment_groups_i0928a83d992c891aa083bcffc1913b67_').click
      driver.find_element(:id, 'copy_all_external_tools').click
    end

    # 2 because the announcement is returned for this too.
    @course.discussion_topics.count.should == 2
    @course.attachments.count.should == 1
    @course.quizzes.count.should == 1 if Qti.migration_executable
    @course.attachments.count.should == 1
    @course.context_modules.count.should == 1
    @course.wiki.wiki_pages.count.should == 0
    @course.folders.count.should == 1
    @course.context_external_tools.count.should == 2
  end

  it "should import canvas cartridge without discussion metadata or quiz folder" do
    run_import("canvas_cc_minimum.zip")

    @course.discussion_topics.count.should == 1
    dt = @course.discussion_topics.first
    dt.title.should == "A topic"
    dt.message.should == "<p>description</p>"
  end



end