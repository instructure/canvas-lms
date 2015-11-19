define([
  'react',
  'react-dom',
  'underscore',
  'jsx/grading/GradingPeriodForm'
], (React, ReactDOM, _, GradingPeriodForm) => {
  const wrapper = document.getElementById('fixtures');
  const Simulate = React.addons.TestUtils.Simulate;

  module('GradingPeriodForm', {
    renderComponent: function(opts={}) {
      const defaults = {
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

  test('mounts', function() {
    let form = this.renderComponent();
    ok(form.isMounted());
  });

  test('renders with the save button enabled', function() {
    let form = this.renderComponent();
    let saveButton = React.findDOMNode(form.refs.saveButton);
    equal(saveButton.disabled, false);
  });

  test('renders with the cancel button enabled', function() {
    let form = this.renderComponent();
    let cancelButton = React.findDOMNode(form.refs.saveButton);
    equal(cancelButton.disabled, false);
  });

  test('optionally renders with the save and cancel buttons disabled', function() {
    let form = this.renderComponent({disabled: true});
    let saveButton = React.findDOMNode(form.refs.saveButton);
    let cancelButton = React.findDOMNode(form.refs.cancelButton);
    equal(saveButton.disabled, true);
    equal(cancelButton.disabled, true);
  });

  test("calls the 'onSave' callback when the save button is clicked", function() {
    let spy = sinon.spy();
    let form = this.renderComponent({onSave: spy});
    let saveButton = React.findDOMNode(form.refs.saveButton);
    Simulate.click(saveButton);
    ok(spy.calledOnce);
  });

  test("calls the 'onCancel' callback when the cancel button is clicked", function() {
    let spy = sinon.spy();
    let form = this.renderComponent({onCancel: spy});
    let cancelButton = React.findDOMNode(form.refs.cancelButton);
    Simulate.click(cancelButton);
    ok(spy.calledOnce);
  });
});
