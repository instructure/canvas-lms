define [
  'i18n!discussions'
  'jquery'
  'compiled/fn/preventDefault'
  'Backbone'
  'jqueryui/tooltip'
], (I18n, $, preventDefault, {View}) ->

  class ToggleableSubscriptionIconView extends View
    tagName:  'a'

    attributes:
      'href': '#'

    messages:
      subscribe:    I18n.t('subscribe', 'Subscribe to this topic')
      subscribed:   I18n.t('subscribed', 'Subscribed')
      unsubscribe:  I18n.t('unsubscribe', 'Unsubscribe from this topic')
      unsubscribed: I18n.t('unsubscribed', 'Unsubscribed')
      initial_post_required: I18n.t('initial_post_required_to_subscribe', 'You must post a reply before subscribing')
      not_in_group_set: I18n.t('cant_subscribe_not_in_group_set', 'You must be in an associated group to subscribe')
      not_in_group: I18n.t('cant_subscribe_not_in_group', 'You must be in this group to subscribe')

    tooltipOptions:
      items: '*'
      position: my: 'center bottom', at: 'center top-10', collision: 'none'
      tooltipClass: 'center bottom vertical'

    events: { 'click', 'keyclick' : 'click', 'hover', 'focus', 'blur' }

    initialize: ->
      @model.on('change:subscribed', @render)
      @model.on('change:user_can_see_posts', @render)
      @model.on('change:subscription_hold', @render)
      super

    hover: ({type}) ->
      @hovering = type in [ 'mouseenter', 'focus' ]
      @displayStateDuringHover = false
      @render()

    blur: @::hover
    focus: @::hover

    click: (e) ->
      e.preventDefault()
      if @subscribed()
        @model.topicUnsubscribe()
        @displayStateDuringHover = true
      else if @canSubscribe()
        @model.topicSubscribe()
        @displayStateDuringHover = true
      @render()

    subscribed: -> @model.get('subscribed') && @canSubscribe()

    canSubscribe: -> !@subscriptionHold()

    subscriptionHold: -> @model.get('subscription_hold')

    classAndTextForTooltip: ->
      # hovering: v, subscribed: s, subscription hold: h, display state during hover: d
      # true: 1, false: 0, don't care: x
      #
      # vshd | class                 | tooltip
      # -----+-----------------------+---------
      # 0xx1 | <should never happen> | <should never happen>
      # 00xx | icon-discussion       | x
      # 01xx | icon-discussion-check | x
      # 1000 | icon-discussion-check | Subscribe
      # 1010 | icon-discussion-x     | <subscription hold message>
      # 11x0 | icon-discussion-x     | Unsubscribe
      # 10x1 | icon-discussion       | Unsubscribed
      # 11x1 | icon-discussion-check | Subscribed
      if @hovering
        if @subscribed()
          if @displayStateDuringHover
            ['icon-discussion-check', @messages['subscribed']]
          else
            ['icon-discussion-x', @messages['unsubscribe']]
        else # unsubscribed
          if @displayStateDuringHover
            ['icon-discussion', @messages['unsubscribed']]
          else if @canSubscribe()
            ['icon-discussion-check', @messages['subscribe']]
          else
            ['icon-discussion-x', @messages[@subscriptionHold()]]
      else
        [(if @subscribed() then 'icon-discussion-check' else 'icon-discussion'), '']

    resetTooltipText: (tooltipText) ->
      @$el.tooltip(@tooltipOptions)
      # cycle the tooltip to recenter, also blinks if the text doesn't change which is good here
      @$el.tooltip('close')
      @$el.tooltip('option', content: -> tooltipText)
      @$el.tooltip('open')

    setScreenreaderText: ->
      @$srElement = @$srElement || @$el.find('.screenreader-only')
      # Doing this here because for some reason, the handlebars template
      # doesn't get called for a re-render like it should. :(
      if (@model.get('subscribed'))
        @$srElement.text(I18n.t('You are subscribed to this topic. Click to unsubscribe.'))
      else
        @$srElement.text(I18n.t('You are not subscribed to this topic. Click to subscribe.'))

    afterRender: ->
      [newClass, tooltipText] = @classAndTextForTooltip()
      @resetTooltipText(tooltipText)
      @$el.removeClass('icon-discussion icon-discussion-x icon-discussion-check')
      @$el.addClass(newClass)
      @setScreenreaderText()
      this
