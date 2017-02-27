define([
  'react',
  'react-addons-test-utils',
  'jsx/choose_mastery_path/components/path-option',
], (React, TestUtils, PathOption) => {

  QUnit.module('Path Option')

  const defaultProps = () => ({
    assignments: [
      {
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
      {
        title: 'Ch 2 Review',
        type: 'assignment',
        points: 10,
        due_at: new Date(),
        itemId: 1,
        category: {
          id: 'other',
          label: 'Other',
        },
      },
    ],
    setId: 1,
    optionIndex: 0,
    selectedOption: null,
    selectOption: () => {},
  })

  const renderComponent = (props) => {
    return TestUtils.renderIntoDocument(
      <PathOption {...props} />
    )
  }

  test('renders component', () => {
    const props = defaultProps()
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'cmp-option')
    equal(renderedList.length, 1, 'renders component')
  })

  test('renders all assignments', () => {
    const props = defaultProps()
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'cmp-assignment')
    equal(renderedList.length, 2, 'renders assignments')
  })

  test('renders selected when selected', () => {
    const props = defaultProps()
    props.selectedOption = 1
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'cmp-option__selected')
    equal(renderedList.length, 1, 'renders selected')
  })

  test('renders disabled when another path is selected', () => {
    const props = defaultProps()
    props.selectedOption = 2
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'cmp-option__disabled')
    equal(renderedList.length, 1, 'renders disabled')
  })
})
