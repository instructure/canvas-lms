/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import TestUtils from 'react-dom/test-utils'
import ConfigurationFormManual from 'jsx/external_apps/components/ConfigurationFormManual'

QUnit.module('External Apps Manual Configuration Form');

const fakeStore = {
  findAppByShortName () {
    return {
      short_name: 'someApp',
      config_options: []
    };
  }
};

const component = TestUtils.renderIntoDocument (
  <ConfigurationFormManual
    domain=''
    description=''
    shortName="someApp"
    store={fakeStore}
    allowMembershipServiceAccess={true}
    membershipServiceFeatureFlagEnabled={true}
  />
);

test('domain field should not be null', () => {

  const app = TestUtils.findRenderedComponentWithType(component, ConfigurationFormManual);

  equal(app.props.domain, '');
});

test('description field should not be null', () => {

  const app = TestUtils.findRenderedComponentWithType(component, ConfigurationFormManual);

  equal(app.props.description, '');
});

QUnit.module('ConfigurationFormManual#getFormData()');

test('returns expected output with membership service feature flag enabled', () => {

  const app = TestUtils.findRenderedComponentWithType(component, ConfigurationFormManual);
  app.refs.allow_membership_service_access.setState({value: true})
  equal(app.getFormData().allow_membership_service_access, true);
});

