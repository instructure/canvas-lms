#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'underscore'
  'i18n!react_files'
  'react'
  'react-dom'
  'page'
  'jsx/files/UsageRightsDialog'
  '../utils/downloadStuffAsAZip'
  '../utils/deleteStuff'
  '../modules/customPropTypes'
  'jsx/files/RestrictedDialogForm'
  'compiled/fn/preventDefault'
  '../modules/FocusStore'
  'compiled/models/Folder'
  'classnames'
  'jquery'
  'compiled/jquery.rails_flash_notifications'
], (_, I18n, React, ReactDOM, page, UsageRightsDialog, downloadStuffAsAZip, deleteStuff, customPropTypes, RestrictedDialogForm, preventDefault, FocusStore, Folder, classnames, $) ->

  Toolbar =
    displayName: 'Toolbar'

    propTypes:
      currentFolder: customPropTypes.folder # not required as we don't have it on the first render
      contextType: customPropTypes.contextType.isRequired
      contextId: customPropTypes.contextId.isRequired

    componentWillMount: ->
      @downloadTitle = I18n.t('Download as Zip')
      @tabIndex = null

    addFolder: (event) ->
      event.preventDefault()
      @props.currentFolder.folders.add({})

    getItemsToDownload: ->
      @props.selectedItems.filter (item) ->
        !item.get('locked_for_user')

    downloadSelectedAsZip: ->
      return unless @getItemsToDownload().length

      downloadStuffAsAZip(@getItemsToDownload(), {
        contextType: @props.contextType,
        contextId: @props.contextId
      })

    componentWillUpdate: (nextProps) ->
      @showingButtons = nextProps.selectedItems.length

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
          ReactDOM.unmountComponentAtNode this
          $(this).remove()

      # This should technically be in JSX land, but ¯\_(ツ)_/¯
      ReactDOM.render(React.createElement(RestrictedDialogForm, {
        models: @props.selectedItems
        usageRightsRequiredForContext: @props.usageRightsRequiredForContext
        closeDialog: -> $dialog.dialog('close')
      }), $dialog[0])

    openUsageRightsDialog: (event)->
      event.preventDefault()

      # This should technically be in JSX land, but ¯\_(ツ)_/¯
      contents = React.createElement(UsageRightsDialog, {
          closeModal: @props.modalOptions.closeModal
          itemsToManage: @props.selectedItems
          userCanRestrictFilesForContext: @props.userCanRestrictFilesForContext
      })

      @props.modalOptions.openModal(contents, => ReactDOM.findDOMNode(@refs.usageRightsBtn).focus())
