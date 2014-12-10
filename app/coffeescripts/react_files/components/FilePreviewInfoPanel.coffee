define [
  'react'
  'i18n!file_preview'
  './FriendlyDatetime'
  'compiled/util/friendlyBytes'
  'compiled/react/shared/utils/withReactDOM'
  '../modules/customPropTypes',
  '../utils/getFileStatus'
  'compiled/util/mimeClass'
 ], (React, I18n, FriendlyDatetime, friendlyBytes, withReactDOM, customPropTypes, getFileStatus, mimeClass) ->

  FilePreviewInfoPanel = React.createClass

    displayName: 'FilePreviewInfoPanel'

    propTypes:
      displayedItem: customPropTypes.filesystemObject.isRequired

    render: withReactDOM ->
      div {className: 'ef-file-preview-information-container'},
        table {className: 'ef-file-preview-infotable'},
          tbody {},
            tr {},
              th {scope: 'row'},
                I18n.t('file_preview_infotable_name', 'Name')
              td {},
                @props.displayedItem.displayName()
            tr {},
              th {scope: 'row'},
                I18n.t('file_preview_infotable_status', 'Status')
              td {},
                getFileStatus(@props.displayedItem)
            tr {},
              th {scope: 'row'},
                I18n.t('file_preview_infotable_kind', 'Kind')
              td {},
                mimeClass.displayName(@props.displayedItem.get('content-type'))
            tr {},
              th {scope: 'row'},
                I18n.t('file_preview_infotable_size', 'Size')
              td {},
                friendlyBytes @props.displayedItem.get('size')
            tr {},
              th {scope: 'row'},
                I18n.t('file_preview_infotable_datemodified', 'Date Modified')
              td {},
                FriendlyDatetime datetime: @props.displayedItem.get('updated_at')
            if user = @props.displayedItem.get('user')
              tr {},
                th {scope: 'row'},
                  I18n.t('file_preview_infotable_modifiedby', 'Last Modified By')
                td {},
                  a {href: user.html_url},
                    user.display_name
            tr {},
              th {scope: 'row'},
                I18n.t('file_preview_infotable_datecreated', 'Date Created')
              td {},
                FriendlyDatetime datetime: @props.displayedItem.get('created_at')
