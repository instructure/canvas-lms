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
  'underscore',
  'jsx/grading/GradingPeriodForm',
  'timezone/America/Chicago',
  'timezone',
  'helpers/fakeENV'
], (React, ReactDOM, {Simulate}, _, GradingPeriodForm, chicago, tz,
  fakeENV) => {
  const wrapper = document.getElementById('fixtures');

  const examplePeriod = {
    id: '1',
    title: 'Q1',
    weight: 30,
    startDate: new Date("2015-11-01T12:00:00Z"),
    endDate: new Date("2015-12-31T12:00:00Z"),
    closeDate: new Date("2016-01-07T12:00:00Z")
  };

  QUnit.module('GradingPeriodForm', {
    renderComponent: function(opts={}) {
      const defaults = {
        period: examplePeriod,
        weighted: true,
        disabled: false,
        onSave:   () => {},
        onCancel: () => {}
      };
      const element = React.createElement(GradingPeriodForm, _.defaults(opts, defaults));
      return ReactDOM.render(element, wrapper);
    },

    teardown: function() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test("sets form values from 'period' props", function() {
    let form = this.renderComponent();
    equal(form.refs.title.value, 'Q1');
    equal(form.refs.startDate.refs.dateInput.value, 'Nov 1, 2015 12pm');
    equal(form.refs.endDate.refs.dateInput.value, 'Dec 31, 2015 12pm');
    equal(form.refs.closeDate.refs.dateInput.value, 'Jan 7, 2016 12pm');
    equal(form.weightInput.value, '30');
  });

  test("does not render weighted input if weighted is false", function() {
    const form = this.renderComponent({weighted: false});
    equal(form.weightInput, null);
  });

  test('renders with the save button enabled', function() {
    let form = this.renderComponent();
    equal(form.refs.saveButton.props.disabled, false);
  });

  test('renders with the cancel button enabled', function() {
    let form = this.renderComponent();
    equal(form.refs.cancelButton.props.disabled, false);
  });

  test('optionally renders with the save and cancel buttons disabled', function() {
    let form = this.renderComponent({disabled: true});
    equal(form.refs.saveButton.props.disabled, true);
    equal(form.refs.cancelButton.props.disabled, true);
  });

  test("auto-updates 'closeDate' when not already set and 'endDate' changes", function() {
    let incompletePeriod = _.extend({}, examplePeriod, { closeDate: null });
    let form = this.renderComponent({period: incompletePeriod});
    let endDateInput = ReactDOM.findDOMNode(form.refs.endDate.refs.dateInput);
    endDateInput.value = 'Dec 31, 2015 12pm';
    endDateInput.dispatchEvent(new Event("change"));
    equal(form.refs.endDate.refs.dateInput.value, 'Dec 31, 2015 12pm');
    equal(form.refs.closeDate.refs.dateInput.value, 'Dec 31, 2015 12pm');
  });

  test("auto-updates 'closeDate' when set equal to 'endDate' and 'endDate' changes", function() {
    let consistentPeriod = _.extend({}, examplePeriod, { closeDate: examplePeriod.endDate });
    let form = this.renderComponent({period: consistentPeriod});
    let endDateInput = ReactDOM.findDOMNode(form.refs.endDate.refs.dateInput);
    endDateInput.value = 'Dec 30, 2015 12pm';
    endDateInput.dispatchEvent(new Event("change"));
    equal(form.refs.endDate.refs.dateInput.value, 'Dec 30, 2015 12pm');
    equal(form.refs.closeDate.refs.dateInput.value, 'Dec 30, 2015 12pm');
  });

  test("preserves 'closeDate' when not set equal to 'endDate' and 'endDate' changes", function() {
    let form = this.renderComponent();
    let endDateInput = ReactDOM.findDOMNode(form.refs.endDate.refs.dateInput);
    endDateInput.value = 'Dec 30, 2015 12pm';
    endDateInput.dispatchEvent(new Event("change"));
    equal(form.refs.endDate.refs.dateInput.value, 'Dec 30, 2015 12pm');
    equal(form.refs.closeDate.refs.dateInput.value, 'Jan 7, 2016 12pm');
  });

  test("preserves 'closeDate' when already set and 'endDate' changes to match, then changes again", function() {
    let form = this.renderComponent();
    let endDateInput = ReactDOM.findDOMNode(form.refs.endDate.refs.dateInput);
    endDateInput.value = 'Jan 7 12pm';
    endDateInput.dispatchEvent(new Event("change"));
    endDateInput.value = 'Dec 30, 2015 12pm';
    endDateInput.dispatchEvent(new Event("change"));
    equal(form.refs.endDate.refs.dateInput.value, 'Dec 30, 2015 12pm');
    equal(form.refs.closeDate.refs.dateInput.value, 'Jan 7, 2016 12pm');
  });

  test("auto-updates 'closeDate' when cleared and 'endDate' changes", function() {
    let form = this.renderComponent();
    let closeDateInput = ReactDOM.findDOMNode(form.refs.closeDate.refs.dateInput);
    closeDateInput.value = '';
    closeDateInput.dispatchEvent(new Event("change"));
    let endDateInput = ReactDOM.findDOMNode(form.refs.endDate.refs.dateInput);
    endDateInput.value = 'Jan 7 12pm';
    endDateInput.dispatchEvent(new Event("change"));
    equal(form.refs.endDate.refs.dateInput.value, 'Jan 7 12pm');
    equal(form.refs.closeDate.refs.dateInput.value, 'Jan 7 12pm');
  });

  test("given a different content timezone, local and server time are shown", function() {
    tz.preload('America/Chicago', chicago);
    fakeENV.setup({TIMEZONE: 'America/Denver', CONTEXT_TIMEZONE: 'America/Chicago'});
    const form = this.renderComponent();
    const datetimeSuggestList = ReactDOM.findDOMNode(form).querySelectorAll('.datetime_suggest');
    equal(datetimeSuggestList.length, 6);
    fakeENV.teardown();
  });

  test("given the same timezone, local and server time are not shown", function() {
    const form = this.renderComponent();
    const datetimeSuggestList = ReactDOM.findDOMNode(form).querySelectorAll('.datetime_suggest');
    equal(datetimeSuggestList.length, 0);
  });

  test("calls the 'onSave' callback when the save button is clicked", function() {
    let spy = sinon.spy();
    let form = this.renderComponent({onSave: spy});
    let saveButton = ReactDOM.findDOMNode(form.refs.saveButton);
    Simulate.click(saveButton);
    ok(spy.calledOnce);
  });

  test("sends form values in 'onSave'", function() {
    let spy = sinon.spy();
    let form = this.renderComponent({onSave: spy});
    let saveButton = ReactDOM.findDOMNode(form.refs.saveButton);
    Simulate.click(saveButton);
    deepEqual(spy.args[0][0], {
      id: '1',
      title: 'Q1',
      startDate: new Date("2015-11-01T12:00:00Z"),
      endDate: new Date("2015-12-31T12:00:00Z"),
      closeDate: new Date("2016-01-07T12:00:00Z"),
      weight: 30
    });
  });

  test("calls the 'onCancel' callback when the cancel button is clicked", function() {
    let spy = sinon.spy();
    let form = this.renderComponent({onCancel: spy});
    let cancelButton = ReactDOM.findDOMNode(form.refs.cancelButton);
    Simulate.click(cancelButton);
    ok(spy.calledOnce);
  });
});
