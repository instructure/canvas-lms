#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative '../../../spec_helper'

describe AuthenticationProvider::SAML::InCommon do
  let(:subject) { AuthenticationProvider::SAML::InCommon }

  describe ".refresh_providers" do
    before do
      allow_any_instance_of(AuthenticationProvider::SAML).to receive(:download_metadata).and_return(nil)
    end

    let!(:saml) { Account.default.authentication_providers.create!(auth_type: 'saml',
                                                                   metadata_uri: subject::URN,
                                                                   idp_entity_id: 'urn:mace:incommon:myschool.edu') }

    it "does nothing if there aren't any InCommon providers" do
      saml.destroy
      expect(subject).to receive(:refresh_if_necessary).never
      subject.refresh_providers
    end

    it "does nothing if no changes" do
      expect(subject).to receive(:refresh_if_necessary).and_return(false)
      expect(subject).to receive(:validate_and_parse_metadata).never
      subject.refresh_providers
    end

    it "records errors for missing metadata" do
      expect(subject).to receive(:refresh_if_necessary).and_return('xml')
      expect(subject).to receive(:validate_and_parse_metadata).and_return({})

      expect(Canvas::Errors).to receive(:capture_exception).once
      expect_any_instantiation_of(saml).to receive(:populate_from_metadata).never

      subject.refresh_providers
    end

    it "continues after a failure" do
      saml2 = Account.default.authentication_providers.create!(auth_type: 'saml',
                                                               metadata_uri: subject::URN,
                                                               idp_entity_id: 'urn:mace:incommon:myschool2.edu')
      expect(subject).to receive(:refresh_if_necessary).and_return('xml')
      expect(subject).to receive(:validate_and_parse_metadata).and_return({
          'urn:mace:incommon:myschool.edu' => 'metadata1',
          'urn:mace:incommon:myschool2.edu' => 'metadata2',
        })

      expect(Canvas::Errors).to receive(:capture_exception).once
      expect_any_instantiation_of(saml).to receive(:populate_from_metadata).with('metadata1').and_raise('error')
      expect_any_instantiation_of(saml2).to receive(:populate_from_metadata).with('metadata2')
      expect_any_instantiation_of(saml2).to receive(:save!).never

      subject.refresh_providers
    end

    it "populates and saves" do
      expect(subject).to receive(:refresh_if_necessary).and_return('xml')
      expect(subject).to receive(:validate_and_parse_metadata).and_return({
                                                                'urn:mace:incommon:myschool.edu' => 'metadata1'
                                                            })

      expect_any_instantiation_of(saml).to receive(:populate_from_metadata).with('metadata1')
      expect_any_instantiation_of(saml).to receive(:changed?).and_return(true)
      expect_any_instantiation_of(saml).to receive(:save!).once

      subject.refresh_providers
    end
  end
end
