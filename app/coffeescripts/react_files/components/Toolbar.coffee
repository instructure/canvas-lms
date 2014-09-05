define [
  'i18n!react_files'
  'react'
  'react-router'
  'compiled/react/shared/utils/withReactDOM'
  './UploadButton'
  '../utils/openMoveDialog'
  '../utils/downloadStuffAsAZip'
], (I18n, React, Router, withReactDOM, UploadButton, openMoveDialog, downloadStuffAsAZip) ->

  Toolbar = React.createClass

    propTypes:
      currentFolder: React.PropTypes.object # not required as we don't have it on the first render

    onSubmitSearch: (event) ->
      event.preventDefault()
      query = {search_term: @refs.searchTerm.getDOMNode().value}
      Router.transitionTo 'search', @props.params, query

    addFolder: (event) ->
      event.preventDefault()
      @props.currentFolder.folders.add({})

    downloadSelecteAsZip: ->
      downloadStuffAsAZip(@props.selectedItems, {
        contextType: @props.params.contextType,
        contextId: @props.params.contextId
      })

    deleteSelectedItems: ->
      count = @props.selectedItems.length
      message = I18n.t('confirm_delete_selected', 'Are you sure you want to delete these %{count} items?', {count})
      return unless confirm message
      promises = @props.selectedItems.map (item) -> item.destroy()
      $.when(promises...).then ->
        $.flashMessage I18n.t('deleted_items_successfully', '%{count} items deleted successfully', {count})
      @setState selectedItems: []


    render: withReactDOM ->
      header className:'ef-header',
        form onSubmit: @onSubmitSearch, className:'ef-search-container',
          i className:'icon-search',
          input placeholder: I18n.t('search', 'Search for files'), type:'search', ref:'searchTerm', defaultValue: @props.query.search_term #, onKeyUp: @onKeyUp
        div className: 'ef-main-buttons',

          if @props.selectedItems.length
            div className: 'ui-buttonset ef-selected-items-actions',
              span className: 'hidden-tablet hidden-phone', style: {paddingRight: 10},
                I18n.t('count_items_selected', '%{count} items selected', {count: @props.selectedItems.length})
              button className: 'ui-button', onClick: @downloadSelecteAsZip,
                i className: 'icon-zipped'
                span className: 'hidden-tablet hidden-phone',
                  I18n.t('download_zip', 'Downlod Zip')
              button className: 'ui-button', onClick: openMoveDialog.bind(null, @props.selectedItems),
                i className: 'icon-copy-course'
                span className: 'hidden-tablet hidden-phone',
                  I18n.t('move', 'Move')
              button className: 'ui-button', onClick: @deleteSelectedItems,
                i className: 'icon-trash'
                span className: 'hidden-tablet hidden-phone',
                  I18n.t('delete', 'Delete')

          div className: 'ui-buttonset',
            button onClick: @addFolder, className:'btn',
              i className:'icon-plus'
              span className: 'hidden-phone',
                  I18n.t('folder', 'Folder')

          div className: 'ui-buttonset',
            UploadButton currentFolder: this.props.currentFolder

