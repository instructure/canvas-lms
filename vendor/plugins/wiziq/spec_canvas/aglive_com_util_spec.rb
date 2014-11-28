require File.expand_path(File.dirname(__FILE__)+'/../../../../spec/spec_helper')

module Wiziq

describe AgliveComUtil do
  # more fine-grained specs testing each class would be more ideal, but this is a q&d way to test the whole stack

  before do
    PluginSetting.create!(:name => 'wiziq', :settings => { :api_url => 'http://wiziq.com/', :access_key => 'test_access_key', :secret_key => 'test_secret_key' })
    BaseRequestBuilder.any_instance.expects(:get_unix_timestamp).returns(1327001480).at_least_once
  end

  it "should schedule a class" do
    aglive = AgliveComUtil.new(ApiConstants::ApiMethods::SCHEDULE)
    class_params = {
      "title" => "my class",
      "duration" => 300,
      "start_time" => "01/01/2013 01:01:01",
      "time_zone" => "UTC",
      "course_id" => 1234,
      "presenter_id" => 4321,
      "presenter_name" => "tester"
    }
    expected_request = {
      'duration' => "300",
      "timestamp" => "1327001480",
      "title" => "my class",
      "signature" => "uUM2sHKLqq9kIsbs+AzQOczqV0Y=",
      "presenter_name" => "tester",
      "access_key" => "test_access_key",
      "time_zone" => "UTC",
      "presenter_id" => "4321",
      "course_id" => "1234",
      "start_time"=>"01/01/2013 01:01:01",
    }
    expected_response = {
      "msg" => "",
      "code" => -1,
      "class_id" => "test_id",
      "recording_url" => "http://example.com/recording_url",
      "presenters" => [ { "presenter_url" => "http://example.com/presenter_url", "presenter_id" => "1" }, ],
    }
    response = mock('Net::HTTPOK')
    Net::HTTPSuccess.expects(:===).with(response).returns(true)
    response.expects(:body).returns <<-XML
      <rsp status='ok'><method>create</method><create status='true' ><class_details><class_id>test_id</class_id><recording_url><![CDATA[http://example.com/recording_url]]></recording_url><presenter_list><presenter> <presenter_id><![CDATA[1]]></presenter_id><presenter_url><![CDATA[http://example.com/presenter_url]]></presenter_url></presenter></presenter_list></class_details></create></rsp>
    XML
    Net::HTTP.any_instance.expects(:request).with { |req| (expect(Rack::Utils.parse_nested_query(req.body)).to eq(expected_request)) if req.is_a?(Net::HTTP::Post) }.returns(response)
    expect(aglive.schedule_class(class_params)).to eq expected_response
  end

  it "should add an attendee (student) to a class" do
    aglive = Wiziq::AgliveComUtil.new(ApiConstants::ApiMethods::ADDATTENDEE)
    expected_request = {
      "timestamp" => "1327001480",
      "signature"=>"73ePU2fH8k7YMUrP6g561ktvxQ4=",
      'class_id' => "test_id",
      "access_key" => "test_access_key",
    }
    expected_attendee_xml = {"attendee_list"=>{"attendee"=>{"attendee_id"=>"1234", "screen_name"=>"test student"}}}

    response = mock('Net::HTTPOK')
    Net::HTTPSuccess.expects(:===).with(response).returns(true)
    response.expects(:body).returns <<-XML
      <rsp status='ok'><method>add_attendees</method><add_attendees status='true' ><class_id>test_id</class_id><attendee_list><attendee><attendee_id><![CDATA[1234]]></attendee_id><attendee_url><![CDATA[http://example.com/attendee_url]]></attendee_url><language_culture_name><![CDATA[en-us]]></language_culture_name></attendee></attendee_list></add_attendees></rsp>
    XML
    Net::HTTP.any_instance.expects(:request).with do |req|
      body = Rack::Utils.parse_nested_query(req.body)
      if req.is_a?(Net::HTTP::Post)
        expect(Hash.from_xml(body.delete('attendee_list'))).to eq expected_attendee_xml
        expect(body).to eq expected_request
      end
    end.returns(response)
    expect(aglive.add_attendee_to_session("test_id", 1234, "test student")["attendee_url"]).to eq "http://example.com/attendee_url"
  end
end

end
