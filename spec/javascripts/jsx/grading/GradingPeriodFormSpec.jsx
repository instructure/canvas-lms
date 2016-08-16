define([
  'react',
  'react-dom',
  'underscore',
  'jsx/grading/GradingPeriodForm'
], (React, ReactDOM, _, GradingPeriodForm) => {
  const wrapper = document.getElementById('fixtures');
  const Simulate = React.addons.TestUtils.Simulate;

  const examplePeriod = {
    id: '1',
    title: 'Q1',
    startDate: new Date("2015-11-01T12:00:00Z"),
    endDate: new Date("2015-12-31T12:00:00Z"),
    closeDate: new Date("2016-01-07T12:00:00Z")
  };

  module('GradingPeriodForm', {
    renderComponent: function(opts={}) {
      const defaults = {
        period: examplePeriod,
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
    equal(form.refs.startDate.refs.dateInput.value, 'Nov 1, 2015 at 12pm');
    equal(form.refs.endDate.refs.dateInput.value, 'Dec 31, 2015 at 12pm');
    equal(form.refs.closeDate.refs.dateInput.value, 'Jan 7 at 12pm');
  });

  test('renders with the save button enabled', function() {
    let form = this.renderComponent();
    let saveButton = ReactDOM.findDOMNode(form.refs.saveButton);
    equal(saveButton.disabled, false);
  });

  test('renders with the cancel button enabled', function() {
    let form = this.renderComponent();
    let cancelButton = ReactDOM.findDOMNode(form.refs.saveButton);
    equal(cancelButton.disabled, false);
  });

  test('optionally renders with the save and cancel buttons disabled', function() {
    let form = this.renderComponent({disabled: true});
    let saveButton = ReactDOM.findDOMNode(form.refs.saveButton);
    let cancelButton = ReactDOM.findDOMNode(form.refs.cancelButton);
    equal(saveButton.disabled, true);
    equal(cancelButton.disabled, true);
  });

  test("auto-updates 'closeDate' when not already set and 'endDate' changes", function() {
    let incompletePeriod = _.extend({}, examplePeriod, { closeDate: null });
    let form = this.renderComponent({period: incompletePeriod});
    let endDateInput = ReactDOM.findDOMNode(form.refs.endDate.refs.dateInput);
    endDateInput.value = 'Dec 31, 2015 at 12pm';
    endDateInput.dispatchEvent(new Event("change"));
    equal(form.refs.endDate.refs.dateInput.value, 'Dec 31, 2015 at 12pm');
    equal(form.refs.closeDate.refs.dateInput.value, 'Dec 31, 2015 at 12pm');
  });

  test("auto-updates 'closeDate' when set equal to 'endDate' and 'endDate' changes", function() {
    let consistentPeriod = _.extend({}, examplePeriod, { closeDate: examplePeriod.endDate });
    let form = this.renderComponent({period: consistentPeriod});
    let endDateInput = ReactDOM.findDOMNode(form.refs.endDate.refs.dateInput);
    endDateInput.value = 'Dec 30, 2015 at 12pm';
    endDateInput.dispatchEvent(new Event("change"));
    equal(form.refs.endDate.refs.dateInput.value, 'Dec 30, 2015 at 12pm');
    equal(form.refs.closeDate.refs.dateInput.value, 'Dec 30, 2015 at 12pm');
  });

  test("preserves 'closeDate' when not set equal to 'endDate' and 'endDate' changes", function() {
    let form = this.renderComponent();
    let endDateInput = ReactDOM.findDOMNode(form.refs.endDate.refs.dateInput);
    endDateInput.value = 'Dec 30, 2015 at 12pm';
    endDateInput.dispatchEvent(new Event("change"));
    equal(form.refs.endDate.refs.dateInput.value, 'Dec 30, 2015 at 12pm');
    equal(form.refs.closeDate.refs.dateInput.value, 'Jan 7 at 12pm');
  });

  test("preserves 'closeDate' when already set and 'endDate' changes to match, then changes again", function() {
    let form = this.renderComponent();
    let endDateInput = ReactDOM.findDOMNode(form.refs.endDate.refs.dateInput);
    endDateInput.value = 'Jan 7 at 12pm';
    endDateInput.dispatchEvent(new Event("change"));
    endDateInput.value = 'Dec 30, 2015 at 12pm';
    endDateInput.dispatchEvent(new Event("change"));
    equal(form.refs.endDate.refs.dateInput.value, 'Dec 30, 2015 at 12pm');
    equal(form.refs.closeDate.refs.dateInput.value, 'Jan 7 at 12pm');
  });

  test("auto-updates 'closeDate' when cleared and 'endDate' changes", function() {
    let form = this.renderComponent();
    let closeDateInput = ReactDOM.findDOMNode(form.refs.closeDate.refs.dateInput);
    closeDateInput.value = '';
    closeDateInput.dispatchEvent(new Event("change"));
    let endDateInput = ReactDOM.findDOMNode(form.refs.endDate.refs.dateInput);
    endDateInput.value = 'Jan 7 at 12pm';
    endDateInput.dispatchEvent(new Event("change"));
    equal(form.refs.endDate.refs.dateInput.value, 'Jan 7 at 12pm');
    equal(form.refs.closeDate.refs.dateInput.value, 'Jan 7 at 12pm');
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
      closeDate: new Date("2016-01-07T12:00:00Z")
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
