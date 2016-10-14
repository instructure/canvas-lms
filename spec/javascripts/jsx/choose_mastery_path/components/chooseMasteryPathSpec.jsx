define([
  'react',
  'jsx/choose_mastery_path/components/choose-mastery-path',
], (React, ChooseMasterPath) => {
  const TestUtils = React.addons.TestUtils

  module('Choose Mastery Path')

  const defaultProps = () => ({
    options: [
      {
        setId: 1,
        assignments: [
          {
            name: 'Ch 2 Quiz',
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
            name: 'Ch 2 Review',
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
      },
      {
        setId: 2,
        assignments: [
          {
            name: 'Ch 2 Quiz',
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
            name: 'Ch 2 Review',
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
      },
    ],
    selectedOption: null,
    selectOption: () => {},
  })

  const renderComponent = (props) => {
    return TestUtils.renderIntoDocument(
      <ChooseMasterPath {...props} />
    )
  }

  test('renders component', () => {
    const props = defaultProps()
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'cmp-wrapper')
    equal(renderedList.length, 1, 'renders component')
  })

  test('renders all options', () => {
    const props = defaultProps()
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'cmp-option')
    equal(renderedList.length, 2, 'renders assignments')
  })
})
