define [
  'jquery'
  'Backbone'
  'compiled/views/SelectView'
  'helpers/jquery.simulate'
], ($, Backbone, SelectView) ->

  view = null

  QUnit.module 'SelectView',
    setup: ->
      view = new SelectView
        template: ->
          """
            <option>foo</option>
            <option>bar</option>
          """
      view.render()
      view.$el.appendTo $('#fixtures')
    teardown: ->
      view.remove()
      $("#fixtures").empty()

  test 'onChange it updates the model', ->
    view.model = new Backbone.Model
    equal view.el.value, 'foo'
    view.el.value = 'bar'
    equal view.el.value, 'bar'
    view.$el.change()
    equal view.model.get('unnamed'), 'bar'

