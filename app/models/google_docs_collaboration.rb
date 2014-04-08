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

class GoogleDocsCollaboration < Collaboration
  def style_class
    'google_docs'
  end
  
  def service_name
    "Google Docs"
  end
  
  def delete_document
    if !self.document_id && self.user
      google_docs = google_docs_for_user
      google_docs.delete_doc(GoogleDocEntry.new(self.data))
    end
  end
  
  def initialize_document
    if !self.document_id && self.user

      name = self.title
      name = nil if name && name.empty?
      name ||= I18n.t('lib.google_docs.default_document_name', "Instructure Doc")

      google_docs = google_docs_for_user
      file = google_docs.create_doc(name, google_docs.retrieve_access_token)
      self.document_id = file.document_id
      self.data = file.entry.to_xml
      self.url = file.alternate_url.to_s
    end
  end
  
  def user_can_access_document_type?(user)
    if self.user && user
      google_services = user.user_services.find_all_by_service_domain("google.com").to_a
      !!google_services.find{|s| s.service_user_id}
    else
      false
    end
  end
  
  def authorize_user(user)
    return unless self.document_id
    google_services = user.user_services.find_all_by_service_domain("google.com").to_a
    service_user_id = google_services.find{|s| s.service_user_id}.service_user_id rescue nil
    collaborator = self.collaborators.find_by_user_id(user.id)
    if collaborator && collaborator.authorized_service_user_id != service_user_id
      google_docs = google_docs_for_user
      google_docs.acl_remove(self.document_id, [collaborator.authorized_service_user_id]) if collaborator.authorized_service_user_id
      google_docs.acl_add(self.document_id, [user])
      collaborator.update_attributes(:authorized_service_user_id => service_user_id)
    end
  end
  
  def remove_users_from_document(users_to_remove)
    google_docs = google_docs_for_user
    google_docs.acl_remove(self.document_id, users_to_remove) if self.document_id
  end

  def add_users_to_document(new_users)
    domain = if context.root_account.feature_enabled?(:google_docs_domain_restriction)
              context.root_account.settings[:google_docs_domain]
             else
               nil
             end
    if document_id
      google_docs = google_docs_for_user
      google_docs.acl_add(self.document_id, new_users, domain)
    end
  end

  def parse_data
    @entry_data ||= Atom::Entry.load_entry(self.data)
  end
  
  def self.config
    GoogleDocs::Connection.config
  end

  private
  def google_docs_for_user
    service_token, service_secret = Rails.cache.fetch(['google_docs_tokens', self.user].cache_key) do
      service = self.user.user_services.find_by_service("google_docs")
      service && [service.token, service.secret]
    end
    raise GoogleDocs::NoTokenError unless service_token && service_secret
    GoogleDocs::Connection.new(service_token, service_secret)
  end
end
