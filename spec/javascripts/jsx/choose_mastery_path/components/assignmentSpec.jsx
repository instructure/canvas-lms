define([
  'react',
  'jsx/choose_mastery_path/components/assignment',
], (React, Assignment) => {
  const TestUtils = React.addons.TestUtils

  module('Assignment')

  const defaultProps = () => ({
    isSelected: false,
    assignment: {
      title: 'Ch 2 Quiz',
      type: 'quiz',
      points: 10,
      due_at: new Date(),
      itemId: 1,
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

  test('renders link title when selected', () => {
    const props = defaultProps()
    props.isSelected = true
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'cmp-assignment__title-link')
    equal(renderedList.length, 1, 'renders link title')
  })
})
