define [
  'Backbone'
  'underscore'
  'compiled/views/content_migrations/ConverterViewControl'
], (Backbone, _, ConverterViewControl) ->
  class BackboneSubView extends Backbone.View
    template: -> "<div>Random Backbone View</div>"

  class ParentView extends Backbone.View
    template: -> "<div>Random Backbone View</div>"

  QUnit.module 'ConverterViewControlSpec',
    teardown: ->
      ConverterViewControl.resetControl()

  test 'registering a view adds the view to the register list', ->
    ConverterViewControl.register value: 'backbone_view', view: new BackboneSubView
    equal ConverterViewControl.registeredViews.length, 1 , "Register the view in the register list"

  test 'before registering a view subscribed is false', ->
    equal ConverterViewControl.subscribed, false, "Subscribed is set to faults by default"

  test 'after registering a view subscribed is true', ->
    ConverterViewControl.register value: 'backbone_view', view: new BackboneSubView
    equal ConverterViewControl.subscribed, true, "Subscribed is set to true after registering a view"

  test 'resetControl sets subscribed to false if it was true', ->
    ConverterViewControl.subscribed = true
    ConverterViewControl.resetControl()
    equal ConverterViewControl.subscribed, false, "resetControl sets subscribed to false"

  test 'resetControl empties registeredViews list', ->
    ConverterViewControl.register value: 'backbone_view', view: new BackboneSubView
    equal ConverterViewControl.registeredViews.length, 1
    ConverterViewControl.resetControl()
    equal ConverterViewControl.registeredViews.length, 0, "Clears the registeredViews"

  #test 'calls renderConverter on options.migrationConverter', -> 
    #viewSpy = @spy()
    #ConverterViewControl.register value: 'backbone_view', view: new BackboneSubView
    #ConverterViewControl.renderViews value: 'backbone_view', migrationConverter: viewSpy

    #ok viewSpy.called, true, "Called migrationConverter"
