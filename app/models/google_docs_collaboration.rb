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
  GOOGLE_DRIVE_SERVICE = "drive.google.com"

  def style_class
    'google_docs'
  end

  def service_name
    "Google Docs"
  end

  def delete_document
    if self.document_id && self.user
      # google docs expected an object
      # drive just wants an id
      doc = self.document_id
      google_adapter_for_user.delete_doc(doc)
    end
  end

  def initialize_document
    if !self.document_id && self.user
      name = self.title
      name = nil if name && name.empty?
      name ||= I18n.t('lib.google_docs.default_document_name', "Instructure Doc")

      result = google_adapter_for_user.create_doc(name)
      if result
        self.document_id = result.data.id
        self.data = result.data.to_json

        self.url = result.data.alternateLink
      end
    end
  end

  def user_can_access_document_type?(user)
    return !!google_adapter_user_service(user) if self.user && user
    false
  end

  def authorize_user(user)
    return unless self.document_id
    service_user_id = google_adapter_user_service(user).service_user_id rescue nil
    collaborator = self.collaborators.where(user_id: user).first

    if collaborator
      if collaborator.authorized_service_user_id != service_user_id
        google_adapter_for_user.acl_remove(self.document_id, [collaborator.authorized_service_user_id]) if collaborator.authorized_service_user_id

        user_param = service_user_id
        google_adapter_for_user.acl_add(self.document_id, [user_param])
        collaborator.update_attributes(:authorized_service_user_id => service_user_id)
      end
    else
      # no collaboration for this user, lets create it
      add_users_to_collaborators([user])
    end
  end

  def remove_users_from_document(users_to_remove)
    users_to_remove = users_to_remove.map do |user|
      user_service = google_user_service(user, GOOGLE_DRIVE_SERVICE) and user_service.service_user_id
    end

    google_adapter_for_user.acl_remove(self.document_id, users_to_remove) if self.document_id
  end

  def add_users_to_document(new_users)
    if document_id
      domain = if context.root_account.feature_enabled?(:google_docs_domain_restriction)
                 context.root_account.settings[:google_docs_domain]
               else
                 nil
               end

      user_ids = new_users.map do |user|
        google_user_service(user, GOOGLE_DRIVE_SERVICE).service_user_id rescue nil
      end.compact

      google_adapter_for_user.acl_add(self.document_id, user_ids, domain)
    end
  end

  def parse_data
    @entry_data ||= JSON.parse(self.data)
  end

  def self.config
    GoogleDrive::Connection.config
  end

  def authorized_service_user_id_for(user)
    service = google_adapter_user_service(user)
    service ? service.service_user_id : nil
  end

  private

  def google_user_service(user, service_domain=GOOGLE_DRIVE_SERVICE)
    google_services = user.user_services.where(service_domain: service_domain).to_a
    google_services.find{|s| s.service_user_id}
  end

  def google_drive_for_user
    refresh_token, access_token = Rails.cache.fetch(['google_drive_tokens', self.user].cache_key) do
      service = self.user.user_services.where(service: "google_drive").first
      service && [service.token, service.secret]
    end
    raise GoogleDrive::NoTokenError unless refresh_token && access_token
    GoogleDrive::Connection.new(refresh_token, access_token, ApplicationController.google_drive_timeout)
  end

  def google_adapter_for_user
    google_drive_for_user
  end

  def google_adapter_user_service(user)
    google_user_service(user)
  end
end
