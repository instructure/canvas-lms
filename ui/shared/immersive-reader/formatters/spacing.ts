/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import type Formatter from '../Formatter'

const MATH_SPAN_QUERY = '.math_equation_latex'

/**
 * Formatter to correct spacing before equations
 *
 * Removes empty math containers to prevent extra
 * spacing before an equation in immersive reader
 */
const spacing: Formatter = function spacing(content: string, parser: DOMParser): string {
  if (!content) return ''

  const body = parser.parseFromString(content, 'text/html').body
  const mathParagraph = body.querySelector(MATH_SPAN_QUERY)?.parentElement

  // Adjacent equations on new lines. Return a break to preserve new lines
  if (body.textContent === '') return '<br />'

  // Adjacent equations on new lines with extra whitespace between them
  if (!body.textContent?.trim()) return `<p>${body.textContent}</p>`

  // The content has actual text, don't remove it
  if (mathParagraph?.textContent?.trim()) return content

  mathParagraph?.remove()
  return body.innerHTML
}

export default spacing
