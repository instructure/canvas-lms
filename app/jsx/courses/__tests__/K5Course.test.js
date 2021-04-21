/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import moxios from 'moxios'
import {render} from '@testing-library/react'
import K5Course from '../K5Course'

const currentUser = {
  id: '1',
  display_name: 'Geoffrey Jellineck'
}
const defaultEnv = {
  current_user: currentUser,
  K5_MODE: true,
  FEATURES: {
    canvas_for_elementary: true,
    unpublished_courses: true
  },
  PREFERENCES: {
    hide_dashcard_color_overlays: false
  },
  MOMENT_LOCALE: 'en',
  TIMEZONE: 'America/Denver'
}
const defaultProps = {
  currentUser,
  loadAllOpportunities: () => {},
  name: 'Arts and Crafts',
  timeZone: defaultEnv.TIMEZONE
}

beforeAll(() => {
  moxios.install()
})

afterAll(() => {
  moxios.uninstall()
})

beforeEach(() => {
  global.ENV = defaultEnv
})

afterEach(() => {
  global.ENV = {}
})

describe('K-5 Subject Course', () => {
  describe('Tabs Header', () => {
    it('displays a huge version of the course image if set', () => {
      const imageUrl = 'https://example.com/path/to/image.png'
      const {getByTestId} = render(<K5Course {...defaultProps} imageUrl={imageUrl} />)
      const hero = getByTestId('k5-course-header-hero')

      expect(hero).toBeInTheDocument()
      expect(hero.style.getPropertyValue('background-image')).toBe(`url(${imageUrl})`)
    })

    it('displays a gray background on the hero header if no image is set', () => {
      const {getByTestId} = render(<K5Course {...defaultProps} />)
      const hero = getByTestId('k5-course-header-hero')

      expect(hero.style.getPropertyValue('background-color')).toBe('rgb(199, 205, 209)')
    })

    it('displays the course name', () => {
      const {getByText} = render(<K5Course {...defaultProps} />)
      expect(getByText(defaultProps.name)).toBeInTheDocument()
    })

    it('shows Overview, Schedule, Modules, and Grades options', () => {
      const {getByText} = render(<K5Course {...defaultProps} />)
      ;['Overview', 'Schedule', 'Modules', 'Grades'].forEach(label =>
        expect(getByText(label)).toBeInTheDocument()
      )
    })

    it('defaults to the Overview tab', () => {
      const {getByRole} = render(<K5Course {...defaultProps} />)
      expect(getByRole('tab', {name: 'Overview', selected: true})).toBeInTheDocument()
    })
  })
})
