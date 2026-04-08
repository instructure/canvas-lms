/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {
  isSubstitutionVariable,
  extractSubstitutionVariables,
  compareSubstitutionVariables,
  SubstitutionVariable,
} from '../extractSubstitutionVariables'
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'

const mockConfig = (overrides?: Partial<InternalLtiConfiguration>): InternalLtiConfiguration => ({
  title: 'Test Tool',
  description: 'Test Description',
  target_link_uri: 'https://example.com',
  oidc_initiation_url: 'https://example.com/oidc',
  custom_fields: {},
  scopes: [],
  placements: [],
  launch_settings: {},
  ...overrides,
})

describe('isSubstitutionVariable', () => {
  it('returns true for valid Canvas substitution variables', () => {
    expect(isSubstitutionVariable('$Canvas.user.id')).toBe(true)
    expect(isSubstitutionVariable('$User.id')).toBe(true)
    expect(isSubstitutionVariable('$Person.name.full')).toBe(true)
    expect(isSubstitutionVariable('$Canvas.course.id')).toBe(true)
    expect(isSubstitutionVariable('$com.instructure.User.observees')).toBe(true)
  })

  it('returns false for non-substitution variables', () => {
    expect(isSubstitutionVariable('regular_string')).toBe(false)
    expect(isSubstitutionVariable('$NotAVariable')).toBe(false)
    expect(isSubstitutionVariable('Canvas.user.id')).toBe(false)
    expect(isSubstitutionVariable('')).toBe(false)
    expect(isSubstitutionVariable('$')).toBe(false)
  })

  it('returns false for custom non-Canvas variables', () => {
    expect(isSubstitutionVariable('$custom.variable')).toBe(false)
    expect(isSubstitutionVariable('$my.custom.field')).toBe(false)
  })
})

