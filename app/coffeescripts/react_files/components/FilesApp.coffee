define [
  'react'
  'react-router'
  'react-modal'
  'i18n!react_files'
  'compiled/react/shared/utils/withReactElement'
  'compiled/str/splitAssetString'
  './Toolbar'
  'jsx/files/Breadcrumbs'
  'jsx/files/FolderTree'
  'jsx/files/FilesUsage'
  '../mixins/MultiselectableMixin'
  '../mixins/dndMixin'
  '../modules/filesEnv'
], (React, ReactRouter, ReactModal, I18n, withReactElement, splitAssetString, ToolbarComponent, Breadcrumbs, FolderTree, FilesUsage, MultiselectableMixin, dndMixin, filesEnv) ->

  Toolbar = React.createFactory ToolbarComponent
  RouteHandler = React.createFactory ReactRouter.RouteHandler


  FilesApp = React.createClass
    displayName: 'FilesApp'

    mixins: [ ReactRouter.State ]

    onResolvePath: ({currentFolder, rootTillCurrentFolder, showingSearchResults, searchResultCollection, pathname}) ->
      @setState
        currentFolder: currentFolder
        key: @getHandlerKey()
        pathname: pathname
        rootTillCurrentFolder: rootTillCurrentFolder
        showingSearchResults: showingSearchResults
        selectedItems: []
        searchResultCollection: searchResultCollection

    getInitialState: ->
      {
        currentFolder: null
        rootTillCurrentFolder: null
        showingSearchResults: false
        showingModal: false
        pathname: window.location.pathname
        key: @getHandlerKey()
        modalContents: null  # This should be a React Component to render in the modal container.
      }

    mixins: [MultiselectableMixin, dndMixin, ReactRouter.Navigation, ReactRouter.State]

    # For react-router handler keys
    getHandlerKey: ->
      childDepth = 1
      childName = @getRoutes()[childDepth].name
      id = @getParams().id
      key = childName + id
      key

    # for MultiselectableMixin
    selectables: ->
      if @state.showingSearchResults
        @state.searchResultCollection.models
      else
        @state.currentFolder.children(@getQuery())

    getPreviewQuery: ->
      retObj =
        preview: @state.selectedItems[0]?.id or true
      if @state.selectedItems.length > 1
        retObj.only_preview = @state.selectedItems.map((item) -> item.id).join(',')
      if @getQuery()?.search_term
        retObj.search_term = @getQuery().search_term
      retObj

    getPreviewRoute: ->
      if @getQuery()?.search_term
        'search'
      else if @state.currentFolder?.urlPath()
        'folder'
      else
        'rootFolder'

    openModal: (contents, afterClose) ->
      @setState
        modalContents: contents
        showingModal: true
        afterModalClose: afterClose

    closeModal: ->
      @setState(showingModal: false, -> @state.afterModalClose())

    previewItem: (item) ->
      @clearSelectedItems =>
        @toggleItemSelected item, null, =>
          params = {splat: @state.currentFolder?.urlPath()}
          @transitionTo(@getPreviewRoute(), params, @getPreviewQuery())

    render: withReactElement ->
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
        if ENV.use_new_styles and contextType == 'courses'
          div {className: 'ic-app-nav-toggle-and-crumbs ic-app-nav-toggle-and-crumbs--files'},
            button {
              className:'Button Button--link Button--small ic-app-course-nav-toggle',
              type:'button',
              id:'courseMenuToggle',
              title:I18n.t("Show and hide courses menu"),
              'aria-hidden':'true'
            },
              i {
                className:'icon-hamburger'
              }
            div {className:'ic-app-crumbs'},
              Breadcrumbs({
                rootTillCurrentFolder: @state.rootTillCurrentFolder
                showingSearchResults: @state.showingSearchResults
              })
        else
          Breadcrumbs({
            rootTillCurrentFolder: @state.rootTillCurrentFolder
            showingSearchResults: @state.showingSearchResults
          })
        Toolbar({
          currentFolder: @state.currentFolder
          query: @getQuery()
          selectedItems: @state.selectedItems
          clearSelectedItems: @clearSelectedItems
          contextType: contextType
          contextId: contextId
          userCanManageFilesForContext: userCanManageFilesForContext
          usageRightsRequiredForContext: usageRightsRequiredForContext
          getPreviewQuery: @getPreviewQuery
          getPreviewRoute: @getPreviewRoute
          modalOptions:
            openModal: @openModal
            closeModal: @closeModal
        })

        div className: 'ef-main',
          if(filesEnv.newFolderTree)
            p {}, "new folder tree goes here"
          else
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
            RouteHandler
              key: @state.key
              pathname: @state.pathname
              query: @getQuery()
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
              modalOptions:
                openModal: @openModal
                closeModal: @closeModal
              dndOptions:
                onItemDragStart: @onItemDragStart
                onItemDragEnterOrOver: @onItemDragEnterOrOver
                onItemDragLeaveOrEnd: @onItemDragLeaveOrEnd
                onItemDrop: @onItemDrop
              clearSelectedItems: @clearSelectedItems

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
        # This is a placeholder modal instance where we can render arbitrary
        # data into it to show.
        if @state.showingModal
          React.createFactory(ReactModal)({
            isOpen: @state.showingModal,
            onRequestClose: @closeModal,
            closeTimeoutMS: 10,
            className: 'ReactModal__Content--canvas',
            overlayClassName: 'ReactModal__Overlay--canvas'
          },
            @state.modalContents
          )
