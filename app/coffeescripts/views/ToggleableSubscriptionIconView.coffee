define [
  'i18n!discussions'
  'jquery'
  'compiled/fn/preventDefault'
  'Backbone'
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
      initial_post_required_to_subscribe: I18n.t('initial_post_required_to_subscribe', 'You must post a reply before subscribing')

    tooltipOptions:
      items: '*'
      position: my: 'center bottom', at: 'center top-10', collision: 'none'
      tooltipClass: 'center bottom vertical'

    events: { 'click', 'hover' }

    initialize: ->
      @model.on('change:subscribed', @render)
      @model.on('change:user_can_see_posts', @render)
      super

    hover: ({type}) ->
      @hovering = type is 'mouseenter'
      @displayStateDuringHover = false
      @render()

    click: (e) ->
      e.preventDefault()
      if @subscribed()
        @model.topicUnsubscribe()
        @displayStateDuringHover = true
      else if @canSubscribe()
        @model.topicSubscribe()
        @displayStateDuringHover = true
      @render()

    subscribed: -> @model.get('subscribed')
    
    canSubscribe: -> @model.get('user_can_see_posts')
    
    render: ->
      super

      # hovering: h, subscribed: s, requires initial post: r, just changed: j
      # true: 1, false: 0, don't care: x
      # j implies h
      # 
      # hsrj | class                 | tooltip 
      # -----+-----------------------+---------
      # 0xx1 | <should never happen> | <should never happen>
      # 00xx | icon-discussion       | x
      # 01xx | icon-discussion-check | x
      # 1000 | icon-discussion-check | Subscribe
      # 1010 | icon-discussion-x     | Initial post required
      # 11x0 | icon-discussion-x     | Unsubscribe
      # 10x1 | icon-discussion       | Unsubscribed
      # 11x1 | icon-discussion-check | Subscribed
      if @hovering
        [newClass, tooltipText] = if @subscribed()
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
            ['icon-discussion-x', @messages['initial_post_required_to_subscribe']]
        @$el.tooltip(@tooltipOptions)
        @$el.tooltip('close')
        @$el.tooltip('option', content: -> tooltipText)
        @$el.tooltip('open')
      else
        newClass = if @subscribed() then 'icon-discussion-check' else 'icon-discussion'

      @$el.removeClass('icon-discussion icon-discussion-x icon-discussion-check')
      @$el.addClass(newClass)
