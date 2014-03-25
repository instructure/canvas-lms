define [
  'i18n!discussions'
  'jquery'
  'underscore'
  'Backbone'
  'jst/DiscussionTopics/discussion'
  'compiled/views/PublishIconView'
  'compiled/views/ToggleableSubscriptionIconView'
  'compiled/views/MoveDialogView'
], (I18n, $, _, {View}, template, PublishIconView, ToggleableSubscriptionIconView, MoveDialogView) ->

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
      user_subscribed: I18n.t('subscribed_hint', 'You are subscribed to this topic. Click to unsubscribe.')
      user_unsubscribed: I18n.t('unsubscribed_hint', 'You are not subscribed to this topic. Click to subscribe.')

    events:
      'click .icon-lock':  'toggleLocked'
      'click .icon-pin':   'togglePinned'
      'click .icon-trash': 'onDelete'
      'click':             'onClick'

    # Public: Option defaults.
    defaults:
      pinnable: false

    els:
      '.screenreader-only': '$title'
      '.discussion-row': '$row'
      '.move_item': '$moveItemButton'

    # Public: Topic is able to be locked/unlocked.
    @optionProperty 'lockable'

    # Public: Topic is able to be pinned/unpinned.
    @optionProperty 'pinnable'

    @child 'publishIcon', '[data-view=publishIcon]' if ENV.permissions.publish

    @child 'toggleableSubscriptionIcon', '[data-view=toggleableSubscriptionIcon]'

    initialize: (options) ->
      @attachModel()
      options.publishIcon = new PublishIconView(model: @model) if ENV.permissions.publish
      options.toggleableSubscriptionIcon = new ToggleableSubscriptionIconView(model: @model)
      @moveItemView = new MoveDialogView
        model: @model
        nested: true
        saveURL: -> @model.collection.reorderURL()
      super

    render: ->
      super
      @$el.attr('data-id', @model.get('id'))
      @moveItemView.setTrigger @$moveItemButton
      this

    # Public: Lock or unlock the model and update it on the server.
    #
    # e - Event object.
    #
    # Returns nothing.
    toggleLocked: (e) =>
      e.preventDefault()
      key    = if @model.get('locked') then 'lock' else 'unlock'
      locked = !@model.get('locked')
      pinned = if locked then false else @model.get('pinned')
      @model.updateBucket(locked: locked, pinned: pinned)
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
      @model.updateBucket(pinned: !@model.get('pinned'))
      $(e.target).text(@messages[key])

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

    # Public: Toggle the view model's "hidden" attribute.
    #
    # Returns nothing.
    hide: =>
      @$el.toggle(!@model.get('hidden'))

    # Public: Generate JSON to pass to the view.
    #
    # Returns an object.
    toJSON: ->
      base = _.extend(@model.toJSON(), @options)
      # handle a student locking their own discussion (they should lose permissions).
      if @model.get('locked') and !_.intersection(ENV.current_user_roles, ['teacher', 'ta', 'admin']).length
        base.permissions.delete = false
      base.display_last_reply_at = I18n.l "#date.formats.medium", base.last_reply_at
      base.ENV = ENV
      base

    # Internal: Re-render for publish state change preserving focus
    #
    # Returns nothing.
    renderPublishChange: =>
      @publishIcon?.render()
      if ENV.permissions.publish
        if @model.get('published')
          @$row.removeClass('discussion-unpublished')
          @$row.addClass('discussion-published')
        else
          @$row.removeClass('discussion-published')
          @$row.addClass('discussion-unpublished')

    # Internal: Add event handlers to the model.
    #
    # Returns nothing.
    attachModel: ->
      @model.on('change:hidden', @hide)
      @model.on('change:published', @renderPublishChange)
