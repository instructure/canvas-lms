define [
  'i18n!discussions'
  'underscore'
  'Backbone'
  'jst/DiscussionTopics/discussion'
], (I18n, _, {View}, template) ->

  class DiscussionView extends View
    # Public: View template (discussion).
    template: template

    # Public: Wrap everything in an <li />.
    tagName: 'li'

    # Public: <li /> class name(s).
    className: 'discussion'

    # Public: I18n translations.
    messages:
      confirm:     I18n.t('confirm_delete_discussion_topic', 'Are you sure you want to delete this discussion topic?')
      delete:       I18n.t('delete', 'Delete')
      lock:         I18n.t('lock', 'Lock')
      unlock:       I18n.t('unlock', 'Unlock')
      pin:          I18n.t('pin', 'Pin')
      unpin:        I18n.t('unpin', 'Unpin')
      subscribe:    I18n.t('subscribe', 'Subscribe to this topic')
      subscribed:   I18n.t('subscribed', 'Subscribed')
      unsubscribe:  I18n.t('unsubscribe', 'Unsubscribe from this topic')
      unsubscribed: I18n.t('unsubscribed', 'Unsubscribed')
      initialPostRequiredToSubscribe: I18n.t('initial_post_required_to_subscribe', 'You must post a reply before subscribing')

    events:
      'click .icon-lock':  'toggleLocked'
      'click .icon-pin':   'togglePinned'
      'click .icon-trash': 'onDelete'
      'mouseenter .subscription-toggler': 'subscriptionHover'
      'mouseleave .subscription-toggler': 'subscriptionHover'
      'click .subscription-toggler': 'toggleSubscription'
      'click':             'onClick'

    # Public: Option defaults.
    defaults:
      lockable: true
      pinnable: false

    els:
      '.subscription-toggler': '$subscriptionToggler'

    # Public: Topic is able to be locked/unlocked.
    @optionProperty 'lockable'

    # Public: Topic is able to be pinned/unpinned.
    @optionProperty 'pinnable'

    initialize: (options) ->
      @attachModel()
      super

    render: ->
      super
      @$el.attr('data-id', @model.get('id'))
      @$subscriptionToggler.tooltip(
        items: '*'
        position: my: 'center bottom', at: 'center top-10', collision: 'fit fit'
        tooltipClass: 'center bottom vertical'
        content: =>
          if @model.get('subscribed')
            if @justChanged
              @messages['subscribed']
            else
              @messages['unsubscribe']
          else if @model.get('require_initial_post')
            @messages['initialPostRequiredToSubscribe']
          else
            if @justChanged
              @messages['unsubscribed']
            else
              @messages['subscribe']) 
      @updateSubscriptionIcon()
      this

    # Public: Lock or unlock the model and update it on the server.
    #
    # e - Event object.
    #
    # Returns nothing.
    toggleLocked: (e) =>
      e.preventDefault()
      key = if @model.get('locked') then 'lock' else 'unlock'
      @model.updateOneAttribute('locked', !@model.get('locked'))
      $(e.target).text(@messages[key])

    # Public: Confirm a request to delete and then complete it if needed.
    #
    # e - Event object.
    #
    # Returns nothing.
    onDelete: (e) =>
      e.preventDefault()
      @delete() if confirm(@messages.confirm)

    # Public: Delete the model and update the server.
    #
    # Returns nothing.
    delete: ->
      @model.destroy()
      @$el.remove()

    # Public: Pin or unpin the model and update it on the server.
    #
    # e - Event object.
    #
    # Returns nothing.
    togglePinned: (e) =>
      e.preventDefault()
      key = if @model.get('pinned') then 'pin' else 'unpin'
      @model.updateOneAttribute('pinned', !@model.get('pinned'))
      $(e.target).text(@messages[key])

    # Public: Subscribe to or unsubscribe from the model and update it on the server.
    #
    # e - Event object.
    #
    # Returns nothing.
    toggleSubscription: (e) =>
      e.preventDefault()
      @justChanged = true
      if @model.get('subscribed')
        @model.topicUnsubscribe()
      else if !@model.get('require_initial_post')
        @model.topicSubscribe()
      else
        @justChanged = false
      @$subscriptionToggler.tooltip('close')
      @$subscriptionToggler.tooltip('open')      

    # Public: Change subscription icon on hover
    #
    # e - Event handler.
    #
    # Returns nothing.
    subscriptionHover: (e) =>
      e.preventDefault()
      @subscriptionHovering = e.type == 'mouseenter'
      @justChanged = false
      @updateSubscriptionIcon()

    # Public: Treat the whole <li /> as a link.
    #
    # e - Event handler.
    #
    # Returns nothing.
    onClick: (e) ->
      # Workaround a behavior of FF 15+ where it fires a click
      # after dropping a sortable item.
      return if @model.get('preventClick')
      return if _.contains(['A', 'I'], e.target.nodeName)
      window.location = @model.get('html_url')

    # Public: Update the subscription icon based on model and hover
    #
    # Returns nothing.
    updateSubscriptionIcon: =>
      @$subscriptionToggler.removeClass('icon-discussion icon-discussion-x icon-discussion-check')
      newClass = if @subscriptionHovering
                   if @justChanged
                     if @model.get('subscribed')
                       'icon-discussion-check'
                     else
                       'icon-discussion'
                   else if @model.get('subscribed') or @model.get('require_initial_post')
                     'icon-discussion-x'
                   else
                     'icon-discussion-check'
                 else
                   if @model.get('subscribed')
                     'icon-discussion-check'
                   else
                     'icon-discussion'
      @$subscriptionToggler.addClass(newClass)

    # Public: Toggle the view model's "hidden" attribute.
    #
    # Returns nothing.
    hide: =>
      @$el.toggle(!@model.get('hidden'))

    # Public: Generate JSON to pass to the view.
    #
    # Returns an object.
    toJSON: ->
      _.extend(@model.toJSON(), @options)

    # Internal: Add event handlers to the model.
    #
    # Returns nothing.
    attachModel: ->
      @model.on('change:hidden', @hide)
      @model.on('change:subscribed', @updateSubscriptionIcon)
