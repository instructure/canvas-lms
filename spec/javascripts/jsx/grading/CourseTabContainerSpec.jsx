define([
  'react',
  'enzyme',
  'jquery',
  'underscore',
  'jsx/grading/CourseTabContainer',
  'jqueryui/tabs',
], (React, { mount }, $, _, CourseTabContainer) => {
  QUnit.module('CourseTabContainer', {
    renderComponent (props = {}) {
      const defaults = {};
      const mergedProps = _.defaults(props, defaults);

      this.wrapper = mount(
        React.createElement(CourseTabContainer, mergedProps)
      );
    },

    setup () {
      this.stub($, 'getJSON').returns({success: () => ({ error: () => {} }), done: () => {}});
    },

    teardown () {
      this.wrapper.unmount();
    }
  });

  test('tabs are present when multiple grading periods is enabled', function () {
    this.renderComponent({ multipleGradingPeriodsEnabled: true });
    equal(this.wrapper.find('.ui-tabs').length, 1);
    equal(this.wrapper.find('.ui-tabs ul.ui-tabs-nav li').length, 2);
    equal(this.wrapper.find('#grading-periods-tab').getDOMNode().getAttribute('style'), 'display: block;');
    equal(this.wrapper.find('#grading-standards-tab').getDOMNode().getAttribute('style'), 'display: none;')
  });

  test('tabs are not present when multiple grading periods is disabled', function () {
    this.renderComponent({ multipleGradingPeriodsEnabled: false });
    equal(this.wrapper.find('.ui-tabs').length, 0);
  });

  test('jquery-ui tabs() is called when grading periods is enabled', function () {
    const tabsSpy = this.spy($.fn, 'tabs');
    this.renderComponent({ multipleGradingPeriodsEnabled: true });
    ok(tabsSpy.calledOnce);
  });

  test('jquery-ui tabs() is not called when grading periods is disabled', function () {
    const tabsSpy = this.spy($.fn, 'tabs');
    this.renderComponent({ multipleGradingPeriodsEnabled: false});
    notOk(tabsSpy.called);
  });

  test('does not render grading periods if Multiple Grading Periods is disabled', function () {
    this.renderComponent({ multipleGradingPeriodsEnabled: false });
    notOk(this.wrapper.node.gradingPeriods);
  });

  test('renders the grading periods if Multiple Grading Periods is enabled', function () {
    this.renderComponent({ multipleGradingPeriodsEnabled: true });
    ok(this.wrapper.node.gradingPeriods);
  });

  test('renders the grading standards if Multiple Grading Periods is disabled', function () {
    this.renderComponent({ multipleGradingPeriodsEnabled: false });
    ok(this.wrapper.node.gradingStandards);
  });

  test('renders the grading standards if Multiple Grading Periods is enabled', function () {
    this.renderComponent({ multipleGradingPeriodsEnabled: true });
    ok(this.wrapper.node.gradingStandards);
  });
});
