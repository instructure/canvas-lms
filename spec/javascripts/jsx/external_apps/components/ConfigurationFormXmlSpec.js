/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import TestUtils from 'react-addons-test-utils'
import ConfigurationFormXml from 'jsx/external_apps/components/ConfigurationFormXml'

const component = TestUtils.renderIntoDocument (
  <ConfigurationFormXml
    name='Test tool'
    consumerKey='key'
    sharedSecret='secret'
    configUrl='http://example.com'
    allowMembershipServiceAccess={true}
    membershipServiceFeatureFlagEnabled={true}
  />
);

QUnit.module('ConfigurationFormXml#getFormData()');

test('returns expected output with membership service feature flag enabled', () => {
  const app = TestUtils.findRenderedComponentWithType(component, ConfigurationFormXml);
  app.refs.allow_membership_service_access.setState({value: true})
  equal(app.getFormData().allow_membership_service_access, true);
});

