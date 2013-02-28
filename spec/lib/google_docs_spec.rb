#
# Copyright (C) 2011-2013 Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

class GoogleDocsTest
  include GoogleDocs

  attr_accessor :user, :current_user, :real_current_user

  def initialize(user, current_user, real_current_user)
    @user = user
    @current_user = current_user
    @real_current_user = real_current_user
  end
end

DOCS_FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures/google_docs/'
def load_fixture(filename)
  File.read(DOCS_FIXTURES_PATH + filename)
end

describe GoogleDocs do

  let(:lib) { GoogleDocsTest.new(@user, nil, nil) }
  let(:xml_schema_id) { 'https://docs.google.com/feeds/documents/private/full' }

  let(:xml_doc_list_empty)      { load_fixture("doc_list_empty.xml") }
  let(:xml_doc_list_one)        { load_fixture("doc_list_one.xml") }
  let(:xml_doc_list_many)        { load_fixture("doc_list_many.xml") }
  let(:xml_create_doc_request)  { load_fixture("create_doc_request.xml") }
  let(:xml_create_doc_response) { load_fixture("create_doc_response.xml") }
  let(:xml_delete_doc_request)  { load_fixture("delete_doc_request.xml") }
  let(:xml_delete_doc_response) { load_fixture("delete_doc_response.xml") }

  before do
    @user = User.create!
    PluginSetting.create!(:name => 'google_docs', :settings => google_doc_settings)
    UserService.register(
      :service => "google_docs",
      :token => GoogleDocs.config["test_user_token"],
      :secret => GoogleDocs.config["test_user_secret"],
      :user => @user,
      :service_domain => "google.com",
      :service_user_id => GoogleDocs.config["test_user_id"],
      :service_user_name => GoogleDocs.config["test_user_name"]
    )
  end

  it "should allow a null access_token to be passed" do
    body     = File.read('spec/fixtures/google_docs/doc_list.xml')
    token    = mock()
    token.expects(:get).
      with('https://docs.google.com/feeds/documents/private/full').
      returns(Struct.new(:body).new(body))
    lib.expects(:google_docs_retrieve_access_token).returns(token)

    lib.google_docs_list(nil)
  end

  describe "documents" do

    it "can be an empty list" do
      prepare_mock_get xml_doc_list_empty

      document_id_list = lib.google_docs_list.files.map(&:document_id)
      document_id_list.should == []
    end

    it "can be listed" do
      prepare_mock_get xml_doc_list_one
      list = lib.google_docs_list
      document_id_list = list.files.map(&:document_id)
      document_id_list.should == ["document:1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA"]
    end

    it "can folderize the list" do
      prepare_mock_get xml_doc_list_many
      root_folder = lib.google_docs_list
      root_folder.should be_a(GoogleDocs::Folder)
      root_folder.name.should == '/'
      root_folder.folders.size.should == 1
      root_folder.folders.map{ |f| f.name }.should == ["Good Stuff"]
      root_folder.folders.first.files.size.should == 1
      root_folder.folders.first.files.map(&:display_name).should == ["2012 Employee Review Form"]
      root_folder.files.size.should == 10
    end

    it "can be created" do
      prepare_mock_post \
        xml_create_doc_request,
        xml_create_doc_response
      new_document = lib.google_docs_create_doc "test document"
    end


    it "can be deleted" do
      prepare_mock_post \
        xml_create_doc_request,
        xml_create_doc_response
      new_document = lib.google_docs_create_doc "test document"

      prepare_mock_delete "#{xml_schema_id}/document:1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA"
      lib.google_docs_delete_doc new_document
    end
  end

  describe '#google_docs_retrieve_access_token' do
    it "should use the real_current_user if possible" do
      lib = GoogleDocsTest.new nil, @user, User.create!
      mock_consumer()

      lambda { lib.google_docs_retrieve_access_token }.should \
        raise_error(RuntimeError, 'User does not have valid Google Docs token')
    end

    it "should use the current_user if no real_current_user" do
      lib = GoogleDocsTest.new nil, @user, nil
      access_token = mock_access_token()
      lib.google_docs_retrieve_access_token.should eql access_token
    end

    it 'should not error out if the google plugin is not configured' do
      GoogleDocs.stubs(:config).returns nil
      lib = GoogleDocsTest.new nil, @user, nil
      lib.google_docs_retrieve_access_token.should be_nil
    end
  end

  describe '#google_docs_download' do
    it 'pulls the document out that matches the provided id' do
      doc_id = 'spreadsheet:0AiN8C_VHrPxkdEF6YmQyc3p2Qm02ODhJWGJnUmJYY2c'
      token = mock_access_token
      token.expects(:get).with('https://docs.google.com/feeds/download/spreadsheets/Export?key=0AiN8C_VHrPxkdEF6YmQyc3p2Qm02ODhJWGJnUmJYY2c').returns(mock())
      response = mock()
      response.expects(:body).returns(xml_doc_list_many)
      token.expects(:get).with(xml_schema_id).returns(response)

      lib = GoogleDocsTest.new nil, @user, nil
      doc_array = lib.google_docs_download(doc_id)
      doc_array[1].should == 'Sprint Teams'
    end
  end

  # ----------------------------
  # Helper methods for this spec
  # ----------------------------

  def google_doc_settings
    path = RAILS_ROOT + "/config/google_docs.yml"
    if File.exists?(path)
      YAML.load_file(path)[RAILS_ENV]
    else
      {
        'test_user_token' => 'u_token',
        'test_user_secret' => 'u_secret',
        'test_user_id' => 'u_id',
        'test_user_name' => 'u_name',
        'api_key' => 'key',
        'secret_key' => 'secret'
      }
    end
  end

  def mock_consumer
    consumer = mock()
    OAuth::Consumer.expects(:new).with(
      GoogleDocs.config["api_key"],
      GoogleDocs.config["secret_key"], {
        :signature_method => 'HMAC-SHA1',
        :request_token_path => '/accounts/OAuthGetRequestToken',
        :site => 'https://www.google.com',
        :authorize_path => '/accounts/OAuthAuthorizeToken',
        :access_token_path => '/accounts/OAuthGetAccessToken'}).returns(consumer)
    return consumer
  end

  def mock_access_token
    access_token = mock()
    OAuth::AccessToken.expects(:new).with(mock_consumer(),
      GoogleDocs.config["test_user_token"],
      GoogleDocs.config["test_user_secret"]).returns(access_token)
    return access_token
  end

  def prepare_mock_get(response_xml)
    response = mock()
    mock_access_token.expects(:get).with(xml_schema_id).returns(response)
    response.expects(:body).returns(response_xml)
  end

  def prepare_mock_post(request_xml, response_xml)
    response = mock()
    headers = {'Content-Type' => 'application/atom+xml'}
    mock_access_token.expects(:post).
      with(xml_schema_id, request_xml, headers).returns(response)
    response.expects(:body).returns(response_xml)
  end

  def prepare_mock_delete(xml_schema_id)
    response = mock()
    headers = {'GData-Version' => '2', 'If-Match' => '*'}
    mock_access_token.expects(:delete).with(xml_schema_id, headers).returns(mock())
  end
end
