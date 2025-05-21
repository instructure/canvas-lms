# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe MessagesController do
  describe "create" do
    context "an admin user" do
      before(:once) { site_admin_user }

      before { user_session(@user) }

      it "is able to access the page" do
        post "create", params: { user_id: @user.to_param }
        expect(response).to have_http_status :ok
      end

      it "is able to send messages" do
        secure_id, message_id = ["secure_id", 42]
        expect_any_instance_of(IncomingMailProcessor::IncomingMessageProcessor).to receive(:process_single)
          .with(anything, "#{secure_id}-#{message_id}")
        post "create", params: { secure_id:,
                                 message_id:,
                                 subject: "subject",
                                 message: "message",
                                 from: "test@example.com",
                                 user_id: @user.to_param }
      end
    end

    context "an unauthorized user" do
      before do
        account_admin_user
        user_session(@user)
      end

      it "receives a redirect" do
        post "create", params: { user_id: @user.to_param }
        expect(response).to have_http_status :found
      end
    end
  end

  describe "html_message" do
    before do
      site_admin_user
      user_session(@user)
    end

    context "with unsafe HTML input" do
      let(:html_body) { '<div>Safe</div><script>alert("XSS")</script>' }
      let(:message) { Message.create!(user: @user, subject: "Test", html_body:, sent_at: Time.zone.now) }

      it "does not allow unsanitized HTML" do
        get :html_message, params: { user_id: @user.to_param, message_id: message.id }

        expect(response).to have_http_status :ok
        expect(response.body).not_to include("<script>")
        expect(response.body).not_to include("alert(")
        expect(response.body).to include("<div>Safe</div>")
      end
    end

    context "with safe HTML input" do
      let(:html_body) { "<div>some random HTML</div>" }
      let(:message) { Message.create!(user: @user, subject: "Test", html_body:, sent_at: Time.zone.now) }

      it "renders allowed HTML" do
        get :html_message, params: { user_id: @user.to_param, message_id: message.id }

        expect(response).to have_http_status :ok
        expect(response.body).to include("<div>some random HTML</div>")
      end
    end

    context "when html_body is blank" do
      let(:html_body) { nil }
      let(:message) { Message.create!(user: @user, subject: "Test", html_body:, sent_at: Time.zone.now) }

      it "renders with no content" do
        get :html_message, params: { user_id: @user.to_param, message_id: message.id }

        expect(response).to have_http_status :ok
        expect(response.body).to eq("")
      end
    end
  end
end
