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
    displayName: 'Toolbar'

    propTypes:
      currentFolder: React.PropTypes.object # not required as we don't have it on the first render
      contextType: React.PropTypes.oneOf(['users', 'groups', 'accounts', 'courses']).isRequired
      contextId: React.PropTypes.string.isRequired

    onSubmitSearch: (event) ->
      event.preventDefault()
      query = {search_term: @refs.searchTerm.getDOMNode().value}
      Router.transitionTo 'search', @props.params, query

    addFolder: (event) ->
      event.preventDefault()
      @props.currentFolder.folders.add({})

    downloadSelecteAsZip: ->
      downloadStuffAsAZip(@props.selectedItems, {
        contextType: @props.contextType,
        contextId: @props.contextId
      })

    deleteSelectedItems: ->
      count = @props.selectedItems.length
      message = I18n.t('confirm_delete_selected', 'Are you sure you want to delete these %{count} items?', {count})
      return unless confirm message
      promises = @props.selectedItems.map (item) -> item.destroy()
      $.when(promises...).then ->
        $.flashMessage I18n.t('deleted_items_successfully', '%{count} items deleted successfully', {count})
      @props.clearSelectedItems()



    render: withReactDOM ->
      showingButtons = @props.selectedItems.length
      header {
        className:'ef-header grid-row between-xs'
        role: 'region'
        'aria-label': I18n.t('files_toolbar', 'Files Toolbar')
      },
        form {
          className: "col-lg-3 #{ if showingButtons
                                    'col-xs-4 col-sm-3 col-md-4'
                                  else
                                    'col-xs-7 col-sm-5 col-md-4'}"
          onSubmit: @onSubmitSearch
        },
          input
            placeholder:  I18n.t('search_for_files', 'Search for files')
            'aria-label': I18n.t('search_for_files', 'Search for files')
            type: 'search'
            ref: 'searchTerm'
            defaultValue: @props.query.search_term

        div className: "ui-buttonset col-xs #{'screenreader-only' unless showingButtons}",
          span className: 'hidden-tablet hidden-phone', style: {paddingRight: 10},
            I18n.t('count_items_selected', '%{count} items selected', {count: @props.selectedItems.length})

          button {
            disabled: !showingButtons
            className: 'ui-button'
            onClick: alert.bind(null, 'TODO: handle CNVS-14727 actually implement previewing of files')
            title: I18n.t('view', 'View')
            'data-tooltip': ''
          },
            i className: 'icon-search'

          button {
            disabled: !showingButtons
            className: 'ui-button',
            onClick: alert.bind(null, 'TODO: handle CNVS-15382 Multi select restricted access')
            title: I18n.t('restrict_access', 'Restrict Access')
            'data-tooltip': ''
          },
            i className: 'icon-unpublished'

          button {
            disabled: !showingButtons
            className: 'ui-button'
            onClick: @downloadSelecteAsZip
            title:  if @props.selectedItems.length is 1
                      I18n.t('download', 'Download')
                    else
                      I18n.t('download_as_zip', 'Downlod as Zip')
            'data-tooltip': ''
          },
            i className: 'icon-download'

          button {
            disabled: !showingButtons
            className: 'ui-button'
            onClick: openMoveDialog.bind null, @props.selectedItems,
              contextType: @props.contextType
              contextId: @props.contextId
            title: I18n.t('move', 'Move')
            'data-tooltip': ''
          },
            i className: 'icon-copy-course'

          button {
            disabled: !showingButtons
            className: 'ui-button'
            onClick: @deleteSelectedItems
            title: I18n.t('delete', 'Delete')
            'data-tooltip': ''
          },
            i className: 'icon-trash'

        div className: 'text-right',
          span className: 'ui-buttonset',
            button {
              onClick: @addFolder
              className:'btn'
              'aria-label': I18n.t('add_folder', 'Add Folder')
            },
              i(className:'icon-plus'),
              span className: ('hidden-phone' if showingButtons),
                I18n.t('folder', 'Folder')

          span className: 'ui-buttonset',
            UploadButton
              currentFolder: @props.currentFolder
              showingButtons: showingButtons

