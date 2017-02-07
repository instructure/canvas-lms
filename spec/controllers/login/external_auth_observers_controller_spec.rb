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

require_relative '../../spec_helper'

describe Login::ExternalAuthObserversController do
  describe 'POST #redirect_login' do
    let(:params) do
      {
          "user" => {"name" => "parent", "terms_of_use" => "1", "initial_enrollment_type" => "observer"},
          "pseudonym" => {"unique_id" => "parent@test.com"},
          "observee" => {"unique_id" => "childstudent"},
          "authenticity_token" => "9fHC1DSto0V"
      }
    end

    it "redirects to login path" do
      controller.stubs(:valid_user_unique_id?).returns(true)
      controller.stubs(:valid_observee_unique_id?).returns(true)
      subject = post :redirect_login, params
      expect(subject).to be_success
    end

    it "returns an error if unique_id is not valid" do
      controller.stubs(:valid_user_unique_id?).returns(false)
      post :redirect_login, params
      expect(response.status).to eq 422
    end
  end
end
