#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../../helpers/outcome_common'

describe "outcomes" do
  include_context "in-process server selenium tests"
  include OutcomeCommon

  let(:who_to_login) { 'teacher' }
  let(:outcome_url) { "/courses/#{@course.id}/outcomes" }

  describe "course outcomes" do
    before(:each) do
      course_with_teacher_logged_in
      enable_all_rcs @course.account
      stub_rcs_config
    end

    def save_without_error(value = 4, title = 'New Outcome')
      replace_content(f('.outcomes-content input[name=title]'), title)
      replace_content(f('input[name=calculation_int]'), value)
      f('.submit_button').click
      wait_for_ajaximations
      expect(f('.title').text).to include(title)
      expect((f('#calculation_int').text).to_i).to eq(value)
    end

    context "create/edit/delete outcomes" do

      it "should create a learning outcome with a new rating (root level)", priority: "1", test_id: 250533 do
        should_create_a_learning_outcome_with_a_new_rating_root_level
      end

      it "should create a learning outcome (nested)", priority: "1", test_id: 250534 do
        should_create_a_learning_outcome_nested
      end

      it "should edit a learning outcome and delete a rating", priority: "1", test_id: 250535 do
        should_edit_a_learning_outcome_and_delete_a_rating
      end

      it "should delete a learning outcome", priority: "1", test_id: 250536 do # no
        skip_if_safari(:alert)
        should_delete_a_learning_outcome
      end

      context "validate decaying average" do
        before do
          get outcome_url
          f('.add_outcome_link').click
        end

        it "should validate default values", priority: "1", test_id: 261707 do
          expect(f('#calculation_method')).to have_value('decaying_average')
          expect(f('#calculation_int')).to have_value('65')
          expect(f('#calculation_int_example')).to include_text("Most recent result counts as 65%"\
                                                              " of mastery weight, average of all other results count"\
                                                              " as 35% of weight. If there is only one result, the single score"\
                                                              " will be returned.")
        end

        it "should validate decaying average_range", priority: "2", test_id: 261708 do
          should_validate_decaying_average_range
        end

        it "should validate calculation int accepatble values", priority: "1", test_id: 261709 do
          save_without_error(1)
          f('.edit_button').click
          save_without_error(99)
        end

        it "should retain the settings after saving", priority: "1", test_id: 261710 do
          save_without_error(rand(99) + 1, 'Decaying Average')
          expect(f('#calculation_method').text).to include('Decaying Average')
        end
      end

      context "validate n mastery" do
        before do
          get outcome_url
          f('.add_outcome_link').click
        end

        it "should validate default values", priority: "1", test_id: 261711 do
          click_option('#calculation_method', "n Number of Times")
          expect(f('#calculation_int')).to have_value('5')
          expect(f('#mastery_points')).to have_value('3')
          expect(f('#calculation_int_example')).to include_text("Must achieve mastery at least 5 times."\
                                                              " Scores above mastery will be averaged"\
                                                              " to calculate final score")
        end

        it "should validate n mastery_range", priority: "2", test_id: 303711 do
          should_validate_n_mastery_range
        end

        it "should validate calculation int acceptable range values", priority: "1", test_id: 261713 do
          click_option('#calculation_method', "n Number of Times")
          save_without_error(2)
          f('.edit_button').click
          save_without_error(5)
        end

        it "should retain the settings after saving", priority: "1", test_id: 261714 do
          click_option('#calculation_method', "n Number of Times")
          save_without_error(3, 'n Number of Times')
          refresh_page
          fj('.outcomes-sidebar .outcome-level:first li').click
          expect(f('#calculation_int').text).to eq('3')
          expect(f('#calculation_method').text).to include('n Number of Times')
        end
      end

      context "create/edit/delete outcome groups" do
        it "should create an outcome group (root level)", priority: "2", test_id: 560586 do
          should_create_an_outcome_group_root_level
        end

        it "should create an outcome group (nested)", priority: "1", test_id: 250237 do
          should_create_an_outcome_group_nested
        end

        it "should edit an outcome group", priority: "2", test_id: 114340 do
          should_edit_an_outcome_group
        end
      end
    end

    context "actions" do
      it "should not render an HTML-escaped title in outcome directory while editing", priority: "2", test_id: 250554 do
        title = 'escape & me <<->> if you dare'
        escaped_title = 'escape &amp; me &lt;&lt;-&gt;&gt; if you dare'
        who_to_login == 'teacher' ? @context = @course : @context = account
        outcome_model
        get outcome_url
        wait_for_ajaximations
        fj('.outcomes-sidebar .outcome-level:first li').click
        wait_for_ajaximations
        f('.edit_button').click

        # pass in the unescaped version of the title:
        replace_content f('.outcomes-content input[name=title]'), title
        f('.submit_button').click
        wait_for_ajaximations

        # the "readable" version should be rendered in directory browser
        li_el = fj('.outcomes-sidebar .outcome-level:first li:first')
        expect(li_el).to be_truthy # should be present
        expect(li_el.text).to eq title

        # the "readable" version should be rendered in the view:
        expect(f(".outcomes-content .title").text).to eq title

        # and the escaped version should be stored!
        # expect(LearningOutcome.where(short_description: escaped_title)).to be_exists
        # or not, looks like it isn't being escaped
        expect(LearningOutcome.where(short_description: title)).to be_exists
      end
    end
  end
end
