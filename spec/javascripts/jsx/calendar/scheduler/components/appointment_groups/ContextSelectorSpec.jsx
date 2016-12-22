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
    const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
    const contextSelector = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector')
    ok(contextSelector)
  })

  test('renders the ContextSelector dropdown', () => {
    const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
    const contextSelector = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector')
    TestUtils.Simulate.click(contextSelector.childNodes[0])
    const contextSelectorDropdown = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector__Dropdown')
    ok(contextSelectorDropdown)
  })
  test('renders a course in the ContextSelector dropdown', () => {
    props.contexts = [
      { id: '1',
        name: 'testcourse',
        asset_string: 'course_1',
        sections: [
          {
            id: '1',
            asset_string: 'course_section_1'
          }
        ]
      }
    ]
    props.appointmentGroup = { context_codes: ['course_1', 'course_section_1'] }
    const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
    const contextSelector = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector')
    TestUtils.Simulate.click(contextSelector.childNodes[0])
    const contextDropdown = TestUtils.findRenderedDOMComponentWithClass(component, 'CourseListItem')
    ok(contextDropdown)
  })

  test('renders a course section in the ContextSelector dropdown', () => {
    props.contexts = [
      { id: '1',
        name: 'testcourse',
        asset_string: 'course_1',
        sections: [
          {
            id: '1',
            asset_string: 'course_section_1'
          }
        ]
      }
    ]
    props.contexts = [
      { id: '1',
        name: 'testcourse',
        asset_string: 'course_1',
        sections: [
          {
            id: '1',
            asset_string: 'course_section_1'
          }
        ]
      }
    ]
    props.appointmentGroup = { context_codes: ['course_1', 'course_section_1'] }
    const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
    const contextSelector = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector')
    TestUtils.Simulate.click(contextSelector.childNodes[0])
    const sectionDropdown = TestUtils.findRenderedDOMComponentWithClass(component, 'sectionItem')
    ok(sectionDropdown)
  })

  test('handleDoneClick properly sets state', () => {
    props.contexts = [
      { id: '1',
        name: 'testcourse',
        asset_string: 'course_1',
        sections: [
          {
            id: '1',
            asset_string: 'course_section_1'
          }
        ]
      }
    ]
    props.contexts = [
      { id: '1',
        name: 'testcourse',
        asset_string: 'course_1',
        sections: [
          {
            id: '1',
            asset_string: 'course_section_1'
          }
        ]
      }
    ]
    props.appointmentGroup = { context_codes: ['course_1', 'course_section_1'] }
    const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
    const contextSelector = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector')
    TestUtils.Simulate.click(contextSelector.childNodes[0])
    const contextSelectorDropdown = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector__Dropdown')
    ok(contextSelectorDropdown)
    component.handleDoneClick({ preventDefault: () => {} })
    ok(!component.state.showDropdown)
  })

  test('toggleCourse toggles correct courses', () => {
    props.contexts = [
      { id: '1',
        name: 'testcourse',
        asset_string: 'course_1',
        sections: [
          {
            id: '1',
            asset_string: 'course_section_1'
          }
        ]
      }
    ]
    props.appointmentGroup = { context_codes: ['course_1', 'course_section_1'] }
    const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
    ok(!component.contextCheckboxes.course_1.checked)
    TestUtils.Simulate.change(component.contextCheckboxes.course_1, { "target": { "checked": true } })
    ok(component.contextCheckboxes.course_1.checked)
    TestUtils.Simulate.change(component.contextCheckboxes.course_1, { "target": { "checked": false} })
    ok(!component.contextCheckboxes.course_1.checked)
  })

  test('toggleCourse toggles section correctly', () => {
    props.contexts = [
      { id: '1',
        name: 'testcourse',
        asset_string: 'course_1',
        sections: [
          {
            id: '1',
            asset_string: 'course_section_1'
          }
        ]
      }
    ]
    props.appointmentGroup = { context_codes: ['course_1', 'course_section_1'] }
    const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
    ok(!component.contextCheckboxes.course_1.checked)
    TestUtils.Simulate.change(component.contextCheckboxes.course_1, { "target": { "checked": true } })
    ok(component.contextCheckboxes.course_1.checked)
    ok(component.sectionsCheckboxes.course_section_1.checked)
    TestUtils.Simulate.change(component.contextCheckboxes.course_1, { "target": { "checked": true } })
    ok(!component.sectionsCheckboxes.course_section_1.checked)
    ok(!component.contextCheckboxes.course_1.checked)
  })

  test('toggle section when course is selected', () => {
    props.contexts = [
      { id: '1',
        name: 'testcourse',
        asset_string: 'course_1',
        sections: [
          {
            id: '1',
            asset_string: 'course_section_1'
          },
          {
            id: '2',
            asset_string: 'course_section_2'
          }
        ]
      }
    ]
    props.appointmentGroup = { context_codes: ['course_1', 'course_section_1', 'course_section_2'] }
    const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
    ok(!component.contextCheckboxes.course_1.checked)
    TestUtils.Simulate.change(component.contextCheckboxes.course_1, { "target": { "checked": true } })
    ok(component.contextCheckboxes.course_1.checked)
    ok(component.sectionsCheckboxes.course_section_1.checked)
    TestUtils.Simulate.change(component.sectionsCheckboxes.course_section_1, { "target": { "checked": false} })
    ok(!component.sectionsCheckboxes.course_section_1.checked)
    ok(component.contextCheckboxes.course_1.checked)
  })

  test('parent course is selected when sub sections are selected', () => {
    props.contexts = [
      { id: '1',
        name: 'testcourse',
        asset_string: 'course_1',
        sections: [
          {
            id: '1',
            asset_string: 'course_section_1'
          },
          {
            id: '2',
            asset_string: 'course_section_2'
          }
        ]
      }
    ]
    props.appointmentGroup = { context_codes: ['course_1', 'course_section_1', 'course_section_2'] }
    const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
    ok(!component.sectionsCheckboxes.course_section_2.checked)
    ok(!component.sectionsCheckboxes.course_section_2.checked)
    TestUtils.Simulate.change(component.sectionsCheckboxes.course_section_1, { "target": { "checked": true} })
    TestUtils.Simulate.change(component.sectionsCheckboxes.course_section_2, { "target": { "checked": true} })
    ok(component.sectionsCheckboxes.course_section_2.checked)
    ok(component.sectionsCheckboxes.course_section_2.checked)
    ok(component.contextCheckboxes.course_1.checked)
  })

  test('toggleSections toggles correct section', () => {
    props.contexts = [
      { id: '1',
        name: 'testcourse',
        asset_string: 'course_1',
        sections: [
          {
            id: '1',
            asset_string: 'course_section_1'
          }
        ]
      }
    ]
    props.appointmentGroup = { context_codes: ['course_1', 'course_section_1'] }
    const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
    ok(!component.sectionsCheckboxes.course_section_1.checked)
    TestUtils.Simulate.change(component.sectionsCheckboxes.course_section_1, { "target": { "checked": true } })
    ok(component.sectionsCheckboxes.course_section_1.checked)
    TestUtils.Simulate.change(component.sectionsCheckboxes.course_section_1, { "target": { "checked": false} })
    ok(!component.sectionsCheckboxes.course_section_1.checked)
  })

  test('toggle course expanded', () => {
    props.contexts = [
      { id: '1',
        name: 'testcourse',
        asset_string: 'course_1',
        sections: [
          {
            id: '1',
            asset_string: 'course_section_1'
          }
        ]
      }
    ]
    props.appointmentGroup = { context_codes: ['course_1', 'course_section_1'] }
    const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
    const contextSelector = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector')
    TestUtils.Simulate.click(contextSelector.childNodes[0])
    const contextDropdown = TestUtils.findRenderedDOMComponentWithClass(component, 'CourseListItem')
    TestUtils.Simulate.click(contextDropdown.getElementsByClassName('icon-arrow-right')[0])
    ok(contextDropdown.getElementsByClassName('icon-arrow-down'))
  })

  test('checkbox state when contexts are in an appointmentgroup', () => {
    props.contexts = [
      { id: '1',
        name: 'testcourse',
        asset_string: 'course_1',
        sections: [
          {
            id: '1',
            asset_string: 'course_section_1'
          }
        ]
      }
    ]
    props.contexts = [
      { id: '1',
        name: 'testcourse',
        asset_string: 'course_1',
        sections: [
          {
            id: '1',
            asset_string: 'course_section_1'
          }
        ]
      }
    ]
    props.appointmentGroup = { context_codes: ['course_1'], sub_context_codes: ['course_section_1'] }
    const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
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
      { id: '1',
        name: 'testcourse',
        asset_string: 'course_1',
        sections: [
          {
            id: '1',
            asset_string: 'course_section_1'
          }
        ]
      }
    ]
    props.contexts = [
      { id: '1',
        name: 'testcourse',
        asset_string: 'course_1',
        sections: [
          {
            id: '1',
            asset_string: 'course_section_1'
          }
        ]
      }
    ]
    props.appointmentGroup = { context_codes: ['course_1', 'course_section_1'] }
    const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
    const contextSelector = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector')
    ok(contextSelector.childNodes[0].textContent === 'Select Calendars')
    component.componentWillReceiveProps(props)
    ok(contextSelector.childNodes[0].textContent === 'testcourse and 1 other')
  })
})
