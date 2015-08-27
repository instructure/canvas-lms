# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/outcome_common')

describe "account admin outcomes" do
  include_context "in-process server selenium tests"
  let(:outcome_url) { "/accounts/#{Account.default.id}/outcomes" }
  let(:who_to_login) { 'admin' }
  let(:account) { Account.default }
  describe "state level outcomes" do
    before(:each) do
      course_with_admin_logged_in
      @root_account = Account.site_admin
      account_admin_user(:account => @root_account, :active_all => true)
      @cm = ContentMigration.create(:context => @root_account)
      @plugin = Canvas::Plugin.find('academic_benchmark_importer')
      @cm.converter_class = @plugin.settings['converter_class']
      @cm.migration_settings[:migration_type] = 'academic_benchmark_importer'
      @cm.migration_settings[:import_immediately] = true
      @cm.migration_settings[:base_url] = "http://example.com/"
      @cm.user = @user
      @cm.save!

      @level_0_browse = File.join(File.dirname(__FILE__) + "/../../../gems/plugins/academic_benchmark/spec_canvas/fixtures", 'example.json')
      @authority_list = File.join(File.dirname(__FILE__) + "/../../../gems/plugins/academic_benchmark/spec_canvas/fixtures", 'auth_list.json')
      File.open(@level_0_browse, 'r') do |file|
        @att = Attachment.create!(:filename => 'standards.json', :display_name => 'standards.json', :uploaded_data => file, :context => @cm)
      end
      @cm.attachment = @att
      @cm.save!
    end

    it "should have state standards available for outcomes through find" do
      state_outcome_setup
      goto_state_outcomes
      expect(ffj(".outcome-level:last .outcome-group .ellipsis")[0]).to have_attribute("title", 'NGA Center/CCSSO')
    end

    it "should import state standards to course groups and all nested outcomes" do
      state_outcome_setup
      goto_state_outcomes
      outcome = ['NGA Center/CCSSO', 'Common Core State Standards', 'College- and Career-Readiness Standards and K-12 Mathematics',
                 'First Grade', '1.DD - zééééééééééééééééééééééééééééééééééééééééééééééééé', 'Something else']
      traverse_nested_outcomes(outcome)
      import_account_level_outcomes
      keep_trying_until do
        expect(ffj(".outcome-level:first .outcome-group .ellipsis")[0]).to have_attribute("title", 'Something else')
        expect(ffj(".outcome-level:last .outcome-link .ellipsis")[0]).to have_attribute("title", '1.DD.1')
      end
    end

    it "should delete state standards outcome groups from course listing" do
      state_outcome_setup
      goto_state_outcomes

      outcome = ['NGA Center/CCSSO', 'Common Core State Standards', 'College- and Career-Readiness Standards and K-12 Mathematics',
                 'First Grade', '1.DD - zééééééééééééééééééééééééééééééééééééééééééééééééé', 'Something else']
      traverse_nested_outcomes(outcome)

      import_account_level_outcomes

      f(".ellipsis[title='Something else']").click
      wait_for_ajaximations

      keep_trying_until do
        f('.delete_button').click
        expect(driver.switch_to.alert).not_to be nil
        driver.switch_to.alert.accept
        refresh_page
        wait_for_ajaximations
        expect(ffj('.outcomes-sidebar .outcome-level:first li')).to be_empty
      end
      expect(f('.outcomes-content .title').text).to eq 'Setting up Outcomes'
    end

    describe "state standard pagination" do
      it "should not fail while filtering the common core group" do
        # setup fake state data, so that it has to paginate
        root_group = LearningOutcomeGroup.global_root_outcome_group
        fake_cc = root_group.child_outcome_groups.create!(:title => "Fake Common Core")
        11.times { root_group.child_outcome_groups.create!(:title => "G is after F") }
        last_group = root_group.child_outcome_groups.create!(:title => "Z is last")
        Setting.set(AcademicBenchmark.common_core_setting_key, fake_cc.id.to_s)

        # go to the find panel
        get outcome_url
        wait_for_ajaximations
        f('.find_outcome').click
        wait_for_ajaximations

        # click on state standards
        top_level_groups = ff(".outcome-level .outcome-group")
        expect(top_level_groups.count).to eq 3
        top_level_groups[1].click
        wait_for_ajaximations

        # make sure the last one is the Z guy
        keep_trying_until do
          expect(ffj(".outcome-level:last .outcome-group .ellipsis").last).to have_attribute("title", 'Z is last')
        end
      end
    end
  end
end