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

import {act, render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {mockSubmission} from '@canvas/assignments/graphql/studentMocks'
import React from 'react'
import TextEntry from '../TextEntry'
import StudentViewContext from '../../Context'

jest.mock(
  '@instructure/canvas-rce/es/rce/plugins/instructure_rce_external_tools/lti11-content-items/RceLti11ContentItem',
  () => ({
    RceLti11ContentItem: {
      fromJSON: contentItem => ({
        codePayload: `<a href="${contentItem.url}" title="${contentItem.title}" target="${contentItem.linkTarget}">${contentItem.title}</a>`,
      }),
    },
  })
)

async function makeProps(opts = {}) {
  const mockedSubmission =
    opts.submission ||
    (await mockSubmission({
      Submission: {
        submissionDraft: {body: 'words'},
      },
    }))

  return {
    createSubmissionDraft: jest.fn(),
    editingDraft: opts.editingDraft || false,
    focusOnInit: false,
    readOnly: opts.readOnly || false,
    onContentsChanged: jest.fn(),
    submission: mockedSubmission,
    updateEditingDraft: jest.fn(),
  }
}

describe('TextEntry', () => {
  let fakeEditor

  beforeAll(() => {
    window.INST = {
      editorButtons: [],
    }
    const liveRegion = document.createElement('div')
    liveRegion.id = 'flash_screenreader_holder'
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)
  })

  beforeEach(() => {
    jest.useFakeTimers()
  })

  afterEach(async () => {
    await act(async () => jest.runOnlyPendingTimers())
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
        it('is not enabled if the readOnly prop is false', async () => {
          await renderEditor()
          await waitFor(() => {
            expect(fakeEditor.readonly).toStrictEqual(false)
          })
        })

        it('is enabled for observers', async () => {
          const props = await makeProps()
          render(
            <StudentViewContext.Provider
              value={{isObserver: true, allowChangesToSubmission: false}}
            >
              <TextEntry {...props} />
            </StudentViewContext.Provider>
          )
          await waitFor(() => {
            expect(tinymce.editors[0]).toBeDefined()
          })
          fakeEditor = tinymce.editors[0]
          await waitFor(() => {
            expect(fakeEditor.readonly).toStrictEqual(true)
          })
        })
      })

      describe('text contents', () => {
        it('uses the submission body if the submission is graded', async () => {
          const props = await makeProps({
            submission: {
              id: '1',
              _id: '1',
              body: 'I am graded!',
              state: 'graded',
            },
          })
          const {findByDisplayValue} = await renderEditor(props)

          const textarea = await findByDisplayValue('I am graded', {exact: false})
          expect(textarea).toBeInTheDocument()
        })

        it('uses the submission body if the submission is submitted', async () => {
          const props = await makeProps({
            submission: {
              id: '1',
              _id: '1',
              body: 'I am not graded!',
              state: 'submitted',
            },
          })
          const {findByDisplayValue} = await renderEditor(props)

          const textarea = await findByDisplayValue('I am not graded', {exact: false})
          expect(textarea).toBeInTheDocument()
        })

        it('uses the contents of the draft if not graded or submitted and a draft is present', async () => {
          const props = await makeProps({
            submission: {
              id: '1',
              _id: '1',
              submissionDraft: {body: 'just a draft'},
            },
          })
          const {findByDisplayValue} = await renderEditor(props)

          const textarea = await findByDisplayValue('just a draft', {exact: false})
          expect(textarea).toBeInTheDocument()
        })

        it('is empty if not graded or submitted and no draft is present', async () => {
          const props = await makeProps({
            submission: {
              id: '1',
              _id: '1',
              body: 'this should be ignored',
              state: 'unsubmitted',
            },
          })
          const {findByDisplayValue} = await renderEditor(props)
          const textarea = await findByDisplayValue('', {exact: true})
          expect(textarea).toBeInTheDocument()
        })

        it('renders the content in the read-only-content div when readOnly is true', async () => {
          const props = await makeProps({
            readOnly: true,
            submission: {
              id: '1',
              _id: '1',
              body: '<p>HELLO WORLD</p>',
              state: 'unsubmitted',
            },
          })
          const {queryByTestId} = await renderEditor(props)
          expect(await queryByTestId('read-only-content')).toBeInTheDocument()
          expect(queryByTestId('text-editor')).not.toBeInTheDocument()
        })

        it('renders the content in the rce component when readOnly is false', async () => {
          const props = await makeProps({
            readOnly: false,
            submission: {
              id: '1',
              _id: '1',
              body: '<p>HELLO WORLD</p>',
              state: 'unsubmitted',
            },
          })
          const {queryByTestId} = await renderEditor(props)
          expect(await queryByTestId('text-editor')).toBeInTheDocument()
          expect(queryByTestId('read-only-content')).not.toBeInTheDocument()
        })
      })
    })
  })

  describe('receiving updated props', () => {
    const initialSubmission = {
      id: '1',
      _id: '1',
      attempt: 1,
      state: 'unsubmitted',
      submissionDraft: {body: 'hello'},
    }

    const doInitialRender = async () => {
      const props = await makeProps({submission: initialSubmission})
      const result = await renderEditor(props)
      return result
    }

    it('does not update the mode of the editor if the readOnly prop has not changed', async () => {
      const {rerender} = await doInitialRender()
      const updatedProps = await makeProps({
        submission: {
          ...initialSubmission,
          submissionDraft: {body: 'hello?'},
        },
      })
      const setModeSpy = jest.spyOn(fakeEditor.mode, 'set')

      rerender(<TextEntry {...updatedProps} />)

      expect(setModeSpy).not.toHaveBeenCalled()
    })

    it('sets the content of the editor if the attempt and body draft has changed', async () => {
      const {rerender} = await doInitialRender()

      const newProps = await makeProps({
        submission: {
          id: '1',
          _id: '1',
          attempt: 2,
          state: 'unsubmitted',
          submissionDraft: {body: 'hello, again'},
        },
      })
      const setContentSpy = jest.spyOn(fakeEditor, 'setContent')
      rerender(<TextEntry {...newProps} />)
      expect(setContentSpy).toHaveBeenCalledWith('hello, again')
    })

    it('does not sets the content of the editor if the body draft has not changed', async () => {
      const {rerender} = await doInitialRender()

      const newProps = await makeProps({
        submission: {
          id: '1',
          _id: '1',
          attempt: 2,
          state: 'unsubmitted',
          submissionDraft: {body: 'hello'},
        },
      })
      const setContentSpy = jest.spyOn(fakeEditor, 'setContent')
      rerender(<TextEntry {...newProps} />)
      expect(setContentSpy).not.toHaveBeenCalled()
    })

    it('does not set the content of the editor if the attempt has not changed', async () => {
      const {rerender} = await doInitialRender()
      const newProps = await makeProps({
        submission: {...initialSubmission, grade: 0, state: 'graded'},
      })
      jest.spyOn(fakeEditor, 'setContent')

      rerender(<TextEntry {...newProps} />)
      expect(fakeEditor.setContent).not.toHaveBeenCalled()
    })
  })

  describe('receiving messages', () => {
    let insertCode

    const fakeEvent = {
      subject: 'ContentDefinitelyNotReady',
      content_items: [
        {
          '@type': 'LtiLinkItem',
          linkTarget: '_blank',
          title: 'a fake item',
          url: 'http://localhost',
        },
      ],
    }

    const realEvent = {
      subject: 'A2ExternalContentReady',
      content_items: [
        {
          '@type': 'LtiLinkItem',
          linkTarget: '_blank',
          title: 'first item',
          url: 'http://localhost:3000/item1',
        },
        {
          '@type': 'LtiLinkItem',
          linkTarget: '_blank',
          title: 'second item',
          url: 'http://localhost:3000/item2',
        },
      ],
    }

    beforeEach(async () => {
      await renderEditor()
      // At the moment, the fake editor throws an error if we call insertCode,
      // so we mock it out. For now this is fine since we don't actually care
      // about the implementation (only that it was called).
      insertCode = jest.fn()
      fakeEditor.rceWrapper.insertCode = insertCode
    })

    it('does nothing if the message is not A2ExternalContentReady', async () => {
      window.postMessage(fakeEvent, '*')
      expect(insertCode).not.toHaveBeenCalled()
    })

    it('inserts a link for each content item if the message is A2ExternalContentReady', async () => {
      window.postMessage(realEvent, '*')
      await act(async () => jest.runOnlyPendingTimers())
      await waitFor(() => {
        expect(insertCode).toHaveBeenCalledTimes(2)
        expect(insertCode).toHaveBeenNthCalledWith(1, expect.stringContaining('first item'))
        expect(insertCode).toHaveBeenNthCalledWith(2, expect.stringContaining('second item'))
      })
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
      const user = userEvent.setup({delay: null})
      const props = await makeProps()
      await renderEditor(props)
      props.onContentsChanged.mockClear()
      await user.type(document.getElementById('textentry_text'), '!')
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

      jest.advanceTimersByTime(3000)
      expect(props.createSubmissionDraft).not.toHaveBeenCalled()
    })

    it('is not called for a brand new entry with no content', async () => {
      const props = await makeProps()
      const {rerender} = await renderEditor(props)

      const newProps = await makeProps({
        submission: {
          id: '1',
          _id: '1',
          attempt: 2,
          state: 'unsubmitted',
        },
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
          id: '1',
        },
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
