# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe AcademicBenchmark do
  before do
    @root_account = Account.site_admin
    account_admin_user(account: @root_account, active_all: true)
    @cm = ContentMigration.new(context: @root_account)
    @plugin = Canvas::Plugin.find("academic_benchmark_importer")
    @cm.converter_class = @plugin.settings["converter_class"]
    @cm.migration_settings[:migration_type] = "academic_benchmark_importer"
    @cm.migration_settings[:import_immediately] = true
    @cm.migration_settings[:migration_options] = { points_possible: 10,
                                                   mastery_points: 6,
                                                   ratings: [{ description: "Bad", points: 0 }, { description: "Awesome", points: 10 }] }
    @cm.user = @user
    @cm.save!

    current_settings = @plugin.settings
    new_settings = current_settings.merge(partner_id: "instructure", partner_key: "secret")
    allow(@plugin).to receive(:settings).and_return(new_settings)

    @florida_standards = File.join(File.dirname(__FILE__) + "/fixtures", "florida_standards.json")
    File.open(@florida_standards, "r") do |file|
      @att = Attachment.create!(
        filename: "standards.json",
        display_name: "standards.json",
        uploaded_data: file,
        context: @cm
      )
    end
    @cm.attachment = @att
    @cm.save!
  end

  def verify_rubric_criterion(outcome)
    expect(outcome.data[:rubric_criterion][:mastery_points]).to eq 6
    expect(outcome.data[:rubric_criterion][:points_possible]).to eq 10
    expect(outcome.data[:rubric_criterion][:ratings]).to eq [{ description: "Bad", points: 0 },
                                                             { description: "Awesome", points: 10 }]
  end

  def verify_full_import
    @root_group = LearningOutcomeGroup.global_root_outcome_group
    expect(@root_group.child_outcome_groups.count).to eq 1
    a = @root_group.child_outcome_groups.first
    expect(a.migration_id).to eq "AF2EAFAE-CCB8-11DD-A7C8-69619DFF4B22"
    expect(a.title).to eq "SS.912.A - American History"
    b = a.child_outcome_groups.first
    expect(b.migration_id).to eq "AF2F25CE-CCB8-11DD-A7C8-69619DFF4B22"
    expect(b.title).to eq "SS.912.A.1 - Use research and inquiry skills to analyze America"
    {
      "AF2F887A-CCB8-11DD-A7C8-69619DFF4B22" =>
        {
          short_description: "SS.912.A.1.1",
          description: "Describe the importance of historiography, which includes how historical knowledge is obtained " \
                       "and transmitted, when interpreting events in history."
        },
      "AF2FEA9A-CCB8-11DD-A7C8-69619DFF4B22" =>
        {
          short_description: "SS.912.A.1.2",
          description: "Utilize a variety of primary and secondary sources to identify author, historical significance, " \
                       "audience, and authenticity to understand a historical period."
        },
      "AF3058F4-CCB8-11DD-A7C8-69619DFF4B22" =>
        {
          short_description: "SS.912.A.1.3",
          description: "Utilize timelines to identify the time sequence of historical data."
        },
      "AF30C56E-CCB8-11DD-A7C8-69619DFF4B22" =>
        {
          short_description: "SS.912.A.1.4",
          description: "Analyze how images, symbols, objects, cartoons, graphs, charts, maps, and artwork may be used " \
                       "to interpret the significance of time periods and events from the past."
        },
      "AF31281A-CCB8-11DD-A7C8-69619DFF4B22" =>
        {
          short_description: "SS.912.A.1.5",
          description: "Evaluate the validity, reliability, bias, and authenticity of current events and Internet resources."
        },
      "AF319610-CCB8-11DD-A7C8-69619DFF4B22" =>
        {
          short_description: "SS.912.A.1.6",
          description: "Use case studies to explore social, political, legal, and economic relationships in history."
        },
      "AF31F8F8-CCB8-11DD-A7C8-69619DFF4B22" =>
        {
          short_description: "SS.912.A.1.7",
          description: "Describe various socio-cultural aspects of American life including arts, artifacts, literature, education, and publications."
        },
      "AF325C58-CCB8-11DD-A7C8-69619DFF4B22" =>
        {
          short_description: "SS.912.A.2",
          description: "Understand the causes, course, and consequences of the Civil War and Reconstruction and its effects on the American people."
        },
      "AF359634-CCB8-11DD-A7C8-69619DFF4B22" =>
        {
          short_description: "SS.912.A.3",
          description: "Analyze the transformation of the American economy and the changing social and " \
                       "political conditions in response to the Industrial Revolution."
        },
      "AF3B2A72-CCB8-11DD-A7C8-69619DFF4B22" =>
        {
          short_description: "SS.912.A.4",
          description: "Demonstrate an understanding of the changing role of the United States in world affairs through the end of World War I."
        },
      "AF3FF1EC-CCB8-11DD-A7C8-69619DFF4B22" =>
        {
          short_description: "SS.912.A.5",
          description: "Analyze the effects of the changing social, political, and economic conditions of the Roaring Twenties and the Great Depression."
        },
      "AF4522DE-CCB8-11DD-A7C8-69619DFF4B22" =>
        {
          short_description: "SS.912.A.6",
          description: "Understand the causes and course of World War II, the character of the war at home and abroad, " \
                       "and its reshaping of the United States role in the post-war world."
        },
      "AF4B6DB0-CCB8-11DD-A7C8-69619DFF4B22" =>
        {
          short_description: "SS.912.A.7",
          description: "Understand the rise and continuing international influence of the United States as a " \
                       "world leader and the impact of contemporary social and political movements on American life."
        }
    }.each do |migration_id, descriptions|
      g = LearningOutcome.global.find_by(migration_id:)
      verify_rubric_criterion(g)
      expect(g.short_description).to eq descriptions[:short_description]
      expect(g.description).to eq descriptions[:description]
    end
  end

  def check_for_parent_num_duplication(outcome)
    parent = outcome.instance_variable_get(:@parent)
    if outcome.resolve_number && parent && parent.build_title && outcome.resolve_number.include?(parent.build_title)
      outcome.title == "#{parent.title}.#{outcome.resolve_number}"
    else
      false
    end
  end

  def check_built_outcome(outcome)
    expect(check_for_parent_num_duplication(outcome)).to be_falsey
    outcome.instance_variable_get(:@children).each { |o| check_built_outcome(o) }
  end

  it "imports the standards successfully" do
    @cm.export_content
    run_jobs
    @cm.reload
    expect(@cm.migration_issues.count).to eq 0
    expect(@cm.workflow_state).to eq "imported"

    verify_full_import
  end

  it "rejects creating global outcomes if no permissions" do
    @cm.user = nil
    @cm.save!
    @cm.export_content
    run_jobs
    @cm.reload

    expect(@cm.migration_issues.count).to eq 1
    expect(@cm.migration_issues.first.description).to eq "User isn't allowed to edit global outcomes"
    expect(@cm.workflow_state).to eq "failed"
  end

  context "using the API" do
    append_before do
      @cm.attachment = nil
      @cm.migration_settings[:no_archive_file] = true
      @cm.migration_settings[:authorities] = ["CC"]
      @cm.save!
    end

    it "fails with no partner ID" do
      @plugin.settings[:partner_id] = nil
      @plugin.settings[:partner_key] = "a"
      @cm.export_content
      run_jobs
      @cm.reload

      expect(@cm.migration_issues.count).to eq 1
      expect(@cm.migration_issues.first.description).to eq "A partner ID is required to use Academic Benchmarks"
      expect(@cm.workflow_state).to eq "failed"
    end

    it "fails with an empty string partner ID" do
      current_settings = @plugin.settings
      new_settings = current_settings.merge(partner_id: "", partner_key: "a")
      allow(@plugin).to receive(:settings).and_return(new_settings)
      @cm.export_content
      run_jobs
      @cm.reload

      expect(@cm.migration_issues.count).to eq 1
      expect(@cm.migration_issues.first.description).to eq "A partner ID is required to use Academic Benchmarks"
      expect(@cm.workflow_state).to eq "failed"
    end
  end

  # This test came about because the titles being generated for
  # Florida outcomes were long and out of control.  They were looking
  # like this:
  #
  #    LAFS.1.L.LAFS.1.L.1.LAFS.1.L.1.1.a
  #
  # instead of this:
  #
  #    LAFS.1.L.1.1.a
  #
  it "doesn't duplicate the base numbers when building a title" do
    json_data = JSON.parse(File.read(@florida_standards))
    AcademicBenchmarks::Standards::StandardsForest.new(json_data).trees.each do |tree|
      tree.children.each do |outcome|
        check_built_outcome(outcome)
      end
    end
  end

  it "raises error with invalid user id" do
    expect { AcademicBenchmark.ensure_real_user(user_id: 0) }.to raise_error(
      Canvas::Migration::Error,
      "Not importing academic benchmark data because no user found matching id '0'"
    )
  end

  it "raises error when crendentials are not set" do
    allow(AcademicBenchmark).to receive(:config).and_return({})
    expect { AcademicBenchmark.ensure_ab_credentials }.to raise_error(
      Canvas::Migration::Error,
      "Not importing academic benchmark data because the Academic Benchmarks Partner ID is not set"
    )
    allow(AcademicBenchmark).to receive(:config).and_return({ partner_id: "user" })
    expect { AcademicBenchmark.ensure_ab_credentials }.to raise_error(
      Canvas::Migration::Error,
      "Not importing academic benchmark data because the Academic Benchmarks Partner key is not set"
    )
  end

  describe ".queue_migration_for" do
    before { allow_any_instance_of(ContentMigration).to receive(:export_content) }

    it "sets context with user" do
      cm = AcademicBenchmark.queue_migration_for(
        authority: "authority",
        publication: "publication",
        user: @user
      )[0]
      expect(cm.root_account_id).to eq 0
    end
  end
end
