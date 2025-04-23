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

import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'

export const sharedMatchingAssessmentCheckboxTests = (InputComponent: React.ComponentType<any>) => {
  const onSubmit = jest.fn()
  const onCancel = jest.fn()

  const renderComponent = (overrideProps?: any) =>
    render(<InputComponent onSubmit={onSubmit} onCancel={onCancel} {...overrideProps} />)

  it('disable other optional fields while uploading', async () => {
    const props = {
      canSelectContent: true,
      canImportBPSettings: true,
      canAdjustDates: true,
      canOverwriteAssessmentContent: true,
      canImportAsNewQuizzes: true,
    }
    const {rerender, getByRole} = renderComponent(props)
    rerender(
      <InputComponent
        onSubmit={onSubmit}
        onCancel={onCancel}
        {...props}
        isSubmitting={true}
        fileUploadProgress={10}
      />,
    )

    expect(
      getByRole('checkbox', {name: /Overwrite assessment content with matching IDs/}),
    ).toBeDisabled()
  })
}

export const sharedImportAsNQTests = (InputComponent: React.ComponentType<any>) => {
  const onSubmit = jest.fn()
  const onCancel = jest.fn()

  const renderComponent = (overrideProps?: any) =>
    render(<InputComponent onSubmit={onSubmit} onCancel={onCancel} {...overrideProps} />)

  it('disable question bank inputs if "Import existing quizzes as New Quizzes" is checked', async () => {
    window.ENV.NEW_QUIZZES_MIGRATION = true
    window.ENV.NEW_QUIZZES_IMPORT = true
    window.ENV.QUIZZES_NEXT_ENABLED = true
    const {getByRole, queryByLabelText} = renderComponent()

    await userEvent.click(getByRole('combobox', {name: 'Default Question bank'}))
    await userEvent.click(getByRole('option', {name: 'Create new question bank...'}))
    await userEvent.click(getByRole('checkbox', {name: /Import existing quizzes as New Quizzes/}))

    await waitFor(() => {
      expect(getByRole('combobox', {name: 'Default Question bank'})).toBeInTheDocument()
      expect(getByRole('combobox', {name: 'Default Question bank'})).toBeDisabled()
      expect(queryByLabelText('New question bank')).not.toBeInTheDocument()
    })
  })
}

export const sharedBankTests = (InputComponent: React.ComponentType<any>) => {
  const onSubmit = jest.fn()
  const onCancel = jest.fn()

  const renderComponent = (overrideProps?: any) =>
    render(<InputComponent onSubmit={onSubmit} onCancel={onCancel} {...overrideProps} />)

  it('disable question bank inputs while uploading', async () => {
    const {getByRole} = renderComponent({isSubmitting: true})

    expect(getByRole('combobox', {name: 'Default Question bank'})).toBeInTheDocument()
    expect(getByRole('combobox', {name: 'Default Question bank'})).toBeDisabled()
  })
}

export const sharedAdjustDateTests = (InputComponent: React.ComponentType<any>) => {
  const onSubmit = jest.fn()
  const onCancel = jest.fn()

  const renderComponent = (overrideProps?: any) =>
    render(<InputComponent onSubmit={onSubmit} onCancel={onCancel} {...overrideProps} />)

  it('disable "Adjust events and due dates" inputs while uploading', async () => {
    const {getByRole, rerender, getByTestId, getByText} = renderComponent()

    await userEvent.click(getByRole('checkbox', {name: 'Adjust events and due dates'}))

    rerender(
      <InputComponent
        onSubmit={onSubmit}
        onCancel={onCancel}
        isSubmitting={true}
        fileUploadProgress={10}
      />,
    )

    await waitFor(() => {
      expect(getByRole('radio', {name: 'Shift dates'})).toBeInTheDocument()
      expect(getByRole('radio', {name: 'Shift dates'})).toBeDisabled()
      expect(getByRole('radio', {name: 'Remove dates'})).toBeDisabled()
      expect(getByText('Beginning date:')).toBeInTheDocument()
      expect(getByTestId('old_start_date')).toBeDisabled()
      expect(getByTestId('new_start_date')).toBeDisabled()
      expect(getByText('Ending date:')).toBeInTheDocument()
      expect(getByTestId('old_end_date')).toBeDisabled()
      expect(getByTestId('new_end_date')).toBeDisabled()
      expect(getByRole('button', {name: 'Add substitution'})).toBeDisabled()
    })
  })
}

