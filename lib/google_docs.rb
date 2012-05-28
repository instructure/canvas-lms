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

# See Google Docs API documentation here:
# http://code.google.com/apis/documents/docs/2.0/developers_guide_protocol.html
module GoogleDocs

  def google_docs_retrieve_access_token
    consumer = google_consumer
    if retrieve_current_user
      service_token, service_secret = Rails.cache.fetch(['google_docs_tokens', @current_user].cache_key) do
        service = @current_user.user_services.find_by_service("google_docs")
        service && [service.token, service.secret]
      end
      raise "User does not have valid Google Docs token" unless service_token && service_secret
      access_token = OAuth::AccessToken.new(consumer, service_token, service_secret)
    else
      access_token = OAuth::AccessToken.new(consumer, session[:oauth_gdocs_access_token_token], session[:oauth_gdocs_access_token_secret])
    end
    access_token
  end

  def retrieve_current_user
    @current_user ||= (self.respond_to?(:user) && self.user.is_a?(User) && self.user) || nil
  end

  def google_docs_get_service_user(access_token)
    doc = google_docs_create_doc("Temp Doc", true, access_token)
    google_docs_delete_doc(doc, access_token)
    service_user_id = doc.entry.authors[0].email rescue nil
    service_user_name = doc.entry.authors[0].email rescue nil
    return service_user_id, service_user_name
  end

  def google_docs_get_access_token(oauth_request, oauth_verifier)
    consumer = google_consumer
    request_token = OAuth::RequestToken.new(consumer,
                                            session.delete(:oauth_google_docs_request_token_token),
                                            session.delete(:oauth_google_docs_request_token_secret))
    access_token = request_token.get_access_token(:oauth_verifier => oauth_verifier)
    service_user_id, service_user_name = google_docs_get_service_user(access_token)
    session[:oauth_gdocs_access_token_token] = access_token.token
    session[:oauth_gdocs_access_token_secret] = access_token.secret
    if oauth_request.user
      UserService.register(
        :service => "google_docs",
        :access_token => access_token,
        :user => oauth_request.user,
        :service_domain => "google.com",
        :service_user_id => service_user_id,
        :service_user_name => service_user_name
      )
      oauth_request.destroy
      session.delete(:oauth_gdocs_access_token_token)
      session.delete(:oauth_gdocs_access_token_secret)
    end
    access_token
  end

  def google_docs_request_token_url(return_to)
    consumer = google_consumer
    request_token = consumer.get_request_token({ :oauth_callback => oauth_success_url(:service => 'google_docs')}, {:scope => "https://docs.google.com/feeds/ https://spreadsheets.google.com/feeds/"})
    session[:oauth_google_docs_request_token_token] = request_token.token
    session[:oauth_google_docs_request_token_secret] = request_token.secret
    OauthRequest.create(
      :service => 'google_docs',
      :token => request_token.token,
      :secret => request_token.secret,
      :user_secret => AutoHandle.generate(nil, 16),
      :return_url => return_to,
      :user => @current_user,
      :original_host_with_port => request.host_with_port
    )
    request_token.authorize_url
  end

  def google_docs_download(document_id)
    access_token = google_docs_retrieve_access_token
    entry = google_doc_list(access_token).files.find{|e| e.document_id == document_id}
    if entry
      response = access_token.get(entry.download_url)
      response = access_token.get(response['Location']) if response.is_a?(Net::HTTPFound)
      [response, entry.display_name, entry.extension]
    else
      [nil, nil, nil]
    end
  end

  def google_doc_list(access_token=nil, only_extensions=nil)
    access_token ||= google_docs_retrieve_access_token
    docs = Atom::Feed.load_feed(access_token.get("https://docs.google.com/feeds/documents/private/full").body)
    folders = []
    entries = []
    docs.entries.each do |entry|
      folder = entry.categories.find{|c| c.scheme.match(/\Ahttp:\/\/schemas.google.com\/docs\/2007\/folders/)}
      folders << folder.label if folder
      entries << GoogleDocEntry.new(entry)
    end
    folders.uniq!
    folders.sort!
    res = OpenObject.new
    unless only_extensions.blank?
      entries.reject! { |e| !only_extensions.include?(e.extension) }
    end
    res.files = entries
    res.folders = folders
    res
  end

  def google_consumer(key=nil, secret=nil)
    require 'oauth'
    require 'oauth/consumer'
    key ||= GoogleDocs.config['api_key']
    secret ||= GoogleDocs.config['secret_key']
    consumer = OAuth::Consumer.new(key, secret, {
      :site => "https://www.google.com",
      :request_token_path => "/accounts/OAuthGetRequestToken",
      :access_token_path => "/accounts/OAuthGetAccessToken",
      :authorize_path=> "/accounts/OAuthAuthorizeToken",
      :signature_method => "HMAC-SHA1"
    })
  end

  class Google
    class Google::Batch
    class Google::Batch::Operation
      attr_accessor :type
      def initialize(operation_type="insert")
        self.type = operation_type
      end
      def to_xml(*opts)
        n = XML::Node.new("batch:operation")
        n['type'] = type
        n
      end
    end
    end
    class Google::GAcl
    class Google::GAcl::Role
      attr_accessor :role
      def initialize()
        self.role = "writer"
      end
      def to_xml(*opts)
        n = XML::Node.new("gAcl:role")
        n['value'] = role
        n
      end
    end
    class Google::GAcl::Scope
      attr_accessor :type, :value
      def initialize(email)
        self.type = "user"
        self.value = email
      end
      def to_xml(*opts)
        n = XML::Node.new("gAcl:scope")
        n['type'] = type
        n['value'] = value
        n
      end
    end
    end
  end
  class Entry < Atom::Entry
    namespace Atom::NAMESPACE
    element "id"
    element "batch:id"
    element "batch:operation", :class => Google::Batch::Operation
    element "gAcl:role", :class => Google::GAcl::Role
    element "gAcl:scope", :class => Google::GAcl::Scope
    elements :categories
    add_extension_namespace :batch, 'http://schemas.google.com/gdata/batch'
    add_extension_namespace :gAcl, 'http://schemas.google.com/acl/2007'
  end
  class Feed < Atom::Feed
    namespace Atom::NAMESPACE
    elements :entries
    elements :categories

    add_extension_namespace :batch, 'http://schemas.google.com/gdata/batch'
    add_extension_namespace :gAcl, 'http://schemas.google.com/acl/2007'
  end

  def google_docs_create_doc(name=nil, include_time=false, access_token=nil)
    name = nil if name && name.empty?
    name ||= I18n.t('lib.google_docs.default_document_name', "Instructure Doc")
    name += ": #{Time.now.strftime("%d %b %Y, %I:%M %p")}" if include_time
    access_token ||= google_docs_retrieve_access_token
    url = "https://docs.google.com/feeds/documents/private/full"
    entry = Atom::Entry.new do |entry|
      entry.title = name
      entry.categories << Atom::Category.new do |category|
        category.scheme = "http://schemas.google.com/g/2005#kind"
        category.term = "http://schemas.google.com/docs/2007#document"
        category.label = "document"
      end
    end
    response = access_token.post(url, entry.to_xml, {'Content-Type' => 'application/atom+xml'})
    entry = GoogleDocEntry.new(Atom::Entry.load_entry(response.body))
  end

  def google_docs_delete_doc(entry, access_token=nil)
    url = entry.edit_url
    access_token ||= google_docs_retrieve_access_token
    response = access_token.delete(url, {"GData-Version" => "2", "If-Match" => "*"})
  end

  def google_docs_acl_remove(document_id, users)
    access_token = google_docs_retrieve_access_token
    url = "https://docs.google.com/feeds/acl/private/full/#{document_id}/batch"
    request_feed = Feed.new do |feed|
      feed.categories << Atom::Category.new{|category|
        category.scheme = "http://schemas.google.com/g/2005#kind"
        category.term = "http://schemas.google.com/acl/2007#accessRule"
      }
      users.each do |user|
        if user.is_a?(String)
          user = OpenObject.new(:id => user, :gmail => user)
        end
        feed.entries << Entry.new do |entry|
          user_identifier = user.google_docs_address || user.gmail
          entry.id = "https://docs.google.com/feeds/acl/private/full/#{CGI.escape(document_id)}/user%3A#{CGI.escape(user_identifier)}"
          entry.batch_operation = Google::Batch::Operation.new("delete")
          entry.gAcl_role = Google::GAcl::Role.new
          entry.gAcl_scope = Google::GAcl::Scope.new(user_identifier)
        end
      end
    end
    response = access_token.post(url, request_feed.to_xml, {'Content-Type' => 'application/atom+xml'})
    feed = Atom::Feed.load_feed(response.body)
    res = []
    feed.entries.each do |entry|
      user = users.to_a.find{|u| u.id == entry['http://schemas.google.com/gdata/batch', 'id'][0].to_i}
      res << user if user
    end
    res
  end

  def google_docs_acl_add(document_id, users)
    access_token = google_docs_retrieve_access_token
    url = "https://docs.google.com/feeds/acl/private/full/#{document_id}/batch"
    request_feed = Feed.new do |feed|
      feed.categories << Atom::Category.new{|category|
        category.scheme = "http://schemas.google.com/g/2005#kind"
        category.term = "http://schemas.google.com/acl/2007#accessRule"
      }
      users.each do |user|
        feed.entries << Entry.new do |entry|
          entry.batch_id = user.id
          entry.batch_operation = Google::Batch::Operation.new
          entry.gAcl_role = Google::GAcl::Role.new
          entry.gAcl_scope = Google::GAcl::Scope.new(user.google_docs_address || user.gmail)
        end
      end
    end
    response = access_token.post(url, request_feed.to_xml, {'Content-Type' => 'application/atom+xml'})
    feed = Atom::Feed.load_feed(response.body)
    res = []
    feed.entries.each do |entry|
      user = users.to_a.find{|u| u.id == entry['http://schemas.google.com/gdata/batch', 'id'][0].to_i}
      res << user if user
    end
    res
  end

  def google_docs_verify_access_token
    access_token = google_docs_retrieve_access_token
    access_token.head("https://www.google.com/accounts/AuthSubTokenInfo").is_a? Net::HTTPSuccess
  end

  def self.config_check(settings)
    o = Object.new
    o.extend(GoogleDocs)
    consumer = o.google_consumer(settings[:api_key], settings[:secret_key])
    token = consumer.get_request_token({}, {:scope => "https://docs.google.com/feeds/"}) rescue nil
    token ? nil : "Configuration check failed, please check your settings"
  end

  def self.config
    Canvas::Plugin.find(:google_docs).try(:settings) || Setting.from_config('google_docs')
  end
end
