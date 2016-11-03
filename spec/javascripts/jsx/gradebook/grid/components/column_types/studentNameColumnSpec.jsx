define([
  'react',
  'react-dom',
  'jsx/gradebook/grid/components/column_types/studentNameColumn'
], (React, ReactDOM, StudentNameColumn) => {
  const TestUtils = React.addons.TestUtils;
  const wrapper = document.getElementById('fixtures');

  const buildComponent = (props = {}) => {
    const defaultProps = {
      toolbarOptions: {
        hideStudentNames: false
      },
      rowData: {
        student: {
          grades: {
            html_url: "/foo"
          }
        },
        studentName: "An Student"
      }
    };
    const deep = true;
    $.extend(deep, props, defaultProps);
    const componentFactory = React.createFactory(StudentNameColumn);
    return ReactDOM.render(componentFactory(props), wrapper);
  };

  test('mounts', () => {
    ok(buildComponent().isMounted());
  });

  module("renderEnrollmentStatus");

  test("renders no label for non-inactive and non-concluded students", () => {
    const refs = ReactDOM.findDOMNode(buildComponent()).refs;
    notOk(refs)
  });

  test("it renders an inactive label for inactive students", () => {
    const props = { rowData: { isInactive: true } };

    let component = buildComponent(props);
    let span = ReactDOM.findDOMNode(component.refs.enrollmentStatus);

    equal(span.classList, 'label');
    equal(span.title, 'This user is currently not able to access the course');
    equal(span.textContent, 'inactive');
  });

  test("it renders an inactive label for concluded students", () => {
    const props = { rowData: { isConcluded: true } };

    let component = buildComponent(props);
    let span = ReactDOM.findDOMNode(component.refs.enrollmentStatus);

    equal(span.classList, 'label');
    equal(span.title, 'This user is currently not able to access the course');
    equal(span.textContent, 'concluded');
  });

  test("renders the url for the students grades", () => {
    let component = buildComponent();
    let link = ReactDOM.findDOMNode(component.refs.gradesUrl);

    equal(link.getAttribute('href'), '/foo');
  });


});
