/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import React from 'react'
import {bool, func, string} from 'prop-types'
import formatMessage from '../../../../format-message'

import {collectionsShape, linkShape} from './propTypes'
import NavigationPanel from './NavigationPanel'
import CollectionPanel from './CollectionPanel'

import {View} from '@instructure/ui-view'
import {pickProps} from '@instructure/ui-react-utils'

function LinksPanel(props) {
  const isCourse = props.contextType === 'course'
  const isGroup = props.contextType === 'group'

  const collectionProps = pickProps(props, CollectionPanel.propTypes)
  return (
    <View as="div" data-testid="instructure_links-LinksPanel">
      {(isCourse || isGroup) && (
        <CollectionPanel
          {...collectionProps}
          editing={props.editing}
          onEditClick={props.onEditClick}
          selectedLink={props.selectedLink}
          collection="wikiPages"
          label={formatMessage('Pages')}
        />
      )}

      {isCourse && (
        <CollectionPanel
          {...collectionProps}
          editing={props.editing}
          onEditClick={props.onEditClick}
          selectedLink={props.selectedLink}
          collection="assignments"
          label={formatMessage('Assignments')}
        />
      )}

      {isCourse && (
        <CollectionPanel
          {...collectionProps}
          editing={props.editing}
          onEditClick={props.onEditClick}
          selectedLink={props.selectedLink}
          collection="quizzes"
          label={formatMessage('Quizzes')}
        />
      )}

      {(isCourse || isGroup) && (
        <CollectionPanel
          {...collectionProps}
          editing={props.editing}
          onEditClick={props.onEditClick}
          selectedLink={props.selectedLink}
          collection="announcements"
          label={formatMessage('Announcements')}
        />
      )}

      {(isCourse || isGroup) && (
        <CollectionPanel
          {...collectionProps}
          editing={props.editing}
          onEditClick={props.onEditClick}
          selectedLink={props.selectedLink}
          collection="discussions"
          label={formatMessage('Discussions')}
        />
      )}

      {isCourse && (
        <CollectionPanel
          {...collectionProps}
          editing={props.editing}
          onEditClick={props.onEditClick}
          selectedLink={props.selectedLink}
          collection="modules"
          label={formatMessage('Modules')}
        />
      )}

      <NavigationPanel
        contextType={props.contextType}
        contextId={props.contextId}
        onLinkClick={props.onLinkClick}
        onChangeAccordion={props.onChangeAccordion}
        selectedAccordionIndex={props.selectedAccordionIndex}
        editing={props.editing}
        onEditClick={props.onEditClick}
      />
    </View>
  )
}

LinksPanel.propTypes = {
  selectedAccordionIndex: string,
  onChangeAccordion: func,
  contextType: string.isRequired,
  contextId: string.isRequired,
  searchString: string,
  collections: collectionsShape.isRequired,
  fetchInitialPage: func,
  fetchNextPage: func,
  onLinkClick: func,
  canCreatePages: bool,
  editing: bool,
  onEditClick: func,
  selectedLink: linkShape,
}

LinksPanel.defaultProps = {
  selectedAccordionIndex: '',
  editing: false,
}

export default LinksPanel
