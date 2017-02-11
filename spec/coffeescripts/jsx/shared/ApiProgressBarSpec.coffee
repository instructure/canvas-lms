define [
  'underscore',
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/shared/ApiProgressBar'
  'jsx/shared/stores/ProgressStore'
], (_, React, ReactDOM, TestUtils, ApiProgressBar, ProgressStore) ->

  QUnit.module 'ApiProgressBarSpec',
    setup: ->
      @progress_id = '1'
      @progress = {
        id: @progress_id,
        context_id: 1,
        context_type: 'EpubExport',
        user_id: 1,
        tag: 'epub_export',
        completion: 0,
        workflow_state: 'queued'
      }
      @store_state = {}
      @store_state[@progress_id] = @progress
      @storeSpy = sinon.stub(ProgressStore, 'get').callsFake((=>
        ProgressStore.setState(@store_state)
      ))
      @clock = sinon.useFakeTimers()

    teardown: ->
      ProgressStore.get.restore()
      ProgressStore.clearState()
      @clock.restore()

  test 'shouldComponentUpdate', ->
    ApiProgressBarElement = React.createElement(ApiProgressBar)
    component = TestUtils.renderIntoDocument(ApiProgressBarElement)

    ok component.shouldComponentUpdate({
      progress_id: @progress_id
    }, {}), 'should update when progress_id prop changes'

    ok component.shouldComponentUpdate({}, {
      workflow_state: 'running'
    }), 'should update when workflow_state changes'

    ok component.shouldComponentUpdate({}, {
      completion: 10
    }), 'should update when completion level changes'

    component.setProps(progress_id: @progress_id)
    component.setState(workflow_state: 'running')

    ok !component.shouldComponentUpdate({
      progress_id: @progress_id
    }, {
      completion: component.state.completion,
      workflow_state: component.state.workflow_state
    }), 'should not update if state & props are the same'

  test 'componentDidUpdate', ->
    onCompleteSpy = sinon.spy()
    ApiProgressBarElement = React.createElement(ApiProgressBar, {
      onComplete: onCompleteSpy,
      progress_id: @progress_id
    })
    component = TestUtils.renderIntoDocument(ApiProgressBarElement)
    @clock.tick(component.props.delay + 5)
    ok !_.isNull(component.intervalID), 'should have interval id'

    @progress.workflow_state = 'running'
    @clock.tick(component.props.delay + 5)
    ok !_.isNull(component.intervalID), 'should have an inverval id after updating to running'

    @progress.workflow_state = 'completed'
    @clock.tick(component.props.delay + 5)
    ok _.isNull(component.intervalID), 'should not have an inverval id after updating to completed'
    ok onCompleteSpy.called, 'should call callback on update if complete'

  test 'handleStoreChange', ->
    ApiProgressBarElement = React.createElement(ApiProgressBar, {
      progress_id: @progress_id
    })
    component = TestUtils.renderIntoDocument(ApiProgressBarElement)
    @clock.tick(component.props.delay + 5)

    _.each [ 'completion', 'workflow_state' ], (stateName) =>
      equal component.state[stateName], @progress[stateName],
        "component #{stateName} should equal progress #{stateName}"

    @progress.workflow_state = 'running'
    @progress.completion = 50
    ProgressStore.setState(@store_state)

    _.each [ 'completion', 'workflow_state' ], (stateName) =>
      equal component.state[stateName], @progress[stateName],
        "component #{stateName} should equal progress #{stateName}"

    ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)

  test 'isComplete', ->
    ApiProgressBarElement = React.createElement(ApiProgressBar, {
      progress_id: @progress_id
    })
    component = TestUtils.renderIntoDocument(ApiProgressBarElement)
    @clock.tick(component.props.delay + 5)

    ok !component.isComplete(), 'is not complete if state is queued'

    @progress.workflow_state = 'running'
    @clock.tick(component.props.delay + 5)
    ok !component.isComplete(), 'is not complete if state is running'

    @progress.workflow_state = 'completed'
    @clock.tick(component.props.delay + 5)
    ok component.isComplete(), 'is complete if state is completed'

  test 'isInProgress', ->
    ApiProgressBarElement = React.createElement(ApiProgressBar, {
      progress_id: @progress_id
    })
    component = TestUtils.renderIntoDocument(ApiProgressBarElement)
    @clock.tick(component.props.delay + 5)

    ok component.isInProgress(), 'is in progress if state is queued'

    @progress.workflow_state = 'running'
    @clock.tick(component.props.delay + 5)
    ok component.isInProgress(), 'is in progress if state is running'

    @progress.workflow_state = 'completed'
    @clock.tick(component.props.delay + 5)
    ok !component.isInProgress(), 'is not in progress if state is completed'

  test 'poll', ->
    ApiProgressBarElement = React.createElement(ApiProgressBar)
    component = TestUtils.renderIntoDocument(ApiProgressBarElement)
    component.poll()
    ok !@storeSpy.called,
      'should not fetch from progress store without progress id'

    component.setProps(progress_id: @progress_id)
    component.poll()
    ok @storeSpy.called, 'should fetch when progress id is present'

    ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)

  test 'render', ->
    ApiProgressBarElement = React.createElement(ApiProgressBar, {
      progress_id: @progress_id
    })
    component = TestUtils.renderIntoDocument(ApiProgressBarElement)
    ok _.isNull(component.getDOMNode()),
      'should not render to DOM if is not in progress'

    @clock.tick(component.props.delay + 5)
    ok !_.isNull(component.getDOMNode()),
      'should render to DOM if is not in progress'

    ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)
