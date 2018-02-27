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

import _ from 'underscore'
import MultiselectableMixin from '../mixins/MultiselectableMixin'
import dndMixin from '../mixins/dndMixin'
import filesEnv from '../modules/filesEnv'

export default {
  displayName: 'FilesApp',

  onResolvePath({
    currentFolder,
    rootTillCurrentFolder,
    showingSearchResults,
    searchResultCollection
  }) {
    const {updatedModels} = this.state

    if (currentFolder && !showingSearchResults) {
      updatedModels.forEach(function(model, index, models) {
        let removedModel
        if (
          currentFolder.id.toString() !== model.get('folder_id') &&
          (removedModel = currentFolder.files.findWhere({id: model.get('id')}))
        ) {
          currentFolder.files.remove(removedModel)
          models.splice(index, 1)
        }
      })
    }

    return this.setState({
      currentFolder,
      rootTillCurrentFolder,
      showingSearchResults,
      selectedItems: [],
      searchResultCollection,
      updatedModels
    })
  },

  getInitialState() {
    return {
      updatedModels: [],
      currentFolder: null,
      rootTillCurrentFolder: null,
      showingSearchResults: false,
      showingModal: false,
      modalContents: null // This should be a React Component to render in the modal container.
    }
  },

  mixins: [MultiselectableMixin, dndMixin],

  // for MultiselectableMixin
  selectables() {
    if (this.state.showingSearchResults) {
      return this.state.searchResultCollection.models
    } else {
      return this.state.currentFolder.children(this.props.query)
    }
  },

  onMove(modelsToMove) {
    const updatedModels = _.uniq(this.state.updatedModels.concat(modelsToMove), 'id')
    this.setState({updatedModels})
  },

  getPreviewQuery() {
    const retObj = {
      preview: (this.state.selectedItems[0] && this.state.selectedItems[0].id) || true
    }
    if (this.state.selectedItems.length > 1) {
      retObj.only_preview = this.state.selectedItems.map(item => item.id).join(',')
    }
    if (this.props.query && this.props.query.search_term) {
      retObj.search_term = this.props.query.search_term
    }
    if (this.props.query && this.props.query.sort) {
      retObj.sort = this.props.query.sort
    }
    if (this.props.query && this.props.query.order) {
      retObj.order = this.props.query.order
    }
    return retObj
  },

  openModal(contents, afterClose) {
    this.setState({
      modalContents: contents,
      showingModal: true,
      afterModalClose: afterClose
    })
  },

  closeModal() {
    this.setState({showingModal: false}, () => this.state.afterModalClose())
  }
}
