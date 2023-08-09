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
import {render} from '@testing-library/react'
import CollectionPanel from '../CollectionPanel'

function renderComponent(props) {
  return render(
    <CollectionPanel
      contextId="1"
      contextType="course"
      collections={{
        assignments: {
          hasMore: false,
          isLoading: false,
          links: [
            {href: 'url1', title: 'link1'},
            {href: 'url2', title: 'link2'},
          ],
        },
      }}
      collection="assignments"
      label="Assignments"
      renderNewPageLink={false}
      suppressRenderEmpty={false}
      fetchInitialPage={() => {}}
      fetchNextPage={() => {}}
      onLinkClick={() => {}}
      newPageLinkExpanded={false}
      toggleNewPageForm={() => {}}
      onChangeAccordion={() => {}}
      selectedAccordionIndex="assignments"
      {...props}
    />
  )
}

describe('RCE "Links" Plugin > CollectionPanel', () => {
  it('renders an expnded collection panel', () => {
    const {getByText, getByTestId} = renderComponent()

    expect(getByTestId('instructure_links-AccordionSection')).toBeInTheDocument()
    expect(getByTestId('instructure_links-LinkSet')).toBeInTheDocument()
    expect(getByText('Assignments')).toBeInTheDocument()
    expect(getByText('link1')).toBeInTheDocument()
    expect(getByText('link2')).toBeInTheDocument()
  })

  it('renders a collapsed collection panel', () => {
    const {getByText, getByTestId, queryByTestId} = renderComponent({
      selectedAccordionIndex: 'modules',
    })

    expect(getByTestId('instructure_links-AccordionSection')).toBeInTheDocument()
    expect(queryByTestId('instructure_links-LinkSet')).toBeNull()
    expect(getByText('Assignments')).toBeInTheDocument()
  })
})
