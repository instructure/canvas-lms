define [
  'Backbone'
  'compiled/views/PublishButtonView'
  'jquery'
  'helpers/jquery.simulate'
], (Backbone, PublishButtonView, $) ->
  module 'PublishButtonView',
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

      @publish   = new Publishable(published: false, publishable: true)
      @published = new Publishable(published: true,  publishable: true)
      @disabled  = new Publishable(published: true,  publishable: false)

  # initialize
  test 'initialize publish', ->
    btnView = new PublishButtonView(model: @publish).render()
    ok btnView.isPublish()
    equal btnView.$el.html().match(/<i class="icon-unpublished"><\/i>&nbsp;Publish/).length, 1

  test 'initialize published', ->
    btnView = new PublishButtonView(model: @published).render()
    ok btnView.isPublished()
    equal btnView.$el.html().match(/<i class="icon-publish"><\/i>&nbsp;Published/).length, 1

  test 'initialize disabled published', ->
    btnView = new PublishButtonView(model: @disabled).render()
    ok btnView.isPublished()
    ok btnView.isDisabled()
    equal btnView.$el.html().match(/<i class="icon-publish"><\/i>&nbsp;Published/).length, 1

  # state
  test 'disable should add disabled state', ->
    btnView = new PublishButtonView(model: @publish).render()
    ok !btnView.isDisabled()
    btnView.disable()
    ok btnView.isDisabled()

  test 'enable should remove disabled state', ->
    btnView = new PublishButtonView(model: @publish).render()
    btnView.disable()
    ok btnView.isDisabled()
    btnView.enable()
    ok !btnView.isDisabled()

  test 'reset should disable states', ->
    btnView = new PublishButtonView(model: @publish).render()
    btnView.reset()
    ok !btnView.isPublish()
    ok !btnView.isPublished()
    ok !btnView.isUnpublish()

  # mouseenter
  test 'mouseenter publish button should remain publish button', ->
    btnView = new PublishButtonView(model: @publish).render()
    btnView.$el.trigger('mouseenter')
    ok btnView.isPublish()

  test 'mouseenter publish button should not change text or icon', ->
    btnView = new PublishButtonView(model: @publish).render()
    btnView.$el.trigger('mouseenter')
    equal btnView.$el.html().match(/<i class="icon-unpublished"><\/i>&nbsp;Publish/).length, 1

  test 'mouseenter published button should remove published state', ->
    btnView = new PublishButtonView(model: @published).render()
    btnView.$el.trigger('mouseenter')
    ok !btnView.isPublished()

  test 'mouseenter published button should add add unpublish state', ->
    btnView = new PublishButtonView(model: @published).render()
    btnView.$el.trigger('mouseenter')
    ok btnView.isUnpublish()

  test 'mouseenter published button should change icon and text', ->
    btnView = new PublishButtonView(model: @published).render()
    btnView.$el.trigger('mouseenter')
    equal btnView.$el.html().match(/<i class="icon-unpublish"><\/i>&nbsp;Unpublish/).length, 1

  test 'mouseenter disabled published button should keep published state', ->
    btnView = new PublishButtonView(model: @disabled).render()
    btnView.$el.trigger('mouseenter')
    ok btnView.isPublished()

  test 'mouseenter disabled published button should not change text or icon', ->
    btnView = new PublishButtonView(model: @disabled).render()
    equal btnView.$el.html().match(/<i class="icon-publish"><\/i>&nbsp;Published/).length, 1


  # mouseleave
  test 'mouseleave published button should add published state', ->
    btnView = new PublishButtonView(model: @published).render()
    btnView.$el.trigger('mouseenter')
    btnView.$el.trigger('mouseleave')
    ok btnView.isPublished()

  test 'mouseleave published button should remove unpublish state', ->
    btnView = new PublishButtonView(model: @published).render()
    btnView.$el.trigger('mouseenter')
    btnView.$el.trigger('mouseleave')
    ok !btnView.isUnpublish()

  test 'mouseleave published button should change icon and text', ->
    btnView = new PublishButtonView(model: @published).render()
    btnView.$el.trigger('mouseenter')
    btnView.$el.trigger('mouseleave')
    equal btnView.$el.html().match(/<i class="icon-publish"><\/i>&nbsp;Published/).length, 1


  # click
  test 'click publish should trigger publish event', ->
    btnView = new PublishButtonView(model: @publish).render()

    triggered = false
    btnView.on "publish", ->
      triggered = true

    btnView.$el.trigger('click')
    ok triggered

  test 'publish event callback should transition to published', ->
    btnView = new PublishButtonView(model: @publish).render()
    ok btnView.isPublish()

    btnView.$el.trigger('mouseenter')
    btnView.$el.trigger('click')

    ok !btnView.isPublish()
    ok  btnView.isPublished()

  test 'publish event callback should transition back to publish if rejected', ->
    # setup rejection
    @publishable.prototype.publish = ->
      @set("published", false)
      $.Deferred().reject()

    btnView = new PublishButtonView(model: @publish).render()
    ok btnView.isPublish()

    btnView.$el.trigger('mouseenter')
    btnView.$el.trigger('click')

    ok  btnView.isPublish()
    ok !btnView.isPublished()

  test 'click published should trigger unpublish event', ->
    btnView = new PublishButtonView(model: @published).render()

    triggered = false
    btnView.on "unpublish", ->
      triggered = true

    btnView.$el.trigger('mouseenter')
    btnView.$el.trigger('click')
    ok triggered

  test 'published event callback should transition to publish', ->
    btnView = new PublishButtonView(model: @published).render()
    ok btnView.isPublished()

    btnView.$el.trigger('mouseenter')
    btnView.$el.trigger('click')

    ok !btnView.isUnpublish()
    ok  btnView.isPublish()

  test 'published event callback should transition back to published if rejected', ->
    # setup rejection
    @publishable.prototype.unpublish = ->
      @set("published", true)
      $.Deferred().reject()

    btnView = new PublishButtonView(model: @published).render()
    ok btnView.isPublished()

    btnView.$el.trigger('mouseenter')
    btnView.$el.trigger('click')

    ok !btnView.isUnpublish()
    ok  btnView.isPublished()

  test 'click disabled published button should not trigger publish event', ->
    btnView = new PublishButtonView(model: @disabled).render()
    ok btnView.isPublished()

    btnView.$el.trigger('mouseenter')
    btnView.$el.trigger('click')

    ok !btnView.isPublish()