describe('extractSubstitutionVariables', () => {
  it('returns empty set when config is undefined', () => {
    const result = extractSubstitutionVariables(undefined)
    expect(result.size).toBe(0)
  })

  it('returns empty set when no custom fields are present', () => {
    const config = mockConfig()
    const result = extractSubstitutionVariables(config)
    expect(result.size).toBe(0)
  })

  it('extracts variables from base custom_fields', () => {
    const config = mockConfig({
      custom_fields: {
        user_id: '$Canvas.user.id',
        course_id: '$Canvas.course.id',
        regular_field: 'not_a_variable',
      },
    })

    const result = extractSubstitutionVariables(config)

    expect(result.size).toBe(2)
    expect(result.has('$Canvas.user.id')).toBe(true)
    expect(result.has('$Canvas.course.id')).toBe(true)
  })

  it('extracts variables from launch_settings custom_fields', () => {
    const config = mockConfig({
      launch_settings: {
        custom_fields: {
          user_name: '$Person.name.full',
          user_email: '$Person.email.primary',
        },
      },
    })

    const result = extractSubstitutionVariables(config)

    expect(result.size).toBe(2)
    expect(result.has('$Person.name.full')).toBe(true)
    expect(result.has('$Person.email.primary')).toBe(true)
  })

  it('extracts variables from placement custom_fields', () => {
    const config = mockConfig({
      placements: [
        {
          placement: 'course_navigation',
          custom_fields: {
            context_id: '$Context.id',
          },
        },
        {
          placement: 'assignment_selection',
          custom_fields: {
            assignment_id: '$Canvas.assignment.id',
          },
        },
      ],
    })

    const result = extractSubstitutionVariables(config)

    expect(result.size).toBe(2)
    expect(result.has('$Context.id')).toBe(true)
    expect(result.has('$Canvas.assignment.id')).toBe(true)
  })

  it('deduplicates variables across all levels', () => {
    const config = mockConfig({
      custom_fields: {
        user_id: '$Canvas.user.id',
      },
      launch_settings: {
        custom_fields: {
          user_id_again: '$Canvas.user.id', // duplicate
        },
      },
      placements: [
        {
          placement: 'course_navigation',
          custom_fields: {
            user_id_third: '$Canvas.user.id', // duplicate again
            course_id: '$Canvas.course.id',
          },
        },
      ],
    })

    const result = extractSubstitutionVariables(config)

    expect(result.size).toBe(2) // Only unique variables
    expect(result.has('$Canvas.user.id')).toBe(true)
    expect(result.has('$Canvas.course.id')).toBe(true)
  })

  it('filters out non-Canvas substitution variables', () => {
    const config = mockConfig({
      custom_fields: {
        valid_var: '$Canvas.user.id',
        custom_var: '$my.custom.variable',
        regular_field: 'some_value',
      },
    })

    const result = extractSubstitutionVariables(config)

    expect(result.size).toBe(1)
    expect(result.has('$Canvas.user.id')).toBe(true)
    expect(result.has('$my.custom.variable' as SubstitutionVariable)).toBe(false)
  })

  it('handles null and undefined custom_fields gracefully', () => {
    const config = mockConfig({
      custom_fields: null,
      launch_settings: {
        custom_fields: undefined,
      },
      placements: [
        {
          placement: 'course_navigation',
          custom_fields: undefined,
        },
      ],
    })

    const result = extractSubstitutionVariables(config)
    expect(result.size).toBe(0)
  })

  it('extracts multiple types of substitution variables', () => {
    const config = mockConfig({
      custom_fields: {
        resource_link: '$ResourceLink.id',
        user_id: '$User.id',
        person_name: '$Person.name.full',
        canvas_user: '$Canvas.user.id',
        instructure_var: '$com.instructure.User.observees',
        vnd_var: '$vnd.instructure.User.uuid',
      },
    })

    const result = extractSubstitutionVariables(config)

    expect(result.size).toBe(6)
    expect(result.has('$ResourceLink.id')).toBe(true)
    expect(result.has('$User.id')).toBe(true)
    expect(result.has('$Person.name.full')).toBe(true)
    expect(result.has('$Canvas.user.id')).toBe(true)
    expect(result.has('$com.instructure.User.observees')).toBe(true)
    expect(result.has('$vnd.instructure.User.uuid')).toBe(true)
  })
})

