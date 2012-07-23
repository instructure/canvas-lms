define [
  'compiled/views/QuickStartBar/DiscussionView'
], (BaseDiscussionView) ->

  class DiscussionView extends BaseDiscussionView
    
    render: (opts = {}) ->
      super opts
      @$('.course_finder').html("&nbsp;")
      $("<input>",
        type: "hidden",
        name: "context_ids[]",
        value: "group_#{ENV.GROUP_ID}")
      .appendTo @$('.course_finder')
      this
