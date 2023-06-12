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

import rule from '../headings-start-at-h2'

describe('test', () => {
  describe('when the rule is disabled', () => {
    const config = {
      disableHeadingsStartAtH2: true,
    }

    test('returns true if the tag is not h1', () => {
      const element = document.createElement('span')
      expect(rule.test(element, config)).toBeTruthy()
    })

    test('returns true even if the tag is h1', () => {
      const element = document.createElement('h1')
      expect(rule.test(element, config)).toBeTruthy()
    })
  })

  describe('when the rule is explicitly enabled', () => {
    const config = {
      disableHeadingsStartAtH2: false,
    }

    test('returns true if the tag is not h1', () => {
      const element = document.createElement('span')
      expect(rule.test(element, config)).toBeTruthy()
    })

    test('returns false if the tag is h1', () => {
      const element = document.createElement('h1')
      expect(rule.test(element, config)).toBeFalsy()
    })
  })

  describe('when the rule is implictly enabled', () => {
    test('returns true if the tag is not h1', () => {
      const element = document.createElement('span')
      expect(rule.test(element)).toBeTruthy()
    })

    test('returns false if the tag is h1', () => {
      const element = document.createElement('h1')
      expect(rule.test(element)).toBeFalsy()
    })
  })
})

describe('data', () => {
  test("default action is 'nothing'", () => {
    expect(rule.data().action).toBe('nothing')
  })
})

describe('form', () => {
  test('returns the proper object', () => {
    expect(rule.form()).toMatchSnapshot()
  })
})

describe('update', () => {
  let body, h1

  beforeEach(() => {
    body = document.createElement('body')
    h1 = document.createElement('h1')
    body.appendChild(h1)
  })

  test('returns same element when no data is passed', () => {
    expect(rule.update(h1, {})).toBe(h1)
  })

  test('returns same element when data is missing an action', () => {
    expect(rule.update(h1, {notAction: 'something'})).toBe(h1)
  })

  test('returns same element when action is nothing', () => {
    expect(rule.update(h1, {action: 'nothing'})).toBe(h1)
  })

  test('returns h2 tag when action is elem-only', () => {
    expect(rule.update(h1, {action: 'elem-only'}).tagName).toBe('H2')
  })

  test('returns p tag when action is modify', () => {
    expect(rule.update(h1, {action: 'modify'}).tagName).toBe('P')
  })
})

describe('message', () => {
  test('returns the proper message', () => {
    expect(rule.message()).toMatchSnapshot()
  })
})

describe('why', () => {
  test('returns the proper why text', () => {
    expect(rule.why()).toMatchSnapshot()
  })
})

describe('link', () => {
  test('returns the proper link', () => {
    expect(rule.link).toMatchSnapshot()
  })
})

describe('linkText', () => {
  test('returns the proper link text', () => {
    expect(rule.linkText()).toMatchSnapshot()
  })
})
