define [
  'jquery'
  'underscore'
  'react'
  'react-router'
  'react-modal'
  '../modules/customPropTypes'
  'Backbone'
  'i18n!file_preview'
  'compiled/util/friendlyBytes'
  'compiled/models/Folder'
  'compiled/models/File'
  'compiled/models/FilesystemObject'
  'compiled/fn/preventDefault'
  '../utils/collectionHandler'
  'jsx/files/FilePreviewInfoPanel'
  '../modules/filesEnv'
  '../modules/FocusStore'
  'jsx/files/codeToRemoveLater'
], ($, _, React, ReactRouter, ReactModal, customPropTypes, Backbone, I18n, friendlyBytes, Folder, File, FilesystemObject, preventDefault, collectionHandler, FilePreviewInfoPanel, filesEnv, FocusStore, codeToRemoveLater) ->

  FilePreview =

    displayName: 'FilePreview'

    mixins: [React.addons.PureRenderMixin, ReactRouter.Navigation, ReactRouter.State]

    propTypes:
      currentFolder: customPropTypes.folder
      query: React.PropTypes.object
      collection: React.PropTypes.object
      params: React.PropTypes.object
      isOpen: React.PropTypes.bool

    getInitialState: ->
      showInfoPanel: false
      displayedItem: null

    componentWillMount: ->
      if(@props.isOpen)
        items = @getItemsToView @props, (items) =>
          @setState @stateProperties(items, @props)

    componentDidMount: ->
      $('.ReactModal__Overlay').on 'keydown', @handleKeyboardNavigation
      codeToRemoveLater.hideFileTreeFromPreviewInJaws()

    componentWillUnmount: ->
      $('.ReactModal__Overlay').off 'keydown', @handleKeyboardNavigation
      codeToRemoveLater.revertJawsChangesBackToNormal()

    componentWillReceiveProps: (newProps) ->
      if(newProps.isOpen)
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

      otherItems =  files.filter (file) ->
                      return true unless onlyIdsToPreview
                      file.id in onlyIdsToPreview

      visibleFile = @getQuery().preview and _.findWhere(files, {id: @getQuery().preview})

      if !visibleFile
        responseDataRequested = ["enhanced_preview_url"]
        responseDataRequested.push("usage_rights") if props.usageRightsRequiredForContext
        new File({id: @getQuery().preview}, {preflightUrl: 'no/url/needed'}).fetch(data: $.param({"include": responseDataRequested})).success (file) ->
          initialItem = new FilesystemObject(file)
          cb?({initialItem, otherItems})
      else
        initialItem = visibleFile or (files[0] if files.length)

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

      # TODO Remove this jQuery line once react modal is upgraded. It should clean
      # itself up after unmounting but it doesn't so using this quick fix for now
      # until everything is upgraded.
      $('#application').removeAttr('aria-hidden')
      ############## kill me #####################

      @transitionTo(@getRouteIdentifier(), @getParams(), @getNavigationParams(except: 'only_preview'))
      FocusStore.setFocusToItem()

    toggle: (key) ->
      newState = {}
      newState[key] = !@state[key]
      return =>
        @setState newState
