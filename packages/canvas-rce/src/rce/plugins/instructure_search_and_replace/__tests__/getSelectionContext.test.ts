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

import {getSelectionContext} from '../getSelectionContext'

describe('getSelectionContext', () => {
  document.body.innerHTML = `
    <p>text before <span class="mce-match-marker-selected">selection</span> text after</p>
    `

  it('returns the text before and after the selection', () => {
    const elements = document.getElementsByClassName('mce-match-marker-selected')
    const [beforeText, afterText] = getSelectionContext(elements)
    expect(beforeText).toBe('text before ')
    expect(afterText).toBe(' text after')
  })

  it('returns the text before the selection when the selection is at the end of the text', () => {
    document.body.innerHTML = `
        <p>text before <span class="mce-match-marker-selected">selection</span></p>
        `
    const elements = document.getElementsByClassName('mce-match-marker-selected')
    const [beforeText, afterText] = getSelectionContext(elements)
    expect(beforeText).toBe('text before ')
    expect(afterText).toBe('')
  })

  it('returns the text after the selection when the selection is at the beginning of the text', () => {
    document.body.innerHTML = `
            <p><span class="mce-match-marker-selected">selection</span> text after</p>
            `
    const elements = document.getElementsByClassName('mce-match-marker-selected')
    const [beforeText, afterText] = getSelectionContext(elements)
    expect(beforeText).toBe('')
    expect(afterText).toBe(' text after')
  })

  it('returns after text up to 10 words', () => {
    document.body.innerHTML = `
            <p>text before <span class="mce-match-marker-selected">selection</span> text after with more than 10 words dogs are cute they go bark</p>
            `
    const elements = document.getElementsByClassName('mce-match-marker-selected')
    const [beforeText, afterText] = getSelectionContext(elements)
    expect(beforeText).toBe('')
    expect(afterText).toBe(' text after with more than 10 words dogs are cute')
  })

  it('returns after text up to first period', () => {
    document.body.innerHTML = `
            <p>text before <span class="mce-match-marker-selected">selection</span> text after. more text after the period</p>
            `
    const elements = document.getElementsByClassName('mce-match-marker-selected')
    const [beforeText, afterText] = getSelectionContext(elements)
    expect(beforeText).toBe('text before ')
    expect(afterText).toBe(' text after.')
  })

  it('returns before text up to a combined total of 10 words', () => {
    document.body.innerHTML = `
            <p>text before with more than 10 words dogs are cute they go bark <span class="mce-match-marker-selected">selection</span> text after</p>
            `
    const elements = document.getElementsByClassName('mce-match-marker-selected')
    const [beforeText, afterText] = getSelectionContext(elements)
    expect(beforeText).toBe('10 words dogs are cute they go bark ')
    expect(afterText).toBe(' text after')
  })

  it('does not count text immediately surrounding the selection as a word', () => {
    document.body.innerHTML = `
            <p>this is a whole bunch of gibberish text before sele<span class="mce-match-marker-selected">c</span>tion text after lorem ipsum something something</p>
            `
    const elements = document.getElementsByClassName('mce-match-marker-selected')
    const [beforeText, afterText] = getSelectionContext(elements)
    expect(beforeText).toBe('of gibberish text before sele')
    expect(afterText).toBe('tion text after lorem ipsum something something')
  })

  it('works when text is broken up into multiple text nodes', () => {
    document.body.innerHTML = `
            <p>this is a whole bunch of <span>g</span>i<span>b</span>berish text be<span>for</span>e s<span>e</span>le<span class="mce-match-marker-selected">c</span>tion te<span>xt af</span>ter lorem ip<span>sum some</span>thing something</p>
            `
    const elements = document.getElementsByClassName('mce-match-marker-selected')
    const [beforeText, afterText] = getSelectionContext(elements)
    expect(beforeText).toBe('of gibberish text before sele')
    expect(afterText).toBe('tion text after lorem ipsum something something')
  })

  it('ignores non-text nodes', () => {
    document.body.innerHTML = `
    <p>text <img alt="Here Be Images" src="https://yodawg.com:3001/some/path"/> before <span class="mce-match-marker-selected">selection</span> text after</p>
    `
    const elements = document.getElementsByClassName('mce-match-marker-selected')
    const [beforeText, afterText] = getSelectionContext(elements)
    expect(beforeText).toBe('text before ')
    expect(afterText).toBe(' text after')
  })

  it('ignores text in different paragraphs', () => {
    document.body.innerHTML = `
    <p>paragraph before</p>
    <p>text before <span class="mce-match-marker-selected">selection</span> text after</p>
    <p>paragraph after</p>
    `
    const elements = document.getElementsByClassName('mce-match-marker-selected')
    const [beforeText, afterText] = getSelectionContext(elements)
    expect(beforeText).toBe('text before ')
    expect(afterText).toBe(' text after')
  })

  it('counts words correctly with multiple whitespaces', () => {
    document.body.innerHTML = `
    <p>text  before the selection   lorem ipsum words   words words  <span class="mce-match-marker-selected">selection</span>  text  after    selection.</p>
    `
    const elements = document.getElementsByClassName('mce-match-marker-selected')
    const [beforeText, afterText] = getSelectionContext(elements)
    expect(beforeText).toBe('the selection lorem ipsum words words words ')
    expect(afterText).toBe('  text  after    selection.')
  })

  it('always includes beginning of selection', () => {
    document.body.innerHTML = `
    <p>text before sele<span class="mce-match-marker-selected">c</span>tion text after this is ten words lorem ipsum dolor sit</p>
    `
    const elements = document.getElementsByClassName('mce-match-marker-selected')
    const [beforeText, afterText] = getSelectionContext(elements)
    expect(beforeText).toBe('sele')
    expect(afterText).toBe('tion text after this is ten words lorem ipsum dolor sit')
  })
})
