/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import GenerateLink from '../GenerateLink'
import CourseEpubExportStore from '../CourseStore'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('epub_exports')

describe('GenerateLink', () => {
  let props

  beforeEach(() => {
    props = {
      course: {
        name: 'Maths 101',
        id: 1,
      },
    }
  })

  it('shows generate link without epub_export object', () => {
    const {getByRole} = render(<GenerateLink {...props} />)
    expect(getByRole('button', {name: I18n.t('Generate ePub')})).toBeInTheDocument()
  })

  it('hides generate link without regenerate permissions', () => {
    props.course.epub_export = {permissions: {regenerate: false}}
    const {container} = render(<GenerateLink {...props} />)
    expect(container.firstChild).toBeNull()
  })

  it('shows generate link with regenerate permissions', () => {
    props.course.epub_export = {permissions: {regenerate: true}}
    const {getByRole} = render(<GenerateLink {...props} />)
    expect(getByRole('button', {name: I18n.t('Regenerate ePub')})).toBeInTheDocument()
  })

  it('shows generating state when clicked', async () => {
    jest.useFakeTimers()
    const createSpy = jest.spyOn(CourseEpubExportStore, 'create')
    const user = userEvent.setup({advanceTimers: jest.advanceTimersByTime})

    const {getByRole, getByText} = render(<GenerateLink {...props} />)
    const button = getByRole('button', {name: I18n.t('Generate ePub')})
    await user.click(button)

    expect(getByText(I18n.t('Generating...'))).toBeInTheDocument()

    jest.advanceTimersByTime(1005)
    expect(getByRole('button', {name: I18n.t('Generate ePub')})).toBeInTheDocument()

    jest.useRealTimers()
    createSpy.mockRestore()
  })

  it('renders regenerate button when epub_export exists with permissions', () => {
    props.course.epub_export = {permissions: {regenerate: true}}
    const {getByRole} = render(<GenerateLink {...props} />)
    const button = getByRole('button', {name: I18n.t('Regenerate ePub')})
    expect(button).toBeInTheDocument()
    expect(button).toHaveAttribute('type', 'button')
  })
})
