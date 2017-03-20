/*
 * Copyright (C) 2017 Instructure, Inc.
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
import AssignmentGroupColumnHeader from 'jsx/gradezilla/default_gradebook/components/AssignmentGroupColumnHeader'

function createExampleProps () {
  return {
    assignmentGroup: {
      groupWeight: 42.5,
      name: 'Assignment Group 1'
    },
    weightedGroups: true
  };
}

function mountComponent (props) {
  return mount(<AssignmentGroupColumnHeader {...props} />);
}

QUnit.module('AssignmentGroupColumnHeader - base behavior', {
  setup () {
    const props = createExampleProps();
    this.wrapper = mountComponent(props);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('renders the assignment group name', function () {
  const assignmentGroupName = this.wrapper.find('.Gradebook__ColumnHeaderDetail').childAt(0);
  equal(assignmentGroupName.text(), 'Assignment Group 1');
});

test('renders the assignment groupWeight percentage', function () {
  const groupWeight = this.wrapper.find('.Gradebook__ColumnHeaderDetail').childAt(1);
  equal(groupWeight.text(), '42.50% of grade');
});

QUnit.module('AssignmentGroupColumnHeader - non-standard assignment group', {
  setup () {
    this.props = createExampleProps();
  },
});

test('renders 0% as the groupWeight percentage when weightedGroups is true but groupWeight is 0', function () {
  this.props.assignmentGroup.groupWeight = 0;

  const wrapper = mountComponent(this.props);

  const groupWeight = wrapper.find('.Gradebook__ColumnHeaderDetail').childAt(1);
  equal(groupWeight.text(), '0.00% of grade');
});

test('does not render the groupWeight percentage when weightedGroups is false', function () {
  this.props.weightedGroups = false;

  const wrapper = mountComponent(this.props);

  const headerDetails = wrapper.find('.Gradebook__ColumnHeaderDetail').children();
  equal(headerDetails.length, 1, 'only the assignment group name is visible');
  equal(headerDetails.text(), 'Assignment Group 1');
});
