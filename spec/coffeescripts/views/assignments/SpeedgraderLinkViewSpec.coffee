define [
  'compiled/views/assignments/SpeedgraderLinkView'
  'compiled/models/Assignment'
  'jquery'
], (SpeedgraderLinkView, Assignment, $) ->

  module "SpeedgraderLinkView",

    setup: ->
      @model = new Assignment published: false
      $('#fixtures').html """
        <a href="#" id="assignment-speedgrader-link" class="hidden"></a>
      """
      @view = new SpeedgraderLinkView
        model: @model
        el: $('#fixtures').find '#assignment-speedgrader-link'
      @view.render()

    teardown: ->
      @view.remove()
      $('#fixtures').empty()

  test "#toggleSpeedgraderLink toggles visibility of speedgrader link on change", ->

    @model.set 'published', true

    ok ! @view.$el.hasClass 'hidden'

    @model.set 'published', false
    ok @view.$el.hasClass 'hidden'

