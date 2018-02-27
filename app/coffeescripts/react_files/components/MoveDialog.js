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
  'i18n!react_files'
  'jquery'
  'react'
  'prop-types'
  '../../fn/preventDefault'
  '../modules/customPropTypes'
  '../utils/moveStuff'
  '../../str/splitAssetString'
], (I18n, $, React, PropTypes, preventDefault,  customPropTypes, moveStuff, splitAssetString) ->

  MoveDialog =
    displayName: 'MoveDialog'

    propTypes:
      rootFoldersToShow: PropTypes.arrayOf(customPropTypes.folder).isRequired
      thingsToMove: PropTypes.arrayOf(customPropTypes.filesystemObject).isRequired
      onClose: PropTypes.func.isRequired
      onMove: PropTypes.func.isRequired

    getInitialState: ->
      destinationFolder: null
      isOpen: true

    contextsAreEqual: (destination = {}, sources = []) ->
      contextsAreEqual = sources.filter (source) ->
        [contextType, contextId] = if assetString = source.get("context_asset_string")
                                     splitAssetString(assetString, false)
                                   else
                                     [(source.collection?.parentFolder?.get("context_type") || source.get("context_type")), (source.collection?.parentFolder?.get("context_id")?.toString() || source.get("context_id").toString())]

        contextType.toLowerCase() is destination.get("context_type").toLowerCase() and
        contextId is destination.get("context_id")?.toString()

      !!contextsAreEqual.length

    onSelectFolder: (event, folder) ->
      event.preventDefault()
      if folder.get('for_submissions')
        @setState(destinationFolder: null)
      else
        @setState(destinationFolder: folder, isCopyingFile: !@contextsAreEqual(folder, @props.thingsToMove))

    submit: () ->
      modelsBeingMoved = @props.thingsToMove
      promise = moveStuff(modelsBeingMoved, @state.destinationFolder)
      promise.then =>
        @props.onMove(modelsBeingMoved)
        @closeDialog()

    closeDialog: ->
      @setState(isOpen: false, ->
        @props.onClose()
      )

    getTitle: ->
      I18n.t('move_question', {
        one: "Where would you like to move %{item}?",
        other: "Where would you like to move these %{count} items?"
      },{
        count: @props.thingsToMove.length
        item: @props.thingsToMove[0]?.displayName()
      })
