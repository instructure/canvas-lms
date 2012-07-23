define [
  'compiled/views/QuickStartBar/AnnouncementView'
], (BaseAnnouncementView) ->

  class AnnouncementView extends BaseAnnouncementView
    
    render: (opts = {}) ->
      super opts
      @$('.course_finder').html("&nbsp;")
      $("<input>", 
        type: "hidden",
        name: "context_ids[]",
        value: "group_#{ENV.GROUP_ID}")
      .appendTo @$('.course_finder')
      this
