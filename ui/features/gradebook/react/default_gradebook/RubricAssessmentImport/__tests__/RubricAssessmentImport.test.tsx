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
import * as ViewRubricQueries from '../../queries/Queries'
import useStore from '../../stores'
import {RubricAssessmentImport} from '../index'

jest.mock('../../queries/Queries', () => ({
  ...jest.requireActual('../../queries/Queries'),
  importRubricAssessment: jest.fn(),
  fetchRubricAssessmentImport: jest.fn(),
}))

describe('ImportRubric Tests', () => {
  afterEach(() => {
    jest.resetAllMocks()
  })

  const renderComponent = () => {
    return render(
      <MockedQueryProvider>
        <RubricAssessmentImport />
      </MockedQueryProvider>,
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
      const {toggleRubricAssessmentImportTray} = useStore.getState()
      toggleRubricAssessmentImportTray(true, {
        id: '7',
        name: 'assignment test',
        courseId: '7',
      })
      jest.spyOn(ViewRubricQueries, 'importRubricAssessment').mockImplementation(() =>
        Promise.resolve({
          id: '1',
          rootAccountId: '2',
          workflowState: 'created',
          userId: '1',
          assignmentId: '7',
          attachmentId: '556',
          courseId: '7',
          progress: 0,
          errorCount: 0,
          errorData: [],
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
          user: {
            id: '1',
            name: 'User Test',
            createdAt: new Date().toISOString(),
            sortableName: 'User Test',
            shortName: 'User Test',
            sisUserId: null,
            integrationId: null,
            sisImportId: null,
            loginId: 'login_id',
          },
          attachment: {
            id: '1',
            filename: 'test-file.csv',
            size: 270,
          },
        }),
      )
    })

    it('renders the Import Tray component', () => {
      const {getByTestId} = renderComponent()
      const importRubricTray = getByTestId('import-rubric-tray')
      expect(importRubricTray).toBeInTheDocument()
      expect(importRubricTray).toHaveTextContent('Import Rubrics')
    })

    // FOO-5334 It's not possible to construct the FileList object that would be needed
    // to simulate a file being dropped. There may be a way to mock this, but it will
    // take some research.
    it.skip('SKIPPED FOO-5334; successfully imports the rubric csv and displays rubric import data in ImportTable', async () => {
      jest.spyOn(ViewRubricQueries, 'fetchRubricAssessmentImport').mockImplementation(() =>
        Promise.resolve({
          id: '1',
          rootAccountId: '2',
          workflowState: 'success',
          userId: '1',
          assignmentId: '7',
          attachmentId: '556',
          courseId: '7',
          progress: 100,
          errorCount: 0,
          errorData: [],
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
          user: {
            id: '1',
            name: 'User Test',
            createdAt: new Date().toISOString(),
            sortableName: 'User Test',
            shortName: 'User Test',
            sisUserId: null,
            integrationId: null,
            sisImportId: null,
            loginId: 'login_id',
          },
          attachment: {
            id: '1',
            filename: 'test-file.csv',
            size: 270,
          },
        }),
      )
      const {getByTestId} = renderComponent()
      const fileDropZone = getByTestId('rubric-import-file-drop')
      dropFile(fileDropZone)

      await new Promise(resolve => setTimeout(resolve, 2000))
      const importFilename = getByTestId('rubric-import-job-filename-1')
      expect(importFilename).toHaveTextContent('file.csv')
      expect(getByTestId('rubric-import-job-size-1')).toHaveTextContent('270 bytes')
    })

    // FOO-5334 It's not possible to construct the FileList object that would be needed
    // to simulate a file being dropped. There may be a way to mock this, but it will
    // take some research.
    it.skip('SKIPPED FOO-5334; displays the ImportFailuresModal if the rubric import failed', async () => {
      jest.spyOn(ViewRubricQueries, 'fetchRubricAssessmentImport').mockImplementation(() =>
        Promise.resolve({
          id: '1',
          rootAccountId: '2',
          workflowState: 'failed',
          userId: '1',
          assignmentId: '7',
          attachmentId: '556',
          courseId: '7',
          progress: 100,
          errorCount: 0,
          errorData: [{message: 'failed format'}],
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
          user: {
            id: '1',
            name: 'User Test',
            createdAt: new Date().toISOString(),
            sortableName: 'User Test',
            shortName: 'User Test',
            sisUserId: null,
            integrationId: null,
            sisImportId: null,
            loginId: 'login_id',
          },
          attachment: {
            id: '1',
            filename: 'test-file.csv',
            size: 270,
          },
        }),
      )

      const {getByTestId} = renderComponent()
      const fileDropZone = getByTestId('rubric-import-file-drop')
      dropFile(fileDropZone)

      await new Promise(resolve => setTimeout(resolve, 2000))
      const importFilename = getByTestId('rubric-import-job-filename-1')
      expect(importFilename).toHaveTextContent('file.csv')
      expect(getByTestId('import-rubric-failure-header')).toHaveTextContent(
        'The import failed for the following file(s):',
      )
      expect(getByTestId('import-failure-message')).toHaveTextContent('failed format')
    })
  })
})
