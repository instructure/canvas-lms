define [
  'ember'
  'underscore'
  '../../components/ic_submission_download_dialog_component'
  '../shared_ajax_fixtures'
], (Ember, _, DownloadDialog, fixtures) ->

  {run} = Ember

  fixtures.create()

  buildComponent = (props) ->
    props = _.extend props,
      'assignmentUrl': '/courses/1/assignments/1'
    DownloadDialog.create(props)

  module 'status'

  test 'is "finished" if file ready', ->
    component = buildComponent
      'attachment': {workflow_state: 'available'}
    equal component.get('status'), 'finished'

  test 'is "zipping" if percent complete is > 95', ->
    component = buildComponent
      'percentComplete': 95
    equal component.get('status'), 'zipping'

  test 'is "starting" otherwise', ->
    component = buildComponent()
    equal component.get('status'), 'starting'

  module 'progress:'

  test 'percentComplete is 100 if file ready', ->
    # initialize percentComplete at 100
    # so the observer that updates the progressbar doesn't fire
    # otherwise the test fails because there is no DOM
    component = buildComponent
      'attachment': {workflow_state: 'available'}
      'percentComplete': 100
    component.progress()
    equal component.get('percentComplete'), 100

  test 'percentComplete is 0 if file_state is a string', ->
    component = buildComponent
      'attachment': {file_state: 'ready_to_download'}
    component.progress()
    equal component.get('percentComplete'), 0

  module 'keepChecking'

  test 'is true if open', ->
    component = buildComponent
      'isOpened': true
    equal component.get('keepChecking'), true

  test 'is undefined if closed', ->
    component = buildComponent()
    equal component.get('keepChecking'), undefined

  test 'is undefined if percentComplete is 100', ->
    component = buildComponent
      'percentComplete': 100
    equal component.get('keepChecking'), undefined

