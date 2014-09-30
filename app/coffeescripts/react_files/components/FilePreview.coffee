define [
  'underscore',
  'react'
  'react-router',
  'bower/react-modal/dist/react-modal'
  'i18n!file_preview'
  './FriendlyDatetime'
  'compiled/models/Folder',
  'compiled/react/shared/utils/withReactDOM'
  '../utils/collectionHandler'
], (_, React, ReactRouter, ReactModal, I18n, FriendlyDatetime, Folder, withReactDOM, collectionHandler) ->
  FilePreview = React.createClass


    displayName: 'FilePreview'

    mixins: [React.addons.PureRenderMixin]

    propTypes:
      initialItem: React.PropTypes.object
      otherItems: React.PropTypes.array
      otherItemsString: React.PropTypes.string

    getInitialState: ->
      showInfoPanel: false
      showFooter: false
      showFooterBtn: true
      displayedItem: @props.initialItem
      user: @props.initialItem.get 'user'
      otherItemsIsBackBoneCollection: @props.otherItems instanceof Backbone.Collection

    componentWillMount: ->
      ReactModal.setAppElement(@props.appElement)

    componentDidMount: ->
      $('.ReactModal__Overlay').on 'keydown', @handleKeyboardNavigation

    componentWillUnmount: ->
      $('.ReactModal__Overlay').off 'keydown', @handleKeyboardNavigation

    componentWillReceiveProps: (newProps) ->
      @setState(
        displayedItem: newProps.initialItem
        user: newProps.initialItem.get 'user'
        otherItemPreviewString: @setUpOtherItemsQuery(newProps.otherItems)
      )

    setUpOtherItemsQuery: (otherItems) ->
      otherItems.map((item) ->
        item.id
      ).join(',')

    openInfoPanel: (event) ->
      event.preventDefault()
      @setState({showInfoPanel: !@state.showInfoPanel});

    toggleFooter: (event) ->
      event.preventDefault()
      @setState({showFooter: !@state.showFooter});

    handleKeyboardNavigation: (event) ->
      return null unless (event.keyCode is 37 or event.keyCode is 39)
      # left arrow
      if (event.keyCode is 37)
        nextItem = collectionHandler.getPreviousInRelationTo(@props.otherItems, @state.displayedItem)

      # right arrow
      if (event.keyCode is 39)
        nextItem = collectionHandler.getNextInRelationTo(@props.otherItems, @state.displayedItem)

      if (@props.otherItemsString)
        ReactRouter.transitionTo((if @props.params.splat then 'folder' else 'rootFolder'), @props.params, {preview: nextItem.id, only_preview: @props.otherItemsString})
      else
        ReactRouter.transitionTo((if @props.params.splat then 'folder' else 'rootFolder'), @props.params, {preview: nextItem.id})

    getStatusMessage: ->
      'A nice status message ;) ' #TODO: Actually do this..

    renderPreview: ->
      fileNameParts = @state.displayedItem.displayName().split('.')
      fileExt = fileNameParts[fileNameParts.length - 1].toUpperCase()
      contentType = @state.displayedItem.get('content-type')
      div {className: if @state.showInfoPanel then 'ef-file-preview-item full-height col-xs-6' else 'ef-file-preview-item full-height col-xs-10'},
      if contentType.substring(0, contentType.indexOf('/')) is 'image'
        img {className: 'ef-file-preview-image' ,src: @state.displayedItem.get('url')}
      else
        h1 {className: 'ef-file-preview-not-available'},
          "Previewing a #{fileExt} file is not yet available."

    renderArrowLink: (direction) ->
      # TODO: Refactor this to use the collectionHandler
      # Get the current position in the collection
      curItemIndex = @props.otherItems.indexOf(@state.displayedItem)
      switch direction
        when 'left'
          goToItemIndex = curItemIndex - 1;
          if goToItemIndex < 0
            goToItemIndex = @props.otherItems.length - 1
        when 'right'
          goToItemIndex = curItemIndex + 1;
          if goToItemIndex > @props.otherItems.length - 1
            goToItemIndex = 0
      goToItem = if @state.otherItemsIsBackBoneCollection then @props.otherItems.at(goToItemIndex) else @props.otherItems[goToItemIndex]
      if (@props.otherItemsString)
        @props.params.only_preview = @props.otherItemsString
      switch direction
        when 'left'
          div {className: 'col-xs-1 full-height'},
            ReactRouter.Link _.defaults({to: (if @props.params.splat then 'folder' else 'rootFolder'), query: {preview: goToItem.id}, className: 'ef-file-preview-arrow-link'}, @props.params),
              div {className: 'ef-file-preview-arrow'},
                i {className: 'icon-arrow-open-left'}
        when 'right'
          div {className: 'col-xs-1 full-height'},
            ReactRouter.Link _.defaults({to: (if @props.params.splat then 'folder' else 'rootFolder'), query: {preview: goToItem.id}, className: 'ef-file-preview-arrow-link'}, @props.params),
              div {className: 'ef-file-preview-arrow'},
                i {className: 'icon-arrow-open-right'}


    scrollLeft: (event) ->
      width = $('.ef-file-preview-footer-list').width();
      console.log("left scroll");
      $('.ef-file-preview-footer-list').animate({
        scrollLeft: '-=' + width
        }, 300, 'easeOutQuad')

    scrollRight: (event) ->
      width = $('.ef-file-preview-footer-list').width();
      console.log("right scroll");
      $('.ef-file-preview-footer-list').animate({
        scrollLeft: '+=' + width
        }, 300, 'easeOutQuad')

    closeModal: ->
      ReactRouter.transitionTo((if @props.params.splat then 'folder' else 'rootFolder'), @props.params)



    render: withReactDOM ->
      ReactModal {isOpen: true, onRequestClose: @closeModal, closeTimeoutMS: 10},
        div {className: 'ef-file-preview-overlay'},
          div {className: 'ef-file-preview-container'},
            div {className: 'ef-file-preview-header grid-row middle-xs'},
              div {className: 'col-xs'},
                div {className: 'ef-file-preview-header-filename-container'},
                  h1 {className: 'ef-file-preview-header-filename'},
                  @props.initialItem.displayName()
              div {className: 'col-xs end-xs'},
                div {className: 'ef-file-preview-header-buttons'},
                  a {className: 'ef-file-preview-header-download ef-file-preview-button', href: @state.displayedItem.get('url')},
                    i {className: 'icon-download'} #Replace with actual icon
                    I18n.t('file_preview_headerbutton_download', ' Download')
                  a {className: 'ef-file-preview-header-info ef-file-preview-button', href: '#', onClick: @openInfoPanel},
                    i {className: 'icon-info'}
                    I18n.t('file_preview_headerbutton_info', ' Info')
                  ReactRouter.Link _.defaults({to: (if @props.params.splat then 'folder' else 'rootFolder'), query: '', className: 'ef-file-preview-header-close ef-file-preview-button'}, @props.params),
                    i {className: 'icon-end'}
                    I18n.t('file_preview_headerbutton_close', ' Close')
            div {className: 'ef-file-preview-preview grid-row middle-xs'},
              # We need to render out the left/right arrows
              @renderArrowLink('left') if @props.otherItems.length > 0
              @renderPreview()
              @renderArrowLink('right') if @props.otherItems.length > 0
              if @state.showInfoPanel
                  div {className: 'col-xs-4 full-height ef-file-preview-information'},
                      table {className: 'ef-file-preview-infotable'},
                        tbody {},
                          tr {},
                            th {scope: 'row'},
                              I18n.t('file_preview_infotable_name', 'Name')
                            td {},
                              @state.displayedItem.displayName()
                          tr {},
                            th {scope: 'row'},
                              I18n.t('file_preview_infotable_status', 'Status')
                            td {},
                              @getStatusMessage();
                          tr {},
                            th {scope: 'row'},
                              I18n.t('file_preview_infotable_kind', 'Kind')
                            td {},
                              @state.displayedItem.get 'content-type'
                          tr {},
                            th {scope: 'row'},
                              I18n.t('file_preview_infotable_size', 'Size')
                            td {},
                              @state.displayedItem.get('size') + ' Kb'
                          tr {},
                            th {scope: 'row'},
                              I18n.t('file_preview_infotable_datemodified', 'Date Modified')
                            td {},
                              FriendlyDatetime datetime: @state.displayedItem.get('updated_at')
                          tr {},
                            th {scope: 'row'},
                              I18n.t('file_preview_infotable_modifiedby', 'Modified By')
                            td {},
                              img {className: 'avatar', src: @state.user?.avatar_image_url }
                                a {href: @state.user?.html_url},
                                  @state.user?.display_name
                          tr {},
                            th {scope: 'row'},
                              I18n.t('file_preview_infotable_datecreated', 'Date Created')
                            td {},
                              FriendlyDatetime datetime: @state.displayedItem.get('created_at')
            div {className: 'ef-file-preview-toggle-row grid-row middle-xs'},
              if @state.showFooterBtn
                a {className: 'ef-file-preview-toggle col-xs-1 off-xs-1', href: '#', onClick: @toggleFooter, role: 'button', style: {bottom: '21%'} if @state.showFooter},
                  if @state.showFooter
                    I18n.t('file_preview_hide', 'Hide')
                  else
                    I18n.t('file_preview_show', 'Show')
            if @state.showFooter
              div {className: 'ef-file-preview-footer grid-row'},
                div {className: 'col-xs-1', onClick: @scrollLeft},
                  div {className: 'ef-file-preview-footer-arrow'},
                    i {className: 'icon-arrow-open-left'}
                div {className: 'col-xs-10'},
                  ul {className: 'ef-file-preview-footer-list'},
                    @props.otherItems.map (file) =>
                      li {className: 'ef-file-preview-footer-list-item', key: file.id},
                        figure {className: 'ef-file-preview-footer-item'},
                          ReactRouter.Link _.defaults({to: (if @props.params.splat then 'folder' else 'rootFolder'), query: {preview: file.id}, className: ''}, @props.params),
                          div {
                            className: if file.displayName() is @state.displayedItem.displayName() then 'ef-file-preview-footer-image ef-file-preview-footer-active' else 'ef-file-preview-footer-image'
                            style: {'background-image': 'url(' + file.get('thumbnail_url') + ')'}
                          }
                          figcaption {},
                            file.displayName()
                div {className: 'col-xs-1', onClick: @scrollRight},
                  div {className: 'ef-file-preview-footer-arrow'},
                    i {className: 'icon-arrow-open-right'}