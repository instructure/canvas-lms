#
# Copyright (C) 2011 Instructure, Inc.
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

describe GoogleDocs do

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

  before(:each) do
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

  it 'should add and remove documents' do
    @lib = GoogleDocsTest.new @user, nil, nil
    unless use_remote_services
      consumer = mock()
      OAuth::Consumer.expects(:new).with(GoogleDocs.config["api_key"],
          GoogleDocs.config["secret_key"], {:signature_method => 'HMAC-SHA1',
          :request_token_path => '/accounts/OAuthGetRequestToken',
          :site => 'https://www.google.com',
          :authorize_path => '/accounts/OAuthAuthorizeToken',
          :access_token_path => '/accounts/OAuthGetAccessToken'}).returns(consumer)
      access_token = mock()
      OAuth::AccessToken.expects(:new).with(consumer,
          GoogleDocs.config["test_user_token"],
          GoogleDocs.config["test_user_secret"]).returns(access_token)
      list_response = mock()
      access_token.expects(:get).with('https://docs.google.com/feeds/documents/private/full').returns(list_response)
      list_response.expects(:body).returns("<?xml version='1.0' encoding='UTF-8'?><feed xmlns='http://www.w3.org/2005/Atom' xmlns:openSearch='http://a9.com/-/spec/opensearchrss/1.0/' xmlns:docs='http://schemas.google.com/docs/2007' xmlns:batch='http://schemas.google.com/gdata/batch' xmlns:gd='http://schemas.google.com/g/2005'><id>https://docs.google.com/feeds/documents/private/full</id><updated>2011-10-31T22:23:05.864Z</updated><category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/docs/2007#item' label='item'/><title type='text'>Available Documents - instructure.test.2011@gmail.com</title><link rel='alternate' type='text/html' href='http://docs.google.com'/><link rel='http://schemas.google.com/g/2005#feed' type='application/atom+xml' href='https://docs.google.com/feeds/documents/private/full'/><link rel='http://schemas.google.com/g/2005#post' type='application/atom+xml' href='https://docs.google.com/feeds/documents/private/full'/><link rel='http://schemas.google.com/g/2005#batch' type='application/atom+xml' href='https://docs.google.com/feeds/documents/private/full/batch'/><link rel='self' type='application/atom+xml' href='https://docs.google.com/feeds/documents/private/full'/><author><name>instructure.test.2011</name><email>instructure.test.2011@gmail.com</email></author><openSearch:totalResults>0</openSearch:totalResults><openSearch:startIndex>1</openSearch:startIndex></feed>")
    end

    document_id_list = @lib.google_doc_list.files.map(&:document_id)

    unless use_remote_services
      consumer = mock()
      OAuth::Consumer.expects(:new).with(GoogleDocs.config["api_key"],
          GoogleDocs.config["secret_key"], {:signature_method => 'HMAC-SHA1',
          :request_token_path => '/accounts/OAuthGetRequestToken',
          :site => 'https://www.google.com',
          :authorize_path => '/accounts/OAuthAuthorizeToken',
          :access_token_path => '/accounts/OAuthGetAccessToken'}).returns(consumer)
      access_token = mock()
      OAuth::AccessToken.expects(:new).with(consumer,
          GoogleDocs.config["test_user_token"],
          GoogleDocs.config["test_user_secret"]).returns(access_token)
      create_response = mock()
      access_token.expects(:post).with('https://docs.google.com/feeds/documents/private/full',
          "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<entry xmlns=\"http://www.w3.org/2005/Atom\">\n  <title>test document</title>\n  <category label=\"document\" scheme=\"http://schemas.google.com/g/2005#kind\" term=\"http://schemas.google.com/docs/2007#document\"/>\n</entry>\n", {'Content-Type' => 'application/atom+xml'}).returns(create_response)
      create_response.expects(:body).returns("<?xml version='1.0' encoding='UTF-8'?><entry xmlns='http://www.w3.org/2005/Atom' xmlns:docs='http://schemas.google.com/docs/2007' xmlns:batch='http://schemas.google.com/gdata/batch' xmlns:gd='http://schemas.google.com/g/2005'><id>https://docs.google.com/feeds/documents/private/full/document%3A1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA</id><published>2011-10-31T22:23:06.375Z</published><updated>2011-10-31T22:23:06.993Z</updated><category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/docs/2007#document' label='document'/><category scheme='http://schemas.google.com/g/2005/labels' term='http://schemas.google.com/g/2005/labels#viewed' label='viewed'/><title type='text'>test document</title><content type='text/html' src='https://docs.google.com/feeds/download/documents/export/Export?id=1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA'/><link rel='alternate' type='text/html' href='https://docs.google.com/document/d/1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA/edit?hl=en_US'/><link rel='self' type='application/atom+xml' href='https://docs.google.com/feeds/documents/private/full/document%3A1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA'/><link rel='edit' type='application/atom+xml' href='https://docs.google.com/feeds/documents/private/full/document%3A1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA/gug1bunq'/><link rel='edit-media' type='text/html' href='https://docs.google.com/feeds/media/private/full/document%3A1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA/gug1bunq'/><author><name>instructure.test.2011</name><email>instructure.test.2011@gmail.com</email></author><gd:resourceId>document:1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA</gd:resourceId><gd:lastModifiedBy><name>instructure.test.2011</name><email>instructure.test.2011@gmail.com</email></gd:lastModifiedBy><gd:lastViewed>2011-10-31T22:23:06.652Z</gd:lastViewed><gd:quotaBytesUsed>0</gd:quotaBytesUsed><docs:writersCanInvite value='true'/><gd:feedLink rel='http://schemas.google.com/acl/2007#accessControlList' href='https://docs.google.com/feeds/acl/private/full/document%3A1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA'/></entry>")
    end

    new_document = @lib.google_docs_create_doc "test document"
    document_id_list.include?(new_document.document_id).should be_false

    unless use_remote_services
      consumer = mock()
      OAuth::Consumer.expects(:new).with(GoogleDocs.config["api_key"],
          GoogleDocs.config["secret_key"], {:signature_method => 'HMAC-SHA1',
          :request_token_path => '/accounts/OAuthGetRequestToken',
          :site => 'https://www.google.com',
          :authorize_path => '/accounts/OAuthAuthorizeToken',
          :access_token_path => '/accounts/OAuthGetAccessToken'}).returns(consumer)
      access_token = mock()
      OAuth::AccessToken.expects(:new).with(consumer,
          GoogleDocs.config["test_user_token"],
          GoogleDocs.config["test_user_secret"]).returns(access_token)
      list_response = mock()
      access_token.expects(:get).with('https://docs.google.com/feeds/documents/private/full').returns(list_response)
      list_response.expects(:body).returns("<?xml version='1.0' encoding='UTF-8'?><feed xmlns='http://www.w3.org/2005/Atom' xmlns:openSearch='http://a9.com/-/spec/opensearchrss/1.0/' xmlns:docs='http://schemas.google.com/docs/2007' xmlns:batch='http://schemas.google.com/gdata/batch' xmlns:gd='http://schemas.google.com/g/2005'><id>https://docs.google.com/feeds/documents/private/full</id><updated>2011-10-31T22:23:07.920Z</updated><category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/docs/2007#item' label='item'/><title type='text'>Available Documents - instructure.test.2011@gmail.com</title><link rel='alternate' type='text/html' href='http://docs.google.com'/><link rel='http://schemas.google.com/g/2005#feed' type='application/atom+xml' href='https://docs.google.com/feeds/documents/private/full'/><link rel='http://schemas.google.com/g/2005#post' type='application/atom+xml' href='https://docs.google.com/feeds/documents/private/full'/><link rel='http://schemas.google.com/g/2005#batch' type='application/atom+xml' href='https://docs.google.com/feeds/documents/private/full/batch'/><link rel='self' type='application/atom+xml' href='https://docs.google.com/feeds/documents/private/full'/><author><name>instructure.test.2011</name><email>instructure.test.2011@gmail.com</email></author><openSearch:totalResults>1</openSearch:totalResults><openSearch:startIndex>1</openSearch:startIndex><entry><id>https://docs.google.com/feeds/documents/private/full/document%3A1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA</id><published>2011-10-31T22:23:06.375Z</published><updated>2011-10-31T22:23:06.993Z</updated><category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/docs/2007#document' label='document'/><category scheme='http://schemas.google.com/g/2005/labels' term='http://schemas.google.com/g/2005/labels#viewed' label='viewed'/><title type='text'>test document</title><content type='text/html' src='https://docs.google.com/feeds/download/documents/export/Export?id=1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA'/><link rel='alternate' type='text/html' href='https://docs.google.com/document/d/1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA/edit?hl=en_US'/><link rel='self' type='application/atom+xml' href='https://docs.google.com/feeds/documents/private/full/document%3A1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA'/><link rel='edit' type='application/atom+xml' href='https://docs.google.com/feeds/documents/private/full/document%3A1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA/gug1buow'/><link rel='edit-media' type='text/html' href='https://docs.google.com/feeds/media/private/full/document%3A1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA/gug1buow'/><author><name>instructure.test.2011</name><email>instructure.test.2011@gmail.com</email></author><gd:resourceId>document:1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA</gd:resourceId><gd:lastModifiedBy><name>instructure.test.2011</name><email>instructure.test.2011@gmail.com</email></gd:lastModifiedBy><gd:lastViewed>2011-10-31T22:23:07.015Z</gd:lastViewed><gd:quotaBytesUsed>0</gd:quotaBytesUsed><docs:writersCanInvite value='true'/><gd:feedLink rel='http://schemas.google.com/acl/2007#accessControlList' href='https://docs.google.com/feeds/acl/private/full/document%3A1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA'/></entry></feed>")
    end

    @lib.google_doc_list.files.map(&:document_id).include?(new_document.document_id).should be_true

    unless use_remote_services
      consumer = mock()
      OAuth::Consumer.expects(:new).with(GoogleDocs.config["api_key"],
          GoogleDocs.config["secret_key"], {:signature_method => 'HMAC-SHA1',
          :request_token_path => '/accounts/OAuthGetRequestToken',
          :site => 'https://www.google.com',
          :authorize_path => '/accounts/OAuthAuthorizeToken',
          :access_token_path => '/accounts/OAuthGetAccessToken'}).returns(consumer)
      access_token = mock()
      OAuth::AccessToken.expects(:new).with(consumer,
          GoogleDocs.config["test_user_token"],
          GoogleDocs.config["test_user_secret"]).returns(access_token)
      access_token.expects(:delete).with('https://docs.google.com/feeds/documents/private/full/document:1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA', {'GData-Version' => '2', 'If-Match' => '*'}).returns(mock())
    end

    @lib.google_docs_delete_doc new_document

    unless use_remote_services
      consumer = mock()
      OAuth::Consumer.expects(:new).with(GoogleDocs.config["api_key"],
          GoogleDocs.config["secret_key"], {:signature_method => 'HMAC-SHA1',
          :request_token_path => '/accounts/OAuthGetRequestToken',
          :site => 'https://www.google.com',
          :authorize_path => '/accounts/OAuthAuthorizeToken',
          :access_token_path => '/accounts/OAuthGetAccessToken'}).returns(consumer)
      access_token = mock()
      OAuth::AccessToken.expects(:new).with(consumer,
          GoogleDocs.config["test_user_token"],
          GoogleDocs.config["test_user_secret"]).returns(access_token)
      list_response = mock()
      access_token.expects(:get).with('https://docs.google.com/feeds/documents/private/full').returns(list_response)
      list_response.expects(:body).returns("<?xml version='1.0' encoding='UTF-8'?><feed xmlns='http://www.w3.org/2005/Atom' xmlns:openSearch='http://a9.com/-/spec/opensearchrss/1.0/' xmlns:docs='http://schemas.google.com/docs/2007' xmlns:batch='http://schemas.google.com/gdata/batch' xmlns:gd='http://schemas.google.com/g/2005'><id>https://docs.google.com/feeds/documents/private/full</id><updated>2011-10-31T22:23:09.244Z</updated><category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/docs/2007#item' label='item'/><title type='text'>Available Documents - instructure.test.2011@gmail.com</title><link rel='alternate' type='text/html' href='http://docs.google.com'/><link rel='http://schemas.google.com/g/2005#feed' type='application/atom+xml' href='https://docs.google.com/feeds/documents/private/full'/><link rel='http://schemas.google.com/g/2005#post' type='application/atom+xml' href='https://docs.google.com/feeds/documents/private/full'/><link rel='http://schemas.google.com/g/2005#batch' type='application/atom+xml' href='https://docs.google.com/feeds/documents/private/full/batch'/><link rel='self' type='application/atom+xml' href='https://docs.google.com/feeds/documents/private/full'/><author><name>instructure.test.2011</name><email>instructure.test.2011@gmail.com</email></author><openSearch:totalResults>0</openSearch:totalResults><openSearch:startIndex>1</openSearch:startIndex></feed>")
    end

    @lib.google_doc_list.files.map(&:document_id).include?(new_document.document_id).should be_false
  end

  it "should use the real_current_user if possible" do
    @user2 = User.create!
    @lib = GoogleDocsTest.new nil, @user, @user2
    unless use_remote_services
      consumer = mock()
      OAuth::Consumer.expects(:new).with(GoogleDocs.config["api_key"],
          GoogleDocs.config["secret_key"], {:signature_method => 'HMAC-SHA1',
          :request_token_path => '/accounts/OAuthGetRequestToken',
          :site => 'https://www.google.com',
          :authorize_path => '/accounts/OAuthAuthorizeToken',
          :access_token_path => '/accounts/OAuthGetAccessToken'}).returns(consumer)
    end
    lambda { @lib.google_docs_retrieve_access_token }.should raise_error
  end

  it "should use the current_user if no real_current_user" do
    @lib = GoogleDocsTest.new nil, @user, nil
    unless use_remote_services
      consumer = mock()
      OAuth::Consumer.expects(:new).with(GoogleDocs.config["api_key"],
          GoogleDocs.config["secret_key"], {:signature_method => 'HMAC-SHA1',
          :request_token_path => '/accounts/OAuthGetRequestToken',
          :site => 'https://www.google.com',
          :authorize_path => '/accounts/OAuthAuthorizeToken',
          :access_token_path => '/accounts/OAuthGetAccessToken'}).returns(consumer)
      access_token = mock()
      OAuth::AccessToken.expects(:new).with(consumer,
          GoogleDocs.config["test_user_token"],
          GoogleDocs.config["test_user_secret"]).returns(access_token)
    end
    @lib.google_docs_retrieve_access_token.should eql access_token
  end
end
