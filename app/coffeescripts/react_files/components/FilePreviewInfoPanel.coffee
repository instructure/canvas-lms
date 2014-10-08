define [
  'react'
  'i18n!file_preview'
  './FriendlyDatetime'
  'compiled/util/friendlyBytes'
  'compiled/react/shared/utils/withReactDOM'
  '../modules/customPropTypes'
 ], (React, I18n, FriendlyDatetime, friendlyBytes, withReactDOM, customPropTypes) ->

  FilePreviewInfoPanel = React.createClass

    displayName: 'FilePreviewInfoPanel'

    propTypes:
      displayedItem: customPropTypes.filesystemObject.isRequired
      getStatusMessage: React.PropTypes.func

    render: withReactDOM ->
      div {className: 'col-xs-4 full-height ef-file-preview-information'},
        table {className: 'ef-file-preview-infotable'},
          tbody {},
            tr {},
              th {scope: 'row'},
                I18n.t('file_preview_infotable_name', 'Name')
              td {},
                @props.displayedItem?.displayName()
            tr {},
              th {scope: 'row'},
                I18n.t('file_preview_infotable_status', 'Status')
              td {},
                @props.getStatusMessage();
            tr {},
              th {scope: 'row'},
                I18n.t('file_preview_infotable_kind', 'Kind')
              td {},
                @props.displayedItem?.get 'content-type'
            tr {},
              th {scope: 'row'},
                I18n.t('file_preview_infotable_size', 'Size')
              td {},
                friendlyBytes @props.displayedItem?.get('size')
            tr {},
              th {scope: 'row'},
                I18n.t('file_preview_infotable_datemodified', 'Date Modified')
              td {},
                FriendlyDatetime datetime: @props.displayedItem?.get('updated_at')
            if @props.displayedItem?.get('user')
              tr {},
                th {scope: 'row'},
                  I18n.t('file_preview_infotable_modifiedby', 'Modified By')
                td {},
                  img {className: 'avatar', src: @props.displayedItem?.get('user').avatar_image_url }
                    a {href: @props.displayedItem?.get('user').html_url},
                      @props.displayedItem?.get('user').display_name
            tr {},
              th {scope: 'row'},
                I18n.t('file_preview_infotable_datecreated', 'Date Created')
              td {},
                FriendlyDatetime datetime: @props.displayedItem?.get('created_at')
