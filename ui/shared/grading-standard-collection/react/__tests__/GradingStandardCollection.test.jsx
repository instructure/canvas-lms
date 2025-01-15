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
import {render, screen, within} from '@testing-library/react'
import GradingStandardCollection from '../index'

// Mock jQuery and its plugins
jest.mock('@canvas/jquery/jquery.instructure_misc_plugins', () => {})

jest.mock('jquery', () => {
  const mockJQuery = jest.fn(() => mockJQuery)
  mockJQuery.fn = {
    defaultAjaxError: jest.fn(),
    extend: jest.fn((_deep, obj) => obj),
  }
  mockJQuery.getJSON = jest.fn()
  mockJQuery.extend = jest.fn((_deep, obj) => obj)
  mockJQuery.flashMessage = jest.fn()
  mockJQuery.flashError = jest.fn()
  return mockJQuery
})

describe('GradingStandardCollection', () => {
  const mockStandards = [
    {
      grading_standard: {
        title: 'Hard to Fail',
        id: '1',
        data: [
          ['A', 0.2],
          ['B', 0.1],
          ['C', 0],
        ],
        permissions: {
          read: true,
          manage: true,
        },
        context_type: 'Course',
        context_id: '1',
        context_code: 'course_1',
      },
    },
  ]

  beforeEach(() => {
    window.ENV = {
      current_user_roles: ['admin', 'teacher'],
      GRADING_STANDARDS_URL: '/courses/1/grading_standards',
      DEFAULT_GRADING_STANDARD_DATA: [
        ['A', 0.94],
        ['B', 0.84],
        ['C', 0.74],
        ['D', 0.64],
        ['F', 0],
      ],
      context_asset_string: 'course_1',
    }

    // Setup jQuery mock responses
    const $ = require('jquery')
    $.getJSON.mockImplementation(() => {
      return {
        done: callback => {
          callback(mockStandards)
          return {
            fail: () => {
              return {}
            },
          }
        },
      }
    })

    // Mock jQuery.extend to properly clone objects
    $.extend = jest.fn((deep, target, ...sources) => {
      if (deep) {
        return JSON.parse(JSON.stringify(Object.assign({}, target, ...sources)))
      }
      return Object.assign({}, target, ...sources)
    })
  })

  afterEach(() => {
    jest.clearAllMocks()
    delete window.ENV
  })

  it('shows empty state when no standards exist', async () => {
    const $ = require('jquery')
    $.getJSON.mockImplementation(() => ({
      done: callback => {
        callback([])
        return {
          fail: () => ({}),
        }
      },
    }))

    render(<GradingStandardCollection />)
    expect(await screen.findByText('No grading schemes to display')).toBeInTheDocument()
  })

  it('renders standards with correct data', async () => {
    render(<GradingStandardCollection />)

    // Wait for the standards to load and render
    const standardContainer = await screen.findByTestId('grading_standard_1')
    expect(standardContainer).toBeInTheDocument()

    // Check for the title within the standard container
    const titleElement = within(standardContainer).getByText('Hard to Fail')
    expect(titleElement).toBeInTheDocument()

    // Check for the grade names and their corresponding percentages
    expect(screen.getByText('A')).toBeInTheDocument()
    expect(screen.getByText('to 20%')).toBeInTheDocument()

    expect(screen.getByText('B')).toBeInTheDocument()
    expect(screen.getByText('to 10%')).toBeInTheDocument()

    expect(screen.getByText('C')).toBeInTheDocument()
    expect(screen.getByText('to 0%')).toBeInTheDocument()
  })

  it('enables add button for admin/teacher roles', async () => {
    render(<GradingStandardCollection />)
    const addButton = screen.getByRole('button', {name: /add grading scheme/i})
    expect(addButton).not.toHaveClass('disabled')
  })

  it('disables add button for student role', async () => {
    window.ENV.current_user_roles = ['student']
    render(<GradingStandardCollection />)
    const addButton = screen.getByRole('button', {name: /add grading scheme/i})
    expect(addButton).toHaveClass('disabled')
  })

  it('renders the correct standard data', async () => {
    render(<GradingStandardCollection />)

    // Wait for standards to load
    await screen.findByTestId('grading_standard_1')

    // Check for correct standard data
    expect(screen.getByText('Hard to Fail')).toBeInTheDocument()
    expect(screen.getByText('A')).toBeInTheDocument()
    expect(screen.getByText('to 20%')).toBeInTheDocument()
    expect(screen.getByText('C')).toBeInTheDocument()
    expect(screen.getByText('to 0%')).toBeInTheDocument()
  })

  it('formats decimal grades to percentages', async () => {
    render(<GradingStandardCollection />)

    // Wait for standards to load and verify the percentage conversion
    await screen.findByTestId('grading_standard_1')
    expect(screen.getByText('to 20%')).toBeInTheDocument() // 0.2 -> 20%
    expect(screen.getByText('to 0%')).toBeInTheDocument() // 0 -> 0%
  })
})
