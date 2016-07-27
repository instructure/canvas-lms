define([
  'react',
  'underscore',
  'jsx/grading/EnrollmentTermsDropdown'
], (React, _, Dropdown) => {
  const wrapper = document.getElementById('fixtures');
  const Simulate = React.addons.TestUtils.Simulate;

  module('EnrollmentTermsDropdown', {
    renderComponent() {
      const props = {
        terms: this.terms(),
        changeSelectedEnrollmentTerm: this.spy()
      };
      const element = React.createElement(Dropdown, props);
      return React.render(element, wrapper);
    },

    terms() {
      return [
        {
          id: "18",
          name: "Fall 2013 - Art",
          startAt: new Date("2013-08-03T02:57:42.000Z"),
          endAt: new Date("2013-11-03T02:57:53.000Z"),
          createdAt: new Date("2013-07-27T16:51:41.000Z"),
          gradingPeriodGroupId: "3",
          displayName: "Fall 2013 - Art"
        },
        {
          id: "21",
          name: "Winter 2013 - Art",
          startAt: new Date("2013-12-03T02:57:42.000Z"),
          endAt: new Date("2014-01-21T02:57:53.000Z"),
          createdAt: new Date("2013-08-27T16:51:41.000Z"),
          gradingPeriodGroupId: "3",
          displayName: "Winter 2013 - Art"
        },
        {
          id: "2",
          name: null,
          startAt: null,
          endAt: new Date("2013-10-21T02:57:53.000Z"),
          createdAt: new Date("2013-08-22T16:51:41.000Z"),
          gradingPeriodGroupId: "2",
          displayName: "Term starting Sep 3, 2013"
        },
        {
          id: "7",
          name: null,
          startAt: null,
          endAt: null,
          createdAt: new Date("2013-08-23T16:51:41.000Z"),
          gradingPeriodGroupId: "2",
          displayName: "Term created Aug 23, 2013"
        }
      ];
    },

    teardown() {
      React.unmountComponentAtNode(wrapper);
    }
  });

  test('includes an option for each term plus an option for "all terms"', function () {
    let dropdown = this.renderComponent();
    const expectedOptionsCount = this.terms().length + 1;
    let node = React.findDOMNode(dropdown.refs.termsDropdown);
    equal(node.length, expectedOptionsCount);
  });

  test('starts by showing all enrollment terms', function () {
    let dropdown = this.renderComponent();
    let node = React.findDOMNode(dropdown.refs.termsDropdown);
    const ALL_TERMS_ID = "0";
    equal(node.value, ALL_TERMS_ID);
  });

  test("calls changeSelectedEnrollmentTerm when a selection is made", function() {
    let dropdown = this.renderComponent();
    let node = React.findDOMNode(dropdown.refs.termsDropdown);
    node.value = "3";
    Simulate.change(node);
    ok(dropdown.props.changeSelectedEnrollmentTerm.calledOnce);
  });

  test("displays the terms in descending order by start date then created date if start date doesn't exist", function() {
    let dropdown = this.renderComponent();
    let node = React.findDOMNode(dropdown.refs.termsDropdown);
    let optionIDs = _.pluck(node.getElementsByTagName("OPTION"), "value");
    propEqual(optionIDs, ["0", "21", "18", "7", "2"]);
  });
});
