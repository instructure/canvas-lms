# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

module CanvasCareer
  describe UserExperiencesController do
    let_once(:root_account) { Account.default }
    let_once(:user) { user_factory(active_all: true) }

    before :once do
      root_account.settings[:horizon_account_ids] = [root_account.id]
      root_account.save!
    end

    before do
      user_session(user)
    end

    describe "POST create" do
      it "creates a user experience record" do
        post :create, format: :json

        expect(response).to have_http_status(:created)
        json = json_parse(response.body)
        expect(json["workflow_state"]).to eql("active")
        expect(UserExperience.active.where(user:, root_account:)).to exist
      end

      it "restores a soft-deleted record" do
        experience = UserExperience.create!(user:, root_account:)
        experience.destroy

        post :create, format: :json

        expect(response).to have_http_status(:created)
        expect(experience.reload.workflow_state).to eql("active")
      end

      it "is idempotent for existing active records" do
        UserExperience.create!(user:, root_account:)

        post :create, format: :json

        expect(response).to have_http_status(:created)
        expect(UserExperience.where(user:, root_account:).count).to be(1)
      end

      it "returns 404 when account is not career affiliated" do
        root_account.settings[:horizon_account_ids] = nil
        root_account.save!

        post :create, format: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    describe "DELETE destroy" do
      it "soft-deletes an active user experience" do
        UserExperience.create!(user:, root_account:)

        delete :destroy, format: :json

        expect(response).to be_successful
        json = json_parse(response.body)
        expect(json["workflow_state"]).to eql("deleted")
        expect(UserExperience.active.where(user:, root_account:)).not_to exist
      end

      it "returns 404 when no active record exists" do
        delete :destroy, format: :json

        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 when account is not career affiliated" do
        root_account.settings[:horizon_account_ids] = nil
        root_account.save!

        delete :destroy, format: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
