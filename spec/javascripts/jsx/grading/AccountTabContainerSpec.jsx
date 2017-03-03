define([
  'react',
  'enzyme',
  'jquery',
  'axios',
  'underscore',
  'jsx/grading/AccountTabContainer',
  'jqueryui/tabs',
], (React, { mount }, $, axios, _, AccountTabContainer) => {
  QUnit.module('AccountTabContainer', {
    renderComponent (props = {}) {
      const defaults = {
        readOnly: false,
        urls: {
          gradingPeriodSetsURL: 'api/v1/accounts/1/grading_period_sets',
          gradingPeriodsUpdateURL:
            'api/v1/grading_period_sets/%7B%7B%20set_id%20%7D%7D/grading_periods/batch_update',
          enrollmentTermsURL: 'api/v1/accounts/1/enrollment_terms',
          deleteGradingPeriodURL: 'api/v1/accounts/1/grading_periods/%7B%7B%20id%20%7D%7D'
        },
      };
      const mergedProps = _.defaults(props, defaults);

      this.wrapper = mount(
        React.createElement(AccountTabContainer, mergedProps)
      );
    },

    setup () {
      const response = {};
      const successPromise = new Promise(resolve => resolve(response));
      this.stub(axios, 'get').returns(successPromise);
      this.stub($, 'ajax').returns({ done () {} });
    },

    teardown () {
      this.wrapper.unmount();
    }
  });

  test('tabs are present', function () {
    this.renderComponent();
    equal(this.wrapper.find('.ui-tabs').length, 1);
    equal(this.wrapper.find('.ui-tabs ul.ui-tabs-nav li').length, 2);
    equal(this.wrapper.find('#grading-periods-tab').getDOMNode().getAttribute('style'), 'display: block;');
    equal(this.wrapper.find('#grading-standards-tab').getDOMNode().getAttribute('style'), 'display: none;')
  });

  test('jquery-ui tabs() is called', function () {
    const tabsSpy = this.spy($.fn, 'tabs');
    this.renderComponent();
    ok(tabsSpy.calledOnce);
  });

  test('renders the grading periods', function () {
    this.renderComponent();
    ok(this.wrapper.node.gradingPeriods);
  });

  test('renders the grading standards', function () {
    this.renderComponent();
    ok(this.wrapper.node.gradingStandards);
  });
});
