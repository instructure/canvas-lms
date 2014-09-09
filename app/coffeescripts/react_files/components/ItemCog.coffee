define [
  'i18n!react_files'
  'react'
  'compiled/react/shared/utils/withReactDOM'
  'compiled/fn/preventDefault'
  'compiled/models/FilesystemObject'
  'compiled/models/Folder'
  './RestrictedDialogForm'
  '../utils/openMoveDialog'
  '../utils/downloadStuffAsAZip'
  'jquery'
  'jqueryui/dialog'
], (I18n, React, withReactDOM, preventDefault, FilesystemObject, Folder, RestrictedDialogForm, openMoveDialog, downloadStuffAsAZip, $) ->

  ItemCog = React.createClass

    # === React Functions === #
    propTypes:
      model: React.PropTypes.instanceOf(FilesystemObject)

    # === Custom Functions === #

    deleteItem: ->
      message = I18n.t('confirm_delete', 'Are you sure you want to delete %{name}?', {
        name: @props.model.displayName()
      })
      if confirm message
        @props.model.destroy()

    # Function Summary
    # Create a blank dialog window via jQuery, then dump the RestrictedDialogForm into that
    # dialog window. This allows us to do react things inside of this all ready rendered
    # jQueryUI widget
    openRestrictedDialog: ->
      $dialog = $('<div>').dialog
        title: I18n.t("title.limit_student_access", "Limit student access")
        width: 400
        close: ->
          React.unmountComponentAtNode this
          $(this).remove()

      React.renderComponent(RestrictedDialogForm({
        model: @props.model
        closeDialog: -> $dialog.dialog('close')
      }), $dialog[0])


    render: withReactDOM ->
      span {},

        button {
          className: 'al-trigger al-trigger-gray btn btn-link'
          'aria-label': I18n.t('settings', 'Settings')
          'data-popup-within' : "#wrapper"
        },
          i className:'icon-settings',
          i className:'icon-mini-arrow-down'

        ul className:'al-options',
          li {},
            a (if @props.model instanceof Folder
              href: '#'
              onClick: preventDefault =>
                downloadStuffAsAZip([@props.model], {
                  contextType: @props.params.contextType
                  contextId: @props.params.contextId
                })
            else
              href: @props.model.get('url')
            ),
              I18n.t('download', 'Download')
          li {},
            a href:'#', onClick: preventDefault(@props.startEditingName),
              I18n.t('edit_name', 'Edit Name')
          li {},
            a href:'#', onClick: preventDefault(@openRestrictedDialog), ref: 'restrictedDialog',
              I18n.t('restrict_access', 'Restrict Access')
          li {},
            a href:'#', onClick: preventDefault(openMoveDialog.bind(null, [@props.model])),
              I18n.t('move', 'Move')
          li {},
            a href:'#', onClick: preventDefault(@deleteItem), ref: 'deleteLink',
              I18n.t('delete', 'Delete')
