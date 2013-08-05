define [
  'Backbone'
  'underscore'
  'compiled/fn/preventDefault'
  'compiled/models/Folder'
  'jst/FolderTreeItem'
], (Backbone, _, preventDefault, Folder, template) ->

  class FileItemView extends Backbone.View
    tagName: 'li'
    attributes:
      'role': 'treeitem'
    template: template