# frozen_string_literal: true

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

require_relative "cc_spec_helper"
require_relative "../../lti2_course_spec_helper"

require "nokogiri"

describe "Learning Outcome exporting" do
  include WebMock::API

  before :once do
    course_with_teacher(active_all: true)
    @ce = @course.content_exports.build
    @ce.export_type = ContentExport::COMMON_CARTRIDGE
    @ce.user = @user
    @ce.save!
  end

  after do
    if @file_handle && File.exist?(@file_handle.path)
      FileUtils.rm(@file_handle.path)
    end
  end

  def run_export(opts = {})
    @ce.export(opts, synchronous: true)
    expect(@ce.error_messages).to eq []
    @file_handle = @ce.attachment.open
    @zip_file = Zip::File.open(@file_handle.path)
  end

  context "account level learning outcomes" do
    before :once do
      outcome_model(context: @course, outcome_context: @course.account)
      assessment_question_bank_model
      @bank.alignments = { @outcome.id => 0.5 }
      @bank.reload
    end

    it "only exports alignments for the current course on account level outcomes" do
      course_factory
      @course.root_outcome_group.add_outcome(@outcome)
      assessment_question_bank_model
      @bank.alignments = { @outcome.id => 0.5 }
      @bank.reload
      run_export
      doc = Nokogiri::XML.parse(@zip_file.read("course_settings/learning_outcomes.xml"))
      expect(doc.css("alignment").count).to eq 1
    end
  end

  context "with selectable_outcomes_in_course_copy enabled" do
    before do
      @course.root_account.enable_feature!(:selectable_outcomes_in_course_copy)
    end

    after do
      @course.root_account.disable_feature!(:selectable_outcomes_in_course_copy)
      @ce.selected_content = nil
    end

    it "exports a single group and all its contents" do
      @context = @course
      source_group = outcome_group_model(title: "source group")
      group1 = outcome_group_model(title: "alpha")
      group2 = outcome_group_model(
        outcome_group_id: group1.id,
        title: "subgroup",
        source_outcome_group_id: source_group.id
      )
      outcome1 = outcome_model(outcome_group: group2, title: "thing1")
      outcome2 = outcome_model(outcome_group: group2, title: "thing2")
      outcome_model(title: "thing3")
      @ce.selected_content = {
        "learning_outcome_groups" => {
          @ce.create_key(group2) => "1"
        }
      }
      run_export
      doc = Nokogiri::XML.parse(@zip_file.read("course_settings/learning_outcomes.xml"))
      # for shorter xpath queries
      doc.remove_namespaces!
      # No root outcomes were selected for export
      expect(doc.xpath("/learningOutcomes/learningOutcome")).to be_empty
      # Only one group was exported
      expect(doc.xpath("/learningOutcomes/learningOutcomeGroup").count).to eq 1
      # ... and its the "subgroup" group
      group_titles = doc.xpath("/learningOutcomes/learningOutcomeGroup/title/text()")
      expect(group_titles.count).to eq 1
      expect(group_titles[0].text).to eq group2.title
      # ... with its contents
      source_outcome_group_id = doc.xpath("/learningOutcomes/learningOutcomeGroup/source_outcome_group_id/text()")
      expect(source_outcome_group_id[0].text).to eq source_group.id.to_s
      outcome_titles = doc.xpath("/learningOutcomes/learningOutcomeGroup/learningOutcomes/learningOutcome/title/text()")
      expect(outcome_titles.map(&:text)).to match_array [outcome1.title, outcome2.title]
    end

    it "exports an outcome and populates its friendly description if the outcome_friendly_description ff is enabled" do
      @context = @course
      Account.site_admin.enable_feature! :outcomes_friendly_description
      root_group = outcome_group_model(title: "root group")
      outcome1 = outcome_model(outcome_group: root_group, title: "thing1")
      friendly_description = "a friendly description"
      OutcomeFriendlyDescription.create!({
                                           learning_outcome: outcome1,
                                           context: @course,
                                           description: friendly_description
                                         })
      @ce.selected_content = {
        "learning_outcomes" => {
          @ce.create_key(outcome1) => "1"
        }
      }
      run_export
      doc = Nokogiri::XML.parse(@zip_file.read("course_settings/learning_outcomes.xml"))
      # for shorter xpath queries
      doc.remove_namespaces!
      # root outcome was selected for export
      expect(doc.xpath("/learningOutcomes/learningOutcome").count).to eq 1
      # with friendly description
      friendly_descriptions = doc.xpath("/learningOutcomes/learningOutcome/friendly_description/text()")
      expect(friendly_descriptions.count).to eq 1
      expect(friendly_descriptions[0].text).to eq friendly_description
      Account.site_admin.disable_feature! :outcomes_friendly_description
    end

    it "does not populate the friendly description if there is none, even if the outcome_friendly_description ff is enabled" do
      @context = @course
      Account.site_admin.enable_feature! :outcomes_friendly_description
      root_group = outcome_group_model(title: "root group")
      outcome1 = outcome_model(outcome_group: root_group, title: "thing1")
      @ce.selected_content = {
        "learning_outcomes" => {
          @ce.create_key(outcome1) => "1"
        }
      }
      run_export
      doc = Nokogiri::XML.parse(@zip_file.read("course_settings/learning_outcomes.xml"))
      # for shorter xpath queries
      doc.remove_namespaces!
      # root outcome was selected for export
      expect(doc.xpath("/learningOutcomes/learningOutcome").count).to eq 1
      # with friendly description
      friendly_descriptions = doc.xpath("/learningOutcomes/learningOutcome/friendly_description/text()")
      expect(friendly_descriptions.count).to eq 0
      Account.site_admin.disable_feature! :outcomes_friendly_description
    end

    it "does not populate the friendly description if the outcome_friendly_description ff is disabled" do
      @context = @course
      root_group = outcome_group_model(title: "root group")
      outcome1 = outcome_model(outcome_group: root_group, title: "thing1")
      friendly_description = "a friendly description"
      OutcomeFriendlyDescription.create!({
                                           learning_outcome: outcome1,
                                           context: @course,
                                           description: friendly_description
                                         })
      @ce.selected_content = {
        "learning_outcomes" => {
          @ce.create_key(outcome1) => "1"
        }
      }
      run_export
      doc = Nokogiri::XML.parse(@zip_file.read("course_settings/learning_outcomes.xml"))
      # for shorter xpath queries
      doc.remove_namespaces!
      # root outcome was selected for export
      expect(doc.xpath("/learningOutcomes/learningOutcome").count).to eq 1
      # with friendly description
      friendly_descriptions = doc.xpath("/learningOutcomes/learningOutcome/friendly_description/text()")
      expect(friendly_descriptions.count).to eq 0
    end

    it "exports an outcome and populates its course-level friendly description if there is a course-level and account-level friendly description" do
      @context = @course
      Account.site_admin.enable_feature! :outcomes_friendly_description
      root_group = outcome_group_model(title: "root group")
      outcome1 = outcome_model(outcome_group: root_group, title: "thing1")
      OutcomeFriendlyDescription.create!({
                                           learning_outcome: outcome1,
                                           context: @course.account,
                                           description: "an account-level friendly description"
                                         })
      friendly_description = "a course-level friendly description"
      OutcomeFriendlyDescription.create!({
                                           learning_outcome: outcome1,
                                           context: @course,
                                           description: friendly_description
                                         })
      @ce.selected_content = {
        "learning_outcomes" => {
          @ce.create_key(outcome1) => "1"
        }
      }
      run_export
      doc = Nokogiri::XML.parse(@zip_file.read("course_settings/learning_outcomes.xml"))
      # for shorter xpath queries
      doc.remove_namespaces!
      # root outcome was selected for export
      expect(doc.xpath("/learningOutcomes/learningOutcome").count).to eq 1
      # with friendly description
      friendly_descriptions = doc.xpath("/learningOutcomes/learningOutcome/friendly_description/text()")
      expect(friendly_descriptions.count).to eq 1
      expect(friendly_descriptions[0].text).to eq friendly_description
    end
  end
end
