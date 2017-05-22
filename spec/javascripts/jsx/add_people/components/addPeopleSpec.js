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

define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/add_people/components/add_people',
], (React, ReactDOM, TestUtils, AddPeople) => {
  QUnit.module('AddPeople');

  const props = {
    isOpen: true,
    courseParams: {
      roles: [],
      sections: []
    },
    apiState: {
      isPending: 0
    },
    inputParams: {
      nameList: '',
    }
  };

  test('renders the component', () => {
    const component = TestUtils.renderIntoDocument(
      <AddPeople
        validateUsers={() => {}}
        enrollUsers={() => {}}
        reset={() => {}}
        {...props}
      />
    );
    const addPeople = document.querySelectorAll('.addpeople');
    equal(addPeople.length, 1, 'AddPeople component rendered.');
    component.close();
    ReactDOM.unmountComponentAtNode(component.node._overlay.parentElement);
  });
});
