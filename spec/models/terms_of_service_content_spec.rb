# frozen_string_literal: true

# Copyright (C) 2017 - present Instructure, Inc.
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
describe TermsOfServiceContent do
  before :once do
    @ac = account_model
    @user = user_model
  end

  describe "#content" do
    it "adds location param to file URLs when file_association_access feature flag is enabled" do
      attachment = attachment_model(context: @user)
      content = "<p>Here is a link to a file: <a href='/users/#{@user.id}/files/#{attachment.id}/download'>file</a></p>"
      terms_of_service_content = TermsOfServiceContent.create!(content:, account: @ac, saving_user: @user)
      terms_of_service_content.root_account.enable_feature!(:file_association_access)
      terms_of_service_content.reload
      expect(terms_of_service_content.content).to include("location=#{terms_of_service_content.asset_string}")
    end

    it "does not add location param to file URLs when file_association_access feature flag is disabled" do
      attachment = attachment_model(context: @user)
      content = "<p>Here is a link to a file: <a href='/users/#{@user.id}/files/#{attachment.id}/download'>file</a></p>"
      terms_of_service_content = TermsOfServiceContent.create!(content:, account: @ac, saving_user: @user)
      terms_of_service_content.reload
      expect(terms_of_service_content.content).not_to include("location=#{terms_of_service_content.asset_string}")
    end

    it "adds location tag for media attachments when file_association_access feature flag is enabled" do
      attachment = attachment_model(context: @user)
      content = "<p>Here is a link to a media file: <iframe src='/media_attachments_iframe/#{attachment.id}'></iframe> </p>"
      terms_of_service_content = TermsOfServiceContent.create!(content:, account: @ac, saving_user: @user)
      terms_of_service_content.root_account.enable_feature!(:file_association_access)
      terms_of_service_content.reload
      expect(terms_of_service_content.content).to include("location=#{terms_of_service_content.asset_string}")
    end

    it "doesn't add location tag to non-relative URLs" do
      attachment = attachment_model(context: @user)
      content = "<p>Here is a link to a file: <a href='https://www.test.com/users/#{@user.id}/files/#{attachment.id}/download'>file</a></p>"
      terms_of_service_content = TermsOfServiceContent.create!(content:, account: @ac, saving_user: @user)
      terms_of_service_content.root_account.enable_feature!(:file_association_access)
      terms_of_service_content.reload
      expect(terms_of_service_content.content).not_to include("location=#{terms_of_service_content.asset_string}")
    end
  end
end
