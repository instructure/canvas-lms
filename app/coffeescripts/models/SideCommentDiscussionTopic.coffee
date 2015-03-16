define [
  'compiled/arr/walk'
  'compiled/models/Topic'
], (walk, MaterializedDiscussionTopic) ->

  class SideCommentDiscussionTopic extends MaterializedDiscussionTopic

    ##
    # restructures `@data.entries` so all ancestors become children of root
    # entries, sorted by creation date as they would have been in the first
    # place if the discussion had never been threaded, allows seemless
    # transitioning from threaded to side-comment
    parse: ->
      super
      flat = {}
      for id, entry of @flattened when not entry.root_entry_id
        flat[entry.id] = entry
        entry.replies = []

      for id, entry of @flattened when entry.root_entry_id
        delete entry.replies
        parent = flat[entry.root_entry_id]
        parent.replies.push entry
        entry.parent = parent
        entry.parent_id = parent.id

      @data.entries = for id, entry of flat
        entry.replies.sort (a, b) ->
          Date.parse(b.created_at) - Date.parse(a.created_at)
        entry
      @data
