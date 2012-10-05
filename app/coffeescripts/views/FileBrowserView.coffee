define [
  'i18n!filebrowserview'
  'Backbone'
  'underscore'
  'jst/FileBrowserView'
  'compiled/views/FolderTreeView'
  'compiled/models/Folder'
  'compiled/str/splitAssetString'
], (I18n, Backbone, _, template, FolderTreeView, Folder, splitAssetString) ->

  class FileBrowserView extends Backbone.View

    template: template

    rootFolders: ->
      # purposely sharing these across instances of FileBrowserView
      # use a 'custom_name' to set I18n'd names for the root folders (the actual names are hard-coded)
      FileBrowserView.rootFolders ||= do ->
        contextFiles = null
        contextTypeAndId = splitAssetString(ENV.context_asset_string || '')
        if contextTypeAndId && contextTypeAndId.length == 2 && (contextTypeAndId[0] == 'courses' || contextTypeAndId[0] == 'groups')
          contextFiles = new Folder
          contextFiles.set 'custom_name', if contextTypeAndId[0] is 'courses' then I18n.t('course_files', 'Course files') else I18n.t('group_files', 'Group files') 
          contextFiles.url = "/api/v1/#{contextTypeAndId[0]}/#{contextTypeAndId[1]}/folders/root"
          contextFiles.fetch()

        myFiles = new Folder
        myFiles.set 'custom_name', I18n.t('my_files', 'My files')
        myFiles.url = '/api/v1/users/self/folders/root'
        myFiles.fetch()
        
        result = []
        result.push contextFiles if contextFiles
        result.push myFiles
        result

    initialize: ->
      @contentTypes = @options?.contentTypes
      super
      
    afterRender: ->
      @$folderTree = @$el.children('.folderTree')
      for folder in @rootFolders()
        new FolderTreeView({model: folder, contentTypes: @contentTypes}).$el.appendTo(@$folderTree)
      super
      