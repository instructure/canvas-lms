/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {NoResults, buildUrl, getMessage, CollectionType} from '../NoResults'

describe('buildUrl', () => {
  it('returns the correct URL non standard cases', () => {
    expect(buildUrl('course', '1', 'wikiPages')).toEqual('/courses/1/pages')
    expect(buildUrl('course', '2', 'discussions')).toEqual('/courses/2/discussion_topics')
  })

  it('returns the correct URL for standard cases', () => {
    expect(buildUrl('course', '3', 'assignments')).toEqual('/courses/3/assignments')
    expect(buildUrl('course', '4', 'quizzes')).toEqual('/courses/4/quizzes')
    expect(buildUrl('course', '5', 'announcements')).toEqual('/courses/5/announcements')
    expect(buildUrl('course', '6', 'modules')).toEqual('/courses/6/modules')
  })

  it('returns the correct URL for group contexts', () => {
    expect(buildUrl('group', '7', 'wikiPages')).toEqual('/groups/7/pages')
  })
})

describe('getMessage', () => {
  describe('when isSearchResult is true', () => {
    it('returns the correct message for non standard cases', () => {
      expect(getMessage('wikiPages', true)).toEqual('No pages found.')
    })

    it('returns the correct message for standard cases', () => {
      ;(
        ['discussions', 'assignments', 'quizzes', 'announcements', 'modules'] as CollectionType[]
      ).forEach(collectionType => {
        expect(getMessage(collectionType, true)).toEqual(`No ${collectionType} found.`)
      })
    })
  })

  describe('when isSearchResult is false', () => {
    it('returns the correct message for non standard cases', () => {
      expect(getMessage('wikiPages', false)).toEqual('No pages created yet.')
    })

    it('returns the correct message for standard cases', () => {
      ;(
        ['discussions', 'assignments', 'quizzes', 'announcements', 'modules'] as CollectionType[]
      ).forEach(collectionType => {
        expect(getMessage(collectionType, false)).toEqual(`No ${collectionType} created yet.`)
      })
    })
  })
})

describe('NoResults', () => {
  const props = {
    contextType: 'course' as const,
    contextId: '1',
    collectionType: 'modules' as const,
    isSearchResult: false,
  }

  it('renders the icon dynamically', () => {
    const {container, rerender} = render(<NoResults {...props} />)
    const icon1 = container.querySelector('svg')
    expect(icon1).toHaveAttribute('name', 'IconModule')

    rerender(<NoResults {...props} collectionType="assignments" />)
    const icon2 = container.querySelector('svg')
    expect(icon2).toHaveAttribute('name', 'IconAssignment')
  })

  it('renders the correct message dynamically', () => {
    const {getByText, rerender} = render(<NoResults {...props} />)
    expect(getByText('No modules created yet.')).toBeInTheDocument()

    rerender(<NoResults {...props} collectionType="assignments" />)
    expect(getByText('No assignments created yet.')).toBeInTheDocument()
  })

  it('renders the correct link dynamically', () => {
    const {getByRole, rerender} = render(<NoResults {...props} />)
    const link1 = getByRole('link', {name: /Add one!/})
    expect(link1).toHaveAttribute('href', '/courses/1/modules')

    rerender(<NoResults {...props} collectionType="assignments" />)
    const link2 = getByRole('link', {name: /Add one!/})
    expect(link2).toHaveAttribute('href', '/courses/1/assignments')
  })
})
