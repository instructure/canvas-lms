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
  'react-dom/test-utils',
  'jsx/collaborations/NewCollaborationsDropDown'
], (React, ReactDOM, TestUtils, NewCollaborationsDropDown) => {

  QUnit.module('NewCollaborationsDropDown');

  let defaultProps = {
    ltiCollaborators: [{name: "A name", id: '1'}]
  }

  test('renders the create-collaborations-dropdown div', () => {
    ENV.context_asset_string = 'courses_1';

    let component = TestUtils.renderIntoDocument(<NewCollaborationsDropDown {...defaultProps} />);
    ok(TestUtils.findRenderedDOMComponentWithClass(component, 'create-collaborations-dropdown'));
  });

  test('has a link to open the lti tool to create a collaboration', () => {
    ENV.context_asset_string = 'courses_1';

    let component = TestUtils.renderIntoDocument(<NewCollaborationsDropDown {...defaultProps} />);
    let button = TestUtils.scryRenderedDOMComponentsWithClass(component, 'Button')[0];
    ok(ReactDOM.findDOMNode(button).href.includes('/courses/1/lti_collaborations/external_tools/1?launch_type=collaboration&display=borderless'));
  })

  test('has a dropdown if there is more than one tool', () => {
    ENV.context_asset_string = 'courses_1';

    let props = {
      ltiCollaborators: [{
        name: "A name",
        id: '1'
      }, {
        name: "Another name",
        id: '2'
      }]
    }

    let component = TestUtils.renderIntoDocument(<NewCollaborationsDropDown {...props} />);
    let dropdownButton = TestUtils.findRenderedDOMComponentWithTag(component, 'button');
    TestUtils.Simulate.click(dropdownButton);

    let links = TestUtils.scryRenderedDOMComponentsWithTag(component, 'a');
    equal(links.length, 2)
  })
});
