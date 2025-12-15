/*
 * Copyright (C) 2025 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import CreateNewModule from '../CreateNewModule'
import type {InfiniteData} from '@tanstack/react-query'
import type {ModulesResponse} from '../../utils/types'

const makeEmptyData = (): InfiniteData<ModulesResponse, unknown> =>
  ({
    pages: [],
    pageParams: [],
  }) as unknown as InfiniteData<ModulesResponse, unknown>

describe('<CreateNewModule />', () => {
  const courseId = '1234'
  const data = makeEmptyData()

  test('renders the CreateNewModule component when there are no modules', () => {
    const {container} = render(<CreateNewModule courseId={courseId} data={data} />)

    const button = container.querySelector('.ic-EmptyStateButton')
    expect(button).toBeInTheDocument()

    const icon = container.querySelector('.ic-EmptyStateButton__SVG')
    expect(icon).toBeInTheDocument()

    const text = container.querySelector('.ic-EmptyStateButton__Text')
    expect(text).toHaveTextContent(/create a new module/i)
  })

  test('clicking the icon causes the UI to react (e.g., open side tray)', async () => {
    const {container} = render(<CreateNewModule courseId={courseId} data={data} />)
    const icon = container.querySelector('.ic-EmptyStateButton__SVG') as HTMLElement
    expect(icon).toBeInTheDocument()

    await userEvent.click(icon)

    const trayHeader = document.querySelector('[data-testid="header-label"]')
    expect(trayHeader).toBeInTheDocument()
    expect(trayHeader).toHaveTextContent(/add module/i)
  })
})
