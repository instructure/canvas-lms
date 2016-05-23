define([
  'react',
  'jsx/grading/AccountGradingPeriod'
], (React, GradingPeriod) => {
  const wrapper = document.getElementById('fixtures');

  module("AccountGradingPeriod", {
    renderComponent() {
      const props = {
        period: {
          id: "1",
          title: "We did it! We did it! We did it! #dora #boots",
          startDate: new Date("2015-01-01T20:11:00+00:00"),
          endDate: new Date("2015-03-01T00:00:00+00:00")
        }
      };

      const element = React.createElement(GradingPeriod, props);
      return React.render(element, wrapper);
    },

    teardown() {
      React.unmountComponentAtNode(wrapper);
    }
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
});
