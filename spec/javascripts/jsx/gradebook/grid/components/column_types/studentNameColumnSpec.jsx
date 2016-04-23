define([
  'react',
  'jsx/gradebook/grid/components/column_types/studentNameColumn'
], (React, StudentNameColumn) => {
  const TestUtils = React.addons.TestUtils;
  const wrapper = document.getElementById('fixtures');

  const buildComponent = (props = {}) => {
    const defaultProps = {
      toolbarOptions: {
        hideStudentNames: false
      },
      rowData: {
        student: {
          html_url: "/foo"
        },
        studentName: "An Student"
      }
    };
    const deep = true;
    $.extend(deep, props, defaultProps);
    const componentFactory = React.createFactory(StudentNameColumn);
    return React.render(componentFactory(props), wrapper);
  };

  test('mounts', () => {
    ok(buildComponent().isMounted());
  });

  module("renderEnrollmentStatus");

  test("renders no label for non-inactive and non-concluded students", () => {
    const refs = React.findDOMNode(buildComponent()).refs;
    notOk(refs)
  });

  test("it renders an inactive label for inactive students", () => {
    const props = { rowData: { isInactive: true } };

    let component = buildComponent(props);
    let span = React.findDOMNode(component.refs.enrollmentStatus);

    equal(span.classList, 'label');
    equal(span.title, 'This user is currently not able to access the course');
    equal(span.textContent, 'inactive');
  });

  test("it renders an inactive label for concluded students", () => {
    const props = { rowData: { isConcluded: true } };

    let component = buildComponent(props);
    let span = React.findDOMNode(component.refs.enrollmentStatus);

    equal(span.classList, 'label');
    equal(span.title, 'This user is currently not able to access the course');
    equal(span.textContent, 'concluded');
  });
});
