# encoding: utf-8
#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/outcome_common')

describe "account admin outcomes" do
  include_examples "in-process server selenium tests"
  include OutcomeCommon

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

    def import_state_standards_to_account(outcome)
      state_outcome_setup
      goto_state_outcomes
      traverse_nested_outcomes(outcome)
      import_account_level_outcomes
    end

    it "should have state standards available for outcomes through find", priority: "2", test_id: 250008 do
      state_outcome_setup
      goto_state_outcomes
      expect(ffj(".outcome-level:last .outcome-group .ellipsis")[0]).to have_attribute("title", 'NGA Center/CCSSO')
    end

    it "should import state standards to course groups and all nested outcomes", priority: "2", test_id: 56584 do
      skip_if_safari(:alert)
      import_state_standards_to_account(state_outcome)
      el1 = fj(".outcome-level:first .outcome-group .ellipsis")
      el2 = fj(".outcome-level:last .outcome-link .ellipsis")
      expect(el1).to have_attribute("title", 'Something else')
      expect(el2).to have_attribute("title", '1.DD.1')
    end

    it "should import a state standard into account level", priority: "2", test_id: 56017 do
      skip_if_safari(:alert)
      outcome = ['NGA Center/CCSSO']
      import_state_standards_to_account(outcome)
      el = fj('.outcome-level:first .outcome-group .ellipsis')
      expect(el).to have_attribute("title", 'NGA Center/CCSSO')
    end

    it "should import account outcomes into course", priority: "1", test_id: 56585 do
      skip_if_safari(:alert)
      import_state_standards_to_account(state_outcome)
      outcome = ['Default Account', 'Something else']
      goto_state_outcomes("/courses/#{@course.id}/outcomes")
      traverse_nested_outcomes(outcome)
      import_account_level_outcomes
    end

    it "should delete state standards outcome groups from course listing", priority: "2", test_id: 250009 do
      skip_if_safari(:alert)
      import_state_standards_to_account(state_outcome)
      f(".ellipsis[title='Something else']").click
      wait_for_ajaximations

      f('.delete_button').click
      expect(driver.switch_to.alert).not_to be nil
      driver.switch_to.alert.accept
      refresh_page
      wait_for_ajaximations
      # validations
      expect(f('.outcomes-sidebar')).not_to contain_jqcss('.outcome-level:first li')
      expect(f('.outcomes-content .title').text).to eq 'Setting up Outcomes'
    end

    describe "state standard pagination" do
      it "should not fail while filtering the common core group", priority: "2", test_id: 250010 do
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
        last_el = ffj(".outcome-level:last .outcome-group .ellipsis").last
        expect(last_el).to have_attribute("title", 'Z is last')
      end
    end
  end
end
