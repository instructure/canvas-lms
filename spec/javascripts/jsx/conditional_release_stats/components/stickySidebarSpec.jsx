define([
  'react',
  'react-dom',
  'jsx/conditional_release_stats/components/sticky-sidebar',
], (React, ReactDOM, Sidebar) => {
  const TestUtils = React.addons.TestUtils

  module('Sticky Sidebar')

  const renderComponent = (props) => {
    return TestUtils.renderIntoDocument(
      <Sidebar {...props} />
    )
  }

  const renderInDOM = (props) => {
    return ReactDOM.render(
      <Sidebar {...props} />
    , document.getElementById('fixtures'))
  }

  const defaultProps = () => {
    return {
      isHidden: false,
      closeSidebar: () => {},
    }
  }

  test('renders sidebarbar component correctly', () => {
    const component = renderComponent(defaultProps())

    const rendered = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-sticky-sidebar')
    equal(rendered.length, 1, 'renders full component')
  })

  test('renders sidebarbar hidden correctly', () => {
    const props = defaultProps()
    props.isHidden = true
    const component = renderComponent(props)

    const rendered = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-sticky-sidebar__hidden')
    equal(rendered.length, 1, 'renders component hidden')
  })

  test('changes focus to close button when sidebar is shown', () => {
    const props = defaultProps()
    props.isHidden = true
    renderInDOM(props)

    props.isHidden = false
    renderInDOM(props)

    const focusElement = document.activeElement
    const isCloseBtn = focusElement.classList.contains('crs-sticky-sidebar__close')

    equal(isCloseBtn, true, 'focuses close button')
  })
})
