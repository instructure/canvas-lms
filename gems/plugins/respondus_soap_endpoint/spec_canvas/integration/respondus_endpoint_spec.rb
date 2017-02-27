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

describe "Respondus SOAP API", type: :request do
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
    setting = PluginSetting.where(name: 'qti_converter').new
    setting.settings = Canvas::Plugin.find('qti_converter').default_settings.merge({:enabled => 'true'})
    setting.save!
    setting = PluginSetting.where(name: 'respondus_soap_endpoint').new
    setting.settings = {:enabled => 'true'}
    setting.save!
    user_with_pseudonym :active_user => true,
      :username => "nobody@example.com",
      :password => "asdfasdf"
    @user.save!
    @course = factory_with_protected_attributes(Course, course_valid_attributes)
    @course.enroll_teacher(@user).accept
    @quiz = Quizzes::Quiz.create!(:title => 'quiz1', :context => @course)
    @question_bank = AssessmentQuestionBank.create!(:title => 'questionbank1', :context => @course)
  end

  it "should identify the server without user credentials" do
    soap_response = soap_request('IdentifyServer', '', '', '')
    expect(soap_response.first).to eq "Success"
    expect(soap_response.last).to eq %{
Respondus Generic Server API
Contract version: 1
Implemented for: Canvas LMS}
  end

  it "should authenticate an existing user" do
    soap_response = soap_request('ValidateAuth',
                                 'nobody@example.com', 'asdfasdf',
                                 '',
                                 ['Institution', ''])
    expect(soap_response.first).to eq "Success"
  end

  it "should reject a user with bad auth" do
    soap_response = soap_request('ValidateAuth',
                                 'nobody@example.com', 'hax0r',
                                 '',
                                 ['Institution', ''])
    expect(soap_response.first).to eq "Invalid credentials"
  end

  if Canvas.redis_enabled?
    it "should limit the max failed login attempts" do
      Setting.set('login_attempts_total', '2')
      soap_response = soap_request('ValidateAuth',
                                   'nobody@example.com', 'hax0r',
                                   '',
                                   ['Institution', ''])
      expect(soap_response.first).to eq "Invalid credentials"
      soap_response = soap_request('ValidateAuth',
                                   'nobody@example.com', 'hax0r',
                                   '',
                                   ['Institution', ''])
      expect(soap_response.first).to eq "Invalid credentials"
      # now use the right credentials, but it'll still fail because max attempts
      # was reached. unfortunately we can't return a more specific error message.
      soap_response = soap_request('ValidateAuth',
                                   'nobody@example.com', 'asdfasdf',
                                   '',
                                   ['Institution', ''])
      expect(soap_response.first).to eq "Invalid credentials"
    end
  end

  describe "delegated auth" do
    before do
      @account = account_with_cas(:account => Account.default)
    end

    it "should error if token is required" do
      soap_response = soap_request('ValidateAuth',
                                   'nobody@example.com', 'hax0r',
                                   '',
                                   ['Institution', ''])
      expect(soap_response.first).to eq "Access token required"
    end

    it "should allow using an oauth token for delegated auth" do
      uname = 'oauth_access_token'
      # we already test the oauth flow in spec/apis/oauth_spec, so shortcut here
      @key = DeveloperKey.create!
      @token = AccessToken.create!(:user => @user, :developer_key => @key)
      soap_response = soap_request('ValidateAuth',
                                   uname, @token.full_token,
                                   '',
                                   ['Institution', ''])
      expect(soap_response.first).to eq "Success"

      status, details, context, list = soap_request('GetServerItems',
                                                    uname, @token.full_token,
                                                    '', ['itemType', 'course'])
      expect(status).to eq "Success"
      pair = list.item
      expect(pair.name).to eq "value for name"
      expect(pair.value).to eq @course.to_param

      # verify that the respondus api session works with token auth
      status, details, context = soap_request('SelectServerItem',
                                              uname, @token.full_token,
                                              context, ['itemType', 'course'],
                                              ['itemID', @course.to_param],
                                              ['clearState', ''])
      expect(status).to eq "Success"
    end

    it "should continue to allow canvas login for delegated domains, for now" do
      soap_response = soap_request('ValidateAuth',
                                   'nobody@example.com', 'asdfasdf',
                                   '',
                                   ['Institution', ''])
      expect(soap_response.first).to eq "Success"
    end
  end

  it "should reject a session created for a different user" do
    user1 = @user
    user2 = user_with_pseudonym :active_user => true,
      :username => "nobody2@example.com",
      :password => "test1234"
    user2.save!

    status, details, context = soap_request('ValidateAuth',
                                 'nobody@example.com', 'asdfasdf',
                                 '',
                                 ['Institution', ''])
    expect(status).to eq "Success"
    status, details, context = soap_request('ValidateAuth',
                                 'nobody@example.com', 'asdfasdf',
                                 context,
                                 ['Institution', ''])
    expect(status).to eq "Success"
    status, details, context2 = soap_request('ValidateAuth',
                                 'nobody2@example.com', 'test1234',
                                 '',
                                 ['Institution', ''])
    expect(status).to eq "Success"
    status, details, context2 = soap_request('ValidateAuth',
                                 'nobody2@example.com', 'test1234',
                                 context,
                                 ['Institution', ''])
    expect(status).to eq "Invalid context"
  end

  it "should allow selecting a course" do
    status, details, context, list = soap_request('GetServerItems',
                                                  'nobody@example.com', 'asdfasdf',
                                                  '', ['itemType', 'course'])
    expect(status).to eq "Success"
    pair = list.item
    expect(pair.name).to eq "value for name"
    expect(pair.value).to eq @course.to_param

    # select the course
    status, details, context = soap_request('SelectServerItem',
                                            'nobody@example.com', 'asdfasdf',
                                            context, ['itemType', 'course'],
                                            ['itemID', @course.to_param],
                                            ['clearState', ''])
    expect(status).to eq "Success"

    # list the existing quizzes
    status, details, context, list = soap_request('GetServerItems',
                                                  'nobody@example.com', 'asdfasdf',
                                                  context, ['itemType', 'quiz'])
    expect(status).to eq "Success"
    pair = list.item
    expect(pair.name).to eq "quiz1"
    expect(pair.value).to eq @quiz.to_param

    # list the existing question banks
    status, details, context, list = soap_request('GetServerItems',
                                                  'nobody@example.com', 'asdfasdf',
                                                  context, ['itemType', 'qdb'])
    expect(status).to eq "Success"
    pair = list.item
    expect(pair.name).to eq "questionbank1"
    expect(pair.value).to eq @question_bank.to_param

    # clear boxin
    data = Marshal.load(Base64.decode64(context.split('--').first))
    expect(data['selection_state']).to eq [ @course.to_param ]
  end

  it "should queue QTI quiz uploads for processing" do
    Setting.set('respondus_endpoint.polling_api', 'false')

    status, details, context = soap_request('SelectServerItem',
                                            'nobody@example.com', 'asdfasdf',
                                            '', ['itemType', 'course'],
                                            ['itemID', @course.to_param],
                                            ['clearState', ''])
    expect(status).to eq "Success"

    mock_migration = ContentMigration.create!(context: @course)
    def mock_migration.export_content
      self.workflow_state = 'imported'
      self.migration_settings[:imported_assets] = ["quizzes:quiz_xyz"]
    end
    ContentMigration.stubs(:new).returns(mock_migration)
    ContentMigration.stubs(:find).with(mock_migration.id).returns(mock_migration)

    status, details, context, item_id = soap_request(
      'PublishServerItem', 'nobody@example.com', 'asdfasdf', context,
      ['itemType', 'quiz'], ['itemName', 'my quiz'], ['uploadType', 'zipPackage'],
      ['fileName', 'import.zip'], ['fileData', 'pretend this is a zip file'])
    expect(status).to eq "Success"

    expect(item_id).to eq "xyz"

    # import root folder should've been created and marked as hidden
    folder = Folder.assert_path(RespondusSoapEndpoint::RespondusAPIPort::ATTACHMENT_FOLDER_NAME,
                                @course)
    expect(folder.hidden?).to eq true
  end

  describe "polling publish" do
    before do
      status, details, context = soap_request('SelectServerItem',
                                              'nobody@example.com', 'asdfasdf',
                                              '', ['itemType', 'course'],
                                              ['itemID', @course.to_param],
                                              ['clearState', ''])
      @mock_migration = ContentMigration.create!(context: @course)
      def @mock_migration.export_content
        self.workflow_state = 'importing'
      end
      ContentMigration.stubs(:new).returns(@mock_migration)
      ContentMigration.stubs(:find).with(@mock_migration.id).returns(@mock_migration)

      status, details, context, item_id = soap_request(
        'PublishServerItem', 'nobody@example.com', 'asdfasdf', context,
        ['itemType', 'quiz'], ['itemName', 'my quiz'], ['uploadType', 'zipPackage'],
        ['fileName', 'import.zip'], ['fileData', 'pretend this is a zip file'])
      @token = context
    end

    it "should respond immediately and allow polling for completion" do
      status, details, context, item_id = soap_request(
        'PublishServerItem', 'nobody@example.com', 'asdfasdf', @token,
        ['itemType', 'quiz'], ['itemName', 'my quiz'], ['uploadType', 'zipPackage'],
        ['fileName', 'import.zip'], ['fileData', "\x0"])
      expect(status).to eq "Success"
      expect(item_id).to eq 'pending'
      expect(@token).to eq context

      @mock_migration.migration_settings[:imported_assets] = ["quizzes:quiz_xyz"]
      @mock_migration.workflow_state = 'imported'

      status, details, context, item_id = soap_request(
        'PublishServerItem', 'nobody@example.com', 'asdfasdf', @token,
        ['itemType', 'quiz'], ['itemName', 'my quiz'], ['uploadType', 'zipPackage'],
        ['fileName', 'import.zip'], ['fileData', "\x0"])
      expect(status).to eq "Success"
      expect(item_id).to eq 'xyz'
    end

    it "should respond with failures asynchronously as well" do
      @mock_migration.migration_settings[:imported_assets] = []
      @mock_migration.workflow_state = 'failed'

      status, details, context, item_id = soap_request(
        'PublishServerItem', 'nobody@example.com', 'asdfasdf', @token,
        ['itemType', 'quiz'], ['itemName', 'my quiz'], ['uploadType', 'zipPackage'],
        ['fileName', 'import.zip'], ['fileData', "\x0"])
      expect(status).to eq "Invalid file data"
      expect(item_id).to eq nil
    end
  end
end
