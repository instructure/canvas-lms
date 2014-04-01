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

DOCS_FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures/google_docs/'

def load_fixture(filename)
  File.read(DOCS_FIXTURES_PATH + filename)
end

describe GoogleDocs do
  let(:xml_schema_id) { 'https://docs.google.com/feeds/documents/private/full' }

  let(:xml_doc_list_empty) { load_fixture("doc_list_empty.xml") }
  let(:xml_doc_list_one) { load_fixture("doc_list_one.xml") }
  let(:xml_doc_list_many) { load_fixture("doc_list_many.xml") }
  let(:xml_create_doc_request) { load_fixture("create_doc_request.xml") }
  let(:xml_create_doc_response) { load_fixture("create_doc_response.xml") }
  let(:xml_remove_doc_request) { load_fixture("remove_doc_request.xml") }
  let(:xml_remove_doc_response) { load_fixture("remove_doc_response.xml") }
  let(:xml_add_user_acl) { load_fixture("add_user_acl.xml") }

  before do
    @user = User.create!
    GoogleDocs.stubs(:config).returns(google_doc_settings)
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

  describe "#google_docs_retrieve_access_token" do
    it "should not error out if the google plugin is not configured" do
      GoogleDocs.stubs(:config).returns nil
      google_docs = GoogleDocs.new(@user, {})
      google_docs.google_docs_retrieve_access_token.should be_nil
    end

    it "should use the current_user" do
      user_service = mock
      google_docs_service = mock(token: 'u_token_from_service', secret: 'u_secret_from_service')
      user_service.expects(:find_by_service).with("google_docs").returns(google_docs_service)
      @user.expects(:user_services).returns(user_service)

      consumer = new_mock_consumer('key', 'secret')
      access_token = new_mock_access_token(consumer, 'u_token_from_service', 'u_secret_from_service')

      google_docs = GoogleDocs.new(@user, {})
      google_docs.google_docs_retrieve_access_token.should eql access_token
    end

    it "should use the session data if no user" do
      consumer = new_mock_consumer('key', 'secret')
      access_token = new_mock_access_token(consumer, 'u_token_from_session', 'u_secret_from_session')
      session = {
        :oauth_gdocs_access_token_token => 'u_token_from_session',
        :oauth_gdocs_access_token_secret => 'u_secret_from_session'
      }
      @google_docs = GoogleDocs.new(nil, session)
      @google_docs.google_docs_retrieve_access_token.should == access_token
    end

    it "raises NoTokenError if user does not have google_docs service" do
      Rails.cache.delete(['google_docs_tokens', @user].cache_key)

      user_service = mock
      user_service.expects(:find_by_service).with("google_docs").returns(nil)
      @user.expects(:user_services).returns(user_service)

      new_mock_consumer('key', 'secret')

      google_docs = GoogleDocs.new(@user, {})
      expect do
        google_docs.google_docs_retrieve_access_token
      end.to raise_error(GoogleDocs::NoTokenError)
    end
  end

  describe "#google_docs_list_with_extension_filter" do
    context "with an empty list" do
      before do
        prepare_mock_get xml_doc_list_empty
        @google_docs = GoogleDocs.new(@user, {})
      end
      it "handles an empty list" do
        document_id_list = @google_docs.google_docs_list_with_extension_filter(nil).files.map(&:document_id)
        document_id_list.should == []
      end
      it "handles an empty list with extensions" do
        document_id_list = @google_docs.google_docs_list_with_extension_filter(["jpg"]).files.map(&:document_id)
        document_id_list.should == []
      end
    end

    context "with a single document" do
      before do
        @google_docs = GoogleDocs.new(@user, {})
      end
      it "and nil filter" do
        prepare_mock_get xml_doc_list_one
        list = @google_docs.google_docs_list_with_extension_filter(nil)
        document_id_list = list.files.map(&:document_id)
        document_id_list.should == ["document:1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA"]
      end
      it "and an empty filter" do
        prepare_mock_get xml_doc_list_one
        list = @google_docs.google_docs_list_with_extension_filter([])
        document_id_list = list.files.map(&:document_id)
        document_id_list.should == ["document:1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA"]
      end

      it "returns matches" do
        prepare_mock_get xml_doc_list_one
        list = @google_docs.google_docs_list_with_extension_filter(['doc'])
        document_id_list = list.files.map(&:document_id)
        document_id_list.should == ["document:1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA"]
      end

      it "rejects non matching documents" do
        prepare_mock_get xml_doc_list_one
        list = @google_docs.google_docs_list_with_extension_filter(['xls'])
        document_id_list = list.files.map(&:document_id)
        document_id_list.should == []
      end

    end

    context "with multiple documents" do
      before do
        @google_docs = GoogleDocs.new(@user, {})
      end
      it "returns filesystem view of results" do
        prepare_mock_get xml_doc_list_many
        root_folder = @google_docs.google_docs_list_with_extension_filter(nil)

        root_folder.should be_a(GoogleDocs::Folder)
        root_folder.name.should == '/'
        root_folder.folders.size.should == 1
        root_folder.folders.map { |f| f.name }.should == ["Good Stuff"]
        root_folder.folders.first.files.size.should == 1
        root_folder.folders.first.files.map(&:display_name).should == ["2012 Employee Review Form"]
        root_folder.files.size.should == 10
      end

      it "rejects non matches" do
        prepare_mock_get xml_doc_list_many
        root_folder = @google_docs.google_docs_list_with_extension_filter(['ppt', 'doc'])
        root_folder.files.size.should == 6
        document_id_list = root_folder.files.map(&:document_id)
        document_id_list.should == ["document:15OmhdkR46iZnjFycN8__s6jVKcemzAxAGiFkr6UFxgw", "document:10jp_7QYXSN90iC6iKj_JieUiE72AuJOzLhfEvs0VGrU", "document:135mk8IhGEusw3-nG-GCHNefnlhzW8wH35ytT3EiytLo", "document:1Ohs0PlPbVsDVB0J-nJM7cSC6kvDnz8xRwH70xor4-W4", "document:1dMP-0Cr8xiuBVo86TBikxdv8uM4MOaN5ssYmNMx_xUc", "document:1yzywXxOorojl6mm0RQpgdwsX9B0K0IIn-efXhrVZVFI"]
      end
      it "accepts any of the extensions" do
        prepare_mock_get xml_doc_list_many
        list = @google_docs.google_docs_list_with_extension_filter(['xls', 'doc'])
        document_id_list = list.files.map(&:document_id)
        document_id_list.should == ["spreadsheet:0AiN8C_VHrPxkdEF6YmQyc3p2Qm02ODhJWGJnUmJYY2c", "spreadsheet:0AqsakWbfzwqRdDN1RDhNQ1hDWXpiVXNKN3VMb2Zlamc", "spreadsheet:0AsOXCUtn3LUxdEh6RC1KZEhoMXNqSHczeDdsc3VyYUE", "document:15OmhdkR46iZnjFycN8__s6jVKcemzAxAGiFkr6UFxgw", "document:10jp_7QYXSN90iC6iKj_JieUiE72AuJOzLhfEvs0VGrU", "document:135mk8IhGEusw3-nG-GCHNefnlhzW8wH35ytT3EiytLo", "document:1Ohs0PlPbVsDVB0J-nJM7cSC6kvDnz8xRwH70xor4-W4", "document:1dMP-0Cr8xiuBVo86TBikxdv8uM4MOaN5ssYmNMx_xUc", "spreadsheet:0AsZU1aOHX2kSdGhQVG9CWWdWcTdVZVdBMXh6V0xlVUE", "document:1yzywXxOorojl6mm0RQpgdwsX9B0K0IIn-efXhrVZVFI"]
      end
    end
  end


  describe "#google_docs_download" do
    it "pulls the document out that matches the provided id" do
      doc_id = 'spreadsheet:0AiN8C_VHrPxkdEF6YmQyc3p2Qm02ODhJWGJnUmJYY2c'
      token = mock_access_token
      document_response = mock()
      token.expects(:get).with('https://docs.google.com/feeds/download/spreadsheets/Export?key=0AiN8C_VHrPxkdEF6YmQyc3p2Qm02ODhJWGJnUmJYY2c').returns(document_response)
      response = mock()
      response.expects(:body).returns(xml_doc_list_many)
      token.expects(:get).with(xml_schema_id).returns(response)

      google_docs = GoogleDocs.new(@user, {})
      doc_array = google_docs.google_docs_download(doc_id)
      doc_array[0].should == document_response
      doc_array[1].should == 'Sprint Teams'
      doc_array[2].should == 'xls'
    end

    it "follows redirects" do
      doc_id = 'spreadsheet:0AiN8C_VHrPxkdEF6YmQyc3p2Qm02ODhJWGJnUmJYY2c'
      token = mock_access_token
      document_response = mock()

      redirect = Net::HTTPFound.new(1.0, 302, "FOUND")
      redirect['Location'] = 'http://example.com/1234'
      token.expects(:get).with('https://docs.google.com/feeds/download/spreadsheets/Export?key=0AiN8C_VHrPxkdEF6YmQyc3p2Qm02ODhJWGJnUmJYY2c').returns(redirect)
      token.expects(:get).with('http://example.com/1234').returns(document_response)

      response = mock()
      response.expects(:body).returns(xml_doc_list_many)
      token.expects(:get).with(xml_schema_id).returns(response)

      google_docs = GoogleDocs.new(@user, {})
      doc_array = google_docs.google_docs_download(doc_id)
      doc_array[0].should == document_response
      doc_array[1].should == 'Sprint Teams'
      doc_array[2].should == 'xls'
    end

    it "handles nonexistant entry" do
      doc_id = 'spreadsheet:WRONG'
      token = mock_access_token
      #token.expects(:get).with('https://docs.google.com/feeds/download/spreadsheets/Export?key=0AiN8C_VHrPxkdEF6YmQyc3p2Qm02ODhJWGJnUmJYY2c').returns(mock())
      response = mock()
      response.expects(:body).returns(xml_doc_list_many)
      token.expects(:get).with(xml_schema_id).returns(response)

      google_docs = GoogleDocs.new(@user, {})
      doc_array = google_docs.google_docs_download(doc_id)
      doc_array.should == [nil, nil, nil]
    end
  end

  describe "documents" do
    it "can be created" do
      prepare_mock_post(xml_schema_id, xml_create_doc_request, xml_create_doc_response)

      google_docs = GoogleDocs.new(@user, {})

      new_document = google_docs.google_docs_create_doc "test document"
      new_document.document_id.should == 'document:1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA'
      new_document.extension.should == 'doc'
      new_document.display_name.should == 'test document'
      new_document.download_url.should == 'https://docs.google.com/feeds/download/documents/export/Export?id=1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA'
      new_document.alternate_url.should be_a(Atom::Link)
      new_document.alternate_url.href.should == 'https://docs.google.com/document/d/1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA/edit?hl=en_US'
    end

    it "can be removed" do
      prepare_mock_post('https://docs.google.com/feeds/acl/private/full/document:1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA/batch', xml_remove_doc_request, xml_remove_doc_response)

      google_docs = GoogleDocs.new(@user, {})
      result = google_docs.google_docs_acl_remove 'document:1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA', ['user@example.com']
      result.should == []
    end

    it "can be deleted" do
      prepare_mock_post(xml_schema_id, xml_create_doc_request, xml_create_doc_response)

      google_docs = GoogleDocs.new(@user, {})
      new_document = google_docs.google_docs_create_doc "test document"

      prepare_mock_delete "#{xml_schema_id}/document:1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA"
      google_docs.google_docs_delete_doc new_document
    end
  end

  describe "#google_docs_acl_add" do
    let(:doc_response) { mock }
    let(:doc_id) { "12345" }
    let(:url) { "https://docs.google.com/feeds/acl/private/full/#{doc_id}/batch" }

    it "should add users to a document" do
      prepare_mock_post(url, xml_add_user_acl, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<feed xmlns=\"http://www.w3.org/2005/Atom\"/>\n")

      google_docs = GoogleDocs.new(@user, {})
      mock_user = mock()
      mock_user.stubs(:id).returns(192)
      mock_user.stubs(:google_docs_address).returns('u_id')

      google_docs.google_docs_acl_add('12345', [mock_user], nil)
    end

    it "should optionally filter by domain" do
      access_token = mock_access_token
      access_token.expects(:post).never

      google_docs = GoogleDocs.new(@user, {})
      mock_user = mock()
      mock_user.stubs(:id).returns(192)
      mock_user.stubs(:google_docs_address).returns('u_id')

      google_docs.google_docs_acl_add('12345', [mock_user], 'does-not-match.com')
    end
  end


  # ----------------------------
  # Helper methods for this spec
  # ----------------------------

  def google_doc_settings
    {
      'test_user_token' => 'u_token',
      'test_user_secret' => 'u_secret',
      'test_user_id' => 'u_id',
      'test_user_name' => 'u_name',
      'api_key' => 'key',
      'secret_key' => 'secret'
    }
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

  def new_mock_consumer(api_key, secret_key)
    consumer = mock()
    OAuth::Consumer.expects(:new).with(
      api_key,
      secret_key, {
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

  def new_mock_access_token(consumer, user_token, user_secret)
    access_token = mock()
    OAuth::AccessToken.expects(:new).with(consumer,
                                          user_token,
                                          user_secret).returns(access_token)
    return access_token
  end

  def prepare_mock_get(response_xml)
    response = mock()
    mock_access_token.expects(:get).with(xml_schema_id).returns(response)
    response.expects(:body).returns(response_xml)
  end

  def prepare_mock_post(url, request_xml, response_xml)
    response = mock()
    headers = {'Content-Type' => 'application/atom+xml'}
    mock_access_token.expects(:post).
      with(url, request_xml, headers).returns(response)
    response.expects(:body).returns(response_xml)
  end

  def prepare_mock_delete(xml_schema_id)
    headers = {'GData-Version' => '2', 'If-Match' => '*'}
    mock_access_token.expects(:delete).with(xml_schema_id, headers).returns(mock())
  end
end
