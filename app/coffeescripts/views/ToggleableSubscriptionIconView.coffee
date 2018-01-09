#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'i18n!discussions'
  'jquery'
  '../fn/preventDefault'
  'Backbone'
  'jqueryui/tooltip'
  '../jquery.rails_flash_notifications'
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
      toggle_on: I18n.t('You are subscribed to this topic. Click to unsubscribe.')
      toggle_off: I18n.t('You are not subscribed to this topic. Click to subscribe.')


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
        $.screenReaderFlashMessage(@messages['toggle_off'])
      else if @canSubscribe()
        @model.topicSubscribe()
        @displayStateDuringHover = true
        $.screenReaderFlashMessage(@messages['toggle_on'])
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
      if (@model.get('subscribed'))
        @$el.attr('aria-label',@messages['toggle_on'])
      else
        @$el.attr('aria-label', @messages['toggle_off'])

    afterRender: ->
      [newClass, tooltipText] = @classAndTextForTooltip()
      @resetTooltipText(tooltipText)
      @$el.removeClass('icon-discussion icon-discussion-x icon-discussion-check')
      @$el.addClass(newClass)
      @setScreenreaderText()
      this
