define([
  'react',
  'react-addons-test-utils',
  'jsx/calendar/scheduler/components/appointment_groups/ContextSelector',
], (React, TestUtils, ContextSelector) => {

    let props

    module('ContextSelector', {
      setup () {
        props = {
          contexts: [],
          appointmentGroup: {},
        };
      },
      teardown () {
        props = null
      }
    })

  test('renders the ContextSelector component', () => {
    const component = TestUtils.renderIntoDocument(<ContextSelector  {...props}/>)
    const contextSelector = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector')
    ok(contextSelector)
  })

  test('renders the ContextSelector dropdown', () => {
    const component = TestUtils.renderIntoDocument(<ContextSelector  {...props}/>)
    const contextSelector = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector')
    TestUtils.Simulate.click(contextSelector.childNodes[0])
    const contextSelectorDropdown = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector__Dropdown')
    ok(contextSelectorDropdown)
  })
  test('renders a course in the ContextSelector dropdown', () => {
    props.contexts = [
      {id: '1', name: 'testcourse', asset_string: 'course_1', sections: [
        {id: '1', asset_string: 'course_section_1'}
      ]}
    ]
    props.appointmentGroup = {context_codes: ['course_1', 'course_section_1']}
    const component = TestUtils.renderIntoDocument(<ContextSelector  {...props}/>)
    const contextSelector = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector')
    TestUtils.Simulate.click(contextSelector.childNodes[0])
    const contextDropdown = TestUtils.findRenderedDOMComponentWithClass(component, 'CourseListItem')
    ok(contextDropdown)
  })

  test('renders a course section in the ContextSelector dropdown', () => {
    props.contexts = [
      {id: '1', name: 'testcourse', asset_string: 'course_1', sections: [
        {id: '1', asset_string: 'course_section_1'}
      ]}
    ]
    props.contexts = [
      {id: '1', name: 'testcourse', asset_string: 'course_1', sections: [
        {id: '1', asset_string: 'course_section_1'}
      ]}
    ]
    props.appointmentGroup = {context_codes: ['course_1', 'course_section_1']}
    const component = TestUtils.renderIntoDocument(<ContextSelector  {...props}/>)
    const contextSelector = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector')
    TestUtils.Simulate.click(contextSelector.childNodes[0])
    const sectionDropdown = TestUtils.findRenderedDOMComponentWithClass(component, 'sectionItem')
    ok(sectionDropdown)
  })

  test('checkbox state when contexts are in an appointmentgroup', () => {
    props.contexts = [
      {id: '1', name: 'testcourse', asset_string: 'course_1', sections: [
        {id: '1', asset_string: 'course_section_1'}
      ]}
    ]
    props.contexts = [
      {id: '1', name: 'testcourse', asset_string: 'course_1', sections: [
        {id: '1', asset_string: 'course_section_1'}
      ]}
    ]
    props.appointmentGroup = {context_codes: ['course_1'], sub_context_codes: ['course_section_1']}
    const component = TestUtils.renderIntoDocument(<ContextSelector  {...props}/>)
    component.componentWillReceiveProps(props)
    const contextSelector = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector')
    TestUtils.Simulate.click(contextSelector.childNodes[0])
    const sectionDropdown = TestUtils.findRenderedDOMComponentWithClass(component, 'sectionItem')
    const contextDropdown = TestUtils.findRenderedDOMComponentWithClass(component, 'CourseListItem')
    ok(sectionDropdown.childNodes[0].checked)
    ok(contextDropdown.childNodes[1].checked)
  })

  test('renders button text correctly on already selected contexts', () => {
    props.contexts = [
      {id: '1', name: 'testcourse', asset_string: 'course_1', sections: [
        {id: '1', asset_string: 'course_section_1'}
      ]}
    ]
    props.contexts = [
      {id: '1', name: 'testcourse', asset_string: 'course_1', sections: [
        {id: '1', asset_string: 'course_section_1'}
      ]}
    ]
    props.appointmentGroup = {context_codes: ['course_1', 'course_section_1']}
    const component = TestUtils.renderIntoDocument(<ContextSelector  {...props}/>)
    const contextSelector = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector')
    ok(contextSelector.childNodes[0].textContent === "Select Calendars")
    component.componentWillReceiveProps(props)
    ok(contextSelector.childNodes[0].textContent === "testcourse and 1 other")
  })
})