export const sharedContentTests = (InputComponent: React.ComponentType<any>) => {
  const onSubmit = jest.fn()
  const onCancel = jest.fn()

  const renderComponent = (overrideProps?: any) =>
    render(<InputComponent onSubmit={onSubmit} onCancel={onCancel} {...overrideProps} />)

  it('disable inputs while uploading', async () => {
    renderComponent({isSubmitting: true})
    await waitFor(() => {
      expect(screen.getByRole('checkbox', {name: 'Adjust events and due dates'})).toBeDisabled()
    })
  })
}

export const sharedFormTests = (InputComponent: React.ComponentType<any>) => {
  const onSubmit = jest.fn()
  const onCancel = jest.fn()

  const renderComponent = (overrideProps?: any) =>
    render(<InputComponent onSubmit={onSubmit} onCancel={onCancel} {...overrideProps} />)

  it('calls onSubmit', async () => {
    renderComponent()

    const file = new File(['blah, blah, blah'], 'my_file.zip', {type: 'application/zip'})
    const input = screen.getByTestId('migrationFileUpload')
    await userEvent.upload(input, file)
    await userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue'}))
    expect(onSubmit).toHaveBeenCalledWith(
      expect.objectContaining({
        pre_attachment: {
          name: 'my_file.zip',
          no_redirect: true,
          size: 16,
        },
      }),
      expect.any(Object),
    )
  })

  it('renders the progressbar info', async () => {
    renderComponent({isSubmitting: true, fileUploadProgress: 10})
    expect(screen.getByText('Uploading File')).toBeInTheDocument()
  })

  it('disable Add and Clear buttons while uploading', async () => {
    renderComponent({isSubmitting: true})
    await waitFor(() => {
      expect(screen.getByTestId('migrationFileUpload')).toBeDisabled()
      expect(screen.getByRole('button', {name: 'Clear'})).toBeDisabled()
      expect(screen.getByRole('button', {name: /Adding.../})).toBeDisabled()
    })
  })

  describe('submit error', () => {
    describe('file input error', () => {
      const expectedFileMissingError = 'You must select a file to import content from'

      it('renders the file missing error', async () => {
        renderComponent()
        await userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue'}))
        expect(screen.getByText(expectedFileMissingError)).toBeInTheDocument()
      })

      it('focuses on input after file error', async () => {
        renderComponent()
        await userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue'}))
        expect(screen.getByTestId('migrationFileUpload')).toHaveFocus()
      })
    })
  })
}

export const sharedDateParsingTests = (InputComponent: React.ComponentType<any>) => {
  const onSubmit = jest.fn()
  const onCancel = jest.fn()

  const renderComponent = (overrideProps?: any) =>
    render(<InputComponent onSubmit={onSubmit} onCancel={onCancel} {...overrideProps} />)

  const expectDateField = (dataCid: string, value: string) => {
    expect((screen.getByTestId(dataCid) as HTMLInputElement).value).toBe(value)
  }

  describe('target course adjust date field prefills', () => {
    it('parse the date from ENV.OLD_END_DATE', async () => {
      window.ENV.OLD_END_DATE = '15 Oct 2024 at 0:00'
      const {getByRole} = renderComponent()

      await userEvent.click(getByRole('checkbox', {name: 'Adjust events and due dates'}))

      expectDateField('new_end_date', 'Oct 15 at 8pm')
    })

    it('parse the date from ENV.OLD_START_DATE', async () => {
      window.ENV.OLD_START_DATE = '15 Oct 2024 at 0:00'
      const {getByRole} = renderComponent()

      await userEvent.click(getByRole('checkbox', {name: 'Adjust events and due dates'}))

      expectDateField('new_start_date', 'Oct 15 at 8pm')
    })
  })
}
