define [
  'jquery'
  'underscore'
  'i18n!dicussions'
  'compiled/models/DiscussionTopic'
  'compiled/views/ToggleableSubscriptionIconView'
], ($, _, I18n, DiscussionTopic, SubscriptionIconView) ->

  module 'SubscriptionIconView',
    setup: ->
      @model = new DiscussionTopic()
      @view = new SubscriptionIconView(model: @model)
      @view.render()
      @e = (name, options={}) -> $.Event(name, _.extend(options, {
        currentTarget: @view.el
      }))

  test 'hover', ->
    console.log @view.el
    spy = sinon.spy(@view, 'render')

    @view.$el.trigger(@e('focus'))
    ok spy.called
    ok @view.hovering
    spy.reset()

    @view.$el.trigger(@e('blur'))
    ok spy.called
    ok !@view.hovering
    spy.reset()

    @view.$el.trigger(@e('mouseenter'))
    ok spy.called
    ok @view.hovering
    spy.reset()

    @view.$el.trigger(@e('mouseleave'))
    ok spy.called
    ok !@view.hovering
    spy.reset()

    @view.render.restore()

  test 'click', ->
    unsubSpy = sinon.stub(@model, 'topicUnsubscribe')
    subSpy = sinon.stub(@model, 'topicSubscribe')
    @model.set({
      subscribed: false
      subscription_hold: false
    })
    ok !@view.dispalyStateDuringHover, 'precondition'

    @view.$el.trigger(@e('click'))
    ok subSpy.called
    ok !unsubSpy.called
    ok @view.displayStateDuringHover

    unsubSpy.reset()
    subSpy.reset()
    @view.displayStateDuringHover = false

    @model.set('subscribed', true)
    @view.$el.trigger(@e('click'))
    ok !subSpy.called
    ok unsubSpy.called
    ok @view.displayStateDuringHover

    unsubSpy.reset()
    subSpy.reset()
    @view.displayStateDuringHover = false
    @model.set({
      subscribed: false
      subscription_hold: true
    })

    @view.$el.trigger(@e('click'))
    ok !subSpy.called
    ok !unsubSpy.called
    ok !@view.displayStateDuringHover

    @model.topicSubscribe.restore()
    @model.topicUnsubscribe.restore()
