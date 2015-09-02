define [
  'jquery'
  'underscore'
  'react'
  'react-router'
  'react-modal'
  '../modules/customPropTypes'
  'i18n!file_preview'
  'jsx/files/FriendlyDatetime'
  'compiled/util/friendlyBytes'
  'compiled/models/Folder'
  'compiled/models/File'
  'compiled/models/FilesystemObject'
  'compiled/fn/preventDefault'
  'compiled/react/shared/utils/withReactElement'
  '../utils/collectionHandler'
  'jsx/files/FilePreviewInfoPanel'
  '../modules/filesEnv'
  '../modules/FocusStore'
], ($, _, React, ReactRouter, ReactModal, customPropTypes, I18n, FriendlyDatetimeComponent, friendlyBytes, Folder, File, FilesystemObject, preventDefault, withReactElement, collectionHandler, FilePreviewInfoPanel, filesEnv, FocusStore) ->

  FriendlyDatetime = React.createFactory FriendlyDatetimeComponent
  Link = React.createFactory ReactRouter.Link

  FilePreview =

    displayName: 'FilePreview'

    mixins: [React.addons.PureRenderMixin, ReactRouter.Navigation, ReactRouter.State]

    propTypes:
      currentFolder: customPropTypes.folder
      query: React.PropTypes.object
      collection: React.PropTypes.object
      params: React.PropTypes.object

    getInitialState: ->
      showInfoPanel: false
      displayedItem: null

    componentWillMount: ->
      items = @getItemsToView @props, (items) =>
        @setState @stateProperties(items, @props)

    componentDidMount: ->
      $('.ReactModal__Overlay').on 'keydown', @handleKeyboardNavigation

    componentWillUnmount: ->
      $('.ReactModal__Overlay').off 'keydown', @handleKeyboardNavigation

    componentWillReceiveProps: (newProps) ->
      items = @getItemsToView newProps, (items) =>
        @setState @stateProperties(items, newProps)

    getItemsToView: (props, cb) ->
      # Sets up our collection that we will be using.
      initialItem = null
      onlyIdsToPreview = @getQuery().only_preview?.split(',')
      files = if !!@getQuery().search_term
                props.collection.models
              else
                props.currentFolder.files.models
      folders = props.currentFolder.folders.models

      items = files.concat folders
      otherItems =  items.filter (item) ->
                      return true unless onlyIdsToPreview
                      item.id in onlyIdsToPreview

      visibleFile = @getQuery().preview and _.findWhere(files, {id: @getQuery().preview})
      visibleFolder = @getQuery().preview and _.findWhere(folders, {id: @getQuery().preview})

      if !visibleFile and !visibleFolder
        responseDataRequested = ["enhanced_preview_url"]
        responseDataRequested.push("usage_rights") if props.usageRightsRequiredForContext
        new File({id: @getQuery().preview}, {preflightUrl: 'no/url/needed'}).fetch(data: $.param({"include": responseDataRequested})).success (file) ->
          initialItem = new FilesystemObject(file)
          cb?({initialItem, otherItems})
      else
        if visibleFile
          initialItem = visibleFile or (files[0] if files.length)
        else if visibleFolder
          initialItem = visibleFolder or (folders[0] if folder.length)

        cb?({initialItem, otherItems})

    stateProperties: (items, props) ->
      initialItem: items.initialItem
      displayedItem: items.initialItem
      otherItems: items.otherItems
      currentFolder: props.currentFolder
      params: props.params
      otherItemsString: (@getQuery().only_preview if @getQuery().only_preview)
      otherItemsIsBackBoneCollection: items.otherItems instanceof Backbone.Collection

    setUpOtherItemsQuery: (otherItems) ->
      otherItems.map((item) ->
        item.id
      ).join(',')

    getRouteIdentifier: ->
      if @getQuery().search_term
        'search'
      else if @props.currentFolder?.urlPath()
        'folder'
      else
        'rootFolder'

    getNavigationParams: (opts = {id: null, except: []}) ->
      obj =
        preview: (opts.id if opts.id)
        search_term: (@getQuery().search_term if @getQuery().search_term)
        only_preview: (@state.otherItemsString if @state.otherItemsString)

      _.each obj, (v, k) ->
        delete obj[k] if not v or (opts.except?.length and (opts.except is k or k in opts.except))

      obj


    handleKeyboardNavigation: (event) ->
      return null unless (event.keyCode is $.ui.keyCode.LEFT or event.keyCode is $.ui.keyCode.RIGHT)
      # left arrow
      if (event.keyCode is $.ui.keyCode.LEFT)
        nextItem = collectionHandler.getPreviousInRelationTo(@state.otherItems, @state.displayedItem)

      # right arrow
      if (event.keyCode is $.ui.keyCode.RIGHT)
        nextItem = collectionHandler.getNextInRelationTo(@state.otherItems, @state.displayedItem)

      @transitionTo(@getRouteIdentifier(), @getParams(), @getNavigationParams(id: nextItem.id))

    closeModal: ->
      @transitionTo(@getRouteIdentifier(), @getParams(), @getNavigationParams(except: 'only_preview'))
      FocusStore.setFocusToItem()

    toggle: (key) ->
      newState = {}
      newState[key] = !@state[key]
      return =>
        @setState newState