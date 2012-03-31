define [
  'use!backbone'
  'compiled/discussions/Entry'
], (Backbone, Entry) ->

  ##
  # Collection for Entries
  class EntryCollection extends Backbone.Collection

    model: Entry

