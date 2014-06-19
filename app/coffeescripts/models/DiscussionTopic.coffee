define [
  'i18n!discussion_topics'
  'Backbone'
  'jquery'
  'underscore'
  'compiled/collections/ParticipantCollection'
  'compiled/collections/DiscussionEntriesCollection'
  'compiled/models/Assignment'
  'compiled/models/DateGroup'
], (I18n, Backbone, $, _, ParticipantCollection, DiscussionEntriesCollection, Assignment, DateGroup) ->

  class DiscussionTopic extends Backbone.Model
    resourceName: 'discussion_topics'

    defaults:
      discussion_type: 'side_comment'
      podcast_enabled: false
      podcast_has_student_posts: false
      require_initial_post: false
      is_announcement: false
      subscribed: false
      user_can_see_posts: true
      subscription_hold: null
      publishable: true
      unpublishable: true

    dateAttributes: [
      'last_reply_at'
      'posted_at'
      'delayed_post_at'
    ]

    initialize: ->
      @participants = new ParticipantCollection
      @entries = new DiscussionEntriesCollection
      @entries.url = => "#{_.result this, 'url'}/entries"
      @entries.participants = @participants

    parse: (json) ->
      json.set_assignment = json.assignment?
      assign_attributes = json.assignment || {}
      assign_attributes.assignment_overrides or= []
      assign_attributes.turnitin_settings or= {}
      json.assignment = @createAssignment(assign_attributes)
      json.publishable = json.can_publish
      json.unpublishable = json.can_unpublish

      json

    createAssignment: (attributes) ->
      assign = new Assignment(attributes)
      assign.alreadyScoped = true
      assign

    # always include assignment in view presentation
    present: =>
      Backbone.Model::toJSON.call(this)

    publish: ->
      @updateOneAttribute('published', true)

    unpublish: ->
      @updateOneAttribute('published', false)

    disabledMessage: -> I18n.t 'cannot_unpublish_with_replies', "Can't unpublish if there are replies"

    topicSubscribe: ->
      baseUrl = _.result this, 'url'
      @set 'subscribed', true
      $.ajaxJSON "#{baseUrl}/subscribed", 'PUT'

    topicUnsubscribe: ->
      baseUrl = _.result this, 'url'
      @set 'subscribed', false
      $.ajaxJSON "#{baseUrl}/subscribed", 'DELETE'

    toJSON: ->
      json = super
      delete json.assignment unless json.set_assignment
      _.extend json,
        summary: @summary()
        unread_count_tooltip: @unreadTooltip()
        reply_count_tooltip: @replyTooltip()
        assignment: json.assignment?.toJSON()
        defaultDates: @defaultDates().toJSON()

    toView: ->
      _.extend @toJSON(),
        name: @get('title')

    unreadTooltip: ->
      I18n.t 'unread_count_tooltip', {
        zero:  'No unread replies.'
        one:   '1 unread reply.'
        other: '%{count} unread replies.'
      }, count: @get('unread_count')

    replyTooltip: ->
      I18n.t 'reply_count_tooltip', {
        zero:  'No replies.'
        one:   '1 reply.'
        other: '%{count} replies.'
      }, count: @get('discussion_subentry_count')

    ##
    # this is for getting the topic 'full view' from the api
    # see: https://<canvas>/doc/api/discussion_topics.html#method.discussion_topics_api.view
    fetchEntries: ->
      baseUrl = _.result this, 'url'
      $.get "#{baseUrl}/view", ({unread_entries, forced_entries, participants, view: entries}) =>
        @unreadEntries = unread_entries
        @forcedEntries = forced_entries
        @participants.reset participants

        # TODO: handle nested replies and 'new_entries' here
        @entries.reset(entries)

    summary: ->
      $('<div/>').html(@get('message')).text() || ''

    # TODO: this would belong in Backbone.model, but I dont know of others are going to need it much
    # or want to commit to this api so I am just putting it here for now
    updateOneAttribute: (key, value, options = {}) ->
      data = {}
      data[key] = value
      @updatePartial(data, options)

    updatePartial: (data, options = {}) ->
      @set(data) unless options.wait
      options = _.defaults options,
        data: JSON.stringify(data)
        contentType: 'application/json'
      @save {}, options

    positionAfter: (otherId) ->
      @updateOneAttribute 'position_after', otherId, wait: true
      collection = @collection
      otherIndex = collection.indexOf collection.get(otherId)
      collection.remove this, silent: true
      collection.models.splice (otherIndex), 0, this
      collection.reset collection.models

    defaultDates: ->
      group = new DateGroup
        due_at:    @dueAt()
        unlock_at: @unlockAt()
        lock_at:   @lockAt()
      return group

    dueAt: ->
      @get('assignment')?.get('due_at')

    unlockAt: ->
      if unlock_at = @get('assignment')?.get('unlock_at')
        return unlock_at
      @get('delayed_post_at')

    lockAt:  ->
      if lock_at = @get('assignment')?.get('lock_at')
        return lock_at
      @get('lock_at')

    updateBucket: (data) ->
      _.defaults data,
        pinned: @get('pinned')
        locked: @get('locked')
      @set('position', null)
      @updatePartial(data)

    groupCategoryId: (id) =>
      return @get( 'group_category_id' ) unless arguments.length > 0
      @set 'group_category_id', id

    canGroup: -> @get('can_group')
