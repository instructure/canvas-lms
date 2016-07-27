#
# Copyright (C) 2016 Instructure, Inc.
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

describe AccountAuthorizationConfig::SAML::InCommon do
  let(:subject) { AccountAuthorizationConfig::SAML::InCommon }

  describe ".refresh_providers" do
    before do
      AccountAuthorizationConfig::SAML.any_instance.stubs(:download_metadata).returns(nil)
    end

    let!(:saml) { Account.default.authentication_providers.create!(auth_type: 'saml',
                                                                   metadata_uri: subject::URN,
                                                                   idp_entity_id: 'urn:mace:incommon:myschool.edu') }

    it "does nothing if there aren't any InCommon providers" do
      saml.destroy
      subject.expects(:refresh_if_necessary).never
      subject.refresh_providers
    end

    it "does nothing if no changes" do
      subject.expects(:refresh_if_necessary).returns(false)
      subject.expects(:validate_and_parse_metadata).never
      subject.refresh_providers
    end

    it "records errors for missing metadata" do
      subject.expects(:refresh_if_necessary).returns('xml')
      subject.expects(:validate_and_parse_metadata).returns({})

      Canvas::Errors.expects(:capture_exception).once
      saml.any_instantiation.expects(:populate_from_metadata).never

      subject.refresh_providers
    end

    it "continues after a failure" do
      saml2 = Account.default.authentication_providers.create!(auth_type: 'saml',
                                                               metadata_uri: subject::URN,
                                                               idp_entity_id: 'urn:mace:incommon:myschool2.edu')
      subject.expects(:refresh_if_necessary).returns('xml')
      subject.expects(:validate_and_parse_metadata).returns({
          'urn:mace:incommon:myschool.edu' => 'metadata1',
          'urn:mace:incommon:myschool2.edu' => 'metadata2',
        })

      Canvas::Errors.expects(:capture_exception).once
      saml.any_instantiation.expects(:populate_from_metadata).with('metadata1').raises('error')
      saml2.any_instantiation.expects(:populate_from_metadata).with('metadata2')
      saml2.any_instantiation.expects(:save!).never

      subject.refresh_providers
    end

    it "populates and saves" do
      subject.expects(:refresh_if_necessary).returns('xml')
      subject.expects(:validate_and_parse_metadata).returns({
                                                                'urn:mace:incommon:myschool.edu' => 'metadata1'
                                                            })

      saml.any_instantiation.expects(:populate_from_metadata).with('metadata1')
      saml.any_instantiation.expects(:changed?).returns(true)
      saml.any_instantiation.expects(:save!).once

      subject.refresh_providers
    end
  end
end
