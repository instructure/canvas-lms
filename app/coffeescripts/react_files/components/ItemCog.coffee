define [
  'i18n!react_files'
  'react'
  'compiled/react/shared/utils/withReactDOM'
  'compiled/fn/preventDefault'
  'compiled/models/FilesystemObject'
  './RestrictedDialogForm'
  './MoveDialog'
  './DialogAdapter'
  './DialogContent'
  './DialogButtons'
  'jquery'
  'jqueryui/dialog'
], (I18n, React, withReactDOM, preventDefault, FilesystemObject, RestrictedDialogForm, MoveDialog, $DialogAdapter, DialogContent, DialogButtons, $) ->

  # Expects @props.model to be either a folder or a file collection/backbone model
  ItemCog = React.createClass

    getInitialState: ->
      restrictedDialogOpen: false

    propTypes:
      model: React.PropTypes.instanceOf(FilesystemObject)

    openRestrictedDialog: preventDefault ->
      @setState restrictedDialogOpen: true

    closeRestrictedDialog: ->
      @setState restrictedDialogOpen: false

    deleteItem: ->
      message = I18n.t('confirm_delete', 'Are you sure you want to delete %{name}?', {
        name: @props.model.displayName()
      })
      if confirm message
        @props.model.destroy()

    openMoveDialog: ->
      $dialog = $('<div>').dialog
        width: 600
        height: 300
        close: -> $dialog.remove()

      React.renderComponent(MoveDialog({
        thingsToMove: [@props.model]
        closeDialog: -> $dialog.dialog('close')
        setTitle: (title) -> $dialog.dialog('option', 'title', title)
      }), $dialog[0])


    render: withReactDOM ->
      div null,

        $DialogAdapter open: @state.restrictedDialogOpen, title: I18n.t("title.limit_student_access", "Limit student access"),
          DialogContent {},
            RestrictedDialogForm {}
          DialogButtons {},
            input type: 'button', onClick: @closeRestrictedDialog, className: "btn", value: I18n.t("button_text.cancel", "Cancel")
            input type: "submit", className: "btn btn-primary", value: I18n.t("button_text.update", "Update")

        div className:'ef-hover-options',
          a href:'#', className: 'adminCog-download-link',
            i className:'icon-download'

          div className:'ef-admin-gear',
            div null,
              a className:'al-trigger al-trigger-gray', role:'button', 'aria-haspopup':'true', 'aria-owns':'content-1', 'aria-label': I18n.t('aria_label.settings', 'Settings'), href:'#',
                i className:'icon-settings',
                i className:'icon-mini-arrow-down'

              ul id:'content-1', className:'al-options', role:'menu', tabIndex:'0', 'aria-hidden':'true', 'aria-expanded':'false', 'aria-activedescendant':'content-2',

                li {},
                  a href:'#', onClick: preventDefault(@props.startEditingName), id:'content-2', tabIndex:'-1', role:'menuitem', title:'Edit Name', 'Edit Name'
                li {},
                  a onClick: preventDefault(@openRestrictedDialog), href:'#', id:'content-3', tabIndex:'-1', role:'menuitem', title:'Restrict Access', 'Restrict Access'
                li {},
                  a onClick: preventDefault(@openMoveDialog), href:'#', id:'content-4', tabIndex:'-1', role:'menuitem', title:'Move', 'Move'
                li {},
                  a ref: 'deleteLink', onClick: preventDefault(@deleteItem), href:'#', id:'content-3', tabIndex:'-1', role:'menuitem', title:'Delete', 'Delete'
                li {},
                  a href:'#', id:'content-3', tabIndex:'-1', role:'menuitem', title:'Download', 'Download'


