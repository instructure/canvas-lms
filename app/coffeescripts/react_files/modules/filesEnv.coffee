define [
  'compiled/models/Folder'
  'compiled/str/splitAssetString'
], (Folder, splitAssetString) ->

  fileContexts = ENV.FILES_CONTEXTS or []
  newFolderTree = ENV.NEW_FOLDER_TREE
  newFolderTree = false if newFolderTree == undefined

  filesEnv =
    newFolderTree: newFolderTree
    contexts: fileContexts

    contextsDictionary: fileContexts.reduce (dict, context)  ->
      [contextType, contextId] = splitAssetString(context.asset_string)
      context.contextType = contextType
      context.contextId = contextId
      dict[[contextType, contextId].join('_')] = context
      dict
    , {}

    showingAllContexts: window.location.pathname.match(/^\/files/) # does the url start with '/files' ?

    contextType: fileContexts[0]?.contextType
    contextId: fileContexts[0]?.contextId

    rootFolders: fileContexts.map (contextData) ->
      if ENV.current_user_id
        folder = new Folder({
          'custom_name': contextData.name
          'context_type': contextData.contextType.replace(/s$/, '') #singularize it
          'context_id': contextData.contextId
        })
        folder.url = "/api/v1/#{contextData.contextType}/#{contextData.contextId}/folders/root"
        folder.fetch()
        folder

  filesEnv.contextFor = (folderOrFile) ->
    if folderOrFile.collection?.parentFolder
      folderOrFile = folderOrFile.collection.parentFolder
    if folderOrFile instanceof Folder
      folder =  folderOrFile
      assetString = (folder?.get('context_type') + 's_' + folder?.get('context_id')).toLowerCase()
    else if folderOrFile.contextType and folderOrFile.contextId
      assetString = "#{folderOrFile.contextType}_#{folderOrFile.contextId}".toLowerCase()
    filesEnv.contextsDictionary?[assetString]

  filesEnv.userHasPermission = (folderOrFile, action) ->
    return false unless folderOrFile

    filesEnv.contextFor(folderOrFile)?.permissions?[action]

  filesEnv.baseUrl =  if filesEnv.showingAllContexts
                        '/files'
                      else
                        "/#{filesEnv.contextType}/#{filesEnv.contextId}/files"


  filesEnv
