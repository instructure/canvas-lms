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
import ConfigurationForm from 'jsx/external_apps/components/ConfigurationForm'

QUnit.module('ConfigurationForm#defaultState');

test('returns object where allow_membership_service_access is false', () => {
  const component = TestUtils.renderIntoDocument (
    <ConfigurationForm
      handleSubmit={() => {}}
      tool={{}}
      configurationType='manual' />
  );
  const app = TestUtils.findRenderedComponentWithType(component, ConfigurationForm);
  equal(app.defaultState().allow_membership_service_access, false);
});

QUnit.module('ConfigurationForm#reset');

test('resets internal state of component', () => {
  const component = TestUtils.renderIntoDocument (
    <ConfigurationForm
      handleSubmit={() => {}}
      tool={{}}
      configurationType='goofy'
      showConfigurationSelector={true} />
  );
  const app = TestUtils.findRenderedComponentWithType(component, ConfigurationForm);
  app.reset()
  deepEqual(app.state, {
    configurationType: 'goofy',
    showConfigurationSelector: true,
    name: '',
    consumerKey: '',
    sharedSecret: '',
    url: '',
    domain: '',
    privacy_level: '',
    customFields: {},
    description: '',
    configUrl: '',
    registrationUrl: '',
    xml: '',
    allow_membership_service_access: false
  });
});


QUnit.module('ConfigurationForm#defaultState');

test('returns a default state', () => {
  const component = TestUtils.renderIntoDocument (
    <ConfigurationForm
      handleSubmit={() => {}}
      tool={{}}
      configurationType='goofy'
      showConfigurationSelector={true} />
  );
  const app = TestUtils.findRenderedComponentWithType(component, ConfigurationForm);
  app.reset()
  deepEqual(app.defaultState(), {
    configurationType: 'goofy',
    showConfigurationSelector: true,
    name: '',
    consumerKey: '',
    sharedSecret: '',
    url: '',
    domain: '',
    privacy_level: '',
    customFields: {},
    description: '',
    configUrl: '',
    registrationUrl: '',
    xml: '',
    allow_membership_service_access: false
  });
});
