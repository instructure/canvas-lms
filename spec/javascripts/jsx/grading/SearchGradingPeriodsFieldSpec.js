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
  'jsx/grading/SearchGradingPeriodsField'
], (React, ReactDOM, {Simulate}, SearchGradingPeriodsField) => {
  const wrapper = document.getElementById('fixtures');

  QUnit.module("SearchGradingPeriodsField", {
    renderComponent() {
      const props = { changeSearchText: sinon.spy() };
      const element = React.createElement(SearchGradingPeriodsField, props);
      return ReactDOM.render(element, wrapper);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test("onChange trims the search text and sends it to the parent component to filter", function() {
    let searchField = this.renderComponent();
    sandbox.spy(searchField, "search");
    let input = ReactDOM.findDOMNode(searchField.refs.input);
    input.value = "   i love spaces!   ";
    Simulate.change(input);
    ok(searchField.search.calledWith("i love spaces!"));
  });
});
