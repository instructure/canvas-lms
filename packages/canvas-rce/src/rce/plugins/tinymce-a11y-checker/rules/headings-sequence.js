/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import formatMessage from '../../../../format-message'
import {changeTag} from '../utils/dom'

/* Headings Sequence rule
 * this rule is ensuring that heading tags (H1-H6) are layed out in sequential
 * order for organizing your site.
 *
 * this rule only looks at H2-H6 headings. all other tags pass.
 * this rule will walk 'up-down' the dom to find the heading tag that is
 * laid out previous to the heading tag being checked.
 * this rule will see if the heading tag number of the previous heading is
 * one more than one less than it's own heading tag and will fail if so
 * this rule will check to see if there is no previous heading tag and will
 * fail the test if so
 */

const isHtag = elem => {
  const allHTags = {
    H1: true,
    H2: true,
    H3: true,
    H4: true,
    H5: true,
    H6: true,
  }
  return elem && allHTags[elem.tagName] === true
}

// gets the H tag that is furthest down in the tree from elem(inclusive)
const getHighestOrderHForElem = elem => {
  const allHForElem = Array.prototype.slice.call(elem.querySelectorAll('H1,H2,H3,H4,H5,H6'))
  if (allHForElem.length > 0) {
    return allHForElem.reverse()[0]
  }
  if (isHtag(elem)) {
    return elem
  }
  return undefined
}

// gets all siblings of elem that come before the elem ordered by nearest to
// elem
const getPrevSiblings = elem => {
  const ret = []
  if (!elem || !elem.parentElement || !elem.parentElement.children) {
    return ret
  }
  const sibs = elem.parentElement.children
  for (let i = 0; i < sibs.length; i++) {
    if (sibs[i] === elem) {
      break
    }
    ret.unshift(sibs[i])
  }
  return ret
}

const searchPrevSiblings = elem => {
  const sibs = getPrevSiblings(elem)
  let ret
  for (let i = 0; i < sibs.length; i++) {
    ret = getHighestOrderHForElem(sibs[i])
    if (ret) {
      break
    }
  }
  return ret
}

const _walkUpTree = elem => {
  let ret
  if (!elem || elem.tagName === 'BODY') {
    return undefined
  }
  if (isHtag(elem)) {
    return elem
  }
  ret = searchPrevSiblings(elem)
  if (!ret) {
    ret = _walkUpTree(elem.parentElement)
  }
  return ret
}

const walkUpTree = elem => {
  let ret = searchPrevSiblings(elem)
  if (!ret) {
    ret = _walkUpTree(elem.parentElement)
  }
  return ret
}

const getPriorHeading = elem => {
  return walkUpTree(elem)
}

// a valid prior H tag is greater or equal to one less than current
const getValidHeadings = elem => {
  const hNum = +elem.tagName.substring(1)
  const ret = {}
  for (let i = hNum - 1; i <= 6; i++) {
    ret[`H${i}`] = true
  }
  return ret
}

export default {
  id: 'headings-sequence',
  test: elem => {
    const testTags = {
      H2: true,
      H3: true,
      H4: true,
      H5: true,
      H6: true,
    }
    if (testTags[elem.tagName] !== true) {
      return true
    }
    const validHeadings = getValidHeadings(elem)
    const priorHeading = getPriorHeading(elem)
    if (priorHeading) {
      return validHeadings[priorHeading.tagName]
    }
    return true
  },

  data: _elem => {
    return {
      action: 'nothing',
    }
  },

  form: () => [
    {
      label: formatMessage('Action to take:'),
      dataKey: 'action',
      options: [
        ['nothing', formatMessage('Leave as is')],
        ['elem', formatMessage('Fix heading hierarchy')],
        ['modify', formatMessage('Remove heading style')],
      ],
    },
  ],

  update: (elem, data) => {
    if (!data || !data.action || data.action === 'nothing') {
      return elem
    }
    switch (data.action) {
      case 'elem': {
        const priorH = getPriorHeading(elem)
        const hIdx = priorH ? +priorH.tagName.substring(1) : 0
        return changeTag(elem, `H${hIdx + 1}`)
      }
      case 'modify': {
        return changeTag(elem, 'p')
      }
    }
  },

  message: () => formatMessage('Heading levels should not be skipped.'),

  why: () =>
    formatMessage(
      'Sighted users browse web pages quickly, looking for large or bolded headings. Screen reader users rely on headers for contextual understanding. Headers should use the proper structure.'
    ),

  link: 'https://www.w3.org/TR/WCAG20-TECHS/G141.html',
  linkText: () => formatMessage('Learn more about organizing page headings'),
}
