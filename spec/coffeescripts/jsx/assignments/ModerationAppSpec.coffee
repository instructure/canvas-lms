define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jsx/assignments/ModerationApp'
  'jsx/assignments/actions/ModerationActions'
], (React, ReactDOM, TestUtils, ModerationApp, Actions) ->

  QUnit.module 'ModerationApp',
    setup: ->
      @store =
        subscribe: sinon.spy()
        dispatch: sinon.spy()
        getState: -> {
          studentList: {
            selectedCount: 0
            students: []
            sort: 'asc'
          },
          inflightAction: {
            review: false,
            publish: false
          },
          flashMessage: {
            message: "",
            time: 0
          },
          assignment: {
            published: false
          },
          urls: {}
        }

      @moderationApp = TestUtils.renderIntoDocument(React.createElement(ModerationApp, store: @store))


    teardown: ->
      @store = null
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@moderationApp).parentNode)

  test 'it subscribes to the store when mounted', ->
    # TODO: Once the rest of the components get dumbed down, this could be
    #       changed to be .calledOnce
    ok @store.subscribe.called, 'subscribe was called'

  test 'it dispatches a single call to apiGetStudents when mounted', ->
    ok @store.dispatch.calledOnce, 'dispatch was called once'

  test 'it updates state when a change event happens', ->
    @store.getState = -> {
      newState: true
    }
    @moderationApp.handleChange()

    ok @moderationApp.state.newState, 'state was updated'
