/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {IconBlank, getIcon} from '../linkUtils'
import {
  IconAssignmentLine,
  IconDiscussionLine,
  IconModuleLine,
  IconQuizLine,
  IconQuizSolid as IconNewQuiz,
  IconAnnouncementLine,
  IconDocumentLine,
} from '@instructure/ui-icons'

describe('linkUtils', () => {
  describe('IconBlank', () => {
    it('renders a blank icon', () => {
      const {container} = render(<IconBlank />)
      const svg = container.querySelector('svg[name="IconBlank"]')
      expect(svg).toBeInTheDocument()
    })
  })

  describe('getIcon', () => {
    it('returns assignment icon when course link type is an assignment', () => {
      expect(getIcon('assignments')).toEqual(IconAssignmentLine)
    })

    it('returns discussion icon when course link type is an discussion', () => {
      expect(getIcon('discussions')).toEqual(IconDiscussionLine)
    })

    it('returns module icon when course link type is an module', () => {
      expect(getIcon('modules')).toEqual(IconModuleLine)
    })

    it('returns quiz icon when course link type is an quiz', () => {
      expect(getIcon('quizzes')).toEqual(IconQuizLine)
    })

    it('returns new quiz icon when course link type is a new quiz', () => {
      expect(getIcon('quizzes.next')).toEqual(IconNewQuiz)
    })

    it('returns announcement icon when course link type is an announcement', () => {
      expect(getIcon('announcements')).toEqual(IconAnnouncementLine)
    })

    it('returns document icon when course link type is an wiki page', () => {
      expect(getIcon('wikiPages')).toEqual(IconDocumentLine)
    })

    it('returns blank icon when course link type is navigation', () => {
      expect(getIcon('navigation')).toEqual(IconBlank)
    })

    it('returns document icon by default', () => {
      expect(getIcon('not a real course link type')).toEqual(IconDocumentLine)
    })
  })
})
