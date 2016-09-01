define([
  'react',
  'jsx/conditional_release_stats/components/student-range',
], (React, StudentRange) => {
  const TestUtils = React.addons.TestUtils

  module('Student Range')

  const defaultProps = () => ({
    range: {
      scoring_range: {
        id: 1,
        rule_id: 1,
        lower_bound: 0.7,
        upper_bound: 1.0,
        created_at: null,
        updated_at: null,
        position: null,
      },
      size: 0,
      students: [
        {
          user: { name: 'Foo Bar' },
        },
        {
          user: { name: 'Bar Foo' },
        },
      ],
    },
    onStudentSelect: () => {},
  })

  const renderComponent = (props) => {
    return TestUtils.renderIntoDocument(
      <StudentRange {...props} />
    )
  }

  test('renders items correctly', () => {
    const props = defaultProps()
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student-range__item')
    equal(renderedList.length, props.range.students.length, 'renders full component')
  })
})
