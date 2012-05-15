define [
  'Backbone'
  'compiled/home/models/quickStartBar/Announcement'
  'jst/quickStartBar/announcement'
  'jquery.instructure_date_and_time'
], ({View}, Announcement, template) ->

  class AnnouncementView extends View

    initialize: ->
      @model or= new Announcement

    render: ->
      html = template @model.toJSON
      @$el.html html
      @filter()
    
    filter: ->
      console.profile 'datetime field'
      @$('.dateField').datetime_field()
      console.profileEnd 'datetime field'

