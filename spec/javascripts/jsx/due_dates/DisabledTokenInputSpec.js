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
  'jsx/due_dates/DisabledTokenInput'
], (React, ReactDOM, {scryRenderedDOMComponentsWithTag}, DisabledTokenInput) => {
  const wrapper = document.getElementById("fixtures");
  const tokens = ["John Smith", "Section 2", "Group 1"];

  QUnit.module('DisabledTokenInput', {
    setup() {
      this.input = ReactDOM.render(<DisabledTokenInput tokens={tokens}/>, wrapper);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test('renders a list item for each token passed in', function() {
    const listItems = scryRenderedDOMComponentsWithTag(this.input, "li");
    propEqual(listItems.map(item => item.textContent), tokens);
  });
});
