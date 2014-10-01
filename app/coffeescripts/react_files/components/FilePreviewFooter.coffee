define [
  'react'
  'react-router',
  'i18n!file_preview'
  'compiled/react/shared/utils/withReactDOM'
  '../modules/customPropTypes'
], (React, ReactRouter, I18n, withReactDOM, customPropTypes) ->

  FilePreviewFooter = React.createClass

    displayName: 'FilePreviewFooter'

    propTypes:
      otherItems: React.PropTypes.object
      to: React.PropTypes.string
      splat: React.PropTypes.string
      query: React.PropTypes.func
      displayedItem: customPropTypes.filesystemObject.isRequired

    thumbnails: ->
      @props.otherItems.map (file) =>
        li {className: 'ef-file-preview-footer-list-item', key: file.id},
          figure {className: 'ef-file-preview-footer-item'},
            ReactRouter.Link {to: @props.to, params: {splat: @props.splat}, query: @props.query(id: file.id)},
            div {
              className: if file.displayName() is @props.displayedItem?.displayName() then 'ef-file-preview-footer-image ef-file-preview-footer-active' else 'ef-file-preview-footer-image'
              style: {'background-image': 'url(' + file.get('thumbnail_url') + ')'}
            }
            figcaption {},
              file.displayName()

    render: withReactDOM ->
      div {className: 'ef-file-preview-footer grid-row'},
        div {className: 'col-xs-1 ef-file-align-center', onClick: @scrollLeft},
          div {className: 'ef-file-preview-footer-arrow'},
            i {className: 'icon-arrow-open-left'}
        div {className: 'col-xs-10 ef-file-preview-list-container ef-file-align-center'},
          ul {className: 'ef-file-preview-footer-list'},
            @thumbnails()
        div {className: 'col-xs-1 ef-file-align-center', onClick: @scrollRight},
          div {className: 'ef-file-preview-footer-arrow'},
            i {className: 'icon-arrow-open-right'}
