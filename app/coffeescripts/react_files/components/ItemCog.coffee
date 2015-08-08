define [
  'i18n!react_files'
  'react'
  'compiled/react/shared/utils/withReactElement'
  'compiled/fn/preventDefault'
  '../modules/customPropTypes'
  '../modules/filesEnv'
  'compiled/models/File'
  'compiled/models/Folder'
  './UsageRightsDialog'
  './RestrictedDialogForm'
  '../utils/openMoveDialog'
  '../utils/downloadStuffAsAZip'
  '../utils/deleteStuff'
  'jquery'
  'jqueryui/dialog'
], (I18n, React, withReactElement, preventDefault, customPropTypes, filesEnv, File, Folder, UsageRightsDialogComponent, RestrictedDialogFormComponent, openMoveDialog, downloadStuffAsAZip, deleteStuff, $) ->

  UsageRightsDialog = React.createFactory UsageRightsDialogComponent
  RestrictedDialogForm = React.createFactory RestrictedDialogFormComponent

  ItemCog = React.createClass
    displayName: 'ItemCog'

    propTypes:
      model: customPropTypes.filesystemObject
      modalOptions: React.PropTypes.object.isRequired

    openUsageRightsDialog: (event) ->
      contents = UsageRightsDialog(
        closeModal: @props.modalOptions.closeModal
        itemsToManage: [@props.model]
      )

      @props.modalOptions.openModal(contents, => @refs.settingsCogBtn.getDOMNode().focus())

    render: withReactElement ->
      if @props.model instanceof File
        externalToolMenuItems = @props.externalToolsForContext.map (tool) =>
          if @props.model.externalToolEnabled(tool)
            li {},
              a {
                href: "#{tool.base_url}&files[]=#{@props.model.id}",
              },
                tool.title
          else
            li {},
              a {
                className: "disabled",
                href: "#"
              },
              tool.title
      else
        externalToolMenuItems = []

      wrap = (fn, params = {}) =>
        preventDefault (event) =>
          singularContextType = @props.model.collection?.parentFolder?.get('context_type').toLowerCase()
          pluralContextType = singularContextType + 's' if singularContextType?
          contextType = pluralContextType || filesEnv.contextType
          contextId = @props.model.collection?.parentFolder?.get('context_id') || filesEnv.contextId
          args = {
            contextType: contextType
            contextId: contextId
            returnFocusTo: @refs.settingsCogBtn.getDOMNode()
          }
          args = $.extend(args, params)
          fn([@props.model], args)

      span style: minWidth: "45px",

        button {
          type: 'button'
          ref: 'settingsCogBtn'
          className: 'al-trigger al-trigger-gray btn btn-link'
          'aria-label': I18n.t('Actions')
          'data-popup-within' : "#wrapper"
          'data-append-to-body' : true
        },
          i className:'icon-settings',
          i className:'icon-mini-arrow-down'

        ul className:'al-options',
          li {},
            a (if @props.model instanceof Folder
              href: '#'
              onClick: wrap(downloadStuffAsAZip)
              ref: 'download'
            else
              href: @props.model.get('url')
              ref: 'download'
            ),
              I18n.t('download', 'Download')
          if @props.userCanManageFilesForContext
            [
              li {},
                a {
                  href:'#'
                  onClick: preventDefault(@props.startEditingName)
                  ref: 'editName'
                },
                  I18n.t('Rename')
              li {},
                a {
                  href:'#'
                  onClick: wrap(openMoveDialog, {clearSelectedItems: @props.clearSelectedItems})
                  ref: 'move'
                },
                  I18n.t('move', 'Move')

              # don't show any usage rights related stuff to people that don't have the feature flag on
              if @props.usageRightsRequiredForContext
                li {className: 'ItemCog__OpenUsageRights'},
                  a {
                    href: '#'
                    onClick: preventDefault(@openUsageRightsDialog)
                    ref: 'usageRights'
                  },
                    I18n.t('Manage Usage Rights')
              li {},
                a {
                  href:'#'
                  onClick: wrap(deleteStuff)
                  ref: 'deleteLink'
                },
                  I18n.t('delete', 'Delete')
            ].concat(externalToolMenuItems)
