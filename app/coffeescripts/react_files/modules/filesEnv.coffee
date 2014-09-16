define [
  'compiled/models/Folder'
  'compiled/str/splitAssetString'
], (Folder, splitAssetString) ->



  filesEnv =

    contexts: ENV.FILES_CONTEXTS

    contextsDictionary: ENV.FILES_CONTEXTS.reduce (dict, context)  ->
      [contextType, contextId] = splitAssetString(context.asset_string)
      context.contextType = contextType
      context.contextId = contextId
      dict[[contextType, contextId].join('_')] = context
      dict
    , {}

    showingAllContexts: window.location.pathname.match(/^\/files/) # does the url start with '/files' ?

    contextType: ENV.FILES_CONTEXTS[0].contextType
    contextId: ENV.FILES_CONTEXTS[0].contextId

    rootFolders: ENV.FILES_CONTEXTS.map (contextData) ->
      folder = new Folder({
        'custom_name': contextData.name
        'context_type': contextData.contextType.replace(/s$/, '') #singularize it
        'context_id': contextData.contextId
        'id': contextData.root_folder_id
      })
      folder.url = "/api/v1/#{contextData.contextType}/#{contextData.contextId}/folders/root"
      folder

    userHasPermission: (folderOrFile, action) ->
      folder = if folderOrFile instanceof Folder
        folderOrFile
      else
        folderOrFile.collection.parentFolder

      assetString = (folder.get('context_type') + 's_' + folder.get('context_id')).toLowerCase()
      filesEnv.contextsDictionary[assetString]?.permissions?[action]



  filesEnv.baseUrl = if filesEnv.showingAllContexts
    '/files'
  else
    "/#{filesEnv.contextType}/#{filesEnv.contextId}/files"


  return filesEnv