describe('compareSubstitutionVariables', () => {
  it('returns all variables as unchanged when newConfig is undefined', () => {
    const oldConfig = mockConfig({
      custom_fields: {
        user_id: '$Canvas.user.id',
        course_id: '$Canvas.course.id',
      },
    })

    const result = compareSubstitutionVariables(oldConfig, undefined)

    expect(result.unchanged.size).toBe(2)
    expect(result.added.size).toBe(0)
    expect(result.removed.size).toBe(0)
    expect(result.unchanged.has('$Canvas.user.id')).toBe(true)
    expect(result.unchanged.has('$Canvas.course.id')).toBe(true)
  })

  it('identifies added variables', () => {
    const oldConfig = mockConfig({
      custom_fields: {
        user_id: '$Canvas.user.id',
      },
    })

    const newConfig = mockConfig({
      custom_fields: {
        user_id: '$Canvas.user.id',
        course_id: '$Canvas.course.id',
        assignment_id: '$Canvas.assignment.id',
      },
    })

    const result = compareSubstitutionVariables(oldConfig, newConfig)

    expect(result.unchanged.size).toBe(1)
    expect(result.added.size).toBe(2)
    expect(result.removed.size).toBe(0)
    expect(result.unchanged.has('$Canvas.user.id')).toBe(true)
    expect(result.added.has('$Canvas.course.id')).toBe(true)
    expect(result.added.has('$Canvas.assignment.id')).toBe(true)
  })

  it('identifies removed variables', () => {
    const oldConfig = mockConfig({
      custom_fields: {
        user_id: '$Canvas.user.id',
        course_id: '$Canvas.course.id',
        assignment_id: '$Canvas.assignment.id',
      },
    })

    const newConfig = mockConfig({
      custom_fields: {
        user_id: '$Canvas.user.id',
      },
    })

    const result = compareSubstitutionVariables(oldConfig, newConfig)

    expect(result.unchanged.size).toBe(1)
    expect(result.added.size).toBe(0)
    expect(result.removed.size).toBe(2)
    expect(result.unchanged.has('$Canvas.user.id')).toBe(true)
    expect(result.removed.has('$Canvas.course.id')).toBe(true)
    expect(result.removed.has('$Canvas.assignment.id')).toBe(true)
  })

  it('identifies both added and removed variables', () => {
    const oldConfig = mockConfig({
      custom_fields: {
        user_id: '$Canvas.user.id',
        course_id: '$Canvas.course.id',
      },
    })

    const newConfig = mockConfig({
      custom_fields: {
        user_id: '$Canvas.user.id',
        assignment_id: '$Canvas.assignment.id',
      },
    })

    const result = compareSubstitutionVariables(oldConfig, newConfig)

    expect(result.unchanged.size).toBe(1)
    expect(result.added.size).toBe(1)
    expect(result.removed.size).toBe(1)
    expect(result.unchanged.has('$Canvas.user.id')).toBe(true)
    expect(result.added.has('$Canvas.assignment.id')).toBe(true)
    expect(result.removed.has('$Canvas.course.id')).toBe(true)
  })

  it('returns all empty sets when both configs have no variables', () => {
    const oldConfig = mockConfig()
    const newConfig = mockConfig()

    const result = compareSubstitutionVariables(oldConfig, newConfig)

    expect(result.unchanged.size).toBe(0)
    expect(result.added.size).toBe(0)
    expect(result.removed.size).toBe(0)
  })

  it('handles changes across different configuration levels', () => {
    const oldConfig = mockConfig({
      custom_fields: {
        user_id: '$Canvas.user.id',
      },
      placements: [
        {
          placement: 'course_navigation',
          custom_fields: {
            course_id: '$Canvas.course.id',
          },
        },
      ],
    })

    const newConfig = mockConfig({
      launch_settings: {
        custom_fields: {
          user_id: '$Canvas.user.id',
        },
      },
      placements: [
        {
          placement: 'assignment_selection',
          custom_fields: {
            assignment_id: '$Canvas.assignment.id',
          },
        },
      ],
    })

    const result = compareSubstitutionVariables(oldConfig, newConfig)

    expect(result.unchanged.size).toBe(1) // $Canvas.user.id is in both
    expect(result.added.size).toBe(1) // $Canvas.assignment.id is new
    expect(result.removed.size).toBe(1) // $Canvas.course.id is removed
    expect(result.unchanged.has('$Canvas.user.id')).toBe(true)
    expect(result.added.has('$Canvas.assignment.id')).toBe(true)
    expect(result.removed.has('$Canvas.course.id')).toBe(true)
  })

  it('correctly handles when all variables are new', () => {
    const oldConfig = mockConfig()
    const newConfig = mockConfig({
      custom_fields: {
        user_id: '$Canvas.user.id',
        course_id: '$Canvas.course.id',
      },
    })

    const result = compareSubstitutionVariables(oldConfig, newConfig)

    expect(result.unchanged.size).toBe(0)
    expect(result.added.size).toBe(2)
    expect(result.removed.size).toBe(0)
  })

  it('correctly handles when all variables are removed', () => {
    const oldConfig = mockConfig({
      custom_fields: {
        user_id: '$Canvas.user.id',
        course_id: '$Canvas.course.id',
      },
    })
    const newConfig = mockConfig()

    const result = compareSubstitutionVariables(oldConfig, newConfig)

    expect(result.unchanged.size).toBe(0)
    expect(result.added.size).toBe(0)
    expect(result.removed.size).toBe(2)
  })
})
