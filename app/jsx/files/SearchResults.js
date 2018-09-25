/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import I18n from 'i18n!react_files'
import _ from 'underscore'
import React from 'react'
import createReactClass from 'create-react-class'
import SearchResults from 'compiled/react_files/components/SearchResults'
import NoResults from '../files/NoResults'
import ColumnHeaders from '../files/ColumnHeaders'
import Folder from 'compiled/models/Folder'
import FolderChild from '../files/FolderChild'
import LoadingIndicator from '../files/LoadingIndicator'
import FilePreview from '../files/FilePreview'
import page from 'page'
import FocusStore from 'compiled/react_files/modules/FocusStore'

SearchResults.displayErrors = function(errors) {
  let error_message = null

  if (errors != null) {
    error_message = errors.map((error) => <li>{error.message}</li>)
  }

  return (
    <div>
      <p>
        {I18n.t(
          {
            one: 'Your search encountered the following error:',
            other: 'Your search encountered the following errors:'
          },
          {count: errors.length}
        )}
      </p>
      <ul>{error_message}</ul>
    </div>
  )
}

SearchResults.closeFilePreview = function(url) {
  page(url)
  FocusStore.setFocusToItem()
}

SearchResults.renderFilePreview = function() {
  if (this.props.query.preview != null && this.state.collection.length) {
    return (
      /*
         * Prepare and render the FilePreview if needed.
         * As long as ?preview is present in the url.
         */
      <FilePreview
        isOpen
        params={this.props.params}
        query={this.props.query}
        collection={this.state.collection}
        usageRightsRequiredForContext={this.props.usageRightsRequiredForContext}
        splat={this.props.splat}
        closePreview={this.closeFilePreview}
      />
    )
  }
}

SearchResults.render = function() {
  if (this.state.errors) {
    return this.displayErrors(this.state.errors)
  } else if (this.state.collection.loadedAll && this.state.collection.length == 0) {
    return <NoResults search_term={this.props.query.search_term} />
  } else {
    return (
      <div role="grid">
        <div
          ref="accessibilityMessage"
          className="SearchResults__accessbilityMessage col-xs"
          tabIndex="0"
        >
          {I18n.t(
            'Warning: For improved accessibility in moving files, please use the Move To Dialog option found in the menu.'
          )}
        </div>
        <ColumnHeaders
          to="search"
          query={this.props.query}
          params={this.props.params}
          pathname={this.props.pathname}
          toggleAllSelected={this.props.toggleAllSelected}
          areAllItemsSelected={this.props.areAllItemsSelected}
          usageRightsRequiredForContext={this.props.usageRightsRequiredForContext}
        />
        {this.state.collection.models
          .sort(
            Folder.prototype.childrenSorter.bind(
              this.state.collection,
              this.props.query.sort,
              this.props.query.order
            )
          )
          .map(child => (
              <FolderChild
                key={child.cid}
                model={child}
                isSelected={_.indexOf(this.props.selectedItems, child) >= 0}
                toggleSelected={this.props.toggleItemSelected.bind(null, child)}
                userCanManageFilesForContext={this.props.userCanManageFilesForContext}
                userCanRestrictFilesForContext={this.props.userCanRestrictFilesForContext}
                usageRightsRequiredForContext={this.props.usageRightsRequiredForContext}
                externalToolsForContext={this.props.externalToolsForContext}
                previewItem={this.props.previewItem.bind(null, child)}
                dndOptions={this.props.dndOptions}
                modalOptions={this.props.modalOptions}
                clearSelectedItems={this.props.clearSelectedItems}
                onMove={this.props.onMove}
              />
            ))}

        <LoadingIndicator isLoading={!this.state.collection.loadedAll} />

        {this.renderFilePreview()}
      </div>
    )
  }
}

export default createReactClass(SearchResults)
