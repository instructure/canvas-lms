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
import HelpLinks from '../HelpLinks'

describe('HelpLinks', () => {
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
  const newLink = {
    id: 'link1',
    text: 'Google',
    subtext: 'Have you tried google?',
    url: 'https://google.com',
    type: 'custom',
    available_to: ['user', 'student', 'teacher', 'admin', 'observer', 'unenrolled'],
    is_featured: false,
    is_new: true,
  }
  const regularLink = {
    id: 'report_a_problem',
    type: 'default',
    available_to: ['user', 'student', 'teacher', 'admin', 'observer', 'unenrolled'],
    text: 'Report a Problem',
    subtext: 'If Canvas misbehaves, tell us about it',
    url: '#create_ticket',
    is_featured: false,
    is_new: false,
  }
  const props = {
    links: [featuredLink, newLink, regularLink],
    hasLoaded: true,
    onClick() {},
  }

  beforeEach(() => {
    window.ENV = {FEATURES: {featured_help_links: true}}
  })

  afterEach(() => {
    window.ENV = {}
  })

  it('renders all the links', () => {
    const {queryByText} = render(<HelpLinks {...props} />)
    expect(queryByText('Google')).toBeInTheDocument()
    expect(queryByText('Search the Canvas Guides')).toBeInTheDocument()
    expect(queryByText('Report a Problem')).toBeInTheDocument()
  })

  it('renders all the links when the FF is disabled', () => {
    window.ENV = {FEATURES: {featured_help_links: false}}
    const {queryByText} = render(<HelpLinks {...props} />)
    expect(queryByText('Google')).toBeInTheDocument()
    expect(queryByText('Search the Canvas Guides')).toBeInTheDocument()
    expect(queryByText('Report a Problem')).toBeInTheDocument()
  })

  it('renders the separator when there is a featured link, additional links, and the FF is enabled', () => {
    const {queryByText} = render(<HelpLinks {...props} />)
    expect(queryByText('OTHER RESOURCES')).toBeInTheDocument()
  })

  it('does not render the separator if there is no featured link', () => {
    const {queryByText} = render(<HelpLinks {...props} links={[newLink, regularLink]} />)
    expect(queryByText('OTHER RESOURCES')).not.toBeInTheDocument()
  })

  it('does not render the separator if the FF is disabled', () => {
    window.ENV = {FEATURES: {featured_help_links: false}}
    const {queryByText} = render(<HelpLinks {...props} />)
    expect(queryByText('OTHER RESOURCES')).not.toBeInTheDocument()
  })

  it('does not render the separator if there is only a featured link', () => {
    const {queryByText} = render(<HelpLinks {...props} links={[featuredLink]} />)
    expect(queryByText('OTHER RESOURCES')).not.toBeInTheDocument()
  })

  it('renders a "NEW" pill when a link is tagged with is_new', () => {
    const {queryByText} = render(<HelpLinks {...props} links={[newLink]} />)
    expect(queryByText('NEW')).toBeInTheDocument()
  })

  it('does not render a "NEW" pill if there is no link tagged with is_new', () => {
    const {queryByText} = render(<HelpLinks {...props} links={[featuredLink, regularLink]} />)
    expect(queryByText('NEW')).not.toBeInTheDocument()
  })

  it('does not render a "NEW" pill if the FF is disabled', () => {
    window.ENV = {FEATURES: {featured_help_links: false}}
    const {queryByText} = render(<HelpLinks {...props} />)
    expect(queryByText('NEW')).not.toBeInTheDocument()
  })
})
