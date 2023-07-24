/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {collectionsShape, linkShape} from './propTypes'
import AccordionSection from './AccordionSection'
import LinkSet from './LinkSet'

export default function CollectionPanel(props) {
  const accordionProps = {
    collection: props.collection,
    onToggle: props.onChangeAccordion,
    expanded: props.selectedAccordionIndex === props.collection,
    label: props.label,
  }

  function fetchInitialPage() {
    if (props.fetchInitialPage) {
      props.fetchInitialPage(props.collection, props.searchString)
    }
  }

  function fetchNextPage() {
    if (props.fetchNextPage) {
      props.fetchNextPage(props.collection, props.searchString)
    }
  }
  return (
    <div data-testid="instructure_links-CollectionPanel">
      <AccordionSection {...accordionProps}>
        <LinkSet
          fetchInitialPage={fetchInitialPage}
          fetchNextPage={fetchNextPage}
          type={props.collection}
          collection={props.collections[props.collection]}
          onLinkClick={props.onLinkClick}
          suppressRenderEmpty={props.suppressRenderEmpty}
          contextType={props.contextType}
          contextId={props.contextId}
          searchString={props.searchString}
          editing={props.editing}
          onEditClick={props.onEditClick}
          selectedLink={props.selectedLink}
        />
      </AccordionSection>
    </div>
  )
}

CollectionPanel.propTypes = {
  contextId: string.isRequired,
  contextType: string.isRequired,
  searchString: string,
  collections: collectionsShape.isRequired,
  collection: string.isRequired,
  label: string.isRequired,
  renderNewPageLink: bool,
  suppressRenderEmpty: bool,
  fetchInitialPage: func,
  fetchNextPage: func,
  onLinkClick: func,
  newPageLinkExpanded: bool,
  toggleNewPageForm: func,
  onChangeAccordion: func.isRequired,
  selectedAccordionIndex: string,
  editing: bool,
  onEditClick: func,
  selectedLink: linkShape,
}

CollectionPanel.defaultProps = {
  renderNewPageLink: false,
  suppressRenderEmpty: false,
  editing: false,
}
