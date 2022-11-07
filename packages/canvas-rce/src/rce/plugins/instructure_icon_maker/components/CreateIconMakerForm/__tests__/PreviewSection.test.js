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
import {getByText, render} from '@testing-library/react'
import {DEFAULT_SETTINGS} from '../../../svg/constants'
import {Preview} from '../Preview'

describe('<Preview />', () => {
  it('renders the svg preview', () => {
    const {container} = render(
      <Preview
        settings={{
          ...DEFAULT_SETTINGS,
          color: null,
          outlineColor: '#0f0',
          outlineSize: 'medium',
          shape: 'triangle',
          size: 'large',
        }}
      />
    )

    expect(container.querySelector('svg')).toMatchInlineSnapshot(`
      <svg
        fill="none"
        height="218px"
        style="padding: 16px"
        viewBox="0 0 218 218"
        width="218px"
        xmlns="http://www.w3.org/2000/svg"
      >
        <svg
          fill="none"
          height="218px"
          viewBox="0 0 218 218"
          width="218px"
          x="0"
        >
          <g
            fill="none"
          >
            <path
              d="M109 8L210 214H8L109 8Z"
            />
          </g>
          <g
            stroke="#0f0"
            stroke-width="4"
          >
            <clippath
              id="clip-path-for-embed"
            >
              <path
                d="M109 8L210 214H8L109 8Z"
              />
            </clippath>
            <path
              d="M109 8L210 214H8L109 8Z"
            />
          </g>
        </svg>
      </svg>
    `)
  })

  it('renders Preview div with screen reader only content and sibling div with aria-hidden="true"', () => {
    const {container} = render(
      <Preview
        settings={{
          ...DEFAULT_SETTINGS,
          color: null,
          outlineColor: '#0f0',
          outlineSize: 'medium',
          shape: 'triangle',
          size: 'large',
        }}
      />
    )

    const ariaLabelDiv = getByText(container, 'Icon Preview')
    const ariaHiddenDiv = container.querySelector('div[aria-hidden="true"]')
    expect(ariaLabelDiv).toBeInTheDocument()
    expect(ariaHiddenDiv).toBeInTheDocument()
  })
})
