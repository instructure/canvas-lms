/* * Copyright (C) 2017 - present Instructure, Inc.
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
import SelectMenu from 'jsx/grade_summary/SelectMenu';

QUnit.module('SelectMenu', function (hooks) {
  let props;
  let wrapper;

  function mountComponent () {
    return mount(<SelectMenu {...props} />);
  }

  function selectMenu () {
    return wrapper.find('select');
  }

  function selectMenuOptions () {
    return selectMenu().node.options;
  }

  function selectedOption () {
    return selectMenuOptions()[selectMenu().node.selectedIndex];
  }

  hooks.beforeEach(function () {
    const options = [
      { id: '3', name: 'Guy B. Studying', url: '/some/url/3' },
      { id: '14', name: 'Jane Doe', url: '/some/url/14' },
      { id: '18', name: 'John Doe', url: '/some/url/18' }
    ];

    props = {
      defaultValue: '14',
      disabled: false,
      id: 'select-menu',
      label: 'Student',
      onChange () {},
      options,
      textAttribute: 'name',
      valueAttribute: 'id'
    };
  });

  hooks.afterEach(function () {
    wrapper.unmount();
  });

  test('initializes showing the option with the default value', function () {
    wrapper = mountComponent();
    strictEqual(selectedOption().innerText, 'Jane Doe');
  });

  test('generates one option per item in the options prop', function () {
    wrapper = mountComponent();
    strictEqual(selectMenuOptions().length, 3);
  });

  test('uses the textAttribute prop to determine the text for each option', function () {
    props.textAttribute = 'url';
    wrapper = mountComponent();
    strictEqual(selectedOption().innerText, '/some/url/14');
  });

  test('textAttribute can be a number that represents the index of the text attribute', function () {
    props.defaultValue = 'due_date';
    props.options = [['Title', 'title'], ['Due Date', 'due_date']];
    props.textAttribute = 0;
    props.valueAttribute = 1;
    wrapper = mountComponent();
    strictEqual(selectedOption().innerText, 'Due Date');
  });

  test('uses the valueAttribute prop to determine the value for each option', function () {
    props.defaultValue = '/some/url/14';
    props.valueAttribute = 'url';
    wrapper = mountComponent();
    strictEqual(selectedOption().value, '/some/url/14');
  });

  test('valueAttribute can be a number that represents the index of the value attribute', function () {
    props.defaultValue = 'due_date';
    props.options = [['Title', 'title'], ['Due Date', 'due_date']];
    props.textAttribute = 0;
    props.valueAttribute = 1;
    wrapper = mountComponent();
    strictEqual(selectedOption().value, 'due_date');
  });

  test('is disabled if passed disabled: true', function () {
    props.disabled = true;
    wrapper = mountComponent();
    strictEqual(selectMenu().node.getAttribute('aria-disabled'), 'true');
  });

  test('calls onChange when the menu is changed', function () {
    props.onChange = sinon.stub();
    wrapper = mountComponent();
    selectMenu().simulate('change', { target: { value: '3' } });
    strictEqual(props.onChange.callCount, 1);
  });
});
