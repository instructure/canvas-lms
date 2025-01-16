// @vitest-environment jsdom
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
import StatusPill from '@canvas/feature-flags/react/StatusPill'

import sampleData from './sampleData.json'

it('includes tooltips for feature preview', () => {
  const {getByText} = render(<StatusPill feature={sampleData.betaFeature} />)
  expect(
    getByText(
      'Feature preview — opting in includes ongoing updates outside the regular release schedule',
    ),
  ).toBeInTheDocument()
})

it('includes tooltips for hidden pills', () => {
  const {getByText} = render(<StatusPill feature={sampleData.siteAdminOffFeature} />)
  expect(
    getByText(
      'This feature option is only visible to users with Site Admin access.' +
        ' End users will not see it until enabled by a Site Admin user. Before enabling for an institution,' +
        ' please be sure you fully understand the functionality and possible impacts to users.',
    ),
  ).toBeInTheDocument()
})

it('Includes tooltips for shadow features', () => {
  const {getByText} = render(<StatusPill feature={sampleData.shadowedRootAccountFeature} />)
  expect(
    getByText(
      'This feature option is only visible to users with Site Admin access. It is similar to "Hidden",' +
        ' but end users will not see it even if enabled by a Site Admin user.',
    ),
  ).toBeInTheDocument()
})
