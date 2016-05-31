define([
  'react',
  'jquery',
  'underscore',
  'jsx/grading/NewGradingPeriodSetForm'
], (React, $, _, NewSetForm) => {
  const wrapper = document.getElementById('fixtures');
  const Simulate = React.addons.TestUtils.Simulate;

  module('NewGradingPeriodSetForm', {
    renderComponent(opts={}) {
      const defaults = {
        enrollmentTerms: [],
        closeForm(){},
        addGradingPeriodSet(){},
        urls: {
          gradingPeriodSetsURL: "api/v1/accounts/1/grading_period_sets",
          enrollmentTermsURL: "api/v1/accounts/1/enrollment_terms"
        }
      };
      const element = React.createElement(NewSetForm, _.defaults(opts, defaults));
      return React.render(element, wrapper);
    },
    teardown() {
      React.unmountComponentAtNode(wrapper);
    }
  });

  test('initially renders with the create button not disabled', function() {
    this.stub($, 'ajax');
    let form = this.renderComponent();
    let createButton = React.findDOMNode(form.refs.createButton);
    equal(createButton.getAttribute('aria-disabled'), 'false');
    notOk(_.contains(createButton.classList, 'disabled'));
  });

  test('initially renders with the cancel button not disabled', function() {
    this.stub($, 'ajax');
    let form = this.renderComponent();
    let cancelButton = React.findDOMNode(form.refs.cancelButton);
    equal(cancelButton.getAttribute('aria-disabled'), 'false');
    notOk(_.contains(cancelButton.classList, 'disabled'));
  });

  test('disables the create button when it is clicked', function() {
    this.stub($, 'ajax');
    let form = this.renderComponent();
    this.stub(form, 'isValid', function(){ return true; });
    let createButton = React.findDOMNode(form.refs.createButton);
    Simulate.click(React.findDOMNode(createButton));
    equal(createButton.getAttribute('aria-disabled'), 'true');
    ok(_.contains(React.findDOMNode(createButton).classList, 'disabled'));
  });

  test('disables the cancel button when the create button is clicked', function() {
    this.stub($, 'ajax');
    let form = this.renderComponent();
    this.stub(form, 'isValid', function(){ return true; });
    let cancelButton = React.findDOMNode(form.refs.cancelButton);
    Simulate.click(form.refs.createButton);
    equal(cancelButton.getAttribute('aria-disabled'), 'true');
    ok(_.contains(React.findDOMNode(cancelButton).classList, 'disabled'));
  });

  test('re-enables the cancel button when the ajax call succeeds', function() {
    let form = this.renderComponent();
    this.stub(form, 'isValid', function(){ return true; });
    let cancelButton = React.findDOMNode(form.refs.cancelButton);
    this.stub($, 'ajax', function(xhr) {
      xhr.success(xhr.data);
    });
    Simulate.click(form.refs.createButton);
    equal(cancelButton.getAttribute('aria-disabled'), 'false');
    notOk(_.contains(cancelButton.classList, 'disabled'));
  });

  test('re-enables the create button when the ajax call succeeds', function() {
    let form = this.renderComponent();
    let createButton = React.findDOMNode(form.refs.createButton);
    this.stub($, 'ajax', function(xhr) {
      xhr.success(xhr.data);
    });
    Simulate.click(createButton);
    equal(createButton.getAttribute('aria-disabled'), 'false');
    notOk(_.contains(createButton.classList, 'disabled'));
  });

  test('re-enables the cancel button when the ajax call fails', function() {
    let form = this.renderComponent();
    let cancelButton = React.findDOMNode(form.refs.cancelButton);
    this.stub($, 'ajax', function(xhr) {
      xhr.error();
    });
    Simulate.click(form.refs.createButton);
    equal(cancelButton.getAttribute('aria-disabled'), 'false');
    notOk(_.contains(cancelButton.classList, 'disabled'));
  });

  test('re-enables the create button when the ajax call fails', function() {
    let form = this.renderComponent();
    let createButton = React.findDOMNode(form.refs.createButton);
    this.stub($, 'ajax', function(xhr) {
      xhr.error();
    });
    Simulate.click(createButton);
    equal(createButton.getAttribute('aria-disabled'), 'false');
    notOk(_.contains(createButton.classList, 'disabled'));
  });
});
