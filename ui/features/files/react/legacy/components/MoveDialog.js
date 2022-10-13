/*
 * Copyright (C) 2014 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import customPropTypes from '@canvas/files/react/modules/customPropTypes'
import moveStuff from '../util/moveStuff'
import splitAssetString from '@canvas/util/splitAssetString'

const I18n = useI18nScope('react_files')

export default {
  displayName: 'MoveDialog',

  propTypes: {
    rootFoldersToShow: PropTypes.arrayOf(customPropTypes.folder).isRequired,
    thingsToMove: PropTypes.arrayOf(customPropTypes.filesystemObject).isRequired,
    onClose: PropTypes.func.isRequired,
    onMove: PropTypes.func.isRequired,
  },

  getInitialState() {
    return {
      destinationFolder: null,
      isOpen: true,
    }
  },

  contextsAreEqual(destination = {}, sources = []) {
    const contextsAreEqual = sources.filter(source => {
      const assetString = source.get('context_asset_string')
      const [contextType, contextId] = assetString
        ? splitAssetString(assetString, false)
        : [
            (source.collection &&
              source.collection.parentFolder &&
              source.collection.parentFolder.get('context_type')) ||
              source.get('context_type'),
            (source.collection &&
              source.collection.parentFolder &&
              source.collection.parentFolder.get('context_id') &&
              source.collection.parentFolder.get('context_id').toString()) ||
              source.get('context_id').toString(),
          ]

      return (
        contextType.toLowerCase() === destination.get('context_type').toLowerCase() &&
        contextId === (destination.get('context_id') && destination.get('context_id').toString())
      )
    })

    return !!contextsAreEqual.length
  },

  onSelectFolder(event, folder) {
    event.preventDefault()
    if (folder.get('for_submissions')) {
      this.setState({destinationFolder: null})
    } else {
      this.setState({
        destinationFolder: folder,
        isCopyingFile: !this.contextsAreEqual(folder, this.props.thingsToMove),
      })
    }
  },

  submit() {
    const modelsBeingMoved = this.props.thingsToMove
    const promise = moveStuff(modelsBeingMoved, this.state.destinationFolder)
    return promise.then(() => {
      this.props.onMove(modelsBeingMoved)
      this.closeDialog()
    })
  },

  closeDialog() {
    this.setState({isOpen: false}, function () {
      this.props.onClose()
    })
  },

  getTitle() {
    return I18n.t(
      'move_question',
      {
        one: 'Where would you like to move %{item}?',
        other: 'Where would you like to move these %{count} items?',
      },
      {
        count: this.props.thingsToMove.length,
        item: this.props.thingsToMove[0] && this.props.thingsToMove[0].displayName(),
      }
    )
  },
}
