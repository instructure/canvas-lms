require [
  'compiled/conversations/Inbox'
], (Inbox) ->
  new Inbox(ENV.CONVERSATIONS)