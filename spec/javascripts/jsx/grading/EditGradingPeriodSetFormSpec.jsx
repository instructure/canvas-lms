define([
  'react',
  'react-dom',
  'jquery',
  'underscore',
  'jsx/grading/EditGradingPeriodSetForm'
], (React, ReactDOM, $, _, GradingPeriodSetForm) => {
  const wrapper = document.getElementById('fixtures');
  const Simulate = React.addons.TestUtils.Simulate;

  const exampleSet = { id: "1", title: "Fall 2015" };

  module('EditGradingPeriodSetForm', {
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
    let saveButton = React.findDOMNode(form.refs.saveButton);
    equal(saveButton.getAttribute('aria-disabled'), 'false');
    notOk(_.contains(saveButton.classList, 'disabled'));
  });

  test('renders with the cancel button enabled', function() {
    let form = this.renderComponent();
    let cancelButton = React.findDOMNode(form.refs.cancelButton);
    equal(cancelButton.getAttribute('aria-disabled'), 'false');
    notOk(_.contains(cancelButton.classList, 'disabled'));
  });

  test('optionally renders with the save and cancel buttons disabled', function() {
    let form = this.renderComponent({ disabled: true });
    let saveButton = React.findDOMNode(form.refs.saveButton);
    let cancelButton = React.findDOMNode(form.refs.cancelButton);
    equal(saveButton.getAttribute('aria-disabled'), 'true');
    ok(_.contains(saveButton.classList, 'disabled'));
    equal(cancelButton.getAttribute('aria-disabled'), 'true');
    ok(_.contains(cancelButton.classList, 'disabled'));
  });

  test('uses attributes from the given set', function() {
    let form = this.renderComponent();
    equal(React.findDOMNode(form.refs.title).value, "Fall 2015");
    equal(form.state.set.id, "1");
  });

  test('uses associated enrollment terms to update set state', function() {
    let form = this.renderComponent();
    deepEqual(form.state.set.enrollmentTermIDs, ["1", "3"]);
  });

  test("calls the 'onSave' callback when the save button is clicked", function() {
    let spy = sinon.spy();
    let form = this.renderComponent({ onSave: spy });
    let saveButton = React.findDOMNode(form.refs.saveButton);
    Simulate.click(saveButton);
    ok(spy.calledOnce);
    ok(spy.calledWith(form.state.set));
  });

  test("calls the 'onCancel' callback when the cancel button is clicked", function() {
    let spy = sinon.spy();
    let form = this.renderComponent({ onCancel: spy });
    let cancelButton = React.findDOMNode(form.refs.cancelButton);
    Simulate.click(cancelButton);
    ok(spy.calledOnce);
  });

  test("does not call 'onSave' when the set has no title", function() {
    let spy = sinon.spy();
    let updatedSet = _.extend({}, exampleSet, { title: "", enrollmentTermIDs: ["1"] });
    let form = this.renderComponent({ onSave: spy, set: updatedSet });
    let saveButton = React.findDOMNode(form.refs.saveButton);
    Simulate.click(saveButton);
    notOk(spy.called);
  });
});
