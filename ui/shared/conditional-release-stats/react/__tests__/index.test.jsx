/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import CyoeStats from '../index'

const defaultEnv = {
  ranges: [
    {
      scoring_range: {
        id: 1,
        rule_id: 1,
        lower_bound: 0.7,
        upper_bound: 1.0,
        created_at: null,
        updated_at: null,
        position: null,
      },
      size: 0,
      students: [],
    },
    {
      scoring_range: {
        id: 3,
        rule_id: 1,
        lower_bound: 0.4,
        upper_bound: 0.7,
        created_at: null,
        updated_at: null,
        position: null,
      },
      size: 0,
      students: [],
    },
    {
      scoring_range: {
        id: 2,
        rule_id: 1,
        lower_bound: 0.0,
        upper_bound: 0.4,
        created_at: null,
        updated_at: null,
        position: null,
      },
      size: 0,
      students: [],
    },
  ],
  enrolled: 10,
  assignment: {
    id: 7,
    title: 'Points',
    description: '',
    points_possible: 15,
    grading_type: 'points',
    submission_types: 'on_paper',
    grading_scheme: null,
  },
  isLoading: false,
  selectRange: () => {},
  rule: {
    trigger_assignment: {
      id: 7,
      title: 'Points',
    },
  },
}

describe('CyoeStats', () => {
  let container

  beforeEach(() => {
    container = document.createElement('div')
    document.body.appendChild(container)
    window.ENV = {
      CONDITIONAL_RELEASE_SERVICE_ENABLED: true,
      CONDITIONAL_RELEASE_ENV: defaultEnv,
      current_user_roles: ['teacher'],
    }
  })

  afterEach(() => {
    document.body.removeChild(container)
    delete window.ENV
  })

  const TestContainer = () => (
    <div>
      <div data-testid="test-details" />
      <div data-testid="test-graphs" />
    </div>
  )

  const initCyoeStats = () => {
    const {getByTestId} = render(<TestContainer />, {container})
    const graphsRoot = getByTestId('test-graphs')
    const detailsParent = getByTestId('test-details')
    CyoeStats.init(graphsRoot, detailsParent)
    return {graphsRoot}
  }

  it('renders components in the correct places when mastery paths enabled', () => {
    const consoleError = jest.spyOn(console, 'error').mockImplementation(() => {})
    const {graphsRoot} = initCyoeStats()
    expect(graphsRoot.getElementsByClassName('crs-breakdown-graph')).toHaveLength(1)
    consoleError.mockRestore()
  })

  it('does not render components when mastery paths not enabled', () => {
    window.ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
    const {graphsRoot} = initCyoeStats()
    expect(graphsRoot.getElementsByClassName('crs-breakdown-graph')).toHaveLength(0)
  })

  it('does not render if there is no rule defined', () => {
    window.ENV.CONDITIONAL_RELEASE_ENV.rule = null
    const {graphsRoot} = initCyoeStats()
    expect(graphsRoot.getElementsByClassName('crs-breakdown-graph')).toHaveLength(0)
  })
})
