define [
  'compiled/views/QuickStartBar/AnnouncementView'
], (BaseAnnouncementView) ->

  class AnnouncementView extends BaseAnnouncementView
    
    render: (opts = {}) ->
      super opts
      @$('.course_finder').html("&nbsp;")
      this
