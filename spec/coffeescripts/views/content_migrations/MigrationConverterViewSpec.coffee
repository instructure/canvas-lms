define [
  'jquery'
  'Backbone'
  'compiled/views/content_migrations/MigrationConverterView'
], ($, Backbone, MigrationConverterView) ->
  class SomeBackboneView extends Backbone.View
    className: 'someViewRendered'
    template: -> '<div id="rendered">Rendered</div>'

  module 'MigrationConverterView',
    setup: ->
      @clock = sinon.useFakeTimers()
      @migrationConverterView = new MigrationConverterView
        selectOptions:[{id: 'some_converter', label: 'Some Converter'}]
        progressView: new Backbone.View

      $('#fixtures').append @migrationConverterView.render().el

    teardown: ->
      @clock.restore()
      @migrationConverterView.remove()

  test "renders a backbone view into it's main view container", 1, ->
    subView = new SomeBackboneView
    @migrationConverterView.on 'converterRendered', =>
      ok @migrationConverterView.$el.find('#converter #rendered').length > 0, "Rendered a sub view"
    @migrationConverterView.renderConverter subView
    @clock.tick(15)

  test "trigger reset event when no subView is passed in to render", 1, ->
    @migrationConverterView.on 'converterReset', ->
      ok true, "converterReset was called"

    @migrationConverterView.renderConverter()
