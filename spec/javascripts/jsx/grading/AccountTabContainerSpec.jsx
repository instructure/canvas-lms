define([
  'react',
  'react-dom',
  'jquery',
  'axios',
  'underscore',
  'jsx/grading/AccountTabContainer',
  'jqueryui/tabs'
], (React, ReactDOM, $, axios, _, AccountTabContainer) => {
  const wrapper = document.getElementById('fixtures');

  module("AccountTabContainer", {
    renderComponent: function(props={}) {
      const defaults = {
        readOnly: false,
        urls: {
          gradingPeriodSetsURL:    "api/v1/accounts/1/grading_period_sets",
          gradingPeriodsUpdateURL: "api/v1/grading_period_sets/%7B%7B%20set_id%20%7D%7D/grading_periods/batch_update",
          enrollmentTermsURL:      "api/v1/accounts/1/enrollment_terms",
          deleteGradingPeriodURL:  "api/v1/accounts/1/grading_periods/%7B%7B%20id%20%7D%7D"
        },
      };

      const element = React.createElement(AccountTabContainer, _.defaults(props, defaults));
      return ReactDOM.render(element, wrapper);
    },
    setup() {
      const response = {};
      const successPromise = new Promise(resolve => resolve(response));
      this.stub(axios, 'get').returns(successPromise);
      this.stub($, 'ajax', function(){ return {done: function(){}};});
    },

    teardown: function() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test('does not render grading periods if Multiple Grading Periods is disabled', function() {
    let component = this.renderComponent({ multipleGradingPeriodsEnabled: false });
    notOk(component.refs.gradingPeriods);
  });

  test('renders the grading periods if Multiple Grading Periods is enabled', function() {
    let component = this.renderComponent({ multipleGradingPeriodsEnabled: true });
    ok(component.refs.gradingPeriods);
  });

  test('renders the grading standards if Multiple Grading Periods is disabled', function() {
    let component = this.renderComponent({ multipleGradingPeriodsEnabled: false });
    ok(component.refs.gradingStandards);
  });

  test('renders the grading standards if Multiple Grading Periods is enabled', function() {
    let component = this.renderComponent({ multipleGradingPeriodsEnabled: true });
    ok(component.refs.gradingStandards);
  });
});
