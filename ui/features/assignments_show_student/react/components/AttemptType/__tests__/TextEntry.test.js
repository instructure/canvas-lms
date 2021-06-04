/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {mockSubmission} from '@canvas/assignments/graphql/studentMocks'
import React from 'react'
import TextEntry from '../TextEntry'

async function makeProps(opts = {}) {
  const mockedSubmission =
    opts.submission ||
    (await mockSubmission({
      Submission: {
        submissionDraft: {body: 'words'}
      }
    }))

  return {
    createSubmissionDraft: jest.fn(),
    editingDraft: opts.editingDraft || false,
    readOnly: opts.readOnly || false,
    onContentsChanged: jest.fn(),
    submission: mockedSubmission,
    updateEditingDraft: jest.fn()
  }
}

describe('TextEntry', () => {
  let fakeEditor

  beforeAll(() => {
    window.INST = {
      editorButtons: []
    }
    const liveRegion = document.createElement('div')
    liveRegion.id = 'flash_screenreader_holder'
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)
  })

  beforeEach(() => {
    jest.useFakeTimers()
  })

  afterEach(() => {
    jest.runOnlyPendingTimers()
    jest.useRealTimers()
  })

  const renderEditor = async props => {
    const propsToRender = props || (await makeProps())
    const retval = render(<TextEntry {...propsToRender} />)
    await waitFor(() => {
      expect(tinymce.editors[0]).toBeDefined()
    })
    fakeEditor = tinymce.editors[0]
    return retval
  }

  describe('initial rendering', () => {
    describe('before rendering has finished', () => {
      it('renders a placeholder text area with the submission contents', async () => {
        const {findByDisplayValue} = await renderEditor()
        const textarea = await findByDisplayValue('words', {exact: false})
        expect(textarea).toBeInTheDocument()
      })
    })

    describe('when the RCE has finished rendering', () => {
      describe('read-only mode', () => {
        it('is enabled if the readOnly prop is true', async () => {
          await renderEditor(
            await makeProps({
              readOnly: true
            })
          )
          await waitFor(() => {
            expect(fakeEditor.readonly).toBeTruthy()
          })
        })

        it('is not enabled if the readOnly prop is false', async () => {
          await renderEditor()
          await waitFor(() => {
            expect(fakeEditor.readonly).toStrictEqual(false)
          })
        })
      })

      describe('text contents', () => {
        it('uses the submission body if the submission is graded', async () => {
          const props = await makeProps({
            submission: {
              body: 'I am graded!',
              state: 'graded'
            }
          })
          const {findByDisplayValue} = await renderEditor(props)

          const textarea = await findByDisplayValue('I am graded', {exact: false})
          expect(textarea).toBeInTheDocument()
        })

        it('uses the submission body if the submission is submitted', async () => {
          const props = await makeProps({
            submission: {
              body: 'I am not graded!',
              state: 'submitted'
            }
          })
          const {findByDisplayValue} = await renderEditor(props)

          const textarea = await findByDisplayValue('I am not graded', {exact: false})
          expect(textarea).toBeInTheDocument()
        })

        it('uses the contents of the draft if not graded or submitted and a draft is present', async () => {
          const props = await makeProps({
            submission: {
              submissionDraft: {body: 'just a draft'}
            }
          })
          const {findByDisplayValue} = await renderEditor(props)

          const textarea = await findByDisplayValue('just a draft', {exact: false})
          expect(textarea).toBeInTheDocument()
        })

        it('is empty if not graded or submitted and no draft is present', async () => {
          const props = await makeProps({
            submission: {
              body: 'this should be ignored',
              state: 'unsubmitted'
            }
          })
          const {findByDisplayValue} = await renderEditor(props)
          const textarea = await findByDisplayValue('', {exact: true})
          expect(textarea).toBeInTheDocument()
        })
      })
    })
  })

  describe('receiving updated props', () => {
    const initialSubmission = {
      attempt: 1,
      state: 'unsubmitted',
      submissionDraft: {body: 'hello'}
    }

    const doInitialRender = async () => {
      const props = await makeProps({submission: initialSubmission})
      const result = await renderEditor(props)
      return result
    }

    it('updates the mode of the editor if the readOnly prop has changed', async () => {
      const {rerender} = await doInitialRender()
      const newProps = await makeProps({
        readOnly: true,
        submission: initialSubmission
      })
      await waitFor(() => {
        expect(fakeEditor.readonly).toStrictEqual(false)
      })

      rerender(<TextEntry {...newProps} />)

      await waitFor(() => {
        expect(fakeEditor.readonly).toStrictEqual(true)
      })
    })

    it('does not update the mode of the editor if the readOnly prop has not changed', async () => {
      const {rerender} = await doInitialRender()
      const updatedProps = await makeProps({
        submission: {
          ...initialSubmission,
          submissionDraft: {body: 'hello?'}
        }
      })
      const setModeSpy = jest.spyOn(fakeEditor.mode, 'set')

      rerender(<TextEntry {...updatedProps} />)

      expect(setModeSpy).not.toHaveBeenCalled()
    })

    it('sets the content of the editor if the attempt has changed', async () => {
      const {rerender} = await doInitialRender()

      const newProps = await makeProps({
        submission: {
          attempt: 2,
          state: 'unsubmitted',
          submissionDraft: {body: 'hello, again'}
        }
      })
      const setContentSpy = jest.spyOn(fakeEditor, 'setContent')
      rerender(<TextEntry {...newProps} />)
      expect(setContentSpy).toHaveBeenCalledWith('hello, again')
    })

    it('does not set the content of the editor if the attempt has not changed', async () => {
      const {rerender} = await doInitialRender()
      const newProps = await makeProps({
        submission: {...initialSubmission, grade: 0, state: 'graded'}
      })
      jest.spyOn(fakeEditor, 'setContent')

      rerender(<TextEntry {...newProps} />)
      expect(fakeEditor.setContent).not.toHaveBeenCalled()
    })
  })

  describe('onContentsChanged prop', () => {
    it('calls onContentsChanged when the content changes', async () => {
      const props = await makeProps()
      await renderEditor(props)
      fakeEditor.setContent('hello?')
      expect(props.onContentsChanged).toHaveBeenCalled()
    })

    it('calls onContentsChanged when the user types', async () => {
      const props = await makeProps()
      await renderEditor(props)
      props.onContentsChanged.mockClear()
      userEvent.type(document.getElementById('textentry_text'), '!')
      expect(props.onContentsChanged).toHaveBeenCalled()
    })
  })

  describe('createSubmissionDraft prop', () => {
    it('is called when the user has made changes, then stopped for at least one second', async () => {
      const props = await makeProps()
      await renderEditor(props)

      fakeEditor.setContent('I')
      jest.advanceTimersByTime(500)
      fakeEditor.setContent('I am editing')
      jest.advanceTimersByTime(500)
      fakeEditor.setContent('I am still editing')

      expect(props.createSubmissionDraft).not.toHaveBeenCalled()
      jest.advanceTimersByTime(1250)

      expect(props.createSubmissionDraft).toHaveBeenCalled()
    })

    it('is called once for each batch of changes', async () => {
      const props = await makeProps()
      await renderEditor(props)

      fakeEditor.setContent('I')
      jest.advanceTimersByTime(500)
      fakeEditor.setContent('I am')
      jest.advanceTimersByTime(500)
      fakeEditor.setContent('I am editing')

      jest.advanceTimersByTime(5000)
      expect(props.createSubmissionDraft).toHaveBeenCalledTimes(1)
    })

    it('is not called for any changes inexplicably emitted in read-only mode', async () => {
      const props = await makeProps({readOnly: true})
      await renderEditor(props)

      fakeEditor.setContent('No')
      jest.advanceTimersByTime(500)
      fakeEditor.setContent('No way')

      jest.advanceTimersByTime(3000)
      expect(props.createSubmissionDraft).not.toHaveBeenCalled()
    })

    it('is not called for a brand new entry with no content', async () => {
      const props = await makeProps()
      const {rerender} = await renderEditor(props)

      const newProps = await makeProps({
        submission: {
          attempt: 2,
          state: 'unsubmitted'
        }
      })
      rerender(<TextEntry {...newProps} />)

      jest.advanceTimersByTime(3000)
      expect(newProps.createSubmissionDraft).not.toHaveBeenCalled()
    })

    it('passes the contents of the submission in its current form', async () => {
      const props = await makeProps()
      await renderEditor(props)

      fakeEditor.setContent('hello there!')
      jest.advanceTimersByTime(1500)

      expect(props.createSubmissionDraft).toHaveBeenCalled()

      const args = props.createSubmissionDraft.mock.calls[0]
      expect(args[0]).toEqual({
        variables: {
          activeSubmissionType: 'online_text_entry',
          attempt: 1,
          body: 'hello there!',
          id: '1'
        }
      })
    })
  })

  describe('unmounting', () => {
    it('does not process any outstanding changes to the text', async () => {
      const props = await makeProps()
      const {unmount} = await renderEditor(props)

      fakeEditor.setContent('oh no')
      jest.advanceTimersByTime(100)
      unmount()

      jest.advanceTimersByTime(3000)
      expect(props.createSubmissionDraft).not.toHaveBeenCalled()
    })
  })
})
