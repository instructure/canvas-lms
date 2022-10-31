/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
  countWords,
  countCharsNoSpaces,
  countChars,
  callbackForCategory,
  countShouldIgnore,
  getTinymceCount,
  countContent,
  IGNORE_WORDCOUNT_ATTRIBUTE,
  Scope,
  Category,
} from '../countContent'

const editor: any = {
  getBody: () => ({
    querySelectorAll: () => [createNode('hello world'), createNode('hi again')],
  }),
  plugins: {
    wordcount: {
      body: {
        getWordCount: () => 50,
        getCharacterCountWithoutSpaces: () => 51,
        getCharacterCount: () => 52,
      },
      selection: {
        getWordCount: () => 53,
        getCharacterCountWithoutSpaces: () => 54,
        getCharacterCount: () => 55,
      },
    },
  },
}

const createNode = (content: string, charsOnly: boolean = false): Element => {
  const node = document.createElement('p')
  node.setAttribute(IGNORE_WORDCOUNT_ATTRIBUTE, charsOnly ? 'chars-only' : '')
  node.innerText = content
  return node
}

describe('countWords', () => {
  it('returns 0 if the ignore attribute is "chars-only"', () => {
    const node = createNode('abc', true)
    expect(countWords(node)).toEqual(0)
  })

  it('returns 0 if the text content is the empty string', () => {
    const node = createNode('')
    expect(countWords(node)).toEqual(0)
  })

  it('returns 0 if the text content is only whitespace', () => {
    const node = createNode('  ')
    expect(countWords(node)).toEqual(0)
  })

  it('returns the number of words (whitespace delimited)', () => {
    const node = createNode('a  b c      d')
    expect(countWords(node)).toEqual(4)
  })
})

describe('countChars', () => {
  it('returns 0 if the text content is the empty string', () => {
    const node = createNode('')
    expect(countChars(node)).toEqual(0)
  })

  it('handles invisible and nonstandard length characters', () => {
    // first one is invisible char U+2062
    ;['⁢', '👉', '𝟈'].forEach(char => {
      const node = createNode(char)
      expect(countChars(node)).toEqual(1)
    })
  })

  it('otherwise handles normal strings of characters', () => {
    ;['abc', 'a b c', 'somethingsomething'].forEach(str => {
      const node = createNode(str)
      expect(countChars(node)).toEqual(str.length)
    })
  })
})

describe('countCharsNoSpaces', () => {
  it('returns 0 if the text content is the empty string', () => {
    const node = createNode('')
    expect(countCharsNoSpaces(node)).toEqual(0)
  })

  it('returns 0 if the text content is only spaces', () => {
    const node = createNode(' ')
    expect(countCharsNoSpaces(node)).toEqual(0)
  })

  it('returns the character count minus the number of spaces', () => {
    const node = createNode('123       ') // 7 spaces
    expect(countCharsNoSpaces(node)).toEqual(3)
  })

  it('returns the character count if there are no spaces spaces', () => {
    const node = createNode('123')
    expect(countCharsNoSpaces(node)).toEqual(3)
  })
})

describe('callbackForCategory', () => {
  it('returns countWords for "words"', () => {
    expect(callbackForCategory('words')).toEqual(countWords)
  })

  it('returns countCharsNoSpaces for "chars-no-spaces"', () => {
    expect(callbackForCategory('chars-no-spaces')).toEqual(countCharsNoSpaces)
  })

  it('returns countChars for "chars"', () => {
    expect(callbackForCategory('chars')).toEqual(countChars)
  })
})

describe('countShouldIgnore', () => {
  it('returns 0 if scope is selection', () => {
    expect(countShouldIgnore(editor, 'selection', 'words')).toEqual(0)
  })

  it('counts correctly using the callback for "words"', () => {
    expect(countShouldIgnore(editor, 'body', 'words')).toEqual(4)
  })

  it('counts correctly using the callback for "chars-no-spaces"', () => {
    expect(countShouldIgnore(editor, 'body', 'chars-no-spaces')).toEqual(17)
  })

  it('counts correctly using the callback for "chars"', () => {
    expect(countShouldIgnore(editor, 'body', 'chars')).toEqual(19)
  })
})

describe('getTinymceCount', () => {
  it('returns the appropriate value for each input combination', () => {
    const scopes: Scope[] = ['body', 'selection']
    const categories: Category[] = ['words', 'chars-no-spaces', 'chars']

    let expectedValue = 50
    scopes.forEach(scope => {
      categories.forEach(category => {
        expect(getTinymceCount(editor, scope, category)).toEqual(expectedValue)
        expectedValue++
      })
    })
  })
})

describe('countContent', () => {
  describe('returns getTinymceCount less countShouldIgnore', () => {
    it('for "body" + "words"', () => {
      expect(countContent(editor, 'body', 'words')).toEqual(50 - 4)
    })

    it('for "body" + "chars-no-spaces"', () => {
      expect(countContent(editor, 'body', 'chars-no-spaces')).toEqual(51 - 17)
    })

    it('for "body" + "chars"', () => {
      expect(countContent(editor, 'body', 'chars')).toEqual(52 - 19)
    })

    it('for "selection" + "words"', () => {
      expect(countContent(editor, 'selection', 'words')).toEqual(53 - 0)
    })

    it('for "selection" + "chars-no-spaces"', () => {
      expect(countContent(editor, 'selection', 'chars-no-spaces')).toEqual(54 - 0)
    })

    it('for "selection" + "chars"', () => {
      expect(countContent(editor, 'selection', 'chars')).toEqual(55 - 0)
    })
  })
})
