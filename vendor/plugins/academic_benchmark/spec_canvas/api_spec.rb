require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe AcademicBenchmark::Api do

  before do
    @api = AcademicBenchmark::Api.new("oioioi", :base_url => "http://example.com/")

    @level_0_browse = File.join(File.dirname(__FILE__) + '/fixtures', 'example.json')
    @authority_list = File.join(File.dirname(__FILE__) + '/fixtures', 'auth_list.json')
  end

  def mock_api_call(code, body, url)
    response = Object.new
    response.stubs(:body).returns(body)
    response.stubs(:code).returns(code.to_s)
    AcademicBenchmark::Api.expects(:get_url).with(url).returns(response)
  end

  it "should fail with bad AB response" do
    mock_api_call(200,
                  %{{"status":"fail","ab_err":{"msg":"API key access violation.","code":"401"}}},
                  "http://example.com/browse?api_key=oioioi&format=json&levels=2")

    expect {
      @api.list_available_authorities
    }.to raise_error(AcademicBenchmark::APIError)
  end

  it "should fail with http error code" do
    mock_api_call(500,
                  '',
                  "http://example.com/browse?api_key=oioioi&format=json&levels=2")

    expect {
      @api.list_available_authorities
    }.to raise_error(AcademicBenchmark::APIError)
  end

  it "should get authority" do
    mock_api_call(200,
                  '{"status":"ok", "itm":[{"test":"yep"}]}',
                  "http://example.com/browse?api_key=oioioi&authority=CC&format=json&levels=0")
    @api.browse_authority("CC", :levels => 0).should == [{"test" => "yep"}]
  end

  it "should get guid" do
    mock_api_call(200,
                  '{"status":"ok", "itm":[{"test":"yep"}]}',
                  "http://example.com/browse?api_key=oioioi&format=json&guid=gggggg&levels=0")
    @api.browse_guid("gggggg", :levels => 0).should == [{"test" => "yep"}]
  end

  it "should get available authorities" do
    mock_api_call(200,
                  File.read(@authority_list),
                  "http://example.com/browse?api_key=oioioi&format=json&levels=2")

    @api.list_available_authorities.should == [{"chld" => "1", "guid" => "AAA", "title" => "NGA Center/CCSSO", "type" => "authority"},
                                               {"chld" => "2", "guid" => "CCC", "title" => "South Carolina", "type" => "authority"},
                                               {"chld" => "3", "guid" => "BBB", "title" => "Louisiana", "type" => "authority"},
                                               {"chld" => "2", "guid" => "111", "title" => "Good Standards", "type" => "authority"},
                                               {"chld" => "3", "guid" => "222", "title" => "Bad Standards", "type" => "authority"}]
  end
end