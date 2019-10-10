#
# Copyright (C) 2019 - present Instructure, Inc.
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

require 'spec_helper'

describe ContentSharesController do
  before :once do
    course_with_teacher(active_all: true)
    @course_1 = @course
    @teacher_1 = @teacher
    course_with_teacher(active_all: true)
    @course_2 = @course
    @teacher_2 = @teacher
    assignment_model(course: @course_1, name: 'assignment share')
    @course.root_account.enable_feature!(:direct_share)
  end

  describe "POST #create" do
    before :each do
      user_session(@teacher_1)
    end

    it "returns http success" do
      post :create, params: {user_id: @teacher_1.id, content_type: 'assignment', content_id: @assignment.id, receiver_ids: [@teacher_2.id]}
      expect(response).to have_http_status(:created)
      expect(SentContentShare.where(user_id: @teacher_1.id)).to exist
      expect(ReceivedContentShare.where(user_id: @teacher_2.id, sender_id: @teacher_1.id)).to exist
      expect(ContentExport.where(context: @assignment.context)).to exist
      json = JSON.parse(response.body)
      expect(json).to include({
        "name" => @assignment.title,
        "user_id" => @teacher_1.id,
        "read_state" => 'read',
        "sender" => nil,
      })
      expect(json['receivers'].first).to include({'id' => @teacher_2.id})
      expect(json['content_export']).to be_present
    end

    it "returns 400 if required parameters aren't included" do
      post :create, params: {user_id: @teacher_1.id, content_type: 'assignment', content_id: @assignment.id}
      expect(response).to have_http_status(:bad_request)

      post :create, params: {user_id: @teacher_1.id, content_type: 'assignment', receiver_ids: [@teacher_2.id]}
      expect(response).to have_http_status(:bad_request)

      post :create, params: {user_id: @teacher_1.id, content_id: @assignment.id, receiver_ids: [@teacher_2.id]}
      expect(response).to have_http_status(:bad_request)

      announcement_model(context: @course_1)
      post :create, params: {user_id: @teacher_1.id, content_type: 'announcement', content_id: @a.id, receiver_ids: [@teacher_2.id]}
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns 400 if the associated content cannot be found' do
      post :create, params: {user_id: @teacher_1.id, content_type: 'discussion_topic', content_id: @assignment.id, receiver_ids: [@teacher_2.id]}
      expect(response).to have_http_status(:bad_request)
    end

    it "returns 401 if the user doesn't have access to export the associated content" do
      user_session(@teacher_2)
      post :create, params: {user_id: @teacher_2.id, content_type: 'assignment', content_id: @assignment.id, receiver_ids: [@teacher_1.id]}
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 if the sharing user doesn't match current user" do
      user_session(@teacher_2)
      post :create, params: {user_id: @teacher_1.id, content_type: 'assignment', content_id: @assignment.id, receiver_ids: [@teacher_2.id]}
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "rest of CRUD" do
    before :once do
      @export = @course_1.content_exports.create!(settings: {"selected_content" => {"assignments" => {CC::CCHelper.create_key(@assignment) => '1'}}})
      @export_2 = @course_1.content_exports.create!(settings: {"selected_content" => {"assignments" => {CC::CCHelper.create_key(@assignment) => '1'}}})
      @sent_share = @teacher_1.sent_content_shares.create! name: 'booga', content_export: @export, read_state: 'read'
      @received_share = @teacher_2.received_content_shares.create! name: 'booga', content_export: @export, sender: @teacher_1, read_state: 'unread'
      @teacher_2.received_content_shares.create! name: 'u read me', content_export: @export_2, sender: @teacher_1, read_state: 'read'
    end

    describe "GET #index" do
      it "lists sent content shares" do
        user_session @teacher_1
        get :index, params: { user_id: @teacher_1.id, list: 'sent' }
        expect(response).to be_successful
        json = JSON.parse(response.body.sub(/^while\(1\);/, ''))
        expect(json.length).to eq 1
        expect(json[0]['id']).to eq @sent_share.id
        expect(json[0]['name']).to eq 'booga'
        expect(json[0]['read_state']).to eq 'read'
        expect(json[0]['sender']).to be_nil
        expect(json[0]['receivers'].length).to eq 1
        expect(json[0]['receivers'][0]['id']).to eq @teacher_2.id
        expect(json[0]['content_type']).to eq 'assignment'
        expect(json[0]['source_course']).to eq({'id' => @course_1.id, 'name' => @course_1.name})
        expect(json[0]['content_export']).to be_present
      end

      it "paginates sent content shares" do
        Timecop.travel(1.hour.ago) do
          export2 = @course_1.content_exports.create!(settings: {"selected_content" => {"assignments" => {'foo' => '1'}, "content_tags" => {'bar' => '1'}}})
          sent_share2 = @teacher_1.sent_content_shares.create! name: 'ooga', content_export: export2, read_state: 'read'
        end
        user_session @teacher_1

        get :index, params: { user_id: 'self', list: 'sent', per_page: 1 }
        json = JSON.parse(response.body.sub(/^while\(1\);/, ''))
        expect(json.length).to eq 1
        expect(json[0]['name']).to eq 'booga'
        expect(json[0]['content_type']).to eq 'assignment'

        links = Api.parse_pagination_links(response.headers['Link'])
        link = links.detect { |link| link[:rel] == 'next' }
        expect(link[:uri].path).to eq '/api/v1/users/self/content_shares/sent'
        expect(link[:uri].query).to include 'page=2'
        expect(link[:uri].query).to include 'per_page=1'

        get :index, params: { user_id: 'self', list: 'sent', per_page: 1, page: 2 }
        json = JSON.parse(response.body.sub(/^while\(1\);/, ''))
        expect(json.length).to eq 1
        expect(json[0]['name']).to eq 'ooga'
        expect(json[0]['content_type']).to eq 'module_item'

        links = Api.parse_pagination_links(response.headers['Link'])
        expect(links.detect { |link| link[:rel] == 'next' }).to be_nil
      end

      it "lists received content shares" do
        user_session @teacher_2
        get :index, params: { user_id: @teacher_2.id, list: 'received' }
        expect(response).to be_successful
        json = JSON.parse(response.body.sub(/^while\(1\);/, ''))
        expect(json.length).to eq 2
        expect(json[1]['id']).to eq @received_share.id
        expect(json[1]['name']).to eq 'booga'
        expect(json[1]['read_state']).to eq 'unread'
        expect(json[1]['sender']['id']).to eq @teacher_1.id
        expect(json[1]['receivers']).to eq([])
        expect(json[1]['content_type']).to eq 'assignment'
        expect(json[1]['source_course']).to eq({'id' => @course_1.id, 'name' => @course_1.name})
        expect(json[1]['content_export']).to be_present
      end

      it "paginates received content shares" do
        Timecop.travel(1.hour.ago) do
          export2 = @course_1.content_exports.create!(settings: {"selected_content" => {"quizzes" => {'foo' => '1'}, "content_tags" => {'bar' => '1'}, "context_modules" => {'baz' => '1'}}})
          received_share2 = @teacher_2.received_content_shares.create! name: 'ooga', content_export: export2, sender_id: user_with_pseudonym, read_state: 'unread'
        end
        user_session @teacher_2

        get :index, params: { user_id: 'self', list: 'received', per_page: 2 }
        json = JSON.parse(response.body.sub(/^while\(1\);/, ''))
        expect(json.length).to eq 2
        expect(json[0]['name']).to eq 'u read me'
        expect(json[0]['content_type']).to eq 'assignment'

        links = Api.parse_pagination_links(response.headers['Link'])
        link = links.detect { |l| l[:rel] == 'next' }
        expect(link[:uri].path).to eq '/api/v1/users/self/content_shares/received'
        expect(link[:uri].query).to include 'page=2'
        expect(link[:uri].query).to include 'per_page=2'

        get :index, params: { user_id: 'self', list: 'received', per_page: 2, page: 2 }
        json = JSON.parse(response.body.sub(/^while\(1\);/, ''))
        expect(json.length).to eq 1
        expect(json[0]['name']).to eq 'ooga'
        expect(json[0]['content_type']).to eq 'module'

        links = Api.parse_pagination_links(response.headers['Link'])
        expect(links.detect { |l| l[:rel] == 'next' }).to be_nil
      end

      it "requires permission on user" do
        user_session @teacher_1
        get :index, params: { user_id: @teacher_2.id, list: 'received' }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe "GET #show" do
      it "returns a content share" do
        user_session @teacher_1
        get :show, params: { user_id: @teacher_1.id, id: @sent_share.id }
        expect(response).to be_successful
        json = JSON.parse(response.body.sub(/^while\(1\);/, ''))
        expect(json['id']).to eq @sent_share.id
        expect(json['name']).to eq 'booga'
        expect(json['read_state']).to eq 'read'
        expect(json['sender']).to be_nil
        expect(json['receivers'].length).to eq 1
        expect(json['receivers'][0]['id']).to eq @teacher_2.id
        expect(json['content_type']).to eq 'assignment'
        expect(json['source_course']).to eq({'id' => @course_1.id, 'name' => @course_1.name})
        expect(json['content_export']).to be_present
      end

      it "scopes to user" do
        user_session @teacher_1
        get :show, params: { user_id: @teacher_1.id, id: @received_share.id }
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "DELETE #destroy" do
      it "deletes a content share" do
        user_session @teacher_1
        delete :destroy, params: { user_id: @teacher_1.id, id: @sent_share.id }
        expect(response).to be_successful
        expect(ContentShare.where(id: @sent_share.id).exists?).to eq false
      end

      it "scopes to user" do
        user_session @teacher_2
        delete :destroy, params: { user_id: @teacher_2.id, id: @sent_share.id }
        expect(response).to have_http_status(:not_found)
      end

      it "requires user=self" do
        user_session @teacher_1
        delete :destroy, params: { user_id: @teacher_2.id, id: @sent_share.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "POST #add_users" do
      before :once do
        @teacher_3 = user_with_pseudonym(active_user: true)
      end

      it "adds users" do
        user_session @teacher_1
        post :add_users, params: { user_id: @teacher_1.id, id: @sent_share.id, receiver_ids: [@teacher_3.id] }
        expect(response).to be_successful
        json = JSON.parse(response.body.sub(/^while\(1\);/, ''))
        expect(json['receivers'].length).to eq 2
        expect(json['receivers'].map { |r| r['id'] }).to match_array([@teacher_2.id, @teacher_3.id])
        expect(@sent_share.receivers.pluck(:id)).to match_array([@teacher_2.id, @teacher_3.id])
      end

      it "ignores users already shared" do
        user_session @teacher_1
        post :add_users, params: { user_id: @teacher_1.id, id: @sent_share.id, receiver_ids: [@teacher_2.id, @teacher_3.id] }
        expect(response).to be_successful
        json = JSON.parse(response.body.sub(/^while\(1\);/, ''))
        expect(json['receivers'].length).to eq 2
        expect(json['receivers'].map { |r| r['id'] }).to match_array([@teacher_2.id, @teacher_3.id])
        expect(@sent_share.receivers.pluck(:id)).to match_array([@teacher_2.id, @teacher_3.id])
      end

      it "disallows sharing with yourself" do
        user_session @teacher_1
        post :add_users, params: { user_id: @teacher_1.id, id: @sent_share.id, receiver_ids: [@teacher_1.id, @teacher_3.id] }
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include 'You cannot share with yourself'
      end

      it "complains if no valid users are included" do
        user_session @teacher_1
        post :add_users, params: { user_id: @teacher_1.id, id: @sent_share.id, receiver_ids: [0] }
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include 'No valid receiving users found'
      end

      it "disallows resharing somebody else's share" do
        user_session @teacher_2
        post :add_users, params: { user_id: @teacher_2.id, id: @received_share.id, receiver_ids: [@teacher_3.id] }
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include 'Content share not owned by you'
      end

      it "scopes to user" do
        user_session @teacher_2
        post :add_users, params: { user_id: @teacher_2.id, id: @sent_share.id, receiver_ids: [@teacher_3.id] }
        expect(response).to have_http_status(:not_found)
      end

      it "requires user=self" do
        user_session @teacher_2
        post :add_users, params: { user_id: @teacher_1.id, id: @sent_share.id, receiver_ids: [@teacher_3.id] }
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "GET #unread_count" do
      it "returns the correct count" do
        user_session @teacher_2
        get :unread_count, params: { user_id: @teacher_2 }
        expect(response).to be_successful
        json = JSON.parse(response.body.sub(/^while\(1\);/, ''))
        expect(json["unread_count"]).to eq 1
      end
    end

    describe "PUT #update" do
      it "marks a content share read" do
        user_session @teacher_2
        put :update, params: { user_id: @teacher_2.id, id: @received_share.id, read_state: 'read' }
        expect(response).to be_successful
        json = JSON.parse(response.body.sub(/^while\(1\);/, ''))
        expect(json['read_state']).to eq 'read'
        expect(json['content_export']).to be_present
        expect(@received_share.reload.read_state).to eq 'read'
      end

      it "rejects an invalid read state" do
        user_session @teacher_2
        put :update, params: { user_id: @teacher_2.id, id: @received_share.id, read_state: 'malarkey' }
        expect(response).to have_http_status(:bad_request)
      end

      it "ignores invalid attributes" do
        user_session @teacher_2
        put :update, params: { user_id: @teacher_2.id, id: @received_share.id, content_export_id: 0, read_state: 'read' }
        expect(response).to be_successful
        expect(@received_share.reload.read_state).to eq 'read'
        expect(@received_share.content_export_id).to eq @export.id
      end

      it "scopes to user" do
        user_session @teacher_1
        put :update, params: { user_id: @teacher_1.id, id: @received_share.id, read_state: 'read' }
        expect(response).to have_http_status(:not_found)
      end

      it "requires user=self" do
        user_session @teacher_1
        put :update, params: { user_id: @teacher_2.id, id: @received_share.id, read_state: 'read' }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
