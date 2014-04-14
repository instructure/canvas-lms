require File.expand_path(File.dirname(__FILE__) + '/common')

def visit_page
  @course.reload
  get "/courses/#{@course.id}/content_migrations"
  wait_for_ajaximations
end

def select_migration_type(type=nil)
  type ||= @type
  click_option('#chooseMigrationConverter', type, :value)
end

def select_migration_file(opts={})
  filename = opts[:filename] || @filename

  new_filename, fullpath, data = get_file(filename, opts[:data])
  f('#migrationFileUpload').send_keys(fullpath)
  return new_filename
end

def fill_migration_form(opts={})
  select_migration_type('none') unless opts[:type] == 'none'
  select_migration_type(opts[:type])
  select_migration_file(opts)
end

def submit
  @course.reload
  count = @course.content_migrations.count

  driver.execute_script("$('#migrationConverterContainer').submit()")
  keep_trying_until do
    @course.content_migrations.count.should == count + 1
  end
  wait_for_ajaximations
end

def run_migration(cm=nil)
  cm ||= @course.content_migrations.last
  cm.reload
  worker_class = Canvas::Migration::Worker.const_get(Canvas::Plugin.find(cm.migration_type).settings['worker'])
  worker_class.new(cm.id).perform
end

def import(cm=nil)
  cm ||= @course.content_migrations.last
  cm.reload
  cm.set_default_settings
  cm.import_content
end

def test_selective_content(source_course=nil)
  visit_page

  # Open selective dialog
  f('.migrationProgressItem .progressStatus').should include_text("Waiting for select")
  f('.migrationProgressItem .selectContentBtn').click
  wait_for_ajaximations

  f('input[name="copy[all_assignments]"]').click

  # Submit selection
  f(".selectContentDialog input[type=submit]").click
  wait_for_ajaximations


  if source_course
    run_migration
  else
    import
  end

  visit_page

  f('.migrationProgressItem .progressStatus').should include_text("Completed")
  @course.assignments.count.should == 1
end

