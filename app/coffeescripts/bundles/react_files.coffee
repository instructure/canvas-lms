require [
  'compiled/react_files/FilesRouter'
  'Backbone'
  'compiled/str/splitAssetString'
], (FilesRouter, Backbone, splitAssetString) ->

  [contextType, contextId] = splitAssetString(ENV.context_asset_string)
  contextId = Number(contextId)

  baseUrl = if contextType is 'user'
    '/files'
  else
    "/#{contextType}/#{contextId}/files"


  new FilesRouter({contextType, contextId})

  Backbone.history.start
    pushState: true
    hashChange: false
    root: baseUrl