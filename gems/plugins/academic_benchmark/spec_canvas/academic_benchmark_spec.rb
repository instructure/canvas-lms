# encoding: utf-8
#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe AcademicBenchmark::Converter do

  before(:each) do
    @root_account = Account.site_admin
    account_admin_user(:account => @root_account, :active_all => true)
    @cm = ContentMigration.new(:context => @root_account)
    @plugin = Canvas::Plugin.find('academic_benchmark_importer')
    @cm.converter_class = @plugin.settings['converter_class']
    @cm.migration_settings[:migration_type] = 'academic_benchmark_importer'
    @cm.migration_settings[:import_immediately] = true
    @cm.migration_settings[:base_url] = "http://example.com/"
    @cm.migration_settings[:migration_options] = {points_possible: 10, mastery_points: 6,
      ratings: [{description: 'Bad', points: 0}, {description: 'Awesome', points: 10}]}
    @cm.user = @user
    @cm.save!

    @level_0_browse = File.join(File.dirname(__FILE__) + '/fixtures', 'example.json')
    @a_levels_3 = File.join(File.dirname(__FILE__) + '/fixtures', 'a_levels_3.json')
    @d_levels_3 = File.join(File.dirname(__FILE__) + '/fixtures', 'd_levels_3.json')
    @j_levels_3 = File.join(File.dirname(__FILE__) + '/fixtures', 'j_levels_3.json')
    @authority_list = File.join(File.dirname(__FILE__) + '/fixtures', 'auth_list.json')
    @florida_auth_list = File.join(File.dirname(__FILE__) + '/fixtures', 'florida_auth_list.json')
    File.open(@level_0_browse, 'r') do |file|
      @att = Attachment.create!(
        :filename => 'standards.json',
        :display_name => 'standards.json',
        :uploaded_data => file,
        :context => @cm
      )
    end
    @cm.attachment = @att
    @cm.save!
  end

  def verify_rubric_criterion(outcome)
    expect(outcome.data[:rubric_criterion][:mastery_points]).to eq 6
    expect(outcome.data[:rubric_criterion][:points_possible]).to eq 10
    expect(outcome.data[:rubric_criterion][:ratings]).to eq [{description: 'Bad', points: 0},
                                                             {description: 'Awesome', points: 10}]
  end

  def verify_full_import
    @root_group = LearningOutcomeGroup.global_root_outcome_group
    expect(@root_group.child_outcome_groups.count).to eq 1
    a = @root_group.child_outcome_groups.first
    expect(a.migration_id).to eq "aaaaaaaaaa"
    expect(a.title).to eq "NGA Center/CCSSO"
    b = a.child_outcome_groups.first
    expect(b.migration_id).to eq "bbbbbbbbbbbb"
    expect(b.title).to eq "Common Core State Standards"
    c = b.child_outcome_groups.first
    expect(c.migration_id).to eq "cccccccccc"
    expect(c.title).to eq "College- and Career-Readiness Standards and K-12 Mathematics"
    d = c.child_outcome_groups.where(migration_id: "ddddddddd").first
    expect(d.migration_id).to eq "ddddddddd"
    expect(d.title).to eq "Kindergarten"
    expect(d.low_grade).to eq "K"
    expect(d.high_grade).to eq "K"
    e = d.child_outcome_groups.first
    expect(e.migration_id).to eq "eeeeeeeeeeee"
    expect(e.title).to eq "K.CC - Counting and Cardinality"
    expect(e.description).to eq "Counting and Cardinality"
    expect(e.low_grade).to eq "K"
    expect(e.high_grade).to eq "K"
    f = e.child_outcome_groups.first
    expect(f.migration_id).to eq "ffffffffffffff"
    expect(f.title).to eq "Know number names and the count sequence."
    expect(f.description).to eq "Know number names and the count sequence."
    expect(f.low_grade).to eq "K"
    expect(f.high_grade).to eq "K"
    expect(f.child_outcome_links.count).to eq 3

    g = LearningOutcome.global.where(migration_id: "ggggggggggggggggg").first
    verify_rubric_criterion(g)
    expect(g.short_description).to eq "K.CC.1"
    expect(g.description).to eq "Count to 100 by ones and by tens."
    g = LearningOutcome.global.where(migration_id: "hhhhhhhhhhhhhhhh").first
    verify_rubric_criterion(g)
    expect(g.short_description).to eq "K.CC.2"
    expect(g.description).to eq "Count forward beginning from a given number within the known sequence (instead of having to begin at 1)."
    g = LearningOutcome.global.where(migration_id: "iiiiiiiiiiiiiiiii").first
    verify_rubric_criterion(g)
    expect(g.short_description).to eq "K.CC.3"
    expect(g.description).to eq "Write numbers from 0 to 20. Represent a number of objects with a written numeral 0-20 (with 0 representing a count of no objects)."

    j = c.child_outcome_groups.where(migration_id: "jjjjjjjjjjj").first
    expect(j.migration_id).to eq "jjjjjjjjjjj"
    expect(j.title).to eq "First Grade"
    expect(j.low_grade).to eq "1"
    expect(j.high_grade).to eq "1"
    k = j.child_outcome_groups.last
    expect(k.migration_id).to eq "kkkkkkkkkkk"
    expect(k.title).to eq "1.DD - zééééééééééééééééééééééééééééééééééééééééééééééééé"
    expect(k.description).to eq "zéééééééééééééééééééééééééééééééééééééééééééééééééééééééééé"
    expect(k.low_grade).to eq "1"
    expect(k.high_grade).to eq "1"
    l = k.child_outcome_groups.first
    expect(l.migration_id).to eq "lllllllll"
    expect(l.title).to eq "Something else"
    expect(l.description).to eq "Something else"
    expect(l.low_grade).to eq "1"
    expect(l.high_grade).to eq "1"
    expect(l.child_outcome_links.count).to eq 1

    m = LearningOutcome.global.where(migration_id: "mmmmmmmmmmm").first
    verify_rubric_criterion(g)
    expect(m.short_description).to eq "1.DD.1"
    expect(m.description).to eq "And something else"
    expect(m.title).to eq "1.DD.1"
  end

  def check_for_parent_num_duplication(outcome)
    parent = outcome.instance_variable_get('@parent')
    if outcome.num && parent && parent.is_standard? && parent.title && outcome.num.include?(parent.title)
      outcome.title == "#{parent.title}.#{outcome.num}"
    else
      false
    end
  end

  def check_built_outcome(outcome)
    expect(check_for_parent_num_duplication(outcome)).to be_falsey
    outcome.instance_variable_get('@children').each { |o| check_built_outcome(o) }
  end

  it "should successfully import the standards" do
    @cm.export_content
    run_jobs
    @cm.reload
    expect(@cm.migration_issues.count).to eq 0
    expect(@cm.workflow_state).to eq 'imported'

    verify_full_import()
  end

  it "should reject creating global outcomes if no permissions" do
    @cm.user = nil
    @cm.save!
    @cm.export_content
    run_jobs
    @cm.reload

    expect(@cm.migration_issues.count).to eq 1
    expect(@cm.migration_issues.first.description).to eq "User isn't allowed to edit global outcomes"
    expect(@cm.workflow_state).to eq 'failed'
  end

  it "should fail if no file or authority set" do
    @cm.attachment = nil
    @cm.migration_settings[:no_archive_file] = true
    @cm.save!

    @cm.export_content
    run_jobs
    @cm.reload

    expect(@cm.migration_issues.count).to eq 1
    expect(@cm.migration_issues.first.description).to eq "No outcome file or authority given"
    expect(@cm.workflow_state).to eq 'failed'
  end

  context "using the API" do
    append_before do
      @plugin.settings['api_key'] = "oioioi"
      @cm.attachment = nil
      @cm.migration_settings[:no_archive_file] = true
      @cm.migration_settings[:authorities] = ["CC"]
      @cm.save!
    end

    def run_and_check
      @cm.export_content
      run_jobs
      @cm.reload

      expect(@cm.migration_issues.count).to eq 0
      expect(@cm.workflow_state).to eq 'imported'

      @root_group = LearningOutcomeGroup.global_root_outcome_group
      expect(@root_group.child_outcome_groups.count).to eq 1
      a = @root_group.child_outcome_groups.first
      expect(a.migration_id).to eq "aaaaaaaaaa"
    end

    it "should fail with no API key" do
      @plugin.settings['api_key'] = nil
      @cm.export_content
      run_jobs
      @cm.reload

      expect(@cm.migration_issues.count).to eq 1
      expect(@cm.migration_issues.first.description).to eq "An API key is required to use Academic Benchmarks"
      expect(@cm.workflow_state).to eq 'failed'
    end

    it "should fail with an empty string API key" do
      @plugin.settings['api_key'] = ""
      @cm.export_content
      run_jobs
      @cm.reload

      expect(@cm.migration_issues.count).to eq 1
      expect(@cm.migration_issues.first.description).to eq "An API key is required to use Academic Benchmarks"
      expect(@cm.workflow_state).to eq 'failed'
    end

    it "should use the API to get the set data with an authority short code" do
      response = Object.new
      response.stubs(:body).returns(File.read(@level_0_browse))
      response.stubs(:code).returns("200")
      AcademicBenchmark::Api.expects(:get_url).with("http://example.com/browse?api_key=oioioi&authority=CC&format=json&levels=3").returns(response)

      run_and_check
      verify_full_import
    end

    it "should use the API to get the set data with a guid" do
      @cm.migration_settings[:authorities] = nil
      @cm.migration_settings[:guids] = ["aaaaaaaaaa"]
      response = Object.new
      response.stubs(:body).returns(File.read(@a_levels_3))
      response.stubs(:code).returns("200")
      AcademicBenchmark::Api.expects(:get_url).with("http://example.com/browse?api_key=oioioi&format=json&guid=aaaaaaaaaa&levels=3").returns(response)
      responsed = Object.new
      responsed.stubs(:body).returns(File.read(@d_levels_3))
      responsed.stubs(:code).returns("200")
      AcademicBenchmark::Api.expects(:get_url).with("http://example.com/browse?api_key=oioioi&format=json&guid=ddddddddd&levels=3").returns(responsed)
      responsej = Object.new
      responsej.stubs(:body).returns(File.read(@j_levels_3))
      responsej.stubs(:code).returns("200")
      AcademicBenchmark::Api.expects(:get_url).with("http://example.com/browse?api_key=oioioi&format=json&guid=jjjjjjjjjjj&levels=3").returns(responsej)

      run_and_check
      verify_full_import
    end

    it "should warn when api returns non-success" do
      response = Object.new
      response.stubs(:body).returns(%{{"status":"fail","ab_err":{"msg":"API key access violation.","code":"401"}}})
      response.stubs(:code).returns("200")
      AcademicBenchmark::Api.expects(:get_url).with("http://example.com/browse?api_key=oioioi&authority=CC&format=json&levels=3").returns(response)

      @cm.export_content
      run_jobs
      @cm.reload

      expect(@cm.migration_settings[:last_error]).to be_nil
      expect(@cm.workflow_state).to eq 'imported'
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
  #    LAFS.1.L.1.1.a instead of LAFS.1.L.LAFS.1.L.1.LAFS.1.L.1.1.a
  #
  it "doesn't duplicate the base numbers when building a title" do
    json_data = JSON.parse(File.read(@florida_auth_list))
    check_built_outcome(AcademicBenchmark::Standard.new(json_data))
  end
end
