define([
  'react',
  'jquery',
  'underscore',
  'compiled/api/gradingPeriodSetsApi',
  'jsx/grading/NewGradingPeriodSetForm'
], (React, $, _, setsApi, NewSetForm) => {
  const wrapper = document.getElementById('fixtures');
  const Simulate = React.addons.TestUtils.Simulate;
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
      return React.render(element, wrapper);
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
      React.unmountComponentAtNode(wrapper);
    }
  });

  test('initially renders with the create button not disabled', function() {
    let form = this.renderComponent();
    let createButton = React.findDOMNode(form.refs.createButton);
    equal(createButton.getAttribute('aria-disabled'), 'false');
    notOk(_.contains(createButton.classList, 'disabled'));
  });

  test('initially renders with the cancel button not disabled', function() {
    let form = this.renderComponent();
    let cancelButton = React.findDOMNode(form.refs.cancelButton);
    equal(cancelButton.getAttribute('aria-disabled'), 'false');
    notOk(_.contains(cancelButton.classList, 'disabled'));
  });

  test('disables the create button when it is clicked', function() {
    this.stubCreateSuccess();
    let form = this.renderComponent();
    this.stub(form, 'isValid', () => true);
    let createButton = React.findDOMNode(form.refs.createButton);
    Simulate.click(createButton);
    equal(createButton.getAttribute('aria-disabled'), 'true');
    ok(_.contains(React.findDOMNode(createButton).classList, 'disabled'));
  });

  test('disables the cancel button when the create button is clicked', function() {
    this.stubCreateSuccess();
    let form = this.renderComponent();
    this.stub(form, 'isValid', () => true);
    let cancelButton = React.findDOMNode(form.refs.cancelButton);
    Simulate.click(form.refs.createButton);
    equal(cancelButton.getAttribute('aria-disabled'), 'true');
    ok(_.contains(React.findDOMNode(cancelButton).classList, 'disabled'));
  });

  asyncTest('re-enables the cancel button when the ajax call fails', function() {
    this.stubCreateFailure();
    let form = this.renderComponent();
    this.stub(form, 'isValid', () => true);
    let cancelButton = React.findDOMNode(form.refs.cancelButton);
    Simulate.click(form.refs.createButton);
    requestAnimationFrame(function() {
      equal(cancelButton.getAttribute('aria-disabled'), 'false');
      notOk(_.contains(cancelButton.classList, 'disabled'));
      start();
    });
  });

  asyncTest('re-enables the create button when the ajax call fails', function() {
    this.stubCreateFailure();
    let form = this.renderComponent();
    this.stub(form, 'isValid', () => true);
    let createButton = React.findDOMNode(form.refs.createButton);
    Simulate.click(createButton);
    requestAnimationFrame(function() {
      equal(createButton.getAttribute('aria-disabled'), 'false');
      notOk(_.contains(createButton.classList, 'disabled'));
      start();
    });
  });
});
