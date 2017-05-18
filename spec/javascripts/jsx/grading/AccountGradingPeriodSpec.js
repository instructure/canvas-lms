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
  'axios',
  'underscore',
  'jsx/grading/AccountGradingPeriod',
  'helpers/fakeENV',
  'timezone',
  'timezone/America/Chicago'
], (React, ReactDOM, { Simulate }, axios, _, GradingPeriod, fakeENV, tz, chicago) => {
  const wrapper = document.getElementById('fixtures');

  const allPermissions = { read: true, create: true, update: true, delete: true };
  const noPermissions = { read: false, create: false, update: false, delete: false };

  const defaultProps = {
    period: {
      id: "1",
      title: "We did it! We did it! We did it! #dora #boots",
      weight: 30,
      startDate: new Date("2015-01-01T20:11:00+00:00"),
      endDate: new Date("2015-03-01T00:00:00+00:00"),
      closeDate: new Date("2015-03-08T00:00:00+00:00")
    },
    weighted: true,
    readOnly: false,
    onEdit: () => {},
    readOnly: false,
    permissions: allPermissions,
    deleteGradingPeriodURL: 'api/v1/accounts/1/grading_periods/%7B%7B%20id%20%7D%7D'
  };

  QUnit.module('AccountGradingPeriod', {
    renderComponent(props = {}) {
      let attrs = _.defaults(props, defaultProps);
      attrs.onDelete = this.stub();
      const element = React.createElement(GradingPeriod, attrs);
      return ReactDOM.render(element, wrapper);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test('shows the "edit grading period" button when "create" is permitted', function () {
    let period = this.renderComponent();
    ok(period.refs.editButton);
  });

  test('does not show the "edit grading period" button when "create" is not permitted', function () {
    let period = this.renderComponent({ permissions: noPermissions });
    notOk(!!period.refs.editButton);
  });

  test('does not show the "edit grading period" button when "read only"', function () {
    let period = this.renderComponent({ permissions: allPermissions, readOnly: true });
    notOk(!!period.refs.editButton);
  });

  test('disables the "edit grading period" button when "actionsDisabled" is true', function () {
    let period = this.renderComponent({actionsDisabled: true});
    ok(period.refs.editButton.props.disabled);
  });

  test('disables the "delete grading period" button when "actionsDisabled" is true', function () {
    let period = this.renderComponent({actionsDisabled: true});
    ok(period.refs.deleteButton.props.disabled);
  });

  test('displays the start date in a friendly format', function () {
    let period = this.renderComponent();
    const startDate = ReactDOM.findDOMNode(period.refs.startDate).textContent;
    equal(startDate, "Starts: Jan 1, 2015");
  });

  test('displays the end date in a friendly format', function () {
    let period = this.renderComponent();
    const endDate = ReactDOM.findDOMNode(period.refs.endDate).textContent;
    equal(endDate, "Ends: Mar 1, 2015");
  });

  test('displays the close date in a friendly format', function () {
    let period = this.renderComponent();
    const closeDate = ReactDOM.findDOMNode(period.refs.closeDate).textContent;
    equal(closeDate, "Closes: Mar 8, 2015");
  });

  test("displays the weight in a friendly format", function() {
    let period = this.renderComponent();
    const weight = ReactDOM.findDOMNode(period.refs.weight).textContent;
    equal(weight, "Weight: 30%");
  });

  test("does not display the weight if weighted grading periods are turned off", function() {
    let period = this.renderComponent({weighted: false});
    equal(period.refs.weight, null);
  });

  test('calls the "onEdit" callback when the edit button is clicked', function () {
    let spy = sinon.spy();
    let period = this.renderComponent({onEdit: spy});
    let editButton = ReactDOM.findDOMNode(period.refs.editButton);
    Simulate.click(editButton);
    ok(spy.calledOnce);
  });

  test('displays the delete button if the user has proper rights', function () {
    let period = this.renderComponent();
    ok(period.refs.deleteButton);
  });

  test('does not display the delete button if readOnly is true', function () {
    let period = this.renderComponent({ readOnly: true });
    notOk(period.refs.deleteButton);
  });

  test('does not display the delete button if the user does not have delete permissions', function () {
    let period = this.renderComponent({ permissions: noPermissions });
    notOk(period.refs.deleteButton);
  });

  test('does not delete the period if the user cancels the delete confirmation', function () {
    this.stub(window, 'confirm').returns(false);
    let period = this.renderComponent();
    Simulate.click(ReactDOM.findDOMNode(period.refs.deleteButton));
    ok(period.props.onDelete.notCalled);
  });

  test('calls onDelete if the user confirms deletion and the ajax call succeeds', function () {
    const deletePromise = new Promise(resolve => resolve());
    this.stub(axios, 'delete').returns(deletePromise);
    this.stub(window, 'confirm').returns(true);
    let period = this.renderComponent();
    Simulate.click(ReactDOM.findDOMNode(period.refs.deleteButton));
    return deletePromise.then(() => {
      ok(period.props.onDelete.calledOnce);
    });
  });
});
