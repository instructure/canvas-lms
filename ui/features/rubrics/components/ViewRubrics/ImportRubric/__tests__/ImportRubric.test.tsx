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
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {fireEvent, render} from '@testing-library/react'
import {ImportRubric, type ImportRubricProps} from '..'
import * as ViewRubricQueries from '../../../../queries/ViewRubricQueries'

jest.mock('../../../../queries/ViewRubricQueries', () => ({
  ...jest.requireActual('../../../../queries/ViewRubricQueries'),
  importRubric: jest.fn(),
  fetchRubricImport: jest.fn(),
}))

describe('ImportRubric Tests', () => {
  afterEach(() => {
    jest.resetAllMocks()
  })

  const renderComponent = (props?: Partial<ImportRubricProps>) => {
    return render(
      <MockedQueryProvider>
        <ImportRubric
          isTrayOpen={true}
          handleImportSuccess={jest.fn()}
          handleTrayClose={jest.fn()}
          accountId="123"
          importFetchInterval={100}
          {...props}
        />
      </MockedQueryProvider>
    )
  }

  const dropFile = (fileDropZone: HTMLElement) => {
    fireEvent.dragOver(fileDropZone)
    const importFile = new File(['file content'], 'test-file.csv', {type: 'text/plain'})
    const dataTransfer = {files: [importFile]}
    fireEvent.drop(fileDropZone, {dataTransfer})
  }

  describe('ImportRubricTray tests', () => {
    beforeEach(() => {
      jest.spyOn(ViewRubricQueries, 'importRubric').mockImplementation(() =>
        Promise.resolve({
          attachment: {
            id: '1',
            filename: 'file.csv',
            size: 487,
          },
          id: '1',
          createdAt: new Date().toISOString(),
          errorCount: 0,
          errorData: [],
          progress: 0,
          workflowState: 'created',
        })
      )
    })

    it('renders the Import Tray component', () => {
      const {getByTestId} = renderComponent()
      const importRubricTray = getByTestId('import-rubric-tray')
      expect(importRubricTray).toBeInTheDocument()
      expect(importRubricTray).toHaveTextContent('Import Rubrics')
    })

    it('successfully imports the rubric csv and displays rubric import data in ImportTable', async () => {
      jest.spyOn(ViewRubricQueries, 'fetchRubricImport').mockImplementation(() =>
        Promise.resolve({
          attachment: {
            id: '1',
            filename: 'file.csv',
            size: 487,
          },
          id: '1',
          createdAt: new Date().toISOString(),
          errorCount: 0,
          errorData: [],
          progress: 100,
          workflowState: 'success',
        })
      )
      const {getByTestId} = renderComponent()
      const fileDropZone = getByTestId('rubric-import-file-drop')
      dropFile(fileDropZone)

      await new Promise(resolve => setTimeout(resolve, 500))
      const importFilename = getByTestId('rubric-import-job-filename-1')
      expect(importFilename).toHaveTextContent('file.csv')
      expect(getByTestId('rubric-import-job-size-1')).toHaveTextContent('487 bytes')
    })

    it('displays the ImportFailuresModal if the rubric import failed', async () => {
      jest.spyOn(ViewRubricQueries, 'fetchRubricImport').mockImplementation(() =>
        Promise.resolve({
          attachment: {
            id: '1',
            filename: 'file.csv',
            size: 487,
          },
          id: '1',
          createdAt: new Date().toISOString(),
          errorCount: 0,
          errorData: [{message: 'failed format'}],
          progress: 100,
          workflowState: 'failed',
        })
      )

      const {getByTestId} = renderComponent()
      const fileDropZone = getByTestId('rubric-import-file-drop')
      dropFile(fileDropZone)

      await new Promise(resolve => setTimeout(resolve, 500))
      const importFilename = getByTestId('rubric-import-job-filename-1')
      expect(importFilename).toHaveTextContent('file.csv')
      expect(getByTestId('import-rubric-failure-header')).toHaveTextContent(
        'The import failed for the following file(s):'
      )
      expect(getByTestId('import-failure-message')).toHaveTextContent('failed format')
    })
  })
})
