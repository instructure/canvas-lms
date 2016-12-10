define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'underscore',
  'jsx/grading/EnrollmentTermInput'
], (React, ReactDOM, {findRenderedDOMComponentWithClass}, _, Input) => {
  const wrapper = document.getElementById('fixtures');

  module('EnrollmentTermInput', {
    renderComponent(props={}) {
      const defaultProps = {
        enrollmentTerms: [
          {
            id: "1",
            name: "Fall 2009 - Art",
            startAt: new Date("2009-06-03T02:57:42.000Z"),
            endAt: new Date("2009-12-03T02:57:53.000Z"),
            createdAt: new Date("2009-05-27T16:51:41.000Z"),
            workflowState: "active",
            gradingPeriodGroupId: "65",
            sisTermId: null,
            displayName: "Fall 2009 - Art"
          },
          {
            id: "2",
            name: null,
            startAt: null,
            endAt: new Date("2013-12-03T02:57:53.000Z"),
            createdAt: new Date("2015-10-27T16:51:41.000Z"),
            workflowState: "active",
            gradingPeriodGroupId: "62",
            sisTermId: null,
            displayName: "Term created Oct 27, 2015"
          },
          {
            id: "5",
            name: null,
            startAt: new Date("2012-06-06T20:09:32.000Z"),
            endAt: null,
            createdAt: new Date("2012-06-03T20:09:32.000Z"),
            workflowState: "active",
            gradingPeriodGroupId: "64",
            sisTermId: null,
            displayName: "Term starting Jun 6, 2016"
          }
        ],
        selectedIDs: ["2"],
        setSelectedEnrollmentTermIDs: function(){},
      };

      const element = React.createElement(Input, _.defaults(props, defaultProps));
      return ReactDOM.render(element, wrapper);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test("displays 'No unassigned terms' if there are no selectable terms", function() {
    let enrollmentTermInput = this.renderComponent({ enrollmentTerms: [], selectedIDs: [] });
    const header = findRenderedDOMComponentWithClass(enrollmentTermInput, "ic-tokeninput-header");
    const title = ReactDOM.findDOMNode(header).textContent
    equal(title, "No unassigned terms");
  });

  test("selectedEnrollmentTerms uses the enrollment term display name", function() {
    let enrollmentTermInput = this.renderComponent();
    const termNames = _.pluck(enrollmentTermInput.selectedEnrollmentTerms(), "name");
    propEqual(termNames, ["Term created Oct 27, 2015"]);
  });

  test("selectableOptions uses the enrollment term display name", function() {
    let enrollmentTermInput = this.renderComponent();
    const options = enrollmentTermInput.selectableOptions("active");
    const termNames = _.map(options, option => option.props.children);
    propEqual(termNames, ["Term starting Jun 6, 2016"]);
  });
});
