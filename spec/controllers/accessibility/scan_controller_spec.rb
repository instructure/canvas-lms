# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

RSpec.describe Accessibility::ScanController do
  describe "#create" do
    let!(:course) { Course.create! }
    let!(:user) { User.create! }

    before do
      allow(controller).to receive_messages(check_authorized_action: true, require_user: true)
      controller.instance_variable_set(:@current_user, user)
    end

    it "calls the service" do
      allow(Accessibility::CourseScannerService).to receive(:call).with(course:).and_return(true)

      post :create, params: { course_id: course.id }

      expect(response).to have_http_status(:ok)
    end

    context "when the course exists" do
      it "calls the CourseScannerService and returns success" do
        allow(controller).to receive(:check_authorized_action).and_return(true)
        expect(Accessibility::CourseScannerService).to receive(:call).with(course:)

        post :create, params: { course_id: course.id }

        expect(response).to have_http_status(:ok)
      end
    end

    context "when the course does not exist" do
      let(:params) { { course_id: -1 } }

      it "returns a not found error" do
        allow(controller).to receive(:check_authorized_action).and_return(true)

        post :create, params: { course_id: -1 }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
