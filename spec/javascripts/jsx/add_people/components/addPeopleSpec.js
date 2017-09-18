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
  'enzyme',
  'jsx/add_people/components/add_people',
], (React, enzyme, AddPeople) => {
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
    const container = document.createElement('div');
    container.id = 'application';
    document.body.appendChild(container);

    const wrapper = enzyme.mount(
      <AddPeople
        validateUsers={() => {}}
        enrollUsers={() => {}}
        reset={() => {}}
        {...props}
      />,
      { attachTo: document.getElementById('fixtures') }
    );

    ok(document.getElementById('add_people_modal'));

    wrapper.unmount();
    document.body.removeChild(container);
  });
});
