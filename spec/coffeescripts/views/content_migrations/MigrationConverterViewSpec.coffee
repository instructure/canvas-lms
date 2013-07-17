define [
  'Backbone'
  'compiled/views/content_migrations/MigrationConverterView'
], (Backbone, MigrationConverterView) -> 
  class SomeBackboneView extends Backbone.View
    className: 'someViewRendered'
    template: -> '<div id="rendered">Rendered</div>'

  module 'MigrationConverterView',
    setup: -> 
      @migrationConverterView = new MigrationConverterView
        selectOptions:[{id: 'some_converter', label: 'Some Converter'}]
        progressView: new Backbone.View

      $('#fixtures').append @migrationConverterView.render().el

    teardown: -> @migrationConverterView.remove()

  test "renders a backbone view into it's main view container", -> 
    subView = new SomeBackboneView
    @migrationConverterView.renderConverter subView

    ok @migrationConverterView.$el.find('#converter #rendered').length > 0, "Rendered a sub view"
