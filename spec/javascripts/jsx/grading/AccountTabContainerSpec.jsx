define([
  'react',
  'underscore',
  'jsx/grading/AccountTabContainer',
  'jqueryui/tabs'
], (React, _, AccountTabContainer) => {
  const wrapper = document.getElementById('fixtures');

  module("AccountTabContainer", {
    renderComponent: function(props={}) {
      const defaults = {
        readOnly: false,
        URLs: {
          gradingPeriodSetsURL:    "api/v1/accounts/1/grading_period_sets",
          gradingPeriodsUpdateURL: "api/v1/grading_period_sets/{{ set_id }}/grading_periods/batch_update",
          enrollmentTermsURL:      "api/v1/accounts/1/enrollment_terms"
        }
      };

      const element = React.createElement(AccountTabContainer, _.defaults(props, defaults));
      return React.render(element, wrapper);
    },

    teardown: function() {
      React.unmountComponentAtNode(wrapper);
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
