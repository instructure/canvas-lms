// Copyright (C) 2020 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import React from 'react'
import {render} from '@testing-library/react'
import FeaturedHelpLink from '../FeaturedHelpLink'

describe('FeaturedHelpLink', () => {
  const featuredLink = {
    id: 'search_the_canvas_guides',
    type: 'default',
    available_to: ['user', 'student', 'teacher', 'admin', 'observer', 'unenrolled'],
    text: 'Search the Canvas Guides',
    subtext: 'Find answers to common questions',
    url: 'https://community.canvaslms.test/t5/Canvas/ct-p/canvas',
    is_featured: true,
    is_new: false,
    feature_headline: 'Little Lost? Try here first!',
  }
  const props = {
    featuredLink,
    handleClick() {},
  }

  beforeEach(() => {
    window.ENV = {FEATURES: {featured_help_links: true}}
  })

  afterEach(() => {
    window.ENV = {}
  })

  it('renders a featured link when enabled', () => {
    const {queryByText} = render(<FeaturedHelpLink {...props} />)
    expect(queryByText('Little Lost? Try here first!')).toBeInTheDocument()
  })

  it('does not render anything when the FF is disabled', () => {
    window.ENV = {FEATURES: {featured_help_links: false}}
    const {queryByText} = render(<FeaturedHelpLink {...props} />)
    expect(queryByText('Little Lost? Try here first!')).not.toBeInTheDocument()
  })

  it('does not render anything when there is no featured link', () => {
    const {queryByText} = render(<FeaturedHelpLink />)
    expect(queryByText('Little Lost? Try here first!')).not.toBeInTheDocument()
  })
})
