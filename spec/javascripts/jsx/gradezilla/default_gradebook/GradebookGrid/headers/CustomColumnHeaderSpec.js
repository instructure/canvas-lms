/*
 * Copyright (C) 2011 - present Instructure, Inc.
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
import { mount } from 'enzyme'
import CustomColumnHeader from 'jsx/gradezilla/default_gradebook/GradebookGrid/headers/CustomColumnHeader'

function mountComponent (props, mountOptions = {}) {
  return mount(<CustomColumnHeader {...props} />, mountOptions);
}

QUnit.module('CustomColumnHeader');

test('displays the given title', function () {
  const wrapper = mount(<CustomColumnHeader title="Notes" />);
  equal(wrapper.text(), 'Notes');
});

QUnit.module('CustomColumnHeader#handleKeyDown', {
  setup () {
    this.wrapper = mountComponent({ title: 'Notes' }, { attachTo: document.querySelector('#fixtures') });
  },

  handleKeyDown (which, shiftKey = false) {
    return this.wrapper.instance().handleKeyDown({ which, shiftKey, preventDefault: this.preventDefault });
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('does not handle Tab', function () {
  // This ensures no issues calling .handleKeyDown for Tab on an instance of
  // this component.
  const returnValue = this.handleKeyDown(9, false); // Tab
  equal(typeof returnValue, 'undefined');
});

test('does not handle Shift+Tab', function () {
  // This ensures no issues calling .handleKeyDown for Shift+Tab on an instance
  // of this component.
  const returnValue = this.handleKeyDown(9, true); // Shift+Tab
  equal(typeof returnValue, 'undefined');
});

test('does not handle Enter', function () {
  // This ensures no issues calling .handleKeyDown for Enter on an instance of
  // this component.
  const returnValue = this.handleKeyDown(13); // Enter
  equal(typeof returnValue, 'undefined');
});

QUnit.module('CustomColumnHeader: focus', {
  setup () {
    this.wrapper = mountComponent({ title: 'Notes' }, { attachTo: document.querySelector('#fixtures') });
    this.activeElement = document.activeElement;
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('#focusAtStart has no effect', function () {
  // This ensures no issues calling .focusAtStart on an instance of this
  // component.
  this.wrapper.instance().focusAtStart();
  equal(document.activeElement, this.activeElement);
});

test('#focusAtEnd has no effect', function () {
  // This ensures no issues calling .focusAtEnd on an instance of this
  // component.
  this.wrapper.instance().focusAtEnd();
  equal(document.activeElement, this.activeElement);
});
