define([
  'react',
  'react-dom',
  'jquery',
  'underscore',
  'compiled/api/gradingPeriodSetsApi',
  'jsx/grading/NewGradingPeriodSetForm'
], (React, ReactDOM, $, _, setsApi, NewSetForm) => {
  const wrapper = document.getElementById('fixtures');
  const Simulate = React.addons.TestUtils.Simulate;

  const assertDisabled = function(component) {
    let $el = ReactDOM.findDOMNode(component);
    equal($el.getAttribute('aria-disabled'), 'true');
  };

  const assertEnabled = function(component) {
    let $el = ReactDOM.findDOMNode(component);
    notEqual($el.getAttribute('aria-disabled'), 'true');
  };

  const exampleSet = {
    grading_period_set: {
      id: "81",
      title: "Example Set!",
      grading_periods: [],
      permissions: { read: true, update: true, delete: true, create: true },
      created_at: "2013-06-03T02:57:42Z"
    }
  };

  module('NewGradingPeriodSetForm', {
    renderComponent(props={}) {
      const defaultProps = {
        enrollmentTerms: [],
        closeForm(){},
        addGradingPeriodSet: this.stub(),
        urls: {
          gradingPeriodSetsURL: "api/v1/accounts/1/grading_period_sets",
          enrollmentTermsURL: "api/v1/accounts/1/enrollment_terms"
        },
        readOnly: false
      };
      const element = React.createElement(NewSetForm, _.defaults(props, defaultProps));
      return ReactDOM.render(element, wrapper);
    },

    stubCreateSuccess(){
      const success = new Promise(resolve => resolve(exampleSet));
      this.stub(setsApi, 'create').returns(success);
      return success;
    },

    stubCreateFailure(){
      const failure = new Promise((_, reject) => reject("FAIL"));
      this.stub(setsApi, 'create').returns(failure);
      return failure;
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test('initially renders with the create button not disabled', function() {
    let form = this.renderComponent();
    assertEnabled(form.refs.createButton);
  });

  test('initially renders with the cancel button not disabled', function() {
    let form = this.renderComponent();
    assertEnabled(form.refs.cancelButton);
  });

  test('disables the create button when it is clicked', function() {
    this.stubCreateSuccess();
    let form = this.renderComponent();
    this.stub(form, 'isValid', () => true);
    Simulate.click(ReactDOM.findDOMNode(form.refs.createButton));
    assertDisabled(form.refs.createButton);
  });

  test('disables the cancel button when the create button is clicked', function() {
    this.stubCreateSuccess();
    let form = this.renderComponent();
    this.stub(form, 'isValid', () => true);
    Simulate.click(ReactDOM.findDOMNode(form.refs.createButton));
    assertDisabled(form.refs.cancelButton);
  });

  asyncTest('re-enables the cancel button when the ajax call fails', function() {
    this.stubCreateFailure();
    let form = this.renderComponent();
    this.stub(form, 'isValid', () => true);
    Simulate.click(ReactDOM.findDOMNode(form.refs.cancelButton));
    requestAnimationFrame(function() {
      assertEnabled(form.refs.cancelButton);
      start();
    });
  });

  asyncTest('re-enables the create button when the ajax call fails', function() {
    this.stubCreateFailure();
    let form = this.renderComponent();
    this.stub(form, 'isValid', () => true);
    Simulate.click(ReactDOM.findDOMNode(form.refs.createButton));
    requestAnimationFrame(function() {
      assertEnabled(form.refs.createButton);
      start();
    });
  });
});
