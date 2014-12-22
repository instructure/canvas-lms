define [
  'i18n!rootFoldersFinder'
  'compiled/models/Folder'
  'compiled/str/splitAssetString'
], (I18n, Folder, splitAssetString) ->

  class RootFoldersFinder
    constructor: (opts) ->
      @rootFoldersToShow = opts.rootFoldersToShow
      @contentTypes = opts.contentTypes

    find: ->
      return @rootFoldersToShow if @rootFoldersToShow
      # purposely sharing these across instances of RootFoldersFinder
      # use a 'custom_name' to set I18n'd names for the root folders (the actual names are hard-coded)
      RootFoldersFinder.rootFolders ||= do =>
        contextFiles = null
        contextTypeAndId = splitAssetString(ENV.context_asset_string || '')
        if contextTypeAndId && contextTypeAndId.length == 2 && (contextTypeAndId[0] == 'courses' || contextTypeAndId[0] == 'groups')
          contextFiles = new Folder({contentTypes: @contentTypes})
          contextFiles.set 'custom_name', if contextTypeAndId[0] is 'courses' then I18n.t('course_files', 'Course files') else I18n.t('group_files', 'Group files') 
          contextFiles.url = "/api/v1/#{contextTypeAndId[0]}/#{contextTypeAndId[1]}/folders/root"
          contextFiles.fetch()

        myFiles = new Folder({contentTypes: @contentTypes})
        myFiles.set 'custom_name', I18n.t('my_files', 'My files')
        myFiles.url = '/api/v1/users/self/folders/root'
        myFiles.fetch()

        result = []
        result.push contextFiles if contextFiles
        result.push myFiles
        result