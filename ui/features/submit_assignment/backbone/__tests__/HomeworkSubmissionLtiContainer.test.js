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
import {isValidFileSubmission} from '../HomeworkSubmissionLtiContainer'
import {findContentExtension} from '../contentExtension'
import {getEnv} from '../environment'

jest.mock('../contentExtension')
jest.mock('../environment')

describe('HomeworkSubmissionLtiContainer', () => {
  afterEach(() => {
    getEnv.mockReset()
    findContentExtension.mockReset()
  })

  describe('#isValidFileSubmission', () => {
    describe('when there is no configuration for allowed extensions', () => {
      it('returns true', () => {
        getEnv.mockReturnValue({})

        expect(isValidFileSubmission({})).toBeTruthy()
      })
    })

    describe('when there are no configured allowed extensions', () => {
      beforeEach(() => {
        getEnv.mockReturnValue({
          SUBMIT_ASSIGNMENT: {
            ALLOWED_EXTENSIONS: [],
          },
        })
      })

      describe('when the content contains no extension', () => {
        beforeEach(() => {
          findContentExtension.mockReturnValue(null)
        })
        it('returns true', () => {
          expect(isValidFileSubmission({})).toBeTruthy()
        })
      })

      describe('when the content contains an extension', () => {
        beforeEach(() => {
          findContentExtension.mockReturnValue('txt')
        })
        it('returns true', () => {
          expect(isValidFileSubmission({})).toBeTruthy()
        })
      })
    })

    describe('when there are allowed extensions', () => {
      beforeEach(() => {
        getEnv.mockReturnValue({
          SUBMIT_ASSIGNMENT: {
            ALLOWED_EXTENSIONS: ['txt'],
          },
        })
      })

      describe('when no extension can be found for the submission', () => {
        it('returns false', () => {
          findContentExtension.mockReturnValue(null)
          expect(isValidFileSubmission({})).toBeFalsy()
        })
      })

      describe('when the found extension is in the list of allowed extensions', () => {
        it('returns true', () => {
          findContentExtension.mockReturnValue('txt')
          expect(isValidFileSubmission({})).toBeTruthy()
        })
      })

      describe('when the found extension is not in the list of allowed extensions', () => {
        it('returns false', () => {
          findContentExtension.mockReturnValue('notallowed')
          expect(isValidFileSubmission({})).toBeFalsy()
        })
      })
    })
  })
})
