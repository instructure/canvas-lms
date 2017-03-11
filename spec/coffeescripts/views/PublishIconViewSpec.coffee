define [
  'Backbone'
  'compiled/views/PublishIconView'
  'jquery'
  'helpers/jquery.simulate'
], (Backbone, PublishIconView, $) ->

  QUnit.module 'PublishIconView',
    setup: ->
      @publishable = class Publishable extends Backbone.Model
        defaults:
          'published':   false
          'publishable': true

        publish: ->
          @set("published", true)
          $.Deferred().resolve()

        unpublish: ->
          @set("published", false)
          $.Deferred().resolve()

        disabledMessage: ->
          "can't unpublish"

      @publish   = new Publishable(published: false, unpublishable: true)
      @published = new Publishable(published: true,  unpublishable: true)
      @disabled  = new Publishable(published: true,  unpublishable: false)

  # initialize
  test 'initialize publish', ->
    btnView = new PublishIconView(model: @publish).render()
    ok btnView.isPublish()
    equal btnView.$text.html().match(/Publish/).length, 1
    ok !btnView.$text.html().match(/Published/)

  test 'initialize publish adds tooltip', ->
    btnView = new PublishIconView(model: @publish).render()
    equal btnView.$el.attr("data-tooltip"), ""

  test 'initialize published', ->
    btnView = new PublishIconView(model: @published).render()
    ok btnView.isPublished()
    equal btnView.$text.html().match(/Published/).length, 1

  test 'initialize published adds tooltip', ->
    btnView = new PublishIconView(model: @published).render()
    equal btnView.$el.attr("data-tooltip"), ""

  test 'initialize disabled published', ->
    btnView = new PublishIconView(model: @disabled).render()
    ok btnView.isPublished()
    ok btnView.isDisabled()
    equal btnView.$text.html().match(/Published/).length, 1

  test 'initialize disabled adds tooltip', ->
    btnView = new PublishIconView(model: @disabled).render()
    equal btnView.$el.attr("data-tooltip"), ""
