define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jquery',
  'axios',
  'moment',
  'jsx/calendar/scheduler/components/appointment_groups/EditPage',
  'vendor/timezone/Europe/London',
  'timezone',
  'helpers/fakeENV',
  'instructure-ui/Button',
  'jquery.instructure_date_and_time'
], (React, ReactDOM, TestUtils, $, axios, moment, EditPage, london, tz, fakeENV, { default: Button }) => {
  const container = document.getElementById('fixtures')

  const renderComponent = (props = { appointment_group_id: '1' }) => {
    return TestUtils.renderIntoDocument(<EditPage {...props} />)
  }

  // use ReactDOM instead of TestUtils to test integration with non-react things that need real DOM
  const renderComponentInDOM = (props = { appointment_group_id: '1' }) => {
    return ReactDOM.render(<EditPage {...props} />, container)
  }

  let sandbox = null

  module('AppointmentGroup EditPage')

  test('renders the EditPage component', () => {
    const component = renderComponent()
    const editPage = TestUtils.findRenderedDOMComponentWithClass(component, 'EditPage')
    ok(editPage)
  })


  module('Message Users')

  test('renders message users button', () => {
    const component = renderComponent()
    ok(component.messageStudentsButton)
  })

  test('clicking message users button opens message students modal', () => {
    const component = renderComponentInDOM()
    const button = ReactDOM.findDOMNode(component.messageStudentsButton)

    // needed by message modal
    component.setState({
      eventDataSource: {
        getParticipants: (group, status, cb) => cb([])
      },
    })

    button.click()
    const messageModal = document.querySelector('#message_participants_form')

    ok(messageModal)
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

  module('Change Handlers')

  test('handleChange updates properties based on the name property', () => {
    const component = renderComponent()
    const fakeEvent = {
      target: {
        name: 'han',
        value: 'solo'
      }
    }
    component.handleChange(fakeEvent)
    equal(component.state.formValues.han, 'solo')
  })

  test('handleCheckboxChange updates the boolean flag based on the name property', () => {
    const component = renderComponent()
    const fakeEvent = {
      target: {
        name: 'han',
        checked: true
      }
    }
    component.handleCheckboxChange(fakeEvent)
    equal(component.state.formValues.han, true)
  })

  module('Save Group', {
   setup () {
     sandbox = sinon.sandbox.create()
   },
   teardown () {
     sandbox.restore()
     sandbox = null
   }
  })

   test('handleSave shows error when limit users per slot is empty', () => {
     const component = renderComponent()
     sandbox.stub($.fn, 'errorBox')
     sandbox.spy(axios, 'put')
     component.setState({
       formValues: {
         limitUsersPerSlot: true
       }
     })

     component.handleSave()

     ok($.fn.errorBox.calledWith('You must provide a value or unselect the option.'))
     ok(!axios.put.called)
   })

   test('handleSave shows error when limit users per slot is less than 1', () => {
     const component = renderComponent()
     sandbox.stub($.fn, 'errorBox')
     sandbox.spy(axios, 'put')
     component.setState({
       formValues: {
         limitUsersPerSlot: true
       }
     })
     $('.EditPage__Options-LimitUsersPerSlot', component.optionFields).val('0')

     component.handleSave()

     ok($.fn.errorBox.calledWith('You must allow at least one appointment per time slot.'))
     ok(!axios.put.called)
   })

   test('handleSave shows error when limit slots per user is empty', () => {
     const component = renderComponent()
     sandbox.stub($.fn, 'errorBox')
     sandbox.spy(axios, 'put')
     component.setState({
       formValues: {
         limitSlotsPerUser: true
       }
     })

     component.handleSave()

     ok($.fn.errorBox.calledWith('You must provide a value or unselect the option.'))
     ok(!axios.put.called)
   })

   test('handleSave shows error when limit slots per user is less than 1', () => {
     const component = renderComponent()
     sandbox.stub($.fn, 'errorBox')
     sandbox.spy(axios, 'put')
     component.setState({
       formValues: {
         limitSlotsPerUser: true
       }
     })
     $('.EditPage__Options-LimitSlotsPerUser', component.optionFields).val('0')

     component.handleSave()

     ok($.fn.errorBox.calledWith('You must allow at least one appointment per participant.'))
     ok(!axios.put.called)
   })

   test('handleSave prepares the proper participant_visibility when students are allowed to view', () => {
     const component = renderComponent()
     sandbox.spy(axios, 'put')
     component.setState({
       formValues: {
         allowStudentsToView: true
       }
     })

     component.handleSave()

     const requestObj = axios.put.args[0][1]
     equal(requestObj.appointment_group.participant_visibility, 'protected')
   })

   test('handleSave prepares the timeblocks appropriately', () => {
     const snapshot = tz.snapshot()
     // set local timezone to UTC
     tz.changeZone(london, 'Europe/London')
     // set user profile timezone to EST (UTC-4)
     fakeENV.setup({ TIMEZONE: 'America/Detroit' })

     const component = renderComponent()
     sandbox.spy(axios, 'put')
     component.setState({
       formValues: {
         timeblocks: [{
           slotEventId: 'NEW-1',
           timeData: {
             date: $.fudgeDateForProfileTimezone(new Date('2016-10-28T19:00:00.000Z')),
             startTime: $.fudgeDateForProfileTimezone(new Date('2016-10-28T19:00:00.000Z')),
             endTime: $.fudgeDateForProfileTimezone(new Date('2016-10-28T19:30:00.000Z'))
           }
         },
         {
           slotEventId: 'NEW-2',
           timeData: {
             date: $.fudgeDateForProfileTimezone(new Date('2016-10-28T19:30:00.000Z')),
             startTime: $.fudgeDateForProfileTimezone(new Date('2016-10-28T19:30:00.000Z')),
             endTime: $.fudgeDateForProfileTimezone(new Date('2016-10-28T20:00:00.000Z'))
           }
         },
         {
           slotEventId: 'NEW-3',
           timeData: {}
         }
       ]}
     })

     component.handleSave()

     const requestObj = axios.put.args[0][1]

     // The expected appointments are not fudged
     const expectedAppointments = [
       [new Date('2016-10-28T19:00:00.000Z'), new Date('2016-10-28T19:30:00.000Z')],
       [new Date('2016-10-28T19:30:00.000Z'), new Date('2016-10-28T20:00:00.000Z')]
     ]

     deepEqual(requestObj.appointment_group.new_appointments, expectedAppointments)

     tz.restore(snapshot)
     fakeENV.teardown()
   })


   test('handleSave sends a request to the proper endpoint', () => {
     const component = renderComponent()
     sandbox.spy(axios, 'put')

     component.handleSave()

     equal(axios.put.getCall(0).args[0], '/api/v1/appointment_groups/1')
   })

   test('flashes error on error delete response', () => {
     const component = renderComponent()
     sandbox.stub(axios, 'put', () => Promise.reject({ respose: { data: new Error('Something bad happened') } }))
     sandbox.stub($, 'flashError')

     component.handleSave()

     ok($.flashError.withArgs('An error ocurred while saving the appointment group'))
   })
 })
