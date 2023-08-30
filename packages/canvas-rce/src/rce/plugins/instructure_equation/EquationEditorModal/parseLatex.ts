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

import {containsAdvancedSyntax} from './advancedOnlySyntax'
import {Editor} from 'tinymce'

// Used to detect inline latex delimited like: \( ... \) OR $$ ... $$
const BOUNDARY_REGEX = /\\\((.+?)\\\)|\$\$(.+?)\$\$/g

export type ParsedLatex = {
  latex?: string
  advancedOnly?: boolean
  startContainer?: Node
  leftIndex?: number
  rightIndex?: number
}

export const selectionIsLatex = (selection: string) => {
  return (
    (selection.startsWith('\\(') && selection.endsWith('\\)')) ||
    (selection.startsWith('$$') && selection.endsWith('$$'))
  )
}

export const cleanLatex = (latex: string) => {
  const sansDelimiters = latex.substr(2, latex.length - 4)
  return sansDelimiters.replace(/&nbsp;/g, '').trim()
}

export const findLatex = (nodeValue: string, cursor: number): ParsedLatex => {
  // The range could still contain more than one formulae, so we need to
  // isolate them and figure out which one the cursor is within.
  const latexMatches = nodeValue.match(BOUNDARY_REGEX)

  if (!latexMatches) return {}

  let leftIndex: number | undefined
  let rightIndex: number | undefined
  const foundLatex = latexMatches.find(latex => {
    leftIndex = nodeValue.indexOf(latex)
    rightIndex = leftIndex + latex.length
    return leftIndex < cursor && cursor < rightIndex && selectionIsLatex(latex)
  })

  return foundLatex ? {latex: cleanLatex(foundLatex), leftIndex, rightIndex} : {}
}

export const parseLatex = (editor: Editor): ParsedLatex => {
  const selection = editor.selection.getContent()
  const selectionNode = editor.selection.getNode()
  const editorRange = editor.selection.getRng()
  const startContainer = editorRange?.startContainer as Text
  const wholeText = startContainer?.wholeText

  // check if selection is inline latex
  if (selection && selectionIsLatex(selection)) {
    const latex = cleanLatex(selection)
    return {latex, advancedOnly: containsAdvancedSyntax(latex)}
  } else if (
    selectionNode?.tagName === 'IMG' &&
    selectionNode?.classList.contains('equation_image')
  ) {
    // check if we launched modal from an equation image
    try {
      const src = new URL((selectionNode as HTMLImageElement).src)
      const encodedLatex = src.pathname.replace(/^\/equation_images\//, '')
      const latex = decodeURIComponent(decodeURIComponent(encodedLatex))
      return {latex, advancedOnly: containsAdvancedSyntax(latex)}
    } catch (ex) {
      // probably failed to create the new URL
      return {}
    }
  } else if (wholeText) {
    // check if the cursor was within inline latex when launched

    // The `wholeText` value is not sufficient, since we could be dealing with
    // a number of nested ranges. The `nodeValue` is the text in the range in
    // which we have found the cursor.
    const nodeValue = startContainer.nodeValue || ''
    const cursor = editorRange.startOffset
    const parsedLatex = findLatex(nodeValue, cursor)
    if (parsedLatex.latex) {
      parsedLatex.startContainer = startContainer
      parsedLatex.advancedOnly = containsAdvancedSyntax(parsedLatex.latex)
    }
    return parsedLatex
  } else {
    return {}
  }
}
