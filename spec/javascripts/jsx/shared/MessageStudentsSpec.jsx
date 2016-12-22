define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'axios',
  'jsx/shared/MessageStudents',
  'instructure-ui/Button',
  'instructure-ui/Portal',
  'instructure-ui/Alert',
  'instructure-ui/Modal'
], (React, ReactDOM, TestUtils, axios, MessageStudents,
    { default: Button },
    { default: Portal },
    { default: Alert },
    { default: Modal, ModalHeader, ModalBody, ModalFooter },
   ) => {

  module('MessageStudents', (hooks) => {
    let subject

    hooks.afterEach(() => {
      if (subject) {
        const componentNode = ReactDOM.findDOMNode(subject)
        if (componentNode) {
          ReactDOM.unmountComponentAtNode(componentNode.parentNode)
        }
      }
      subject = null
    })

    test('it renders', () => {
      const subject = TestUtils.renderIntoDocument(
        <MessageStudents contextCode="course_1" title="Send a message" />
      )
      ok(subject)
    })

    module('composeRequestData()', () => {
      test('simplifies recipients to an array of ids', () => {
        const subject = TestUtils.renderIntoDocument(
          <MessageStudents title="Send a message"
            contextCode='course_1'
            recipients={[{
              id: 1, email: 'some@one.com'
            }]}
          />
        )

        const requestData = subject.composeRequestData()
        const recipient = requestData.recipients[0]
        ok(typeof recipient !== 'object')
        ok(recipient === 1)
      })
    })

    module('errorMessagesFor()', () => {
      test('fetches error for a given field from state', () => {
        const subject = TestUtils.renderIntoDocument(
          <MessageStudents contextCode='course_1' title="Send a message" />
        )
        const errorMessage = 'Please provide a subject.'
        subject.setState({
          errors: {
            'subject': errorMessage
          }
        })
        const errors = subject.errorMessagesFor('subject')
        equal(errors[0].text, errorMessage)
      })
    })

    module('sendMessage()', (hooks) => {
      let data
      const successPromise = new Promise((resolve) => resolve())
      const errorResponse = {
        data: {
          attribute: 'subject',
          message: 'blank'
        }
      }
      const errorPromise = new Promise((_, reject) => reject(errorResponse))

      hooks.beforeEach(() => {
        subject = TestUtils.renderIntoDocument(
          <MessageStudents title="Send a message"
            contextCode='course_1'
            subject='Here is a subject'
            body='Here is a body'
            recipients={[{
              id: 1, email: 'some@one.com'
            }]}
          />
        )
        data = subject.composeRequestData()
        sinon.spy(subject, 'handleResponseSuccess')
        sinon.spy(subject, 'handleResponseError')
      })

      hooks.afterEach(() => {
        subject.handleResponseSuccess.restore()
        subject.handleResponseError.restore()
      })

      test('sets state.sending', () => {
        notOk(subject.state.sending, 'precondition, should not be sending')
        subject.sendMessage(data)
        ok(subject.state.sending)
      })

      test('sets hideAlert to false', () => {
        subject.setState({hideAlert: true})
        ok(subject.state.hideAlert, 'precondition, should not be hideAlert')
        subject.sendMessage(data)
        notOk(subject.state.hideAlert)
      })

      module('on success', (hooks) => {
        hooks.beforeEach(() => {
          sinon.stub(axios, 'post').returns(successPromise)
        })

        hooks.afterEach(() => {
          axios.post.restore()
        })

        asyncTest('calls handleResponseSuccess', () => {
          subject.sendMessage(data)
          successPromise.then(() => {
            ok(subject.handleResponseSuccess.calledOnce)
            start()
          })
        })
      })

      module('on error', (hooks) => {
        hooks.beforeEach(() => {
          sinon.stub(axios, 'post').returns(errorPromise)
        })

        hooks.afterEach(() => {
          axios.post.restore()
        })

        asyncTest('calls handleResponseSuccess', () => {
          subject.sendMessage(data)
          Promise.all([errorPromise]).catch(() => {
            ok(subject.handleResponseError.calledOnce)
            start()
          })
        })
      })
    })

    module('validationErrors()', () => {
      const fields = ['subject', 'body']
      fields.forEach((field) => {
        test(`validates length of ${field} and sets error`, () => {
          const component = TestUtils.renderIntoDocument(
            <MessageStudents contextCode='course_1' title="Send a message" />
          )
          let data = {
            body: '',
            subject: ''
          }
          let errors = component.validationErrors(data)
          ok(errors.hasOwnProperty(field))
          data[field] = 'a value'
          errors = component.validationErrors(data)
          ok(!errors.hasOwnProperty(field))
        })
      })

      test('validates max length for subject', () => {
        const component = TestUtils.renderIntoDocument(
          <MessageStudents contextCode="course_1" title="Send a message" />
        )
        const data = {
          body: '',
          subject: "x".repeat(256)
        }
        let errors = component.validationErrors(data)
        ok(errors.hasOwnProperty('subject'))
      })
    })

    module('handleAlertClose()', (hooks) => {
      let closeButton

      hooks.beforeEach(() => {
        subject = TestUtils.renderIntoDocument(
          <MessageStudents contextCode='course_1' title="Send a message" />
        )
        subject.setState({errors: {
          subject: 'provide a subject'
        }})
        closeButton = document.querySelector('div.MessageStudents__Alert button')
      })

      test('sets state.hideAlert to true', () => {
        notOk(subject.state.hideAlert, 'precondition')
        Promise.resolve().then(() => {
          TestUtils.Simulate.click(closeButton)
        }).then(() => {
          ok(subject.state.hideAlert)
        })
      })
    })

    module('handleChange()', (hooks) => {
      hooks.beforeEach(() => {
        subject = TestUtils.renderIntoDocument(
          <MessageStudents contextCode='course_1' title="Send a message" />
        )
      })

      test('sets provided field / value pair in state.data', () => {
        const messageSubject = 'This is a message subject'
        ok(subject.state.data.subject.length === 0)

        subject.handleChange('subject', messageSubject)
        equal(subject.state.data.subject, messageSubject)
      })

      test('removes error for provided field if present', () => {
        subject.setState({
          errors: {
            subject: 'There was an error'
          }
        })
        ok(subject.state.errors.hasOwnProperty('subject'))

        subject.handleChange('subject', 'Fine here is a subject')
        ok(!subject.state.errors.hasOwnProperty('subject'))
      })
    })

    module('handleClose()', (hooks) => {
      let closeButton

      hooks.beforeEach(() => {
        subject = TestUtils.renderIntoDocument(
          <MessageStudents contextCode='course_1' title="Send a message" />
        )
        const buttons = document.querySelectorAll('button')
        closeButton = buttons[buttons.length - 2]
      })

      test('sets state.open to false', () => {
        ok(subject.state.open, 'precondition, should be open')
        TestUtils.Simulate.click(closeButton)
        notOk(subject.state.open)
      })
    })

    module('handleSubmit()', (hooks) => {
      let submitButton

      hooks.beforeEach(() => {
        subject = TestUtils.renderIntoDocument(
          <MessageStudents title="Send a message"
            contextCode='course_1'
            recipients={[{
              id: 1, email: 'some@one.com'
            }]}
          />
        )
        sinon.spy(subject, 'sendMessage')

        const buttons = document.querySelectorAll('button')
        submitButton = buttons[buttons.length - 1]
      })

      hooks.afterEach(() => {
        subject.sendMessage.restore()
      })

      test('does not call sendMessage if errors are present', () => {
        TestUtils.Simulate.click(submitButton)
        ok(subject.sendMessage.notCalled)
      })

      test('sets state errors based on validationErrors', () => {
        ok(subject.state.data.subject.length === 0, 'precondition, subject is blank')
        notOk(Object.keys(subject.state.errors).includes('subject'), 'precondition, no errors on subject')
        TestUtils.Simulate.click(submitButton)
        ok(Object.keys(subject.state.errors).includes('subject'))
      })

      test('sets state.hideAlert to false if errors are present', () => {
        subject.setState({hideAlert: true})
        ok(subject.state.hideAlert, 'precondition')
        TestUtils.Simulate.click(submitButton)
        notOk(subject.state.hideAlert)
      })

      module('with valid data', (hooks) => {
        hooks.beforeEach(() => {
          subject.handleChange('subject', 'here is a subject')
          subject.handleChange('body', 'here is a body')
        })

        test('does not set any errors', () => {
          notOk(Object.keys(subject.state.errors).includes('subject'), 'precondition, no errors on subject')
          TestUtils.Simulate.click(submitButton)
          notOk(Object.keys(subject.state.errors).includes('subject'))
        })

        test('calls sendMessage', () => {
          TestUtils.Simulate.click(submitButton)
          ok(subject.sendMessage.calledOnce)
        })
      })
    })

    module('handleResponseSuccess()', (hooks) => {
      let clocks

      hooks.beforeEach(() => {
        clocks = sinon.useFakeTimers()
        subject = TestUtils.renderIntoDocument(
          <MessageStudents title="Send a message"
            contextCode='course_1'
            subject='Here is a subject'
            body='Here is a body'
            recipients={[{
              id: 1, email: 'some@one.com'
            }]}
          />
        )
        subject.setState({
          hideAlert: true,
          sending: true
        })
      })

      hooks.afterEach(() => {
        clocks.restore()
      })

      test('updates state accordingly', () => {
        ok(subject.state.hideAlert, 'precondition, hideAlert should be true')
        ok(subject.state.sending, 'precondition, sending should be true')
        notOk(subject.state.success, 'precondition, success should be false')

        subject.handleResponseSuccess()

        notOk(subject.state.hideAlert)
        notOk(subject.state.sending)
        ok(subject.state.success)
      })

      test('sets timeout to close modal', () => {
        ok(subject.state.open, 'precondition, should be open')

        subject.handleResponseSuccess()

        clocks.tick(2700)
        ok(!subject.state.open)
      })
    })

    module('handleResponseError()', (hooks) => {
      let errorResponse

      hooks.beforeEach(() => {
        errorResponse = {
          response: {
            data: [{
              attribute: 'subject',
              message: 'blank'
            }]
          }
        }

        subject = TestUtils.renderIntoDocument(
          <MessageStudents title="Send a message"
            contextCode='course_1'
            recipients={[{
              id: 1, email: 'some@one.com'
            }]}
          />
        )
        subject.setState({
          sending: true
        })
      })

      test('sets field errors based on errorResponse', () => {
        ok(Object.keys(subject.state.errors).length === 0, 'precondition, no error present on subject')

        subject.handleResponseError(errorResponse)

        ok(Object.keys(subject.state.errors).includes('subject'))
      })

      test('marks sending as false', () => {
        ok(subject.state.sending, 'precondition, is sending')

        Promise.resolve().then(() => {
          subject.handleResponseError(errorResponse)
        }).then(() => {
          ok(!subject.state.sending)
        })
      })
    })

    module('renderAlert()', (hooks) => {
      hooks.beforeEach(() => {
        subject = TestUtils.renderIntoDocument(
          <MessageStudents title="Send a message"
            contextCode='course_1'
            recipients={[{
              id: 1, email: 'some@one.com'
            }]}
          />
        )
      })

      test('is null if provided callback is not truthy', () => {
        const callback = () => { return false }
        notOk(subject.renderAlert('Alert Message', 'info', callback))
      })

      test('renders alert component if callback returns true', () => {
        const callback = () => { return true }
        ok(subject.renderAlert('Alert Message', 'info', callback))
      })

      test('is null if state.hideAlert is true', () => {
        const callback = () => { return true }
        ok(subject.renderAlert('Alert Message', 'info', callback), 'precondition')

        subject.setState({hideAlert: true})
        notOk(subject.renderAlert('Alert Message', 'info', callback))
      })
    })
  })
})
