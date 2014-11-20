define [
  'underscore'
  'react'
  'react-router'
  'react-modal'
  '../modules/customPropTypes'
  'i18n!file_preview'
  './FriendlyDatetime'
  'compiled/util/friendlyBytes'
  'compiled/models/Folder'
  'compiled/fn/preventDefault'
  'compiled/react/shared/utils/withReactDOM'
  '../utils/collectionHandler'
  './FilePreviewFooter'
  './FilePreviewInfoPanel',
  '../modules/filesEnv'
], (_, React, ReactRouter, ReactModal, customPropTypes, I18n, FriendlyDatetime, friendlyBytes, Folder, preventDefault, withReactDOM, collectionHandler, FilePreviewFooter, FilePreviewInfoPanel, filesEnv) ->

  FilePreview = React.createClass

    displayName: 'FilePreview'

    mixins: [React.addons.PureRenderMixin, ReactRouter.Navigation]

    propTypes:
      currentFolder: customPropTypes.folder
      query: React.PropTypes.object
      collection: React.PropTypes.object
      params: React.PropTypes.object

    getInitialState: ->
      showInfoPanel: false
      showFooter: false
      showFooterBtn: true
      displayedItem: null

    componentWillMount: ->
      items = @getItemsToView(@props)
      @setState @stateProperties(items, @props)

    componentDidMount: ->
      $('.ReactModal__Overlay').on 'keydown', @handleKeyboardNavigation

    componentWillUnmount: ->
      $('.ReactModal__Overlay').off 'keydown', @handleKeyboardNavigation

    componentWillReceiveProps: (newProps) ->
      items = @getItemsToView(newProps)
      @setState @stateProperties(items, newProps), @scrollFooterToItem

    getItemsToView: (props) ->
      # Sets up our collection that we will be using.
      onlyIdsToPreview = props.query.only_preview?.split(',')
      files = if !!props.query.search_term
                props.collection.models
              else
                props.currentFolder.files.models

      otherItems =  files.filter (file) ->
                      return true unless onlyIdsToPreview
                      file.id in onlyIdsToPreview

      initialItem = (props.query.preview and _.findWhere(files, {id: props.query.preview})) or files[0]

      {initialItem, otherItems}

    stateProperties: (items, props) ->
      initialItem: items.initialItem
      displayedItem: items.initialItem
      otherItems: items.otherItems
      currentFolder: props.currentFolder
      params: props.params
      otherItemsString: (props.query.only_preview if props.query.only_preview)
      otherItemsIsBackBoneCollection: items.otherItems instanceof Backbone.Collection

    scrollFooterToItem: ->
      # Determine if the footer is open.
      if @state.showFooter

        $active = $('.ef-file-preview-footer-active')
        $footerList = $('.ef-file-preview-footer-list')
        footerOffset = $footerList.offset()
        activeOffset = $active.offset()

        # Check if the displayed item thumbnail is hidden to right
        if (activeOffset.left > (footerOffset.left + $footerList.width()))
          $footerList.scrollTo $active
          # @scrollRight()
        # Hidden to the left
        if (activeOffset.left < footerOffset.left )
          $footerList.scrollTo $active
          # @scrollLeft()

    setUpOtherItemsQuery: (otherItems) ->
      otherItems.map((item) ->
        item.id
      ).join(',')

    getRouteIdentifier: ->
      if @props.query.search_term
        'search'
      else if @props.currentFolder?.urlPath()
        'folder'
      else
        'rootFolder'

    getNavigationParams: (opts = {id: null, except: []}) ->
      obj =
        preview: (opts.id if opts.id)
        search_term: (@props.query.search_term if @props.query.search_term)
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

      @transitionTo(@getRouteIdentifier(), @props.params, @getNavigationParams(id: nextItem.id))

    renderArrowLink: (direction) ->
      # TODO: Refactor this to use the collectionHandler
      # Get the current position in the collection
      curItemIndex = @state.otherItems.indexOf(@state.displayedItem)
      switch direction
        when 'left'
          goToItemIndex = curItemIndex - 1
          if goToItemIndex < 0
            goToItemIndex = @state.otherItems.length - 1
        when 'right'
          goToItemIndex = curItemIndex + 1
          if goToItemIndex > @state.otherItems.length - 1
            goToItemIndex = 0
      goToItem = if @state.otherItemsIsBackBoneCollection
        @state.otherItems.at(goToItemIndex)
      else
        @state.otherItems[goToItemIndex]
      if (@state.otherItemsString)
        @props.params.only_preview = @state.otherItemsString
      div {className: 'ef-file-align-center'},
        ReactRouter.Link {
          to: @getRouteIdentifier()
          query: (@getNavigationParams(id: goToItem.id) if goToItem)
          params: @props.params
          className: 'ef-file-preview-container-arrow-link'
        },
          div {className: 'ef-file-preview-arrow-link'},
            i {className: "icon-arrow-open-#{direction}"}



    scrollLeft: (event) ->
      width = $('.ef-file-preview-footer-list').width()
      $('.ef-file-preview-footer-list').animate({
        scrollLeft: '-=' + width
        }, 300, 'easeOutQuad')

    scrollRight: (event) ->
      width = $('.ef-file-preview-footer-list').width()
      $('.ef-file-preview-footer-list').animate({
        scrollLeft: '+=' + width
        }, 300, 'easeOutQuad')

    closeModal: ->
      @transitionTo(@getRouteIdentifier(), @props.params, @getNavigationParams(except: 'only_preview'))

    toggle: (key) ->
      newState = {}
      newState[key] = !@state[key]
      return =>
        @setState(newState)

    render: withReactDOM ->
      ReactModal {isOpen: true, onRequestClose: @closeModal, closeTimeoutMS: 10},
        div {className: 'ef-file-preview-overlay'},
          div {className: 'ef-file-preview-header'},
            h1 {className: 'ef-file-preview-header-filename'},
              @state.initialItem?.displayName()
            div {className: 'ef-file-preview-header-buttons'},
              a {
                className: 'ef-file-preview-header-download ef-file-preview-button'
                download: true
                href: @state.displayedItem?.get('url')
              },
                i {className: 'icon-download'}
                ' ' + I18n.t('file_preview_headerbutton_download', 'Download')
              button {
                type: 'button'
                className: "ef-file-preview-header-info ef-file-preview-button #{if @state.showInfoPanel then 'ef-file-preview-button--active'}"
                onClick: @toggle('showInfoPanel')
              },
                i {className: 'icon-info'}
                ' ' + I18n.t('file_preview_headerbutton_info', 'Info')
              ReactRouter.Link {
                to: @getRouteIdentifier(),
                query: @getNavigationParams(except: 'only_preview'),
                params: @props.params,
                className: 'ef-file-preview-header-close ef-file-preview-button',
              },
                i {className: 'icon-end'}
                ' ' + I18n.t('file_preview_headerbutton_close', 'Close')


          div {className: 'ef-file-preview-stretch'},
            div {className: 'ef-file-preview-content'},
              # We need to render out the left/right arrows
              @renderArrowLink('left') if @state.otherItems?.length > 0
              if @state.displayedItem
                div {className: 'ef-file-preview-viewer-content'},
                  #TODO - we need to figure out how to make this full height
                  iframe {
                    src: "/#{filesEnv.contextType}/#{filesEnv.contextId}/files/#{@state.displayedItem.id}/file_preview"
                    className: 'ef-file-preview-frame'
                  }
              @renderArrowLink('right') if @state.otherItems?.length > 0

              if @state.showInfoPanel
                FilePreviewInfoPanel
                  displayedItem: @state.displayedItem
                  getStatusMessage: @getStatusMessage

          div {className: 'ef-file-preview-footer'},
            if @state.showFooterBtn
              button {
                className: 'ef-file-preview-toggle btn-link'
                onClick: @toggle('showFooter')
                style: {bottom: '140px'} if @state.showFooter
              },
                if @state.showFooter
                  I18n.t('file_preview_hide', 'Hide')
                else
                  I18n.t('file_preview_show', 'Show')

          if @state.showFooter
            FilePreviewFooter
              otherItems: @state.otherItems
              to: @getRouteIdentifier()
              splat: @props.params.splat
              query: @getNavigationParams
              displayedItem: @state.displayedItem


