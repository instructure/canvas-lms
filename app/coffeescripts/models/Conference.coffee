define [
  'underscore'
  'Backbone'
], (_, {Model}) ->

  class Conference extends Model
    urlRoot: ->
      url = @get('url')
      url.replace(/([^\/]*$)/, '')

    special_urls: ->
      join_url: @get('url') + '/join'
      close_url: @get('url') + '/close'

    recordings_data: ->
      recording: @get('recordings')[0]
      recordingCount: @get('recordings').length
      multipleRecordings: @get('recordings').length > 1

    permissions_data: ->
      has_actions: @get('permissions')['edit'] || @get('permissions')['delete']
      show_end: @get('permissions')['close'] && @get('started_at') && !@get('ended_at')

    schedule_data: ->
      scheduled: 'scheduled_date' of @get('user_settings')
      scheduled_at: @get('user_settings').scheduled_date

    toJSON: ->
      json = super
      for attr in ['special_urls', 'recordings_data', 'schedule_data', 'permissions_data']
        _.extend(json, @[attr]())
      json