describe "content migrations" do
  include_examples "in-process server selenium tests"

  context "common cartridge importing" do
    before :each do
      course_with_teacher_logged_in
      @type = 'common_cartridge_importer'
      @filename = 'cc_full_test.zip'
    end

    it "should import all content immediately by default" do
      pending unless Qti.qti_enabled?
      visit_page
      fill_migration_form
      ff('[name=selective_import]')[0].click
      submit
      run_migration

      keep_trying_until do
        visit_page
        f('.migrationProgressItem .progressStatus').should include_text("Completed")
      end

      # From spec/lib/cc/importer/common_cartridge_converter_spec.rb
      @course.attachments.count.should == 10
      @course.discussion_topics.count.should == 2
      @course.context_modules.count.should == 3
      @course.context_external_tools.count.should == 2
      @course.quizzes.count.should == 1
      @course.quizzes.first.quiz_questions.count.should == 11
    end

    it "should show each form" do
      visit_page

      migration_types = ff('#chooseMigrationConverter option').map { |op| op['value'] } - ['none']
      migration_types.each do |type|
        select_migration_type(type)
        wait_for_ajaximations
        ff("input[type=\"submit\"]").any? { |el| el.displayed? }.should == true

        select_migration_type('none')
        ff("input[type=\"submit\"]").any? { |el| el.displayed? }.should == false
      end

      select_migration_type
      cancel_btn = f('#migrationConverterContainer .cancelBtn')
      cancel_btn.should be_displayed
      cancel_btn.click

      f('#migrationFileUpload').should_not be_present
    end

    it "should submit, queue and list migrations" do
      visit_page
      fill_migration_form
      ff('[name=selective_import]')[0].click
      submit

      ff('.migrationProgressItem').count.should == 1

      fill_migration_form(:filename => 'cc_ark_test.zip')

      ff('[name=selective_import]')[0].click
      submit

      visit_page
      @course.content_migrations.count.should == 2

      progress_items = ff('.migrationProgressItem')
      progress_items.count.should == 2

      source_links = []
      progress_items.each do |item|
        item.find_element(:css, '.migrationName').should include_text('Common Cartridge')
        item.find_element(:css, '.progressStatus').should include_text('Queued')

        source_links << item.find_element(:css, '.sourceLink a')
      end

      hrefs = source_links.map { |a| a.attribute(:href) }

      @course.content_migrations.each do |cm|
        hrefs.find { |href| href.include?("/files/#{cm.attachment.id}/download") }.should_not be_nil
      end
    end

    it "should import selective content" do
      pending unless Qti.qti_enabled?
      visit_page
      fill_migration_form
      ff('[name=selective_import]')[1].click
      submit
      run_migration

      test_selective_content
    end

    it "should overwrite quizzes when option is checked and duplicate otherwise" do
      pending unless Qti.qti_enabled?

      # Pre-create the quiz
      q = @course.quizzes.create!(:title => "Name to be overwritten")
      q.migration_id = "QDB_1"
      q.save!

      # Don't overwrite
      visit_page
      fill_migration_form(:type => "qti_converter")
      submit
      run_migration
      @course.quizzes.reload.count.should == 2
      @course.quizzes.map(&:title).sort.should == ["Name to be overwritten", "Pretest"]

      # Overwrite original
      visit_page
      fill_migration_form(:type => "qti_converter", :filename => 'cc_full_test.zip')
      f('#overwriteAssessmentContent').click
      submit
      cm = @course.content_migrations.last
      cm.migration_settings["overwrite_quizzes"].should == true
      run_migration(cm)
      @course.quizzes.reload.count.should == 2
      @course.quizzes.map(&:title).should == ["Pretest", "Pretest"]
    end

    context "default question bank" do
      it "should import into selected question bank" do
        pending unless Qti.qti_enabled?

        bank = @course.assessment_question_banks.create!(:title => "bankity bank")
        visit_page

        data = File.read(File.dirname(__FILE__) + '/../fixtures/migration/cc_default_qb_test.zip')
        fill_migration_form(:filename => 'cc_default_qb_test.zip', :data => data)

        click_option('.questionBank', bank.id.to_s, :value)
        ff('[name=selective_import]')[0].click

        submit
        run_migration

        @course.assessment_question_banks.count.should == 1
        bank.assessment_questions.count.should == 1
      end

      it "should import into new question bank" do
        pending unless Qti.qti_enabled?

        old_bank = @course.assessment_question_banks.create!(:title => "bankity bank")
        visit_page

        data = File.read(File.dirname(__FILE__) + '/../fixtures/migration/cc_default_qb_test.zip')
        fill_migration_form(:filename => 'cc_default_qb_test.zip', :data => data)

        click_option('.questionBank', 'new_question_bank', :value)

        f('#createQuestionInput').send_keys('new bank naem')

        ff('[name=selective_import]')[0].click
        submit
        run_migration

        @course.assessment_question_banks.count.should == 2
        new_bank = @course.assessment_question_banks.find_by_title('new bank naem')
        new_bank.assessment_questions.count.should == 1
      end

      it "should import into default question bank if not selected" do
        pending unless Qti.qti_enabled?

        old_bank = @course.assessment_question_banks.create!(:title => "bankity bank")
        visit_page

        data = File.read(File.dirname(__FILE__) + '/../fixtures/migration/cc_default_qb_test.zip')
        fill_migration_form(:filename => 'cc_default_qb_test.zip', :data => data)

        click_option('.questionBank', 'new_question_bank', :value)
        click_option('.questionBank', f('.questionBank option').text, :text)

        ff('[name=selective_import]')[0].click
        submit
        run_migration

        @course.assessment_question_banks.count.should == 2
        new_bank = @course.assessment_question_banks.find_by_title(AssessmentQuestionBank.default_imported_title)
        new_bank.assessment_questions.count.should == 1
      end
    end
  end

  context "course copy" do
    before :all do
      Account.clear_special_account_cache!
      @copy_from = course
      @copy_from.update_attribute(:name, 'copy from me')
      data = File.read(File.dirname(__FILE__) + '/../fixtures/migration/cc_full_test.zip')

      cm = ContentMigration.new(:context => @copy_from, :migration_type => "common_cartridge_importer")
      cm.migration_settings = {:import_immediately => true,
                               :migration_ids_to_import => {:copy => {:everything => true}}}
      cm.skip_job_progress = true
      cm.save!

      att = attachment_model(:context => cm, :filename => "cc_full_test.zip",
                             :uploaded_data => stub_file_data("cc_full_test.zip", data, "application/zip"))
      cm.attachment = att
      cm.save!

      worker_class = Canvas::Migration::Worker.const_get(Canvas::Plugin.find(cm.migration_type).settings['worker'])
      worker_class.new(cm.id).perform

      @course = nil
      @type = "course_copy_importer"
    end

    before :each do
      course_with_teacher_logged_in(:active_all => true)
      @copy_from.enroll_teacher(@user).accept
    end

    after :all do
      truncate_all_tables
    end

    it "should select by drop-down or by search box" do
      visit_page
      select_migration_type
      wait_for_ajaximations

      # drop-down
      f("option[value=\"#{@copy_from.id}\"]").should_not be_nil

      # search bar
      f('#courseSearchField').send_keys("cop")
      keep_trying_until do
        ui_auto_complete = f('.ui-autocomplete')
        ui_auto_complete.should be_displayed
      end

      el = f('.ui-autocomplete li a')
      el.text.should == @copy_from.name
      el.click

      ff('[name=selective_import]')[0].click
      submit

      cm = @course.content_migrations.last
      cm.migration_settings["source_course_id"].should == @copy_from.id

      source_link = f('.migrationProgressItem .sourceLink a')
      source_link.text.should == @copy_from.name
      source_link['href'].should include("/courses/#{@copy_from.id}")
    end

    it "should only show courses the user is authorized to see" do
      new_course = Course.create!(:name => "please don't see me")
      visit_page
      select_migration_type
      wait_for_ajaximations

      f("option[value=\"#{@copy_from.id}\"]").should_not be_nil
      f("option[value=\"#{new_course.id}\"]").should be_nil

      admin_logged_in

      visit_page
      select_migration_type
      wait_for_ajaximations

      f("option[value=\"#{new_course.id}\"]").should_not be_nil
    end

    it "should include completed courses when checked" do
      new_course = Course.create!(:name => "completed course")
      new_course.enroll_teacher(@user).accept
      new_course.complete!

      visit_page

      select_migration_type
      wait_for_ajaximations

      f("option[value=\"#{new_course.id}\"]").should be_nil
      f('#include_completed_courses').click
      f("option[value=\"#{new_course.id}\"]").should_not be_nil
    end

    it "should find courses in other accounts" do
      new_account1 = account_model
      enrolled_course = Course.create!(:name => "faraway course", :account => new_account1)
      enrolled_course.enroll_teacher(@user).accept

      new_account2 = account_model
      admin_course = Course.create!(:name => "another course", :account => new_account2)
      account_admin_user(:user => @user, :account => new_account2)

      visit_page

      select_migration_type
      wait_for_ajaximations

      f("option[value=\"#{admin_course.id}\"]").should_not be_nil
      f("option[value=\"#{enrolled_course.id}\"]").should_not be_nil
    end

    it "should copy all content from a course" do
      pending unless Qti.qti_enabled?
      visit_page

      select_migration_type
      wait_for_ajaximations

      click_option('#courseSelect', @copy_from.id.to_s, :value)
      ff('[name=selective_import]')[0].click
      submit

      run_migration

      @course.attachments.count.should == 10
      @course.discussion_topics.count.should == 2
      @course.context_modules.count.should == 3
      @course.context_external_tools.count.should == 2
      @course.quizzes.count.should == 1
      @course.quizzes.first.quiz_questions.count.should == 11
    end

    it "should selectively copy content" do
      pending unless Qti.qti_enabled?
      visit_page

      select_migration_type
      wait_for_ajaximations

      click_option('#courseSelect', @copy_from.id.to_s, :value)
      ff('[name=selective_import]')[1].click
      submit

      test_selective_content(@copy_from)
    end

    it "should set day substitution and date adjustment settings" do
      new_course = Course.create!(:name => "day sub")
      new_course.enroll_teacher(@user).accept

      visit_page
      select_migration_type
      wait_for_ajaximations
      click_option('#courseSelect', new_course.id.to_s, :value)

      f('#dateShiftCheckbox').click
      3.times do
        f('#addDaySubstitution').click
      end

      ff("#daySubstitution ul > div").count.should == 3
      f("#daySubstitution ul > div a").click # Remove day substitution
      ff("#daySubstitution ul > div").count.should == 2

      click_option('#daySubstitution ul > div:nth-child(1) .currentDay', "1", :value)
      click_option('#daySubstitution ul > div:nth-child(1) .subDay', "2", :value)

      click_option('#daySubstitution ul > div:nth-child(2) .currentDay', "2", :value)
      click_option('#daySubstitution ul > div:nth-child(2) .subDay', "3", :value)

      f('#oldStartDate').send_keys('7/1/2012')
      f('#oldEndDate').send_keys('Jul 11, 2012')
      f('#newStartDate').clear
      f('#newStartDate').send_keys('8-5-2012')
      f('#newEndDate').send_keys('Aug 15, 2012')

      ff('[name=selective_import]')[0].click
      submit

      opts = @course.content_migrations.last.migration_settings["date_shift_options"]
      opts["day_substitutions"].should == {"1" => "2", "2" => "3"}
      expected = {
          "old_start_date" => "Jul 1, 2012", "old_end_date" => "Jul 11, 2012",
          "new_start_date" => "Aug 5, 2012", "new_end_date" => "Aug 15, 2012"
      }
      expected.each do |k, v|
        Date.parse(opts[k].to_s).should == Date.parse(v)
      end
    end

    it "should set pre-populate date adjustment settings" do
      new_course = Course.create!(:name => "date adjust", :start_at => 'Jul 1, 2012', :conclude_at => 'Jul 11, 2012')
      new_course.enroll_teacher(@user).accept

      @course.start_at = 'Aug 5, 2012'
      @course.conclude_at = 'Aug 15, 2012'
      @course.save!

      visit_page
      select_migration_type
      wait_for_ajaximations
      click_option('#courseSelect', new_course.id.to_s, :value)

      f('#dateShiftCheckbox').click
      ff('[name=selective_import]')[0].click

      submit

      opts = @course.content_migrations.last.migration_settings["date_shift_options"]
      opts["day_substitutions"].should == {}
      expected = {
          "old_start_date" => "Jul 1, 2012", "old_end_date" => "Jul 11, 2012",
          "new_start_date" => "Aug 5, 2012", "new_end_date" => "Aug 15, 2012"
      }
      expected.each do |k, v|
        Date.parse(opts[k].to_s).should == Date.parse(v)
      end
    end
  end
end
