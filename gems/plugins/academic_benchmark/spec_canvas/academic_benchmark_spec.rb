# encoding: utf-8

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
    @cm.user = @user
    @cm.save!

    @level_0_browse = File.join(File.dirname(__FILE__) + '/fixtures', 'example.json')
    @a_levels_3 = File.join(File.dirname(__FILE__) + '/fixtures', 'a_levels_3.json')
    @d_levels_3 = File.join(File.dirname(__FILE__) + '/fixtures', 'd_levels_3.json')
    @j_levels_3 = File.join(File.dirname(__FILE__) + '/fixtures', 'j_levels_3.json')
    @authority_list = File.join(File.dirname(__FILE__) + '/fixtures', 'auth_list.json')
    File.open(@level_0_browse, 'r') do |file|
      @att = Attachment.create!(:filename => 'standards.json', :display_name => 'standards.json', :uploaded_data => file, :context => @cm)
    end
    @cm.attachment = @att
    @cm.save!
  end

  def verify_full_import
    @root_group = LearningOutcomeGroup.global_root_outcome_group
    @root_group.child_outcome_groups.count.should == 1
    a = @root_group.child_outcome_groups.first
    a.migration_id.should == "aaaaaaaaaa"
    a.title.should == "NGA Center/CCSSO"
    b = a.child_outcome_groups.first
    b.migration_id.should == "bbbbbbbbbbbb"
    b.title.should == "Common Core State Standards"
    c = b.child_outcome_groups.first
    c.migration_id.should == "cccccccccc"
    c.title.should == "College- and Career-Readiness Standards and K-12 Mathematics"
    d = c.child_outcome_groups.where(migration_id: "ddddddddd").first
    d.migration_id.should == "ddddddddd"
    d.title.should == "Kindergarten"
    d.low_grade.should == "K"
    d.high_grade.should == "K"
    e = d.child_outcome_groups.first
    e.migration_id.should == "eeeeeeeeeeee"
    e.title.should == "K.CC - Counting and Cardinality"
    e.description.should == "Counting and Cardinality"
    e.low_grade.should == "K"
    e.high_grade.should == "K"
    f = e.child_outcome_groups.first
    f.migration_id.should == "ffffffffffffff"
    f.title.should == "Know number names and the count sequence."
    f.description.should == "Know number names and the count sequence."
    f.low_grade.should == "K"
    f.high_grade.should == "K"
    f.child_outcome_links.count.should == 3

    g = LearningOutcome.global.where(migration_id: "ggggggggggggggggg").first
    g.short_description.should == "K.CC.1"
    g.description.should == "Count to 100 by ones and by tens."
    g = LearningOutcome.global.where(migration_id: "hhhhhhhhhhhhhhhh").first
    g.short_description.should == "K.CC.2"
    g.description.should == "Count forward beginning from a given number within the known sequence (instead of having to begin at 1)."
    g = LearningOutcome.global.where(migration_id: "iiiiiiiiiiiiiiiii").first
    g.short_description.should == "K.CC.3"
    g.description.should == "Write numbers from 0 to 20. Represent a number of objects with a written numeral 0-20 (with 0 representing a count of no objects)."

    j = c.child_outcome_groups.where(migration_id: "jjjjjjjjjjj").first
    j.migration_id.should == "jjjjjjjjjjj"
    j.title.should == "First Grade"
    j.low_grade.should == "1"
    j.high_grade.should == "1"
    k = j.child_outcome_groups.last
    k.migration_id.should == "kkkkkkkkkkk"
    k.title.should == "1.DD - zééééééééééééééééééééééééééééééééééééééééééééééééé"
    k.description.should == "zéééééééééééééééééééééééééééééééééééééééééééééééééééééééééé"
    k.low_grade.should == "1"
    k.high_grade.should == "1"
    l = k.child_outcome_groups.first
    l.migration_id.should == "lllllllll"
    l.title.should == "Something else"
    l.description.should == "Something else"
    l.low_grade.should == "1"
    l.high_grade.should == "1"
    l.child_outcome_links.count.should == 1

    m = LearningOutcome.global.where(migration_id: "mmmmmmmmmmm").first
    m.short_description.should == "1.DD.1"
    m.description.should == "And something else"
    m.title.should == "1.DD.1"
  end

  it "should successfully import the standards" do
    @cm.export_content
    run_jobs
    @cm.reload
    @cm.migration_issues.count.should == 0
    @cm.workflow_state.should == 'imported'

    verify_full_import()
  end

  it "should reject creating global outcomes if no permissions" do
    @cm.user = nil
    @cm.save!
    @cm.export_content
    run_jobs
    @cm.reload

    @cm.migration_issues.count.should == 1
    @cm.migration_issues.first.description.should == "User isn't allowed to edit global outcomes"
    @cm.workflow_state.should == 'failed'
  end

  it "should fail if no file or authority set" do
    @cm.attachment = nil
    @cm.migration_settings[:no_archive_file] = true
    @cm.save!

    @cm.export_content
    run_jobs
    @cm.reload

    @cm.migration_issues.count.should == 1
    @cm.migration_issues.first.description.should == "No outcome file or authority given"
    @cm.workflow_state.should == 'failed'
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

      @cm.migration_issues.count.should == 0
      @cm.workflow_state.should == 'imported'

      @root_group = LearningOutcomeGroup.global_root_outcome_group
      @root_group.child_outcome_groups.count.should == 1
      a = @root_group.child_outcome_groups.first
      a.migration_id.should == "aaaaaaaaaa"
    end

    it "should fail with no API key" do
      @plugin.settings['api_key'] = nil
      @cm.export_content
      run_jobs
      @cm.reload

      @cm.migration_issues.count.should == 1
      @cm.migration_issues.first.description.should == "An API key is required to use Academic Benchmarks"
      @cm.workflow_state.should == 'failed'
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

      er = ErrorReport.last
      @cm.old_warnings_format.should == [["Couldn't update standards for authority CC.", "ErrorReport:#{er.id}"]]
      @cm.migration_settings[:last_error].should be_nil
      @cm.workflow_state.should == 'imported'
    end

    it "should pull down the list of available authorities" do
      @cm.migration_settings[:authorities] = nil
      @cm.migration_settings[:refresh_all_standards] = true
      @cm.save!

      response = Object.new
      response.stubs(:body).returns(File.read(@authority_list))
      response.stubs(:code).returns("200")
      AcademicBenchmark::Api.expects(:get_url).with("http://example.com/browse?api_key=oioioi&format=json&levels=2").returns(response)

      ["CCC", "BBB", "AAA", "111", "222"].each do |guid|
        response2 = Object.new
        response2.stubs(:body).returns(File.read(@level_0_browse))
        response2.stubs(:code).returns("200")
        AcademicBenchmark::Api.expects(:get_url).with("http://example.com/browse?api_key=oioioi&format=json&guid=%s&levels=3" % guid).returns(response2)
      end

      run_and_check
      verify_full_import
    end

  end

end
