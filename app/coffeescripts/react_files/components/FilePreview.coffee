define [
  'jquery'
  'underscore'
  'react'
  'react-addons-pure-render-mixin'
  'page'
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
  'compiled/jquery.rails_flash_notifications'
], ($, _, React, PureRenderMixin, page, ReactModal, customPropTypes, Backbone, I18n, friendlyBytes, Folder, File, FilesystemObject, preventDefault, collectionHandler, FilePreviewInfoPanel, filesEnv, FocusStore, codeToRemoveLater) ->

  FilePreview =

    displayName: 'FilePreview'

    mixins: [PureRenderMixin]

    propTypes:
      currentFolder: customPropTypes.folder
      query: React.PropTypes.object
      collection: React.PropTypes.object
      params: React.PropTypes.object
      isOpen: React.PropTypes.bool
      closePreview: React.PropTypes.func

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
      onlyIdsToPreview = props.query.only_preview?.split(',')
      files = if !!props.query.search_term
                props.collection.models
              else
                props.currentFolder.files.models

      otherItems =  files.filter (file) ->
                      return true unless onlyIdsToPreview
                      file.id in onlyIdsToPreview

      visibleFile = props.query.preview and _.findWhere(files, {id: props.query.preview})

      if !visibleFile
        responseDataRequested = ["enhanced_preview_url"]
        responseDataRequested.push("usage_rights") if props.usageRightsRequiredForContext
        new File({id: props.query.preview}, {preflightUrl: 'no/url/needed'}).fetch(data: $.param({"include": responseDataRequested})).success (file) ->
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
      otherItemsString: (props.query.only_preview if props.query.only_preview)
      otherItemsIsBackBoneCollection: items.otherItems instanceof Backbone.Collection

    setUpOtherItemsQuery: (otherItems) ->
      otherItems.map((item) ->
        item.id
      ).join(',')

    getNavigationParams: (opts = {id: null, except: []}) ->
      obj =
        preview: (opts.id if opts.id)
        search_term: (@props.query.search_term if @props.query.search_term)
        only_preview: (@state.otherItemsString if @state.otherItemsString)
        sort: (@props.query.sort if @props.query.sort)
        order: (@props.query.order if @props.query.order)

      _.each obj, (v, k) ->
        delete obj[k] if not v or (opts.except?.length and (opts.except is k or k in opts.except))

      obj

    toggle: (key) ->
      newState = {}
      newState[key] = !@state[key]
      return =>
        @setState newState, ->
          if (key == 'showInfoPanel' && @state.showInfoPanel)
            $.screenReaderFlashMessage(I18n.t('Info panel displayed'))
          else
            $.screenReaderFlashMessage(I18n.t('Info panel hidden'))
