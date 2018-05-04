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
define([
  'react',
  'enzyme',
  'jsx/new_user_tutorial/NewUserTutorialToggleButton',
  '@instructure/ui-icons/lib/Line/IconMoveLeft',
  '@instructure/ui-icons/lib/Line/IconMoveRight',
  'jsx/new_user_tutorial/utils/createTutorialStore'
], (React, { shallow }, NewUserTutorialToggleButton, { default: IconMoveLeftLine }, { default: IconMoveRightLine }, createTutorialStore) => {
  QUnit.module('NewUserTutorialToggleButton Spec');

  test('Deafaults to expanded', () => {
    const store = createTutorialStore();
    const wrapper = shallow(
      <NewUserTutorialToggleButton store={store} />
    );

    ok(!wrapper.state('isCollapsed'))
  });

  test('Toggles isCollapsed when clicked', () => {
    const fakeEvent = {
      preventDefault () {}
    }

    const store = createTutorialStore();
    const wrapper = shallow(
      <NewUserTutorialToggleButton store={store} />
    );

    wrapper.simulate('click', fakeEvent);
    ok(wrapper.state('isCollapsed'))
  });

  test('shows IconMoveLeftLine when isCollapsed is true', () => {
    const store = createTutorialStore({ isCollapsed: true });
    const wrapper = shallow(
      <NewUserTutorialToggleButton store={store} />
    );

    ok(wrapper.find(IconMoveLeftLine).exists())
  });

  test('shows IconMoveRightLine when isCollapsed is false', () => {
    const store = createTutorialStore({ isCollapsed: false });
    const wrapper = shallow(
      <NewUserTutorialToggleButton store={store} />
    );

    ok(wrapper.find(IconMoveRightLine).exists())
  })
});
