define([
  'react',
  'underscore',
  'jsx/grading/AccountGradingPeriod'
], (React, _, GradingPeriod) => {
  const wrapper = document.getElementById('fixtures');
  const Simulate = React.addons.TestUtils.Simulate;

  const allPermissions = { read: true, create: true, update: true, delete: true };
  const noPermissions = { read: false, create: false, update: false, delete: false };

  const props = {
    period: {
      id: "1",
      title: "We did it! We did it! We did it! #dora #boots",
      startDate: new Date("2015-01-01T20:11:00+00:00"),
      endDate: new Date("2015-03-01T00:00:00+00:00")
    },
    onEdit: () => {},
    permissions: allPermissions
  };

  module("AccountGradingPeriod", {
    renderComponent(attr = {}) {
      let attrs = _.extend({}, props, attr);
      const element = React.createElement(GradingPeriod, attrs);
      return React.render(element, wrapper);
    },

    teardown() {
      React.unmountComponentAtNode(wrapper);
    }
  });

  test("shows the 'edit grading period' button when 'create' is permitted", function() {
    let period = this.renderComponent();
    ok(period.refs.editButton);
  });

  test("does not show the 'edit grading period' button when 'create' is not permitted", function() {
    let period = this.renderComponent({ permissions: noPermissions });
    notOk(!!period.refs.editButton);
  });

  test("does not show the 'edit grading period' button when 'read only'", function() {
    let period = this.renderComponent({ permissions: allPermissions, readOnly: true });
    notOk(!!period.refs.editButton);
  });

  test("disables the 'edit grading period' button when 'actionsDisabled' is true", function() {
    let period = this.renderComponent({actionsDisabled: true});
    ok(period.refs.editButton.props.disabled);
  });

  test("disables the 'delete grading period' button when 'actionsDisabled' is true", function() {
    let period = this.renderComponent({actionsDisabled: true});
    ok(period.refs.deleteButton.props.disabled);
  });

  test("displays the start date in a friendly format", function() {
    let period = this.renderComponent();
    const startDate = React.findDOMNode(period.refs.startDate).textContent;
    equal(startDate, "Start Date: Jan 1, 2015 at 8:11pm");
  });

  test("displays the end date in a friendly format", function() {
    let period = this.renderComponent();
    const endDate = React.findDOMNode(period.refs.endDate).textContent;
    equal(endDate, "End Date: Mar 1, 2015 at 12am");
  });

  test("calls the 'onEdit' callback when the edit button is clicked", function() {
    let spy = sinon.spy();
    let period = this.renderComponent({onEdit: spy});
    let editButton = React.findDOMNode(period.refs.editButton);
    Simulate.click(editButton);
    ok(spy.calledOnce);
  });
});
