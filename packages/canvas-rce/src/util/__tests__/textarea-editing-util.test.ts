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

import {
  performTextEditActionOnTextarea,
  performTextEditActionsOnString,
} from '../textarea-editing-util'

import * as textFieldEdit from 'text-field-edit'

jest.mock('text-field-edit')

describe('performTextEditActionsOnString', () => {
  it('should insert into an empty string', () => {
    expect(
      performTextEditActionsOnString({
        text: '',
        selStart: 0,
        selEnd: 0,
        actions: [{action: 'insert', text: 'foo'}],
      })
    ).toEqual({
      text: 'foo',
      selStart: 3,
      selEnd: 3,
    })
  })

  it('should insert into a populated string', () => {
    expect(
      performTextEditActionsOnString({
        text: 'something',
        selStart: 4,
        selEnd: 4,
        actions: [{action: 'insert', text: ' other '}],
      })
    ).toEqual({
      text: 'some other thing',
      selStart: 11,
      selEnd: 11,
    })
  })

  it('should replace a substring', () => {
    expect(
      performTextEditActionsOnString({
        text: 'one two three',
        selStart: 4,
        selEnd: 7,
        actions: [{action: 'insert', text: 'foobar'}],
      })
    ).toEqual({
      text: 'one foobar three',
      selStart: 10,
      selEnd: 10,
    })
  })

  it('should wrap a substring', () => {
    expect(
      performTextEditActionsOnString({
        text: 'one two three',
        selStart: 4,
        selEnd: 7,
        actions: [{action: 'wrapSelection', before: '<<', after: '>>'}],
      })
    ).toEqual({
      text: 'one <<two>> three',
      selStart: 6,
      selEnd: 9,
    })
  })
})

describe('performTextEditActionOnTextarea', () => {
  it('should handle insert', () => {
    const textarea = document.createElement('textarea')

    performTextEditActionOnTextarea(textarea, {
      action: 'insert',
      text: 'test',
    })

    expect(textFieldEdit.insert as jest.Mock).toHaveBeenCalledWith(textarea, 'test')
  })

  it('should handle wrapSelection', () => {
    const textarea = document.createElement('textarea')

    performTextEditActionOnTextarea(textarea, {
      action: 'wrapSelection',
      before: 'before',
      after: 'after',
    })

    expect(textFieldEdit.wrapSelection as jest.Mock).toHaveBeenCalledWith(
      textarea,
      'before',
      'after'
    )

    performTextEditActionOnTextarea(textarea, {
      action: 'wrapSelection',
      before: null,
      after: 'after',
    })

    expect(textFieldEdit.wrapSelection as jest.Mock).toHaveBeenCalledWith(textarea, '', 'after')

    performTextEditActionOnTextarea(textarea, {
      action: 'wrapSelection',
      before: 'before',
      after: null,
    })

    expect(textFieldEdit.wrapSelection as jest.Mock).toHaveBeenCalledWith(textarea, '', 'after')
  })
})
