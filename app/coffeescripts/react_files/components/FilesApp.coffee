define [
  'old_unsupported_dont_use_react'
  'old_unsupported_dont_use_react-router'
  'i18n!react_files'
  'compiled/react/shared/utils/withReactDOM'
  'compiled/str/splitAssetString'
  './Toolbar'
  './Breadcrumbs'
  './FolderTree'
  './FilesUsage'
  '../mixins/MultiselectableMixin'
  '../mixins/dndMixin'
  '../modules/filesEnv'
], (React, ReactRouter, I18n, withReactDOM, splitAssetString, Toolbar, Breadcrumbs, FolderTree, FilesUsage, MultiselectableMixin, dndMixin, filesEnv) ->

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

    mixins: [MultiselectableMixin, dndMixin, ReactRouter.Navigation]

    # for MultiselectableMixin
    selectables: ->
      if @state.showingSearchResults
        @state.searchResultCollection.models
      else
        @state.currentFolder.children(@props.query)

    getPreviewQuery: ->
      retObj =
        preview: @state.selectedItems[0]?.id or true
      if @state.selectedItems.length > 1
        retObj.only_preview = @state.selectedItems.map((item) -> item.id).join(',')
      if @props.query?.search_term
        retObj.search_term = @props.query.search_term
      retObj

    getPreviewRoute: ->
      if @props.query?.search_term
        'search'
      else if @state.currentFolder?.urlPath()
        'folder'
      else
        'rootFolder'

    previewItem: (item) ->
      @clearSelectedItems =>
        @toggleItemSelected item, null, =>
          params = {splat: @state.currentFolder?.urlPath()}
          @transitionTo(@getPreviewRoute(), params, @getPreviewQuery())

    render: withReactDOM ->
      if @state.currentFolder # when showing a folder
        contextType = @state.currentFolder.get('context_type').toLowerCase() + 's'
        contextId = @state.currentFolder.get('context_id')
      else # when showing search results
        contextType = filesEnv.contextType
        contextId = filesEnv.contextId

      userCanManageFilesForContext = filesEnv.userHasPermission({contextType: contextType, contextId: contextId}, 'manage_files')
      usageRightsRequiredForContext = filesEnv.contextsDictionary["#{contextType}_#{contextId}"]?.usage_rights_required
      externalToolsForContext = filesEnv.contextFor({contextType: contextType, contextId: contextId})?.file_menu_tools || []

      div null,
        # For whatever reason, VO in Safari didn't like just the h1 tag.
        # Sometimes it worked, others it didn't, this makes it work always
        header {},
          h1 {className: 'screenreader-only'},
              I18n.t('files_heading', "Files")
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
          usageRightsRequiredForContext: usageRightsRequiredForContext
          getPreviewQuery: @getPreviewQuery
          getPreviewRoute: @getPreviewRoute
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
              dndOptions:
                onItemDragEnterOrOver: @onItemDragEnterOrOver
                onItemDragLeaveOrEnd: @onItemDragLeaveOrEnd
                onItemDrop: @onItemDrop
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
              usageRightsRequiredForContext: usageRightsRequiredForContext
              externalToolsForContext: externalToolsForContext
              previewItem: @previewItem
              dndOptions:
                onItemDragStart: @onItemDragStart
                onItemDragEnterOrOver: @onItemDragEnterOrOver
                onItemDragLeaveOrEnd: @onItemDragLeaveOrEnd
                onItemDrop: @onItemDrop

        div className: 'ef-footer grid-row',
          if userCanManageFilesForContext
            FilesUsage({
              className: 'col-xs-4'
              contextType: contextType
              contextId: contextId
            })
          unless filesEnv.showingAllContexts
            div className: 'col-xs',
              div {},
                a className: 'pull-right', href: '/files',
                  I18n.t('all_my_files', 'All My Files')
