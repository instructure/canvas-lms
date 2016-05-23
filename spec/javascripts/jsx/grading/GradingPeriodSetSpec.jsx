define([
  'react',
  'underscore',
  'jsx/grading/GradingPeriodSet'
], (React, _, GradingPeriodSet) => {
  const wrapper = document.getElementById('fixtures');
  const Simulate = React.addons.TestUtils.Simulate;

  module("GradingPeriodSet", {
    renderComponent() {
      const props = {
        set: {
          id: "1",
          title: "Dora the Explorer Grading Period Set",
        },
        gradingPeriods: [
          {
            id: "1",
            title: "We did it! We did it! We did it! #dora #boots",
            startDate: new Date("2015-01-01T20:11:00+00:00"),
            endDate: new Date("2015-03-01T00:00:00+00:00")
          },
          {
            id: "3",
            title: "Como estas?",
            startDate: new Date("2014-11-01T20:11:00+00:00"),
            endDate: new Date("2014-11-11T00:00:00+00:00")
          },
          {
            id: "2",
            title: "Swiper no swiping!",
            startDate: new Date("2015-04-01T20:11:00+00:00"),
            endDate: new Date("2015-05-01T00:00:00+00:00")
          }
        ]
      };

      const element = React.createElement(GradingPeriodSet, props);
      return React.render(element, wrapper);
    },

    teardown() {
      React.unmountComponentAtNode(wrapper);
    }
  });

  test("initially renders as 'expanded', showing the set body", function() {
    let set = this.renderComponent();
    ok(set.refs.setBody);
  });

  test("collapses the set body when the toggle is clicked", function() {
    let set = this.renderComponent();
    Simulate.click(set.refs.toggleSetBody);
    notOk(set.refs.setBody);
  });

  test("re-expands the set body when the toggle is clicked twice", function() {
    let set = this.renderComponent();
    Simulate.click(set.refs.toggleSetBody);
    Simulate.click(set.refs.toggleSetBody);
    ok(set.refs.setBody);
  });

  test("sorts grading periods by start date, ascending", function() {
    let set = this.renderComponent();
    const periods = set.refs.gradingPeriodList.props.children;
    const startDates = _.map(periods, period => period.props.period.startDate);
    ok((startDates[0] < startDates[1]) && (startDates[1] < startDates[2]));
  });
});
