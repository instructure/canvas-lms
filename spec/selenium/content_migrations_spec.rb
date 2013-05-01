require File.expand_path(File.dirname(__FILE__) + '/common')

describe "external migrations" do
  it_should_behave_like "in-process server selenium tests"

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
    f('#config_options').find_element(:name, 'export_file').send_keys(fullpath)
    submit_form('#config_options')
    keep_trying_until { f('#file_uploaded').should be_displayed }

    ContentMigration.for_context(@course).count.should == 1
    @migration = ContentMigration.for_context(@course).first
    @migration.attachment.should_not be_nil
    job = @migration.export_content
    job.invoke_job

    @migration.reload
    @migration.workflow_state.should == 'exported'

    get "/courses/#{@course.id}/imports/migrate/#{@migration.id}"
    wait_for_ajaximations
    keep_trying_until { fj("#copy_everything").should be_displayed }

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
      f('#copy_everything').click
      f('#copy_all_quizzes').click if Qti.migration_executable
      f('#copy_folders_I_00001_R_').click
      f('#copy_folders_I_00006_Media_').click
      f('#copy_folders_I_media_R_').click
      f('#copy_modules_I_00000_').click
      f('#copy_topics_I_00009_R_').click
      f('#copy_topics_I_00006_R_').click
      f('#copy_external_tools_I_00010_R_').click
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
      f('#copy_assignments_ibcb9ab84f8045f00a3463e8380003e67_').click
      f('#copy_quizzes_i11ae878a000f370b007a8fe081d0ded9_').click
      f('#copy_files_ic855ab1cf35ada44a34ce4b852b0c0d0_').click
      f('#copy_modules_i2df6315abd91395f682eb5213a9d1220_').click
      f('#copy_topics_i5022718bd70b5298815190094ee482b3_').click
      f('#copy_topics_i2538e409b017a221d89a5f5c3c182605_').click
      f('#copy_assignment_groups_i8adfc688d7d74aa856838cc3333a4849_').click
      f('#copy_assignment_groups_i485520d3863b0e293df4c8f4951ab1e2_').click
      f('#copy_all_wikis').click
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

  it "should load import page for canvas cartridge without any items to select (e.g. only questions)" do
    run_import("canvas_cc_only_questions.zip")

    @course.assessment_questions.count.should == 41
  end
end