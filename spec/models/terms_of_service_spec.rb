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
require_relative '../spec_helper'
describe TermsOfService do
  before :once do
    @ac = account_model
    @terms_of_service_content = TermsOfServiceContent.create!(content: "default content")
    @terms_of_service = TermsOfService.create!(terms_type: "default",
                                               terms_of_service_content: @terms_of_service_content,
                                               account: @ac)
  end

  describe "::terms_of_service_workflow_state" do

    it "returns 'deleted' for deleted terms of service" do
      @terms_of_service.destroy!
      expect(@terms_of_service.workflow_state).to eq 'deleted'
    end

    it "returns 'active' for Terms Of Service Content even if its terms has been deleted" do
      expect(@terms_of_service_content.workflow_state).to eq 'active'
    end
  end

  it "creates a Terms Of Service defaulting passive to true" do
    ac2 = account_model
    tos = TermsOfService.create!(terms_type: "default",
                                               terms_of_service_content: @terms_of_service_content,
                                               account: ac2)
    expect(tos.passive).to eq true
  end
end
