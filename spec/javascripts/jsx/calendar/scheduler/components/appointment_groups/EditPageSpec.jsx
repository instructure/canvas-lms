define([
  'react',
  'jquery',
  'axios',
  'jsx/calendar/scheduler/components/appointment_groups/EditPage',
], (React, $, axios, EditPage) => {
  const TestUtils = React.addons.TestUtils

  const renderComponent = (props = { appointment_group_id: '1' }) => {
    return TestUtils.renderIntoDocument(<EditPage {...props} />)
  }

  let sandbox = null

  module('AppointmentGroup EditPage')

  test('renders the EditPage component', () => {
    const component = renderComponent()
    const editPage = TestUtils.findRenderedDOMComponentWithClass(component, 'EditPage')
    ok(editPage)
  })


  module('Delete Group', {
    setup: () => {
      sandbox = sinon.sandbox.create()
    },
    teardown: () => {
      sandbox.restore()
      sandbox = null
    }
  })

  test('fires delete ajax request with the correct id', () => {
    const component = renderComponent()
    sandbox.spy(axios, 'delete')

    component.deleteGroup()

    ok(axios.delete.calledOnce)
    equal(axios.delete.getCall(0).args[0], '/api/v1/appointment_groups/1')
  })

  test('flashes error on error delete response', () => {
    const component = renderComponent()
    sandbox.stub(axios, 'delete', () => Promise.reject({ respose: { data: new Error('Something bad happened') } }))
    sandbox.spy($, 'flashError')

    component.deleteGroup()

    ok($.flashError.withArgs('An error ocurred while deleting the appointment group'))
  })

})
