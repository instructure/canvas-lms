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

import {render} from '@testing-library/react'
import {mockSubmission} from '@canvas/assignments/graphql/studentMocks'
import React from 'react'
import RichContentEditor from '@canvas/rce/RichContentEditor'
import TextEntry from '../TextEntry'

jest.mock('@canvas/rce/RichContentEditor')

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
  let finishLoadingEditor
  let fakeEditor
  let editorContent

  beforeEach(() => {
    jest.useFakeTimers()

    jest.spyOn(RichContentEditor, 'callOnRCE').mockImplementation(() => editorContent)
    jest.spyOn(RichContentEditor, 'destroyRCE')
    jest.spyOn(RichContentEditor, 'loadNewEditor').mockImplementation((_textarea, options) => {
      fakeEditor = {
        focus: () => {},
        getBody: () => {},
        getContent: jest.fn(() => editorContent),
        mode: {
          set: jest.fn()
        },
        setContent: jest.fn(content => {
          editorContent = content
        }),
        selection: {
          collapse: () => {},
          select: () => {}
        }
      }

      finishLoadingEditor = () => {
        options.tinyOptions.init_instance_callback(fakeEditor)
      }
    })
  })

  afterEach(() => {
    jest.runOnlyPendingTimers()
    jest.useRealTimers()
  })

  const renderWithoutFinishing = async props => {
    const propsToRender = props || (await makeProps())
    return render(<TextEntry {...propsToRender} />)
  }

  const renderEditor = async props => {
    const result = await renderWithoutFinishing(props)
    finishLoadingEditor()

    return result
  }

  describe('initial rendering', () => {
    describe('before rendering has finished', () => {
      it('renders a placeholder text area with the submission contents', async () => {
        const {getByRole} = await renderWithoutFinishing()

        const textarea = getByRole('textbox')
        expect(textarea).toBeInTheDocument()
        expect(textarea).toHaveTextContent('words')
      })

      it('renders a loading indicator for the RCE', async () => {
        const {getByText} = await renderWithoutFinishing()

        expect(getByText('Loading')).toBeInTheDocument()
      })
    })

    describe('when the RCE has finished rendering', () => {
      it('hides the loading indicator', async () => {
        const {queryByText} = await renderEditor()
        expect(queryByText('Loading')).not.toBeInTheDocument()
      })

      describe('read-only mode', () => {
        it('is enabled if the readOnly prop is true', async () => {
          await renderEditor(await makeProps({readOnly: true}))
          expect(fakeEditor.mode.set).toHaveBeenCalledWith('readonly')
        })

        it('is not enabled if the readOnly prop is false', async () => {
          await renderEditor()
          expect(fakeEditor.mode.set).toHaveBeenCalledWith('design')
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
          await renderEditor(props)

          expect(fakeEditor.setContent).toHaveBeenCalledWith('I am graded!')
        })

        it('uses the submission body if the submission is submitted', async () => {
          const props = await makeProps({
            submission: {
              body: 'I am not graded!',
              state: 'submitted'
            }
          })
          await renderEditor(props)
          expect(fakeEditor.setContent).toHaveBeenCalledWith('I am not graded!')
        })

        it('uses the contents of the draft if not graded or submitted and a draft is present', async () => {
          const props = await makeProps({
            submission: {
              submissionDraft: {body: 'just a draft'}
            }
          })
          await renderEditor(props)
          expect(fakeEditor.setContent).toHaveBeenCalledWith('just a draft')
        })

        it('is empty if not graded or submitted and no draft is present', async () => {
          const props = await makeProps({
            submission: {
              body: 'this should be ignored',
              state: 'unsubmitted'
            }
          })
          await renderEditor(props)
          expect(fakeEditor.setContent).toHaveBeenCalledWith('')
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

      // Some of these mocks will have been called above; clear their call
      // counts so we can test the re-render sensibly
      fakeEditor.mode.set.mockClear()
      fakeEditor.setContent.mockClear()

      return result
    }

    it('updates the mode of the editor if the readOnly prop has changed', async () => {
      const {rerender} = await doInitialRender()
      const newProps = await makeProps({
        readOnly: true,
        submission: initialSubmission
      })

      rerender(<TextEntry {...newProps} />)
      expect(fakeEditor.mode.set).toHaveBeenCalledWith('readonly')
    })

    it('does not update the mode of the editor if the readOnly prop has not changed', async () => {
      const {rerender} = await doInitialRender()
      const updatedProps = await makeProps({
        submission: {
          ...initialSubmission,
          submissionDraft: {body: 'hello?'}
        }
      })

      rerender(<TextEntry {...updatedProps} />)
      expect(fakeEditor.mode.set).not.toHaveBeenCalled()
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
      rerender(<TextEntry {...newProps} />)
      expect(fakeEditor.setContent).toHaveBeenCalledWith('hello, again')
    })

    it('does not set the content of the editor if the attempt has not changed', async () => {
      const {rerender} = await doInitialRender()
      const newProps = await makeProps({
        submission: {...initialSubmission, grade: 0, state: 'graded'}
      })

      rerender(<TextEntry {...newProps} />)
      expect(fakeEditor.setContent).not.toHaveBeenCalled()
    })
  })

  describe('onContentsChanged prop', () => {
    it('checks for changes every 250ms', async () => {
      const props = await makeProps()
      await renderEditor(props)

      fakeEditor.setContent('hello?')
      jest.advanceTimersByTime(250)
      expect(props.onContentsChanged).toHaveBeenCalled()
    })

    it('runs no more often than every 250ms', async () => {
      const props = await makeProps()
      await renderEditor(props)

      props.onContentsChanged.mockClear()
      fakeEditor.setContent('hello?')
      jest.advanceTimersByTime(200)
      fakeEditor.setContent('hello!')
      jest.advanceTimersByTime(200)
      fakeEditor.setContent('hello.')
      jest.advanceTimersByTime(200)

      expect(props.onContentsChanged).toHaveBeenCalledTimes(2)
    })

    it('is not called if there have been no changes within 250ms', async () => {
      const props = await makeProps()
      await renderEditor(props)

      jest.advanceTimersByTime(275)
      expect(props.onContentsChanged).not.toHaveBeenCalled()
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
    it('calls the destroyRCE method', async () => {
      const {unmount} = await renderEditor()
      unmount()

      expect(RichContentEditor.destroyRCE).toHaveBeenCalled()
    })

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
