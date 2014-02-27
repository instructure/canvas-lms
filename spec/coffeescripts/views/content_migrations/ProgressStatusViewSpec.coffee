define [
  'jquery'
  'compiled/views/content_migrations/ProgressStatusView'
  'compiled/models/ProgressingContentMigration'
], ($, ProgressStatusView, ProgressingModel) -> 

  module 'ProgressStatusViewSpec', 
    setup: -> 
      @progressingModel = new ProgressingModel
      @psv = new ProgressStatusView(model: @progressingModel)
      @$fixtures = $('#fixtures')

    teardown: ->
      @psv.remove()

  test 'displays progress workflow_state when migrations workflow_state is running', -> 
    @progressingModel.set('workflow_state', 'running') # this is a migration
    @progressingModel.progressModel.set('workflow_state', 'foo')

    @$fixtures.append @psv.render().el

    equal @psv.$el.find('.label').text(), 'Foo', "Displays correct workflow state"

  test 'displays migration workflow_state when migrations workflow_state is not running', -> 
    @progressingModel.set('workflow_state', 'some_not_running_state')
    @$fixtures.append @psv.render().el
    equal @psv.$el.find('.label').text(), 'Some not running state', "Displays correct workflow state"

  test 'adds label-success class to status when status is complete', -> 
    @progressingModel.set('workflow_state', 'complete')
    @$fixtures.append @psv.render().el
    ok @psv.$el.find('.label-success'), "Adds the label-success class"

  test 'adds label-important class to status when status is failed', -> 
    @progressingModel.set('workflow_state', 'failed')
    @$fixtures.append @psv.render().el
    ok @psv.$el.find('.label-important'), "Adds the label-important class"

  test 'adds label-info class to status when status is running', -> 
    @progressingModel.set('workflow_state', 'running')
    @progressingModel.progressModel.set('workflow_state', 'running')
    @$fixtures.append @psv.render().el
    ok @psv.$el.find('.label-info'), "Adds the label-info class"






