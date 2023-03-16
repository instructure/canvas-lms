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

import indicate from './indicate'

const ELEMENT_NODE = 1
const WALK_BATCH_SIZE = 25

const _indexOf = Array.prototype.indexOf

export function walk(node, fn, done) {
  const stack = [{node, index: 0}]
  const processBatch = () => {
    let batchRemaining = WALK_BATCH_SIZE
    while (stack.length > 0 && batchRemaining > 0) {
      const depth = stack.length - 1
      const node = stack[depth].node.childNodes[stack[depth].index]
      if (node) {
        stack[depth].index += 1
        if (node.nodeType === ELEMENT_NODE) {
          fn(node)
          stack.push({node, index: 0})
          batchRemaining -= 0
        }
      } else {
        stack.pop()
      }
    }
    setTimeout(stack.length > 0 ? processBatch : done, 0)
  }
  processBatch()
}

export function select(elem, indicateFn = indicate) {
  if (elem == null) {
    return
  }
  elem.scrollIntoView(false)
  if (elem.ownerDocument?.documentElement) {
    elem.ownerDocument.documentElement.scrollTop += 5 // room for the indicator highlight
  }
  indicateFn(elem)
}

export function prepend(parent, child) {
  if (parent.childNodes.length > 0) {
    parent.insertBefore(child, parent.childNodes[0])
  } else {
    parent.appendChild(child)
  }
}

export function changeTag(elem, tagName) {
  const newElem = elem.ownerDocument.createElement(tagName)
  while (elem.firstChild) {
    newElem.appendChild(elem.firstChild)
  }
  for (let i = elem.attributes.length - 1; i >= 0; --i) {
    newElem.attributes.setNamedItem(elem.attributes[i].cloneNode())
  }
  elem.parentNode.replaceChild(newElem, elem)
  return newElem
}

export function pathForNode(ancestor, decendant) {
  const path = []
  let node = decendant
  while (true) {
    if (node == ancestor) {
      return path
    }
    const parent = node.parentNode
    if (parent == null) {
      return null
    }
    path.push(_indexOf.call(parent.childNodes, node))
    node = parent
  }
}

export function nodeByPath(ancestor, path) {
  let node = ancestor
  let index
  while ((index = path.pop()) !== undefined) {
    node = node.childNodes[index]
    if (node == null) {
      return null
    }
  }
  return node
}

export function onlyContainsLink(elem) {
  const links = elem.getElementsByTagName('a')
  if (links.length) {
    return links[0].textContent === elem.textContent
  } else {
    return false
  }
}

export function splitStyleAttribute(styleString) {
  const split = styleString.split(';')
  return split.reduce((styleObj, attributeValue) => {
    const pair = attributeValue.split(':')
    if (pair.length === 2) {
      styleObj[pair[0].trim()] = pair[1].trim()
    }
    return styleObj
  }, {})
}

export function createStyleString(styleObj) {
  let styleString = Object.keys(styleObj)
    .map(key => `${key}:${styleObj[key]}`)
    .join(';')
  if (styleString) {
    styleString = `${styleString};`
  }
  return styleString
}

export function hasTextNode(elem) {
  const nodes = Array.from(elem.childNodes)
  return nodes.some(x => x.nodeType === Node.TEXT_NODE)
}
