define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'underscore',
  'jsx/grading/EditGradingPeriodSetForm'
], (React, ReactDOM, {Simulate}, _, GradingPeriodSetForm) => {
  const wrapper = document.getElementById('fixtures');

  const assertDisabled = function(component) {
    let $el = ReactDOM.findDOMNode(component);
    equal($el.getAttribute('aria-disabled'), 'true');
  };

  const assertEnabled = function(component) {
    let $el = ReactDOM.findDOMNode(component);
    notEqual($el.getAttribute('aria-disabled'), 'true');
  };

  const exampleSet = { id: '1', title: 'Fall 2015', weighted: true, displayTotalsForAllGradingPeriods: false };

  QUnit.module('EditGradingPeriodSetForm', {
    renderComponent(opts={}) {
      const defaults = {
        set: exampleSet,
        enrollmentTerms: [
          { id: "1", gradingPeriodGroupId: "1" },
          { id: "2", gradingPeriodGroupId: "2" },
          { id: "3", gradingPeriodGroupId: "1" }
        ],
        disabled: false,
        onSave:   () => {},
        onCancel: () => {}
      };
      const element = React.createElement(GradingPeriodSetForm, _.defaults(opts, defaults));
      return ReactDOM.render(element, wrapper);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test('renders with the save button enabled', function() {
    let form = this.renderComponent();
    assertEnabled(form.refs.saveButton);
  });

  test('renders with the cancel button enabled', function() {
    let form = this.renderComponent();
    assertEnabled(form.refs.cancelButton);
  });

  test('optionally renders with the save and cancel buttons disabled', function() {
    let form = this.renderComponent({ disabled: true });
    assertDisabled(form.refs.saveButton);
    assertDisabled(form.refs.cancelButton);
  });

  test('uses attributes from the given set', function() {
    let form = this.renderComponent();
    equal(ReactDOM.findDOMNode(form.refs.title).value, "Fall 2015");
    equal(form.weightedCheckbox.checked, true);
    equal(form.state.set.id, "1");
  });

  test('updates weighted state when checkbox is clicked', function() {
    const form = this.renderComponent();
    equal(form.state.set.weighted, true);
    form.weightedCheckbox.handleChange({ target: { checked: false } });
    equal(form.state.set.weighted, false);
  });

  test('defaults to unchecked for the "Display totals for All Grading Periods option" checkbox', function () {
    const set = { id: '1', title: 'Fall 2015', weighted: true, displayTotalsForAllGradingPeriods: null };
    const form = this.renderComponent({ set });
    notOk(form.displayTotalsCheckbox._input.checked);
  });

  test('initializes to checked for the "Display totals for All Grading Periods option" checkbox if passed true', function () {
    const set = { id: '1', title: 'Fall 2015', weighted: true, displayTotalsForAllGradingPeriods: true };
    const form = this.renderComponent({ set });
    ok(form.displayTotalsCheckbox._input.checked);
  });

  test('the "Display totals for All Grading Periods option" checkbox changes state when clicked', function () {
    const form = this.renderComponent();
    const beforeChecked = form.displayTotalsCheckbox._input.checked;
    Simulate.change(form.displayTotalsCheckbox._input, { target: { checked: true } });
    const afterChecked = form.displayTotalsCheckbox._input.checked;
    notEqual(beforeChecked, afterChecked);
  });

  test('the "Display totals for All Grading Periods option" checkbox state is included when the set is saved', function () {
    const saveStub = this.stub();
    const form = this.renderComponent({ onSave: saveStub });
    const saveButton = ReactDOM.findDOMNode(form.refs.saveButton);
    Simulate.click(saveButton);
    equal(saveStub.callCount, 1, 'onSave was called once');
    const { displayTotalsForAllGradingPeriods } = saveStub.getCall(0).args[0];
    equal(displayTotalsForAllGradingPeriods, false, 'includes displayTotalsForAllGradingPeriods');
  });

  test('uses associated enrollment terms to update set state', function() {
    let form = this.renderComponent();
    deepEqual(form.state.set.enrollmentTermIDs, ["1", "3"]);
  });

  test("calls the 'onSave' callback when the save button is clicked", function() {
    let spy = sinon.spy();
    let form = this.renderComponent({ onSave: spy });
    let saveButton = ReactDOM.findDOMNode(form.refs.saveButton);
    Simulate.click(saveButton);
    ok(spy.calledOnce);
    ok(spy.calledWith(form.state.set));
  });

  test("calls the 'onCancel' callback when the cancel button is clicked", function() {
    let spy = sinon.spy();
    let form = this.renderComponent({ onCancel: spy });
    let cancelButton = ReactDOM.findDOMNode(form.refs.cancelButton);
    Simulate.click(cancelButton);
    ok(spy.calledOnce);
  });

  test("does not call 'onSave' when the set has no title", function() {
    let spy = sinon.spy();
    let updatedSet = _.extend({}, exampleSet, { title: "", enrollmentTermIDs: ["1"] });
    let form = this.renderComponent({ onSave: spy, set: updatedSet });
    let saveButton = ReactDOM.findDOMNode(form.refs.saveButton);
    Simulate.click(saveButton);
    notOk(spy.called);
  });
});
