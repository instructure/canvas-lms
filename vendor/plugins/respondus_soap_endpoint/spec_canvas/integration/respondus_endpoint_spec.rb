require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/spec_helper')

require 'soap/rpc/driver'

class SpecStreamHandler < SOAP::StreamHandler
  def send(url, conn_data, soapaction = nil, charset = nil)
    response = @capture_block.call(conn_data.send_string, {})
    conn_data.receive_string = response.body
    conn_data.receive_contenttype = response['Content-Type']
    conn_data
  end

  def capture(obj, method, *args, &block)
    @capture_block = block
    obj.send(method, *args)
  end

  def self.create(*a)
    new
  end
end

describe "full soap stack", :type => :integration do
  # args is an array of [ arg_name, value ], not just raw values
  def soap_request(method, userName, password, context, *args)
    soap = SOAP::RPC::Driver.new('test', "urn:RespondusAPI")
    soap.options['protocol.streamhandler'] = 'SpecStreamHandler'
    soap.add_method(method,
                    'userName', 'password', 'context', *(args.map(&:first)))
    streamHandler = soap.proxy.streamhandler
    method_args = [userName, password, context, *(args.map(&:last))]
    streamHandler.capture(soap, method, *method_args) do |s_body, s_headers|
      post "/api/respondus/soap", s_body, s_headers
      response
    end
  end

  before(:each) do
    setting = PluginSetting.find_or_create_by_name('qti_exporter')
    setting.settings = {:enabled => true}
    setting.save!
    setting = PluginSetting.find_or_create_by_name('respondus_soap_endpoint')
    setting.settings = {:enabled => true}
    setting.save!
    user_with_pseudonym :active_user => true,
      :username => "nobody@example.com",
      :password => "asdfasdf"
    @user.save!
  end

  it "should identify the server without user credentials" do
    soap_response = soap_request('IdentifyServer', '', '', '')
    soap_response.first.should == "Success"
    soap_response.last.should == %{
Respondus Generic Server API
Contract version: 1
Implemented for: Canvas LMS}
  end

  it "should authenticate an existing user" do
    soap_response = soap_request('ValidateAuth',
                                 'nobody@example.com', 'asdfasdf',
                                 '',
                                 ['Institution', ''])
    soap_response.first.should == "Success"
  end

  it "should reject a user with bad auth" do
    soap_response = soap_request('ValidateAuth',
                                 'nobody@example.com', 'hax0r',
                                 '',
                                 ['Institution', ''])
    soap_response.first.should == "Invalid credentials"
  end

  it "should reject a session created for a different user" do
    user1 = @user
    user2 = user_with_pseudonym :active_user => true,
      :username => "nobody2@example.com",
      :password => "test123"
    user2.save!

    status, details, context = soap_request('ValidateAuth',
                                 'nobody@example.com', 'asdfasdf',
                                 '',
                                 ['Institution', ''])
    status.should == "Success"
    status, details, context = soap_request('ValidateAuth',
                                 'nobody@example.com', 'asdfasdf',
                                 context,
                                 ['Institution', ''])
    status.should == "Success"
    status, details, context2 = soap_request('ValidateAuth',
                                 'nobody2@example.com', 'test123',
                                 '',
                                 ['Institution', ''])
    status.should == "Success"
    status, details, context2 = soap_request('ValidateAuth',
                                 'nobody2@example.com', 'test123',
                                 context,
                                 ['Institution', ''])
    status.should == "Invalid context"
  end
end
