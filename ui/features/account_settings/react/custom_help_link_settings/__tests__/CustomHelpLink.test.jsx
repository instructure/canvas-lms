/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import CustomHelpLink from '../CustomHelpLink'
import {render} from '@testing-library/react'

function makeProps(overrides = {}) {
  const linkOverride = overrides.link || {}
  delete overrides.link
  return {
    link: {
      available_to: ['student'],
      text: 'Ask Your Instructor a Question',
      subtext: 'Questions are submitted to your instructor',
      url: '#teacher_feedback',
      type: 'default',
      is_featured: false,
      is_new: false,
      feature_headline: '',
      ...linkOverride,
    },
    ...overrides,
  }
}

describe('<CustomHelpLink/>', () => {
  it('renders', () => {
    const {getByText} = render(<CustomHelpLink {...makeProps()} />)
    expect(getByText('Ask Your Instructor a Question')).toBeInTheDocument()
  })

  it('does not render Featured for featured links', () => {
    const {queryByText} = render(<CustomHelpLink {...makeProps({link: {is_featured: true}})} />)
    expect(queryByText('Featured')).toBeNull()
  })

  describe('with featured help links', () => {
    beforeEach(() => {
      window.ENV = {FEATURES: {featured_help_links: true}}
    })

    afterEach(() => {
      window.ENV = {}
    })

    it('does not render Featured or New for plain links', () => {
      const {queryByText} = render(<CustomHelpLink {...makeProps()} />)
      expect(queryByText('Featured')).toBeNull()
      expect(queryByText('New')).toBeNull()
    })

    it('renders Featured for featured links', () => {
      const {getByText} = render(<CustomHelpLink {...makeProps({link: {is_featured: true}})} />)
      expect(getByText('Featured')).toBeInTheDocument()
    })

    it('renders New for new links', () => {
      const {getByText} = render(<CustomHelpLink {...makeProps({link: {is_new: true}})} />)
      expect(getByText('New')).toBeInTheDocument()
    })
  })
})
