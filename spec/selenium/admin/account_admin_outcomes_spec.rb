require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/outcome_specs')

describe "account admin outcomes" do
  describe "shared outcome specs" do
    let(:outcome_url) { "/accounts/#{Account.default.id}/outcomes" }
    let(:who_to_login) { 'admin' }
    let(:account) { Account.default }
    it_should_behave_like "outcome tests"

    describe "find/import dialog" do
      it "should not allow importing top level groups" do
        get outcome_url
        wait_for_ajaximations

        f('.find_outcome').click
        wait_for_ajaximations
        groups = ff('.outcome-group')
        groups.size.should == 2
        groups.each do |g|
          g.click
          f('.ui-dialog-buttonpane .btn-primary').should_not be_displayed
        end
      end
    end

    describe "state level outcomes" do
      before(:each) do
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

        @level_0_browse = File.join(File.dirname(__FILE__) + "/../../../vendor/plugins/academic_benchmark/spec_canvas/fixtures", 'example.json')
        @authority_list = File.join(File.dirname(__FILE__) + "/../../../vendor/plugins/academic_benchmark/spec_canvas/fixtures", 'auth_list.json')
        File.open(@level_0_browse, 'r') do |file|
          @att = Attachment.create!(:filename => 'standards.json', :display_name => 'standards.json', :uploaded_data => file, :context => @cm)
        end
        @cm.attachment = @att
        @cm.save!
      end

      it "should have state standards available for outcomes through find" do
        state_outcome_setup
        goto_state_outcomes
        ffj(".outcome-level:last .outcome-group .ellipsis")[0].should have_attribute("title", 'NGA Center/CCSSO')
      end

      it "should import state standards to course groups and all nested outcomes" do
        state_outcome_setup
        goto_state_outcomes
        outcome = ['NGA Center/CCSSO', 'Common Core State Standards', 'College- and Career-Readiness Standards and K-12 Mathematics', 'First Grade', '1.DD - Something', 'Something else']
        traverse_nested_outcomes(outcome)
        import_account_level_outcomes
        keep_trying_until do
          ffj(".outcome-level:first .outcome-group .ellipsis")[0].should have_attribute("title", 'Something else')
          ffj(".outcome-level:last .outcome-link .ellipsis")[0].should have_attribute("title", '1.DD.1')
        end
      end

      it "should delete state standards outcome groups from course listing" do
        state_outcome_setup
        goto_state_outcomes

        outcome = ['NGA Center/CCSSO', 'Common Core State Standards', 'College- and Career-Readiness Standards and K-12 Mathematics', 'First Grade', '1.DD - Something', 'Something else']
        traverse_nested_outcomes(outcome)

        import_account_level_outcomes

        f(".ellipsis[title='Something else']").click
        wait_for_ajaximations

        keep_trying_until do
          f('.delete_button').click
          driver.switch_to.alert.should_not be nil
          driver.switch_to.alert.accept
          refresh_page
          wait_for_ajaximations
          ffj('.outcomes-sidebar .outcome-level:first li').should be_empty
        end

        f('.outcomes-content .title').text.should == 'Setting up Outcomes'
      end
    end
  end
end