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

/* global QUnit */
import React from 'react';
import {shallow, mount} from 'enzyme';
import TutorialTray from 'jsx/new_user_tutorial/trays/TutorialTray';
import createTutorialStore from 'jsx/new_user_tutorial/utils/createTutorialStore'

QUnit.module('TutorialTray Spec');

const store = createTutorialStore();

const getDefaultProps = overrides => (
  Object.assign({}, {
    label: 'TutorialTray Test',
    returnFocusToFunc () {
      return {
        focus () {
          return document.body;
        }
      }
    },
    store
  }, overrides)
);

test('Renders', () => {
  const wrapper = shallow(
    <TutorialTray {...getDefaultProps()}>
      <div>Some Content</div>
    </TutorialTray>
  );
  ok(wrapper.exists());
});

test('handleEntering sets focus on the toggle button', () => {
  const wrapper = mount(
    <TutorialTray {...getDefaultProps()}>
      <div>Some Content</div>
    </TutorialTray>
  );
  wrapper.setState({
    isCollapsed: false
  });

  wrapper.instance().handleEntering();

  ok(wrapper.instance().toggleButton.button.focused);
});

test('handleExiting calls focus on the return value of the returnFocusToFunc', () => {
  const spy = sinon.spy();
  const fakeReturnFocusToFunc = () => ({ focus: spy });
  const wrapper = mount(
    <TutorialTray {...getDefaultProps({returnFocusToFunc: fakeReturnFocusToFunc})}>
      <div>Some Content</div>
    </TutorialTray>
  );

  wrapper.instance().handleExiting();

  ok(spy.called);
});

test('handleToggleClick toggles the isCollapsed state of the store', () => {
  const wrapper = mount(
    <TutorialTray {...getDefaultProps()}>
      <div>Some Content</div>
    </TutorialTray>
  );

  wrapper.instance().handleToggleClick();

  ok(store.getState().isCollapsed);
});

test('initial state sets endUserTutorialShown to false', () => {
  const wrapper = shallow(
    <TutorialTray {...getDefaultProps()}>
      <div>Some Content</div>
    </TutorialTray>
  );

  equal(wrapper.state('endUserTutorialShown'), false);
});

test('handleEndTutorialClick sets endUserTutorialShown to true', () => {
  const wrapper = shallow(
    <TutorialTray {...getDefaultProps()}>
      <div>Some Content</div>
    </TutorialTray>
  );

  wrapper.instance().handleEndTutorialClick();

  equal(wrapper.state('endUserTutorialShown'), true);
});

test('closeEndTutorialDialog sets endUserTutorialShown to false', () => {
  const wrapper = shallow(
    <TutorialTray {...getDefaultProps()}>
      <div>Some Content</div>
    </TutorialTray>
  );

  wrapper.instance().closeEndTutorialDialog();

  equal(wrapper.state('endUserTutorialShown'), false);
});
