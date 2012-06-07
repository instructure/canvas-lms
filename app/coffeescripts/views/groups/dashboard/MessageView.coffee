define [
  'compiled/views/QuickStartBar/MessageView'
], (BaseMessageView) ->

  class MessageView extends BaseMessageView
    
    render: (opts = {}) ->
      super opts
      @$('.recipient_finder').html("&nbsp;")
      $("<input>", 
        type: "hidden",
        name: "recipients[]",
        value: "group_#{ENV.GROUP_ID}")
      .appendTo @$('.course_finder')
      this
