require File.expand_path(File.dirname(__FILE__) + '/common')

def visit_page
  @course.reload
  get "/courses/#{@course.id}/content_migrations"
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
    expect(@course.content_migrations.count).to eq count + 1
  end
end

def run_migration(cm=nil)
  cm ||= @course.content_migrations.last
  cm.reload
  cm.skip_job_progress = false
  cm.reset_job_progress
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
  expect(f('.migrationProgressItem .progressStatus')).to include_text("Waiting for select")
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

  expect(f('.migrationProgressItem .progressStatus')).to include_text("Completed")
  expect(@course.assignments.count).to eq(source_course ? source_course.assignments.count : 1)
end

describe "content migrations", :non_parallel do
  include_examples "in-process server selenium tests"

  context "common cartridge importing" do
    before :each do
      course_with_teacher_logged_in
      @type = 'common_cartridge_importer'
      @filename = 'cc_full_test.zip'
    end

    it "should import all content immediately by default" do
      skip('fragile')
      skip unless Qti.qti_enabled?
      visit_page
      fill_migration_form
      ff('[name=selective_import]')[0].click
      submit
      run_migration

      keep_trying_until do
        visit_page
        expect(f('.migrationProgressItem .progressStatus')).to include_text("Completed")
      end

      # From spec/lib/cc/importer/common_cartridge_converter_spec.rb
      expect(@course.attachments.count).to eq 10
      expect(@course.discussion_topics.count).to eq 2
      expect(@course.context_modules.count).to eq 3
      expect(@course.context_external_tools.count).to eq 2
      expect(@course.quizzes.count).to eq 1
      expect(@course.quizzes.first.quiz_questions.count).to eq 11
    end

    it "should show each form" do
      visit_page

      migration_types = ff('#chooseMigrationConverter option').map { |op| op['value'] } - ['none']
      migration_types.each do |type|
        select_migration_type(type)

        keep_trying_until { expect(ffj("input[type=\"submit\"]").any? { |el| el.displayed? }).to eq true }

        select_migration_type('none')
        expect(ff("input[type=\"submit\"]").any? { |el| el.displayed? }).to eq false
      end

      select_migration_type
      cancel_btn = f('#migrationConverterContainer .cancelBtn')
      expect(cancel_btn).to be_displayed
      cancel_btn.click

      expect(f('#migrationFileUpload')).not_to be_present
    end

    it "should submit, queue and list migrations" do
      visit_page
      fill_migration_form
      ff('[name=selective_import]')[0].click
      submit

      expect(ff('.migrationProgressItem').count).to eq 1

      fill_migration_form(:filename => 'cc_ark_test.zip')

      ff('[name=selective_import]')[0].click
      submit

      visit_page
      expect(@course.content_migrations.count).to eq 2

      progress_items = ff('.migrationProgressItem')
      expect(progress_items.count).to eq 2

      source_links = []
      progress_items.each do |item|
        expect(item.find_element(:css, '.migrationName')).to include_text('Common Cartridge')
        expect(item.find_element(:css, '.progressStatus')).to include_text('Queued')

        source_links << item.find_element(:css, '.sourceLink a')
      end

      hrefs = source_links.map { |a| a.attribute(:href) }

      @course.content_migrations.each do |cm|
        expect(hrefs.find { |href| href.include?("/files/#{cm.attachment.id}/download") }).not_to be_nil
      end
    end

    it "should import selective content" do
      skip('fragile')
      skip unless Qti.qti_enabled?
      visit_page
      fill_migration_form
      ff('[name=selective_import]')[1].click
      submit
      run_migration

      test_selective_content
    end

    it "should overwrite quizzes when option is checked and duplicate otherwise" do
      skip('fragile')
      skip unless Qti.qti_enabled?

      # Pre-create the quiz
      q = @course.quizzes.create!(:title => "Name to be overwritten")
      q.migration_id = "QDB_1"
      q.save!

      # Don't overwrite
      visit_page
      fill_migration_form(:type => "qti_converter")
      submit
      run_migration
      expect(@course.quizzes.reload.count).to eq 2
      expect(@course.quizzes.map(&:title).sort).to eq ["Name to be overwritten", "Pretest"]

      # Overwrite original
      visit_page
      fill_migration_form(:type => "qti_converter", :filename => 'cc_full_test.zip')
      f('#overwriteAssessmentContent').click
      submit
      cm = @course.content_migrations.last
      expect(cm.migration_settings["overwrite_quizzes"]).to eq true
      run_migration(cm)
      expect(@course.quizzes.reload.count).to eq 2
      expect(@course.quizzes.map(&:title)).to eq ["Pretest", "Pretest"]
    end

    it "should shift dates" do
      visit_page
      fill_migration_form
      f('#dateAdjustCheckbox').click
      ff('[name=selective_import]')[0].click
      set_value f('#oldStartDate'), '7/1/2014'
      set_value f('#oldEndDate'), 'Jul 11, 2014'
      set_value f('#newStartDate'), '8-5-2014'
      set_value f('#newEndDate'), 'Aug 15, 2014'
      2.times { f('#addDaySubstitution').click }
      click_option('#daySubstitution ul > div:nth-child(1) .currentDay', "1", :value)
      click_option('#daySubstitution ul > div:nth-child(1) .subDay', "2", :value)
      click_option('#daySubstitution ul > div:nth-child(2) .currentDay', "5", :value)
      click_option('#daySubstitution ul > div:nth-child(2) .subDay', "4", :value)
      submit
      opts = @course.content_migrations.last.migration_settings["date_shift_options"]
      expect(opts["shift_dates"]).to eq '1'
      expect(opts["day_substitutions"]).to eq({"1" => "2", "5" => "4"})
      expect(Date.parse(opts["old_start_date"])).to eq Date.new(2014, 7, 1)
      expect(Date.parse(opts["old_end_date"])).to eq Date.new(2014, 7, 11)
      expect(Date.parse(opts["new_start_date"])).to eq Date.new(2014, 8, 5)
      expect(Date.parse(opts["new_end_date"])).to eq Date.new(2014, 8, 15)
    end

    it "should remove dates" do
      skip('fragile')
      visit_page
      fill_migration_form
      f('#dateAdjustCheckbox').click
      f('#dateRemoveOption').click
      ff('[name=selective_import]')[0].click
      submit
      opts = @course.content_migrations.last.migration_settings["date_shift_options"]
      expect(opts["remove_dates"]).to eq '1'
    end

    context "default question bank" do
      it "should import into selected question bank" do
        skip('fragile')
        skip unless Qti.qti_enabled?

        bank = @course.assessment_question_banks.create!(:title => "bankity bank")
        visit_page

        data = File.read(File.dirname(__FILE__) + '/../fixtures/migration/cc_default_qb_test.zip')
        fill_migration_form(:filename => 'cc_default_qb_test.zip', :data => data)

        click_option('.questionBank', bank.id.to_s, :value)
        ff('[name=selective_import]')[0].click

        submit
        run_migration

        keep_trying_until do
          expect(@course.assessment_question_banks.count).to eq 1
          expect(bank.assessment_questions.count).to eq 1
        end
      end

      it "should import into new question bank" do
        skip('fragile')
        skip unless Qti.qti_enabled?

        old_bank = @course.assessment_question_banks.create!(:title => "bankity bank")
        visit_page

        data = File.read(File.dirname(__FILE__) + '/../fixtures/migration/cc_default_qb_test.zip')
        fill_migration_form(:filename => 'cc_default_qb_test.zip', :data => data)

        click_option('.questionBank', 'new_question_bank', :value)

        f('#createQuestionInput').send_keys('new bank naem')

        ff('[name=selective_import]')[0].click
        submit
        run_migration

        expect(@course.assessment_question_banks.count).to eq 2
        new_bank = @course.assessment_question_banks.where(title: 'new bank naem').first
        expect(new_bank.assessment_questions.count).to eq 1
      end

      it "should import into default question bank if not selected" do
        skip('fragile')
        skip unless Qti.qti_enabled?

        old_bank = @course.assessment_question_banks.create!(:title => "bankity bank")
        visit_page

        data = File.read(File.dirname(__FILE__) + '/../fixtures/migration/cc_default_qb_test.zip')
        fill_migration_form(:filename => 'cc_default_qb_test.zip', :data => data)

        click_option('.questionBank', 'new_question_bank', :value)
        click_option('.questionBank', f('.questionBank option').text, :text)

        ff('[name=selective_import]')[0].click
        submit
        run_migration

        expect(@course.assessment_question_banks.count).to eq 2
        new_bank = @course.assessment_question_banks.where(title: AssessmentQuestionBank.default_imported_title).first
        expect(new_bank.assessment_questions.count).to eq 1
      end
    end
  end

  context "course copy" do
    before :all do
      #the "true" param is important, it forces the cache clear
      #  without it this spec group fails if
      #  you run it with the whole suite
      #  because of a cached default account
      #  that no longer exists in the db
      Account.clear_special_account_cache!(true)
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

    it "should show warning before self-copy" do
      visit_page
      select_migration_type
      wait_for_ajaximations

      # drop-down
      click_option('#courseSelect', @course.id.to_s, :value)
      wait_for_ajaximations

      expect(f('#courseSelectWarning')).to be_displayed

      click_option('#courseSelect', @copy_from.id.to_s, :value)
      wait_for_ajaximations

      expect(f('#courseSelectWarning')).to_not be_displayed
    end

    it "should select by drop-down or by search box" do
      visit_page
      select_migration_type
      wait_for_ajaximations

      # drop-down
      expect(f("option[value=\"#{@copy_from.id}\"]")).not_to be_nil

      # search bar
      f('#courseSearchField').send_keys("cop")
      keep_trying_until do
        ui_auto_complete = f('.ui-autocomplete')
        expect(ui_auto_complete).to be_displayed
      end

      el = f('.ui-autocomplete li a')
      divs = ff('div', el)
      expect(divs[0].text).to eq @copy_from.name
      expect(divs[1].text).to eq @copy_from.enrollment_term.name
      el.click

      ff('[name=selective_import]')[0].click
      submit

      cm = @course.content_migrations.last
      expect(cm.migration_settings["source_course_id"]).to eq @copy_from.id
      expect(cm.source_course).to eq @copy_from
      expect(cm.initiated_source).to eq :api

      source_link = f('.migrationProgressItem .sourceLink a')
      expect(source_link.text).to eq @copy_from.name
      expect(source_link['href']).to include("/courses/#{@copy_from.id}")
    end

    it "should only show courses the user is authorized to see" do
      new_course = Course.create!(:name => "please don't see me")
      visit_page
      select_migration_type
      wait_for_ajaximations

      expect(f("option[value=\"#{@copy_from.id}\"]")).not_to be_nil
      expect(f("option[value=\"#{new_course.id}\"]")).to be_nil

      admin_logged_in

      visit_page
      select_migration_type
      wait_for_ajaximations

      expect(f("option[value=\"#{new_course.id}\"]")).not_to be_nil
    end

    it "should include completed courses when checked" do
      new_course = Course.create!(:name => "completed course")
      new_course.enroll_teacher(@user).accept
      new_course.complete!

      visit_page

      select_migration_type
      wait_for_ajaximations

      expect(f("option[value=\"#{new_course.id}\"]")).to be_nil
      f('#include_completed_courses').click
      expect(f("option[value=\"#{new_course.id}\"]")).not_to be_nil
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

      expect(f("option[value=\"#{admin_course.id}\"]")).not_to be_nil
      expect(f("option[value=\"#{enrolled_course.id}\"]")).not_to be_nil
    end

    it "should copy all content from a course" do
      skip unless Qti.qti_enabled?
      visit_page

      select_migration_type
      wait_for_ajaximations

      click_option('#courseSelect', @copy_from.id.to_s, :value)
      ff('[name=selective_import]')[0].click
      submit

      run_migration

      expect(@course.attachments.count).to eq 10
      expect(@course.discussion_topics.count).to eq 2
      expect(@course.context_modules.count).to eq 3
      expect(@course.context_external_tools.count).to eq 2
      expect(@course.quizzes.count).to eq 1
      expect(@course.quizzes.first.quiz_questions.count).to eq 11
    end

    it "should selectively copy content" do
      skip unless Qti.qti_enabled?
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

      f('#dateAdjustCheckbox').click
      3.times do
        f('#addDaySubstitution').click
      end

      expect(ff("#daySubstitution ul > div").count).to eq 3
      f("#daySubstitution ul > div a").click # Remove day substitution
      expect(ff("#daySubstitution ul > div").count).to eq 2

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
      expect(opts["shift_dates"]).to eq '1'
      expect(opts["day_substitutions"]).to eq({"1" => "2", "2" => "3"})
      expected = {
          "old_start_date" => "Jul 1, 2012", "old_end_date" => "Jul 11, 2012",
          "new_start_date" => "Aug 5, 2012", "new_end_date" => "Aug 15, 2012"
      }
      expected.each do |k, v|
        expect(Date.parse(opts[k].to_s)).to eq Date.parse(v)
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

      f('#dateAdjustCheckbox').click
      ff('[name=selective_import]')[0].click

      submit

      opts = @course.content_migrations.last.migration_settings["date_shift_options"]
      expect(opts["shift_dates"]).to eq '1'
      expect(opts["day_substitutions"]).to eq({})
      expected = {
          "old_start_date" => "Jul 1, 2012", "old_end_date" => "Jul 11, 2012",
          "new_start_date" => "Aug 5, 2012", "new_end_date" => "Aug 15, 2012"
      }
      expected.each do |k, v|
        expect(Date.parse(opts[k].to_s)).to eq Date.parse(v)
      end
    end

    it "should remove dates" do
      new_course = Course.create!(:name => "date remove", :start_at => 'Jul 1, 2014', :conclude_at => 'Jul 11, 2014')
      new_course.enroll_teacher(@user).accept

      visit_page
      select_migration_type
      wait_for_ajaximations
      click_option('#courseSelect', new_course.id.to_s, :value)

      f('#dateAdjustCheckbox').click
      f('#dateRemoveOption').click
      ff('[name=selective_import]')[0].click

      submit

      opts = @course.content_migrations.last.migration_settings["date_shift_options"]
      expect(opts["remove_dates"]).to eq '1'
    end
  end

  context "importing LTI content" do
    let(:import_course) {
      account = account_model
      account.enable_feature!(:lor_for_account)
      course_with_teacher_logged_in(:account => account).course
    }
    let(:import_tool) do
      tool = import_course.context_external_tools.new({
                                                          name: "test lti import tool",
                                                          consumer_key: "key",
                                                          shared_secret: "secret",
                                                          url: "http://www.example.com/ims/lti",
                                                      })
      tool.migration_selection = {
          url: "http://#{HostUrl.default_host}/selection_test",
          text: "LTI migration text",
          selection_width: 500,
          selection_height: 500,
          icon_url: "/images/add.png",
      }
      tool.save!
      tool
    end
    let(:other_tool) do
      tool = import_course.context_external_tools.new({
                                                          name: "other lti tool",
                                                          consumer_key: "key",
                                                          shared_secret: "secret",
                                                          url: "http://www.example.com/ims/lti",
                                                      })
      tool.resource_selection = {
          url: "http://#{HostUrl.default_host}/selection_test",
          text: "other resource text",
          selection_width: 500,
          selection_height: 500,
          icon_url: "/images/add.png",
      }
      tool.save!
      tool
    end

    it "should show LTI tools with migration_selection in the select control" do
      import_tool
      other_tool
      visit_page
      migration_type_options = ff('#chooseMigrationConverter option')
      migration_type_values = migration_type_options.map { |op| op['value'] }
      migration_type_texts = migration_type_options.map { |op| op.text }
      expect(migration_type_values).to include(import_tool.asset_string)
      expect(migration_type_texts).to include(import_tool.name)
      expect(migration_type_values).not_to include(other_tool.asset_string)
      expect(migration_type_texts).not_to include(other_tool.name)
    end

    it "should show LTI view when LTI tool selected" do
      import_tool
      visit_page
      select_migration_type(import_tool.asset_string)
      expect(f("#converter .externalToolLaunch")).to be_displayed
      expect(f("#converter .selectContent")).to be_displayed
    end

    it "should launch LTI tool on browse and get content link" do
      import_tool
      visit_page
      select_migration_type(import_tool.asset_string)
      f("button#externalToolLaunch").click
      tool_iframe = keep_trying_until { f(".tool_launch") }
      expect(f('.ui-dialog-title').text).to eq import_tool.label_for(:migration_selection)

      driver.switch_to.frame(tool_iframe)
      keep_trying_until { f("#basic_lti_link") }.click

      driver.switch_to.default_content
      file_name_elt = keep_trying_until { expect(f("#converter .file_name").text).to eq "lti embedded link" }
    end

    it "should have content selection option" do
      import_tool
      visit_page
      select_migration_type(import_tool.asset_string)
      expect(ff('input[name=selective_import]').size).to eq 2
    end
  end
end
