define [
  'compiled/models/Topic'
], ( Topic ) ->
  QUnit.module "Topic"

#  test "#parse should set author on view entries", ->
#    topic = new Topic
#    participant = id: 1
#    entry = id: 1, user_id: participant.id
#    data = topic.parse
#      participants: [participant]
#      view: [entry]
#      new_entries: []
#      unread_entries: []
#    strictEqual data.entries[0].author, participant

  test "#parse should set author on new entries", ->
    topic = new Topic
    participant = id: 1
    entry = id: 1, user_id: participant.id
    data = topic.parse
      participants: [participant]
      view: []
      new_entries: [entry]
      unread_entries: []
      forced_entries: []
      entry_ratings: {}
    strictEqual data.entries[0].author, participant
