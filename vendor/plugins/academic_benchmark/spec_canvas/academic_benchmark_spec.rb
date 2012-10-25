require File.dirname(__FILE__) + '/spec_helper'

describe AcademicBenchmark::Converter do

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

    @level_0_browse = File.join(File.dirname(__FILE__) + '/fixtures', 'example.json')
    @authority_list = File.join(File.dirname(__FILE__) + '/fixtures', 'auth_list.json')
    File.open(@level_0_browse, 'r') do |file|
      @att = Attachment.create!(:filename => 'standards.json', :display_name => 'standards.json', :uploaded_data => file, :context => @cm)
    end
    @cm.attachment = @att
    @cm.save!
  end

  it "should successfully import the standards" do
    @cm.export_content
    run_jobs
    @cm.reload
    @cm.migration_settings[:warnings].should be_nil
    @cm.migration_settings[:last_error].should be_nil
    @cm.workflow_state.should == 'imported'

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
    d = c.child_outcome_groups.first
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

    g = LearningOutcome.global.find_by_migration_id("ggggggggggggggggg")
    g.short_description.should == "K.CC.1"
    g.description.should == "Count to 100 by ones and by tens."
    g = LearningOutcome.global.find_by_migration_id("hhhhhhhhhhhhhhhh")
    g.short_description.should == "K.CC.2"
    g.description.should == "Count forward beginning from a given number within the known sequence (instead of having to begin at 1)."
    g = LearningOutcome.global.find_by_migration_id("iiiiiiiiiiiiiiiii")
    g.short_description.should == "K.CC.3"
    g.description.should == "Write numbers from 0 to 20. Represent a number of objects with a written numeral 0-20 (with 0 representing a count of no objects)."
  end

  it "should reject creating global outcomes if no permissions" do
    @cm.user = nil
    @cm.save!
    @cm.export_content
    run_jobs
    @cm.reload

    @cm.migration_settings[:warnings].should == [["You're not allowed to manage global outcomes, can't add \"NGA Center/CCSSO\"", ""]]
    @cm.migration_settings[:last_error].should be_nil
    @cm.workflow_state.should == 'imported'
  end

  it "should fail if no file or authority set" do
    @cm.attachment = nil
    @cm.migration_settings[:no_archive_file] = true
    @cm.save!

    @cm.export_content
    run_jobs
    @cm.reload

    @cm.migration_settings[:warnings].should == [["No outcome file or authority given", ""]]
    @cm.migration_settings[:last_error].should_not be_nil
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

      @cm.migration_settings[:warnings].should be_nil
      @cm.migration_settings[:last_error].should be_nil
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

      @cm.migration_settings[:warnings].should == [["An API key is required to use Academic Benchmarks", ""]]
      @cm.migration_settings[:last_error].should_not be_nil
      @cm.workflow_state.should == 'failed'
    end

    it "should use the API to get the set data with an authority short code" do
      response = Object.new
      response.stubs(:body).returns(File.read(@level_0_browse))
      response.stubs(:code).returns("200")
      Canvas::HTTP.expects(:get).with("http://example.com/browse?levels=0&format=json&api_key=oioioi&authority=CC").returns(response)

      run_and_check
    end

    it "should use the API to get the set data with a guid" do
      @cm.migration_settings[:authorities] = nil
      @cm.migration_settings[:guids] = ["aaaaaaaaaa"]
      response = Object.new
      response.stubs(:body).returns(File.read(@level_0_browse))
      response.stubs(:code).returns("200")
      Canvas::HTTP.expects(:get).with("http://example.com/browse?levels=0&format=json&api_key=oioioi&guid=aaaaaaaaaa").returns(response)

      run_and_check
    end
    
    it "should warn when api returns non-success" do
      response = Object.new
      response.stubs(:body).returns(%{{"status":"fail","ab_err":{"msg":"API key access violation.","code":"401"}}})
      response.stubs(:code).returns("200")
      Canvas::HTTP.expects(:get).with("http://example.com/browse?levels=0&format=json&api_key=oioioi&authority=CC").returns(response)
      
      @cm.export_content
      run_jobs
      @cm.reload

      @cm.migration_settings[:warnings].should == [["Error accessing Academic Benchmark API", "responseCode: 401 - API key access violation."]]
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
      Canvas::HTTP.expects(:get).with("http://example.com/browse?levels=2&format=json&api_key=oioioi").returns(response)
      
      ["CCC", "BBB", "AAA", "111", "222"].each do |guid|
        response2 = Object.new
        response2.stubs(:body).returns(File.read(@level_0_browse))
        response2.stubs(:code).returns("200")
        Canvas::HTTP.expects(:get).with("http://example.com/browse?levels=0&format=json&api_key=oioioi&guid=" + guid).returns(response2)
      end
      
      run_and_check
    end
    
  end

end