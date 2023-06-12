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

import {planInsertTextIntoLatexTextarea} from '../latexTextareaUtil'
import {performTextEditActionsOnString} from '../../../../../util/textarea-editing-util'

describe('planInsertTextIntoLatexTextarea', () => {
  const paramIndicatorPairs = [
    ['[ ', ' ]'],
    ['{ ', ' }'],
    ['[', ']'],
    ['{', '}'],
  ]

  it('handles basic cases', () => {
    testInsertionPlan('<>', 'test', 'test<>')
    testInsertionPlan('<foo>', 'x', 'x<>')
    testInsertionPlan('foo<>bar', ' and a ', 'foo and a <>bar')
    testInsertionPlan('foo<bar>', 'man', 'fooman<>')

    testInsertionPlan('te\n<foo>st', 'xx', 'te\nxx<>st')
    testInsertionPlan('te<fo\no>st', 'xx', 'texx<>st')
  })

  it('handles single argument insertions', () => {
    paramIndicatorPairs.forEach(([before, after]) => {
      testInsertionPlan('<>', `\\foo${before}${after}`, `\\foo${before.trim()}<>${after.trim()}`)
    })

    testInsertionPlan('before <> after', '\\foo{}', 'before \\foo{<>} after')
    testInsertionPlan('some<thing> else', '\\foo{}', 'some\\foo{thing}<> else')
  })

  it('handles double argument insertions', () => {
    testInsertionPlan('<>', '\\foo[  ]{  }', '\\foo[<>]{}')
    testInsertionPlan('<>', '\\foo[  ][]', '\\foo[<>][]')
    testInsertionPlan('<>', '\\foo[  ]{}', '\\foo[<>]{}')
    testInsertionPlan('<>', '\\foo{  }[  ]', '\\foo{<>}[]')
    testInsertionPlan('<>', '\\foo{  }{  }', '\\foo{<>}{}')
    testInsertionPlan('<>', '\\foo{  }[]', '\\foo{<>}[]')
    testInsertionPlan('<>', '\\foo{  }{}', '\\foo{<>}{}')
    testInsertionPlan('<>', '\\foo[][  ]', '\\foo[<>][]')
    testInsertionPlan('<>', '\\foo[]{  }', '\\foo[<>]{}')
    testInsertionPlan('<>', '\\foo[][]', '\\foo[<>][]')
    testInsertionPlan('<>', '\\foo[]{}', '\\foo[<>]{}')
    testInsertionPlan('<>', '\\foo{}[  ]', '\\foo{<>}[]')
    testInsertionPlan('<>', '\\foo{}{  }', '\\foo{<>}{}')
    testInsertionPlan('<>', '\\foo{}[]', '\\foo{<>}[]')
    testInsertionPlan('<>', '\\foo{}{}', '\\foo{<>}{}')

    testInsertionPlan('before <> after', '\\foo{}{}', 'before \\foo{<>}{} after')
    testInsertionPlan('some<thing> else', '\\foo{}{}', 'some\\foo{thing}{<>} else')
  })
})

const selStartIndicator = '<'
const selEndIndicator = '>'

function testInsertionPlan(inputState: string, insertionText: string, expectedState: string) {
  const selStart = inputState.indexOf(selStartIndicator)
  const selEnd = inputState.indexOf(selEndIndicator) - 1

  if (selStart < 0 || selEnd < 0) {
    throw new Error(
      `inputState must contain a selection start (${selStartIndicator}) and end indicator (${selEndIndicator})`
    )
  }

  const beforeText =
    inputState.substring(0, selStart) +
    inputState.substring(selStart + 1, selEnd + 1) +
    inputState.substring(selEnd + 2)

  const actions = planInsertTextIntoLatexTextarea({
    currentText: beforeText,
    selStart,
    selEnd,
    insertionText,
  })

  const result = performTextEditActionsOnString({
    text: beforeText,
    selStart,
    selEnd,
    actions,
  })

  const resultStateString =
    result.text.substring(0, result.selStart) +
    selStartIndicator +
    result.text.substring(result.selStart, result.selEnd) +
    selEndIndicator +
    result.text.substring(result.selEnd)

  expect(resultStateString).toEqual(expectedState)
}
