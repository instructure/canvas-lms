define [
  'underscore'
  'i18n!react_files'
  'react'
  'react-router'
  'compiled/react/shared/utils/withReactElement'
  'jsx/files/UploadButton'
  'jsx/files/UsageRightsDialog'
  '../utils/openMoveDialog'
  '../utils/downloadStuffAsAZip'
  '../utils/deleteStuff'
  '../modules/customPropTypes'
  'jsx/files/RestrictedDialogForm'
  'compiled/fn/preventDefault'
  '../modules/FocusStore'
  'jquery'
  'compiled/jquery.rails_flash_notifications'
], (_, I18n, React, Router, withReactElement, UploadButtonComponent, UsageRightsDialog, openMoveDialog, downloadStuffAsAZip, deleteStuff, customPropTypes, RestrictedDialogForm, preventDefault, FocusStore, $) ->

  UploadButton = React.createFactory UploadButtonComponent
  Link = React.createFactory Router.Link


  Toolbar = React.createClass
    displayName: 'Toolbar'

    mixins: [Router.Navigation, Router.State]

    propTypes:
      currentFolder: customPropTypes.folder # not required as we don't have it on the first render
      contextType: customPropTypes.contextType.isRequired
      contextId: customPropTypes.contextId.isRequired

    onSubmitSearch: (event) ->
      event.preventDefault()
      query = {search_term: @refs.searchTerm.getDOMNode().value}
      @transitionTo 'search', {}, query

    addFolder: (event) ->
      event.preventDefault()
      @props.currentFolder.folders.add({})

    getItemsToDownload: ->
      itemsToDownload = @props.selectedItems.filter (item) ->
        !item.get('locked_for_user')

    downloadSelectedAsZip: ->
      return unless @getItemsToDownload().length

      downloadStuffAsAZip(@getItemsToDownload(), {
        contextType: @props.contextType,
        contextId: @props.contextId
      })

    componentDidUpdate: (prevProps) ->
      if prevProps.selectedItems.length isnt @props.selectedItems.length
        $.screenReaderFlashMessage(I18n.t({one: '%{count} item selected', other: '%{count} items selected'}, {count: @props.selectedItems.length}))

    # Function Summary
    # Create a blank dialog window via jQuery, then dump the RestrictedDialogForm into that
    # dialog window. This allows us to do react things inside of this already rendered
    # jQueryUI widget
    openRestrictedDialog: ->
      $dialog = $('<div>').dialog
        title: I18n.t({
            one: "Edit permissions for: %{itemName}",
            other: "Edit permissions for %{count} items"
          }, {
            count: @props.selectedItems.length
            itemName: @props.selectedItems[0].displayName()
          })

        width: 800
        minHeight: 400
        close: ->
          React.unmountComponentAtNode this
          $(this).remove()

      React.render(RestrictedDialogForm({
        models: @props.selectedItems
        usageRightsRequiredForContext: @props.usageRightsRequiredForContext
        closeDialog: -> $dialog.dialog('close')
      }), $dialog[0])

    openUsageRightsDialog: (event)->
      event.preventDefault()

      contents = UsageRightsDialog(
        closeModal: @props.modalOptions.closeModal
        itemsToManage: @props.selectedItems
      )

      @props.modalOptions.openModal(contents, => @refs.usageRightsBtn.getDOMNode().focus())

    openPreview: ->
      FocusStore.setItemToFocus(@refs.previewLink.getDOMNode())
      @transitionTo(@props.getPreviewRoute(), {splat: @props.currentFolder?.urlPath()}, @props.getPreviewQuery())

    render: withReactElement ->
      showingButtons = @props.selectedItems.length
      downloadTitle = if @props.selectedItems.length is 1
        I18n.t('download', 'Download')
      else
        I18n.t('download_as_zip', 'Download as Zip')

      header {
        className:'ef-header'
        role: 'region'
        'aria-label': I18n.t('files_toolbar', 'Files Toolbar')
      },
        form {
          className:
            if showingButtons
              "ic-Input-group ef-search-form ef-search-form--showing-buttons"
            else
              "ic-Input-group ef-search-form"
          onSubmit: @onSubmitSearch
        },
          input {
            placeholder:  I18n.t('search_for_files', 'Search for files')
            'aria-label': I18n.t('search_for_files', 'Search for files')
            type: 'search'
            ref: 'searchTerm'
            className: 'ic-Input'
            defaultValue: @getQuery().search_term
          },
          button {
            className: 'Button'
            type: 'submit'
          },
            i(className:'icon-search'),
            span className: ('screenreader-only'),
              I18n.t('search_for_files', 'Search for files')

        div className: 'ef-header__secondary',
          div className: "ui-buttonset #{'screenreader-only' unless showingButtons}",

            a {
                ref: 'previewLink'
                href: '#'
                onClick: preventDefault(@openPreview)
                className: 'ui-button btn-view'
                title: I18n.t('view', 'View')
                role: 'button'
                'aria-label': I18n.t('view', 'View')
                'data-tooltip': ''
                'aria-disabled': !showingButtons
                disabled: !showingButtons
                tabIndex: -1 unless showingButtons # This is to make it okay for keyboard-nav when hidden.
              },
              i className: 'icon-eye'

            if @props.userCanManageFilesForContext
              button {
                type: 'button'
                disabled: !showingButtons
                className: 'ui-button btn-restrict',
                onClick: @openRestrictedDialog
                title: I18n.t('restrict_access', 'Manage Access')
                'aria-label': I18n.t('restrict_access', 'Manage Access')
                'data-tooltip': ''
              },
                i className: 'icon-cloud-lock'
            if @getItemsToDownload().length
              if (@props.selectedItems.length is 1) and @props.selectedItems[0].get('url')
                a {
                  tabIndex: -1 unless showingButtons
                  className: 'ui-button btn-download'
                  href: @props.selectedItems[0].get('url')
                  download: true
                  title: downloadTitle
                  'aria-label': downloadTitle
                  'data-tooltip': ''
                },
                  i className: 'icon-download'
              else
                button {
                  type: 'button'
                  disabled: !showingButtons
                  className: 'ui-button btn-download'
                  onClick: @downloadSelectedAsZip
                  title: downloadTitle
                  'aria-label': downloadTitle
                  'data-tooltip': ''
                },
                  i className: 'icon-download'

            if @props.userCanManageFilesForContext
              button {
                type: 'button'
                disabled: !showingButtons
                className: 'ui-button btn-move'
                onClick: (event) =>
                  openMoveDialog(@props.selectedItems, {
                    contextType: @props.contextType
                    contextId: @props.contextId
                    returnFocusTo: event.target
                    clearSelectedItems: @props.clearSelectedItems
                  })
                title: I18n.t('move', 'Move')
                'aria-label': I18n.t('move', 'Move')
                'data-tooltip': ''
              },
                i className: 'icon-copy-course'

            if @props.userCanManageFilesForContext and @props.usageRightsRequiredForContext
              button {
                ref: 'usageRightsBtn'
                type: 'button'
                disabled: !showingButtons
                className: 'Toolbar__ManageUsageRights ui-button btn-rights'
                onClick: @openUsageRightsDialog
                title: I18n.t('Manage Usage Rights')
                'aria-label': I18n.t('Manage Usage Rights')
                'data-tooltip': ''
              },
                i className: 'icon-files-copyright'

            if @props.userCanManageFilesForContext
              button {
                type: 'button'
                disabled: !showingButtons
                className: 'ui-button btn-delete'
                onClick: =>
                  @props.clearSelectedItems()
                  deleteStuff(@props.selectedItems)
                title: I18n.t('delete', 'Delete')
                'aria-label': I18n.t('delete', 'Delete')
                'data-tooltip': ''
              },
                i className: 'icon-trash'

            span className: 'ef-selected-count hidden-tablet hidden-phone',
              I18n.t({one: '%{count} item selected', other: '%{count} items selected'}, {count: @props.selectedItems.length})

          if @props.userCanManageFilesForContext
            div className: 'ef-actions',
              button {
                type: 'button'
                onClick: @addFolder
                className:'btn btn-add-folder'
                'aria-label': I18n.t('add_folder', 'Add Folder')
              },
                i(className:'icon-plus'),
                span className: ('hidden-phone' if showingButtons),
                  I18n.t('folder', 'Folder')

              UploadButton
                currentFolder: @props.currentFolder
                showingButtons: showingButtons
                contextId: @props.contextId
                contextType: @props.contextType
