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
#

describe AiExperiences::Jobs::AiExperienceProvisionJob do
  let_once(:account) { account_model }
  let(:provision_service) { instance_double(AiExperiences::ProvisionService) }

  before do
    allow(AiExperiences::ProvisionService).to receive(:new).and_return(provision_service)
    allow(provision_service).to receive(:provision)
  end

  describe ".provision_account_for_ai_experiences" do
    context "when the ai_experiences_v2_auth feature flag is disabled" do
      before { account.disable_feature!(:ai_experiences_v2_auth) }

      it "raises AiExperienceProvisionError" do
        expect { described_class.provision_account_for_ai_experiences(account) }
          .to raise_error(AiExperiences::AiExperienceProvisionError, /#{account.uuid}/)
      end

      it "does not call the provision service" do
        described_class.provision_account_for_ai_experiences(account)
      rescue AiExperiences::AiExperienceProvisionError
        expect(provision_service).not_to have_received(:provision)
      end
    end

    context "when the ai_experiences_v2_auth feature flag is enabled" do
      before { account.enable_feature!(:ai_experiences_v2_auth) }

      it "calls the provision service with the account" do
        described_class.provision_account_for_ai_experiences(account)

        expect(provision_service).to have_received(:provision).with(account)
      end
    end
  end
end
