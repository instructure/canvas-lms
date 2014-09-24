define [
  'react'
  'i18n!react_files'
  'compiled/react/shared/utils/withReactDOM'
  'compiled/str/splitAssetString'
  './Toolbar'
  './Breadcrumbs'
  './FolderTree'
  './FilesUsage'
  '../mixins/MultiselectableMixin'
  '../modules/filesEnv'
], (React, I18n, withReactDOM, splitAssetString, Toolbar, Breadcrumbs, FolderTree, FilesUsage, MultiselectableMixin, filesEnv) ->

  FilesApp = React.createClass
    displayName: 'FilesApp'

    onResolvePath: ({currentFolder, rootTillCurrentFolder, showingSearchResults, searchResultCollection}) ->
      @setState
        currentFolder: currentFolder
        rootTillCurrentFolder: rootTillCurrentFolder
        showingSearchResults: showingSearchResults
        selectedItems: []
        searchResultCollection: searchResultCollection

    getInitialState: ->
      {
        currentFolder: undefined
        rootTillCurrentFolder: undefined
        showingSearchResults: false
        selectedItems: undefined
      }

    mixins: [MultiselectableMixin]

    # for MultiselectableMixin
    selectables: ->
      if @state.showingSearchResults
        @state.searchResultCollection.models
      else
        @state.currentFolder.children(@props.query)

    render: withReactDOM ->
      if @state.currentFolder # when showing a folder
        contextType = @state.currentFolder.get('context_type').toLowerCase() + 's'
        contextId = @state.currentFolder.get('context_id')
      else # when showing search results
        contextType = filesEnv.contextType
        contextId = filesEnv.contextId

      userCanManageFilesForContext = filesEnv.userHasPermission({contextType: contextType, contextId: contextId}, 'manage_files')

      div null,
        Breadcrumbs({
          rootTillCurrentFolder: @state.rootTillCurrentFolder
          query: @props.query
          showingSearchResults: @state.showingSearchResults
        })
        Toolbar({
          currentFolder: @state.currentFolder
          query: @props.query
          selectedItems: @state.selectedItems
          clearSelectedItems: @clearSelectedItems
          contextType: contextType
          contextId: contextId
          userCanManageFilesForContext: userCanManageFilesForContext
        })

        div className: 'ef-main',
          aside {
            className: 'visible-desktop ef-folder-content'
            role: 'region'
            'aria-label' : I18n.t('folder_browsing_tree', 'Folder Browsing Tree')
          },
            FolderTree({
              rootTillCurrentFolder: @state.rootTillCurrentFolder
              rootFoldersToShow: filesEnv.rootFolders
            })
          div {
            className:'ef-directory'
            role: 'region'
            'aria-label' : I18n.t('file_list', 'File List')
          },
            @props.activeRouteHandler
              onResolvePath: @onResolvePath
              currentFolder: @state.currentFolder
              contextType: contextType
              contextId: contextId
              selectedItems: @state.selectedItems
              toggleItemSelected: @toggleItemSelected
              toggleAllSelected: @toggleAllSelected
              areAllItemsSelected: @areAllItemsSelected
              userCanManageFilesForContext: userCanManageFilesForContext
        div className: 'ef-footer grid-row',
          if userCanManageFilesForContext
            FilesUsage({
              className: 'col-xs-3'
              contextType: contextType
              contextId: contextId
            })
          unless filesEnv.showingAllContexts
            div className: 'col-xs',
              div {},
                a className: 'pull-right', href: '/files?show_all_contexts=1',
                  I18n.t('all_my_files', 'All My Files')
