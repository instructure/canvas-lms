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

describe "Respondus SOAP API", :type => :integration do
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
    setting.settings = Canvas::Plugin.find('qti_exporter').default_settings.merge({:enabled => true})
    setting.save!
    setting = PluginSetting.find_or_create_by_name('respondus_soap_endpoint')
    setting.settings = {:enabled => true}
    setting.save!
    user_with_pseudonym :active_user => true,
      :username => "nobody@example.com",
      :password => "asdfasdf"
    @user.save!
    @course = factory_with_protected_attributes(Course, course_valid_attributes)
    @course.enroll_teacher(@user).accept
    @course.assert_assignment_group
    @group = @course.assignment_groups.first
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

  it "should allow selecting a course and then an assignment group" do
    status, details, context, list = soap_request('GetServerItems',
                                                  'nobody@example.com', 'asdfasdf',
                                                  '', ['itemType', 'course'])
    status.should == "Success"
    pair = list.item
    pair.name.should == "value for name"
    pair.value.should == @course.to_param

    # select the course
    status, details, context = soap_request('SelectServerItem',
                                            'nobody@example.com', 'asdfasdf',
                                            context, ['itemType', 'course'],
                                            ['itemID', @course.to_param],
                                            ['clearState', ''])
    status.should == "Success"

    # list the assignment groups
    status, details, context, list = soap_request('GetServerItems',
                                                  'nobody@example.com', 'asdfasdf',
                                                  context, ['itemType', 'content'])
    status.should == "Success"
    pair = list.item
    pair.name.should == "Assignments"
    pair.value.should == @group.to_param

    # select the assignment group
    status, details, context = soap_request('SelectServerItem',
                                            'nobody@example.com', 'asdfasdf',
                                            context, ['itemType', 'content'],
                                            ['itemID', @group.to_param],
                                            ['clearState', ''])
    status.should == "Success"

    # clear boxin
    data = Marshal.load(Base64.decode64(context.split('--').first))
    data['selection_state'].should == [ @course.to_param, @group.to_param ]
  end

  it "should queue QTI quiz uploads for processing" do
    status, details, context = soap_request('SelectServerItem',
                                            'nobody@example.com', 'asdfasdf',
                                            '', ['itemType', 'course'],
                                            ['itemID', @course.to_param],
                                            ['clearState', ''])
    status.should == "Success"

    mock_migration = ContentMigration.new
    mock_migration.should_receive(:export_content) do
      mock_migration.workflow_state = :imported
      mock_migration.migration_settings[:imported_assets] = ["quiz_xyz"]
      mock_migration.save!
    end
    ContentMigration.stub(:new).and_return(mock_migration)

    status, details, context, item_id = soap_request(
      'PublishServerItem', 'nobody@example.com', 'asdfasdf', context,
      ['itemType', 'quiz'], ['itemName', 'my quiz'], ['uploadType', 'zipPackage'],
      ['fileName', 'import.zip'], ['fileData', 'pretend this is a zip file'])
    status.should == "Success"

    item_id.should == "xyz"
  end
end
