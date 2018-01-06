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

import React from 'react';
import { mount } from 'enzyme';
import GradebookSettingsModal from 'jsx/gradezilla/default_gradebook/components/GradebookSettingsModal';
import GradebookSettingsModalApi from 'jsx/gradezilla/default_gradebook/apis/GradebookSettingsModalApi';
import { destroyContainer } from 'jsx/shared/FlashAlert';

let clock;

QUnit.module('GradebookSettingsModal', {
  setup () {
    clock = sinon.useFakeTimers();
    this.qunitTimeout = QUnit.config.testTimeout;
    QUnit.config.testTimeout = 1000;
    const applicationElement = document.createElement('div');
    applicationElement.id = 'application';
    document.getElementById('fixtures').appendChild(applicationElement);
  },

  mountComponent (customProps = {}) {
    const defaultProps = {
      courseId: '1',
      locale: 'en',
      onClose () {},
      gradedLateSubmissionsExist: true,
      onLatePolicyUpdate () {}
    };
    const props = { ...defaultProps, ...customProps };
    this.wrapper = mount(<GradebookSettingsModal {...props} />);
    return this.wrapper.get(0);
  },

  stubLatePolicyFetchSuccess (component, customData) {
    const data = {
      latePolicy: {
        id: '15',
        missingSubmissionDeductionEnabled: false,
        missingSubmissionDeduction: 0,
        lateSubmissionDeductionEnabled: false,
        lateSubmissionDeduction: 0,
        lateSubmissionInterval: 'day',
        lateSubmissionMinimumPercentEnabled: false,
        lateSubmissionMinimumPercent: 0,
        ...customData
      }
    };

    const fetchSuccess = Promise.resolve({ data });
    const promise = fetchSuccess.then(component.onFetchLatePolicySuccess)
    this.stub(component, 'fetchLatePolicy').returns(promise);
    return promise;
  },

  teardown () {
    QUnit.config.testTimeout = this.qunitTimeout;
    this.wrapper.unmount();
    destroyContainer();
    document.getElementById('fixtures').innerHTML = '';
    clock.restore();
  }
});

test('modal is initially closed', function () {
  this.mountComponent();
  equal(this.wrapper.find('Modal').prop('open'), false);
});

test('calling open causes the modal to be rendered', function () {
  const component = this.mountComponent();
  const fetchLatePolicy = this.stubLatePolicyFetchSuccess(component);
  component.open();
  return fetchLatePolicy.then(() => {
    equal(this.wrapper.find('Modal').prop('open'), true);
  });
});

test('calling close closes the modal', function () {
  const component = this.mountComponent();
  const fetchLatePolicy = this.stubLatePolicyFetchSuccess(component);
  component.open();
  return fetchLatePolicy.then(() => {
    equal(this.wrapper.find('Modal').prop('open'), true, 'modal is open');
    component.close();
    equal(this.wrapper.find('Modal').prop('open'), false, 'modal is closed');
  });
});

test('clicking cancel closes the modal', function () {
  const component = this.mountComponent();
  const fetchLatePolicy = this.stubLatePolicyFetchSuccess(component);
  component.open();
  clock.tick(50); // wait for Modal to transition open
  return fetchLatePolicy.then(() => {
    equal(this.wrapper.find('Modal').prop('open'), true);
    document.getElementById('gradebook-settings-cancel-button').click();
    equal(this.wrapper.find('Modal').prop('open'), false);
  });
});

test('the "Update" button is disabled when the modal opens', function () {
  const component = this.mountComponent();
  const fetchLatePolicy = this.stubLatePolicyFetchSuccess(component);
  component.open();
  clock.tick(50); // wait for Modal to transition open
  return fetchLatePolicy.then(() => {
    const updateButton = document.getElementById('gradebook-settings-update-button')
    ok(updateButton.getAttribute('aria-disabled'));
  });
});

test('the "Update" button is enabled if a setting is changed', function () {
  const component = this.mountComponent();
  const fetchLatePolicy = this.stubLatePolicyFetchSuccess(component);
  component.open();
  clock.tick(50); // wait for Modal to transition open
  return fetchLatePolicy.then(() => {
    component.changeLatePolicy({ ...component.state.latePolicy, changes: { lateSubmissionDeductionEnabled: true } });
    const updateButton = document.getElementById('gradebook-settings-update-button');
    notOk(updateButton.getAttribute('aria-disabled'));
  });
});

test('the "Update" button is disabled if a setting is changed, but there are validation errors', function () {
  const component = this.mountComponent();
  const fetchLatePolicy = this.stubLatePolicyFetchSuccess(component);
  component.open();
  clock.tick(50); // wait for Modal to transition open
  return fetchLatePolicy.then(() => {
    component.changeLatePolicy({
      ...component.state.latePolicy,
      changes: { lateSubmissionDeductionEnabled: true },
      validationErrors: { missingSubmissionDeduction: 'Missing submission percent must be numeric' }
    });
    const updateButton = document.getElementById('gradebook-settings-update-button');
    ok(updateButton.getAttribute('aria-disabled'));
  });
});

test('clicking "Update" sends a request to update the late policy', function () {
  this.stub(GradebookSettingsModalApi, 'updateLatePolicy').returns(Promise.resolve());
  const component = this.mountComponent();
  const fetchLatePolicy = this.stubLatePolicyFetchSuccess(component);
  component.open();
  clock.tick(50); // wait for Modal to transition open
  return fetchLatePolicy.then(() => {
    const changes = { lateSubmissionDeductionEnabled: true };
    component.changeLatePolicy({ ...component.state.latePolicy, changes });
    const button = document.getElementById('gradebook-settings-update-button');
    button.click();
    equal(GradebookSettingsModalApi.updateLatePolicy.callCount, 1, 'updateLatePolicy is called once');
    const changesArg = GradebookSettingsModalApi.updateLatePolicy.getCall(0).args[1];
    propEqual(changesArg, changes, 'updateLatePolicy is called with the late policy changes');
  });
});

test('clicking "Update" sends a post request to create a late policy if one does not yet exist', function () {
  this.stub(GradebookSettingsModalApi, 'createLatePolicy').returns(Promise.resolve());
  // When a late policy does not exist, the API call returns 'Not Found'
  const component = this.mountComponent();
  const fetchLatePolicy = this.stubLatePolicyFetchSuccess(component, { newRecord: true });
  component.open();
  clock.tick(50); // wait for Modal to transition open

  return fetchLatePolicy.then(() => {
    const changes = { lateSubmissionDeductionEnabled: true };
    component.changeLatePolicy({ ...component.state.latePolicy, changes});
    document.getElementById('gradebook-settings-update-button').click();
    equal(GradebookSettingsModalApi.createLatePolicy.callCount, 1, 'createLatePolicy is called once');
    const changesArg = GradebookSettingsModalApi.createLatePolicy.getCall(0).args[1];
    propEqual(changesArg, changes, 'createLatePolicy is called with the late policy changes');
  });
});

test('onUpdateLatePolicySuccess calls the onLatePolicyUpdate prop', function () {
  const onLatePolicyUpdate = this.stub();
  const component = this.mountComponent({ onLatePolicyUpdate });
  component.onUpdateLatePolicySuccess();
  strictEqual(onLatePolicyUpdate.callCount, 1);
});
