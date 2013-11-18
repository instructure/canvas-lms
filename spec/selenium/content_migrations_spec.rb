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

  f('.migrationProgressItem .progressStatus').should include_text("Waiting for select")
  f('.migrationProgressItem .selectContentBtn').click
  wait_for_ajaximations

  topic_id = "I_00009_R"
  att_ids = ["I_00003_R_IMAGERESOURCE", "6a35b0974f59819404dc86d48fe39fc3", "7acb90d1653008e73753aa2cafb16298", "f5",
             "8612e3db71e452d5d2952ff64647c0d8", "f4", "f3", "I_media_R", "I_00006_Media", "I_00001_R"]
  # these attachments are inside the folder we'll deselect
  selected_att_ids = att_ids - ["6a35b0974f59819404dc86d48fe39fc3", "7acb90d1653008e73753aa2cafb16298", "I_00003_R_IMAGERESOURCE"]

  folder_name = "I_00003_R"
  tool_ids = ["I_00010_R", "I_00011_R"]

  if source_course
    topic_id = CC::CCHelper.create_key(source_course.discussion_topics.find_by_migration_id(topic_id))
    att_ids = att_ids.map{|id| CC::CCHelper.create_key(source_course.attachments.find_by_migration_id(id))}
    selected_att_ids = selected_att_ids.map{|id| CC::CCHelper.create_key(source_course.attachments.find_by_migration_id(id))}
    tool_ids = tool_ids.map{|id| CC::CCHelper.create_key(source_course.context_external_tools.find_by_migration_id(id))}
    folder_name = source_course.folders.find_by_name(folder_name).full_name
  end

  boxes_to_click = [
      ["copy[all_context_modules]", false],
      ["copy[all_quizzes]", false],
      ["copy[all_discussion_topics]", false],
      ["copy[discussion_topics][id_#{topic_id}]", true],
      ["copy[all_context_external_tools]", false],
      ["copy[discussion_topics][id_#{topic_id}]", false], # deselect
      ["copy[all_attachments]", false]
  ]
  boxes_to_click += att_ids.map{|id| ["copy[attachments][id_#{id}]", true]}

  # directly click checkboxes
  boxes_to_click.each do |name, value|
    keep_trying_until do
      escaped_name = name.gsub("[", "\\[").gsub("]", "\\]")
      selector = ".selectContentDialog input[name=\"#{escaped_name}\"]"
      box = f(selector)
      selector = selector.gsub("\"", "\\\"")
      box.should_not be_nil
      set_value(box, value)
      wait_for_ajaximations
      is_checked(selector).should == value
    end
  end

  # click on select all for external tools
  suffix = f(".selectContentDialog input[name=\"copy[all_context_external_tools]\"]")["id"].split('-')[1] #checkbox-viewXX -> viewXX
  all_link = f(".selectContentDialog .showHide #selectAll-#{suffix}")
  all_link.text.should == "Select All"
  all_link.click

  # click on select none for folder
  none_link = ff('.selectContentDialog .showHide a:last-child').last
  none_link.text.should == "Select None"
  none_link.click

  expected_params = {
      "all_assignments" => "1",
      "context_external_tools" => {tool_ids[0] => "1", tool_ids[1] => "1"},
      "attachments" => {}
  }
  selected_att_ids.each{|id| expected_params["attachments"][id] = "1"}
  if source_course
    expected_params.merge!({"all_course_settings" => "1", "all_syllabus_body" => "1", "all_assessment_question_banks" => "1"})
  end

  f(".selectContentDialog input[type=submit]").click
  wait_for_ajaximations

  cm = @course.content_migrations.last

  cm.migration_settings[:migration_ids_to_import][:copy].should == expected_params
  cm.migration_settings[:copy_options].should == expected_params

  if source_course
    run_migration
  else
    import
  end
  visit_page

  f('.migrationProgressItem .progressStatus').should include_text("Completed")

  @course.context_modules.count.should == 0
  @course.assignments.count.should == 1
  @course.quizzes.count.should == 0
  @course.discussion_topics.count.should == 0
  @course.context_external_tools.count.should == 2
  @course.attachments.map(&:migration_id).sort.should == selected_att_ids.sort
end

describe "content migrations" do
  it_should_behave_like "in-process server selenium tests"

  context "common cartridge importing" do
    before :each do
      course_with_teacher_logged_in
      @type = 'common_cartridge_importer'
      @filename = 'cc_full_test.zip'
    end

    it "should show each form" do
      visit_page

      migration_types = ff('#chooseMigrationConverter option').map{|op| op['value']} - ['none']
      migration_types.each do |type|
        select_migration_type(type)
        wait_for_ajaximations
        ff("input[type=\"submit\"]").any?{|el| el.displayed?}.should == true

        select_migration_type('none')
        ff("input[type=\"submit\"]").any?{|el| el.displayed?}.should == false
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
      submit

      ff('.migrationProgressItem').count.should == 1

      fill_migration_form(:filename => 'cc_ark_test.zip')
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

      hrefs = source_links.map{|a| a.attribute(:href)}

      @course.content_migrations.each do |cm|
        hrefs.find{|href| href.include?("/files/#{cm.attachment.id}/download")}.should_not be_nil
      end
    end

    it "should import all content immediately by default" do
      pending unless Qti.qti_enabled?
      visit_page
      fill_migration_form
      submit
      run_migration

      visit_page
      f('.migrationProgressItem .progressStatus').should include_text("Completed")

      # From spec/lib/cc/importer/common_cartridge_converter_spec.rb
      @course.attachments.count.should == 10
      @course.discussion_topics.count.should == 2
      @course.context_modules.count.should == 3
      @course.context_external_tools.count.should == 2
      @course.quizzes.count.should == 1
      @course.quizzes.first.quiz_questions.count.should == 11
    end

    it "should import selective content" do
      pending unless Qti.qti_enabled?
      visit_page
      fill_migration_form
      f('#selectContentCheckbox').click
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
      @copy_from = course_model(:name => "copy from me")
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

      @type = "course_copy_importer"
    end

    before :each do
      course_with_teacher_logged_in(:active_all => true)
      @copy_from.enroll_teacher(@user).accept
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

      submit

      cm = @course.content_migrations.last
      cm.migration_settings["source_course_id"].should == @copy_from.id.to_s

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

    it "should copy all content from a course by default" do
      pending unless Qti.qti_enabled?
      visit_page

      select_migration_type
      wait_for_ajaximations

      click_option('#courseSelect', @copy_from.id.to_s, :value)
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
      f('#selectContentCheckbox').click
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
