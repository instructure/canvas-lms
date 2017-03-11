define([
  'react',
  'react-addons-test-utils',
  'jsx/choose_mastery_path/components/assignment',
], (React, TestUtils, Assignment) => {

  QUnit.module('Assignment')

  const defaultProps = () => ({
    isSelected: false,
    assignment: {
      name: 'Ch 2 Quiz',
      type: 'quiz',
      points_possible: 10,
      due_at: new Date(),
      itemId: 1,
      description: 'a quiz',
      category: {
        id: 'other',
        label: 'Other',
      },
    },
  })

  const renderComponent = (props) => {
    return TestUtils.renderIntoDocument(
      <Assignment {...props} />
    )
  }

  test('renders component', () => {
    const props = defaultProps()
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'cmp-assignment')
    equal(renderedList.length, 1, 'renders component')
  })

  test('renders title', () => {
    const props = defaultProps()
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'item_name')
    equal(renderedList[0].textContent, 'Ch 2 Quiz', 'renders title')
  })

  test('renders points', () => {
    const pointyProps = defaultProps()
    const component = renderComponent(pointyProps)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'points_possible_display')
    equal(renderedList[0].textContent, '10 pts', 'renders points')
  })

  test('omits points', () => {
    const pointlessProps = defaultProps()
    pointlessProps.assignment.points_possible = null
    const component = renderComponent(pointlessProps)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'points_possible_display')
    equal(renderedList.length, 0, 'omits points')
  })

  test('renders link title when selected', () => {
    const props = defaultProps()
    props.isSelected = true
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'cmp-assignment__title-link')
    equal(renderedList.length, 1, 'renders link title')
  })

  test('renders description', () => {
    const props = defaultProps()
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'ig-description')
    equal(renderedList.length, 1, 'renders link description')
  })
})
