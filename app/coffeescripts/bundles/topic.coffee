require [
  'jquery'
  'compiled/discussionEntryReadMarker'
  'topic'
], ($, discussionEntryReadMarker) ->
  setTimeout ->
    discussionEntryReadMarker.init()
  , 100
