define [
  'react'
  'compiled/react/shared/utils/withReactDOM'
  'compiled/models/Folder'
  'compiled/models/File'
  './RestrictedDialogForm'
  './DialogAdapter'
  'i18n!dialog_adapter'
], (React, withReactDOM, Folder, File, RestrictedDialogForm, $DialogAdapter, I18n) ->

  # Expects @props.model to be either a folder or a file collection/backbone model
  ItemCog = React.createClass

    getInitialState: ->
      restrictedDialogOpen: false

    propTypes:
      model: React.PropTypes.oneOfType([
        React.PropTypes.instanceOf(File),
        React.PropTypes.instanceOf(Folder)
      ])

    isAFolderCog: -> @props.model instanceof Folder

    openRestrictedDialog: (event) ->
      event.preventDefault()
      @setState restrictedDialogOpen: true

    closeRestrictedDialog: ->
      @setState restrictedDialogOpen: false

    render: withReactDOM ->
      div null,

        $DialogAdapter open: @state.restrictedDialogOpen, title: I18n.t("title.limit_student_access", "Limit student access"),
          RestrictedDialogForm closeDialog: @closeRestrictedDialog

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
                  a href:'#', id:'content-2', tabIndex:'-1', role:'menuitem', title:'Edit Name', 'Edit Name'
                li {},
                  a onClick: @openRestrictedDialog, href:'#', id:'content-3', tabIndex:'-1', role:'menuitem', title:'Restrict Access', 'Restrict Access'
                li {},
                  a href:'#', id:'content-3', tabIndex:'-1', role:'menuitem', title:'Delete', 'Delete'

                (li {},
                  a href:'#', id:'content-3', tabIndex:'-1', role:'menuitem', title:'Download as Zip',
                    'Download as Zip'
                ) if @isAFolderCog()


