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

  test('tabs are present when there are grading periods', function () {
    this.renderComponent({ hasGradingPeriods: true });
    equal(this.wrapper.find('.ui-tabs').length, 1);
    equal(this.wrapper.find('.ui-tabs ul.ui-tabs-nav li').length, 2);
    equal(this.wrapper.find('#grading-periods-tab').getDOMNode().getAttribute('style'), 'display: block;');
    equal(this.wrapper.find('#grading-standards-tab').getDOMNode().getAttribute('style'), 'display: none;')
  });

  test('tabs are not present when there are no grading periods', function () {
    this.renderComponent({ hasGradingPeriods: false });
    equal(this.wrapper.find('.ui-tabs').length, 0);
  });

  test('jquery-ui tabs() is called when there are grading periods', function () {
    const tabsSpy = this.spy($.fn, 'tabs');
    this.renderComponent({ hasGradingPeriods: true });
    ok(tabsSpy.calledOnce);
  });

  test('jquery-ui tabs() is not called when there are no grading periods', function () {
    const tabsSpy = this.spy($.fn, 'tabs');
    this.renderComponent({ hasGradingPeriods: false});
    notOk(tabsSpy.called);
  });

  test('does not render grading periods if there are no grading periods', function () {
    this.renderComponent({ hasGradingPeriods: false });
    notOk(this.wrapper.node.gradingPeriods);
  });

  test('renders the grading periods if there are grading periods', function () {
    this.renderComponent({ hasGradingPeriods: true });
    ok(this.wrapper.node.gradingPeriods);
  });

  test('renders the grading standards if there are no grading periods', function () {
    this.renderComponent({ hasGradingPeriods: false });
    ok(this.wrapper.node.gradingStandards);
  });

  test('renders the grading standards if there are grading periods', function () {
    this.renderComponent({ hasGradingPeriods: true });
    ok(this.wrapper.node.gradingStandards);
  });
});
