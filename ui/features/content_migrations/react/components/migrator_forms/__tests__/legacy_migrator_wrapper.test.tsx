/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import LegacyMigratorWrapper from '../legacy_migrator_wrapper'
import ConverterViewControl from '@canvas/content-migrations/backbone/views/ConverterViewControl'

jest.mock('@canvas/content-migrations/backbone/views/ConverterViewControl', () => {
  const el = window.document.createElement('div')
  el.innerHTML = '<input name="file" type="file" />'
  const view = {
    validateBeforeSave: jest.fn().mockReturnValue({}),
    render: () => ({el}),
    el,
  }
  return {
    getModel: () => ({
      toJSON: jest.fn().mockResolvedValue({}),
      on: jest.fn(),
      resetModel: jest.fn(),
    }),
    renderView: jest
      .fn()
      .mockImplementation(({_, migrationConverter}) => migrationConverter.renderConverter(view)),
  }
})

const onSubmit = jest.fn()
const onCancel = jest.fn()

const renderComponent = (overrideProps?: any) =>
  render(
    <LegacyMigratorWrapper
      value="angel_exporter"
      onSubmit={onSubmit}
      onCancel={onCancel}
      {...overrideProps}
    />
  )

describe('LegacyMigratorWrapper', () => {
  afterEach(() => jest.clearAllMocks())

  it('calls ConverterViewControl render', () => {
    renderComponent()

    expect(ConverterViewControl.renderView).toHaveBeenCalledWith({
      value: 'angel_exporter',
      migrationConverter: {renderConverter: expect.any(Function)},
    })
  })

  it('renders Backbone view inside form', () => {
    renderComponent()

    expect(ConverterViewControl.renderView).toHaveBeenCalledWith({
      value: 'angel_exporter',
      migrationConverter: {renderConverter: expect.any(Function)},
    })
    expect(document.getElementById('migrationConverterContainer')).toMatchInlineSnapshot(`
      <form
        class="form-horizontal"
        id="migrationConverterContainer"
      >
        <div>
          <input
            name="file"
            type="file"
          />
        </div>
      </form>
    `)
  })

  it('calls onSubmit', async () => {
    renderComponent()

    const file = new File(['blah, blah, blah'], 'my_file.zip', {type: 'application/zip'})
    await userEvent.upload(document.querySelector('input[type="file"]') as HTMLInputElement, file)

    await userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue'}))
    expect(onSubmit).toHaveBeenCalledWith(
      {
        date_shift_options: {},
        // Issue when getting file from FormData mock
        pre_attachment: {
          name: '',
          no_redirect: true,
          size: 0,
        },
        selective_import: false,
        settings: {import_quizzes_next: false},
      },
      expect.any(File)
    )
  })

  it('calls onCancel', async () => {
    renderComponent()

    await userEvent.click(screen.getByRole('button', {name: 'Cancel'}))
    expect(onCancel).toHaveBeenCalled()
  })
})
