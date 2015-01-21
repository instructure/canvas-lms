define [
  'old_unsupported_dont_use_react'
  'jquery'
  'compiled/react_files/components/PublishCloud'
  'compiled/models/FilesystemObject'
], (React, $, PublishCloud, FilesystemObject) ->

  Simulate = React.addons.TestUtils.Simulate

  # Integration Tests
  module 'PublishCloud',
    setup: ->
      @model = new FilesystemObject(locked: true, hidden: false, id: 42)
      @model.url = -> "/api/v1/folders/#{@id}"
      props =
        model: @model
        userCanManageFilesForContext: true

      @publishCloud = React.renderComponent(PublishCloud(props), $('#fixtures')[0])

    teardown: ->
      React.unmountComponentAtNode(@publishCloud.getDOMNode().parentNode)

  test "model change event updates components state", ->
    equal @publishCloud.state.published, false, "published starts off as false"
    @model.set('locked', false)
    equal @publishCloud.state.published, true, "changing models locked changes it to true"

  test "clicking a published cloud opens restricted dialog", ->
    sinon.stub(React, 'renderComponent')
    Simulate.click(@publishCloud.refs.publishCloud.getDOMNode())

    ok React.renderComponent.calledOnce, 'renders a component inside the dialog'
    React.renderComponent.restore()

  module 'PublishCloud Student View',
    setup: ->
      @model = new FilesystemObject(locked: false, hidden: true, lock_at: '123', unlock_at: '123', id: 42)
      @model.url = -> "/api/v1/folders/#{@id}"
      props =
        model: @model
        userCanManageFilesForContext: false

      @publishCloud = React.renderComponent(PublishCloud(props), $('#fixtures')[0])

    teardown: ->
      React.unmountComponentAtNode(@publishCloud.getDOMNode().parentNode)

  test 'should display a non clickable restricted dates icon', ->
    equal @publishCloud.refs.publishCloud.props.onClick, undefined, 'does not have a click event'
    equal @publishCloud.refs.publishCloud.props.title, "Available after Jan 1, 1970 at 12:00am until Jan 1, 1970 at 12:00am", "has a available from hoverover"

  # Unit Tests

  module 'PublishCloud#togglePublishedState',
    setup: ->
      props =
        model: new FilesystemObject(hidden: false, id: 42)
        userCanManageFilesForContext: true

      @publishCloud = React.renderComponent(PublishCloud(props), $('#fixtures')[0])

    teardown: ->
      React.unmountComponentAtNode(@publishCloud.getDOMNode().parentNode)

  test "when published is true, toggles it to false", ->
    @publishCloud.setState published: true
    @publishCloud.togglePublishedState()
    equal @publishCloud.state.published, false, "published state should be false"

  test "when published is false, toggles publish to true and clears restricted state", ->
    @publishCloud.setState published: false, restricted: true
    @publishCloud.togglePublishedState()
    equal @publishCloud.state.published, true, "published state should be true"
    equal @publishCloud.state.restricted, false, "published state should be true"

  test "when published is false, toggles publish to true and sets hidden to false", ->
    @publishCloud.setState published: false, restricted: true
    @publishCloud.togglePublishedState()
    equal @publishCloud.state.published, true, "published state should be true"
    equal @publishCloud.state.hidden, false, "hidden is false"

  module 'PublishCloud#getInitialState'

  test "sets published initial state based on params model hidden property", ->
    model = new FilesystemObject(locked: false, id: 42)
    props =
      model: model
      userCanManageFilesForContext: true

    @publishCloud = React.renderComponent(PublishCloud(props), $('#fixtures')[0])
    equal @publishCloud.state.published, !model.get('locked'), "not locked is published"
    equal @publishCloud.state.restricted, false, "restricted should be false"
    equal @publishCloud.state.hidden, false, "hidden should be false"
    React.unmountComponentAtNode(@publishCloud.getDOMNode().parentNode)

  test "restricted is true when lock_at/unlock_at is set", ->
    model = new FilesystemObject(hidden: false, lock_at: '123', unlock_at: '123', id: 42)
    props = model: model

    @publishCloud = React.renderComponent(PublishCloud(props), $('#fixtures')[0])

    equal @publishCloud.state.restricted, true, "restricted is true when lock_at/ulock_at is set"
    React.unmountComponentAtNode(@publishCloud.getDOMNode().parentNode)

  module 'PublishCloud#extractStateFromModel'

  test "returns object that can be used to set state", ->
    model = new FilesystemObject(locked: true, hidden: true, lock_at: '123', unlock_at: '123', id: 42)
    props = model: model
    @publishCloud = React.renderComponent(PublishCloud(props), $('#fixtures')[0])

    newModel = new FilesystemObject(locked: false, hidden: true, lock_at: null, unlock_at: null)
    deepEqual @publishCloud.extractStateFromModel(newModel), {hidden: true, published: true, restricted: false}, "returns object to set state with"
    React.unmountComponentAtNode(@publishCloud.getDOMNode().parentNode)
