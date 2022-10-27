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
import LinksPanel from '../LinksPanel'

function makeCollection(overrides = {}) {
  return {
    hasMore: false,
    isLoading: false,
    links: [],
    ...overrides,
  }
}

function renderComponent(renderer, props) {
  return renderer(
    <LinksPanel
      selectedAccordionIndex=""
      onChangeAccordion={() => {}}
      contextType="course"
      contextId="1"
      collections={{
        wikiPages: makeCollection(),
        assignments: makeCollection({
          links: [
            {href: 'url1', title: 'link1'},
            {href: 'url2', title: 'link2'},
          ],
        }),
        quizzes: makeCollection(),
        announcements: makeCollection(),
        discussions: makeCollection(),
        modules: {
          hasMore: false,
          isLoading: false,
          links: [
            {href: 'url3', title: 'link3'},
            {href: 'url4', title: 'link4'},
          ],
        },
      }}
      fetchInitialPage={() => {}}
      fetchNextPage={() => {}}
      onLinkClick={() => {}}
      {...props}
    />
  )
}

describe('RCE "Links" Plugin > LinksPanel', () => {
  it('renders a links panel with accordion fully collapsed', () => {
    const {getByText, queryAllByTestId, queryAllByText} = renderComponent(render)

    expect(queryAllByTestId('instructure_links-LinksPanel')).toHaveLength(1)
    expect(queryAllByTestId('instructure_links-CollectionPanel')).toHaveLength(6)
    expect(queryAllByTestId('instructure_links-NavigationPanel')).toHaveLength(1)
    expect(getByText('Pages')).toBeInTheDocument()
    expect(getByText('Assignments')).toBeInTheDocument()
    expect(getByText('Quizzes')).toBeInTheDocument()
    expect(getByText('Announcements')).toBeInTheDocument()
    expect(getByText('Discussions')).toBeInTheDocument()
    expect(getByText('Modules')).toBeInTheDocument()
    expect(getByText('Course Navigation')).toBeInTheDocument()
    expect(queryAllByText('Expand to see', {exact: false})).toHaveLength(7)
    expect(queryAllByText('Collapse to see', {exact: false})).toHaveLength(0)
  })

  it('expands one panel at a time', () => {
    const {queryAllByText, rerender} = renderComponent(render, {
      selectedAccordionIndex: 'modules',
    })

    expect(queryAllByText('Expand to see', {exact: false})).toHaveLength(6)
    expect(queryAllByText('Collapse to hide Modules')).toHaveLength(1)

    renderComponent(rerender, {
      selectedAccordionIndex: 'assignments',
    })

    expect(queryAllByText('Expand to see', {exact: false})).toHaveLength(6)
    expect(queryAllByText('Collapse to hide Assignments')).toHaveLength(1)
  })
})
