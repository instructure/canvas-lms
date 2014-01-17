define [
  'ember',
  'compiled/behaviors/tooltip'
], (Ember) ->

  # http://emberjs.com/guides/components/
  # http://emberjs.com/api/classes/Ember.Component.html

  IcTooltipComponent = Ember.Component.extend

    tagName: 'span'
    linkHref: '#'

    init: ->
      @set 'selectorId', Em.generateGuid( {}, 'vdd_tooltip_')
      @_super.apply(this, arguments)

    triggerTooltip: ( =>
      @$('.vdd_tooltip_link').tooltip
        position: {my: 'center bottom', at: 'center top-10', collision: 'fit fit'},
        tooltipClass: 'center bottom vertical',
        content: -> Em.$('#'+ Em.$(this).data('tooltip-selector')).html()
    ).on('didInsertElement')

    willDestroy: ->
      target = @$('.vdd_tooltip_link')
      if target
        target.tooltip('destroy')
      @_super()
