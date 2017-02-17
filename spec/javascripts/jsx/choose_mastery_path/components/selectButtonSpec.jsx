define([
  'react',
  'react-addons-test-utils',
  'jsx/choose_mastery_path/components/select-button',
], (React, TestUtils, SelectButton) => {

  QUnit.module('Select Button')

  const defaultProps = () => ({
    isSelected: false,
    isDisabled: false,
    onSelect: () => {},
  })

  const renderComponent = (props) => {
    return TestUtils.renderIntoDocument(
      <SelectButton {...props} />
    )
  }

  test('renders component', () => {
    const props = defaultProps()
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'cmp-button')
    equal(renderedList.length, 1, 'renders component')
  })

  test('renders button when not selected or disabled', () => {
    const props = defaultProps()
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'btn-primary')
    equal(renderedList.length, 1, 'renders as button')
  })

  test('renders selected badge when selected', () => {
    const props = defaultProps()
    props.isSelected = true
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'cmp-button__selected')
    equal(renderedList.length, 1, 'renders selected')
  })

  test('renders disabled badge when disabled', () => {
    const props = defaultProps()
    props.isDisabled = true
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'cmp-button__disabled')
    equal(renderedList.length, 1, 'renders disabled')
  })
})
