define [
  'jquery'
  'underscore'
  'compiled/util/Popover'
  'compiled/models/grade_summary/Outcome'
  'compiled/views/grade_summary/OutcomePopoverView'
  'jst/outcomes/outcomePopover'
], ($, _, Popover, Outcome, OutcomePopoverView, template) ->

  module 'OutcomePopoverViewSpec',
    setup: ->
      @popoverView = new OutcomePopoverView({
        el: $('<div></div>')
        model: new Outcome()
        template: template
      })
      @e = (name, options={}) -> $.Event(name, _.extend(options, {
        currentTarget: @popoverView.el
      }))
      @clock = sinon.useFakeTimers()
    teardown: ->
      @clock.restore()

  test 'closePopover', ->
    ok _.isUndefined(@popoverView.popover, 'precondition')
    ok @popoverView.closePopover()

    @popoverView.popover = new Popover(@e('mouseleave'), @popoverView.render(), {
      verticalSide: 'bottom'
      manualOffset: 14
    })
    ok @popoverView.popover instanceof Popover

    ok @popoverView.closePopover()
    ok _.isUndefined(@popoverView.popover)

  test 'mouseenter', ->
    spy = sinon.spy(@popoverView, 'openPopover')
    ok !@popoverView.inside, 'precondition'

    @popoverView.el.trigger(@e('mouseenter'))

    ok spy.called
    ok @popoverView.inside

    @popoverView.openPopover.restore()

  test 'mouseleave when no popover is present', ->
    spy = sinon.spy(@popoverView, 'closePopover')

    ok _.isUndefined(@popoverView.popover), 'precondition'
    @popoverView.el.trigger(@e('mouseleave'))
    @clock.tick(@popoverView.TIMEOUT_LENGTH)
    ok !spy.called

    @popoverView.closePopover.restore()

  test 'mouseleave when popover is present', ->
    @popoverView.el.trigger('mouseenter')
    ok !_.isUndefined(@popoverView.popover), 'precondition'
    ok @popoverView.inside, 'precondition'

    spy = sinon.spy(@popoverView, 'closePopover')
    @popoverView.el.trigger(@e('mouseleave'))
    @clock.tick(@popoverView.TIMEOUT_LENGTH)
    ok spy.called

    @popoverView.closePopover.restore()

  test 'openPopover', ->
    ok _.isUndefined(@popoverView.popover), 'precondition'
    spy = sinon.spy(@popoverView, 'trigger')

    @popoverView.openPopover(@e('mouseenter'))

    ok @popoverView.popover instanceof Popover
    ok spy.calledWith('outcomes:popover:open')

    @popoverView.trigger.restore()

  test 'togglePopover', ->
   openSpy = sinon.spy(@popoverView, 'openPopover')
   closeSpy = sinon.spy(@popoverView, 'closePopover')

   @popoverView.togglePopover(@e('keypress', {
     keyCode: 32
   }))

   ok openSpy.called, 'should open with a spacebar'
   # A little confusing, but it's called in the course of
   # calling openPopover, so we need to allow for one.
   ok closeSpy.calledOnce, 'should not close with a spacebar'

   openSpy.reset()
   closeSpy.reset()

   @popoverView.togglePopover(@e('keypress', {
     keyCode: 27
   }))

   ok !openSpy.called, 'should not open with an escape'
   ok closeSpy.called, 'should close with an escape'

   @popoverView.openPopover.restore()
   @popoverView.closePopover.restore()
