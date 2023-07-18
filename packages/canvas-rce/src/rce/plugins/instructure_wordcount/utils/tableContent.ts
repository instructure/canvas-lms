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

import {Editor} from 'tinymce'
import {countContent, Category} from './countContent'
import formatMessage from '../../../../format-message'

export interface Header {
  readonly id: string
  readonly getLabel: () => string
}

export interface CountRow {
  readonly label: string
  readonly documentCount: number
  readonly selectionCount: number
}

export const HEADERS: Header[] = [
  {id: 'count', getLabel: () => formatMessage('Count')},
  {id: 'document', getLabel: () => formatMessage('Document')},
  {id: 'selection', getLabel: () => formatMessage('Selection')},
]

const ROW_LABELS: [Category, () => string][] = [
  ['words', () => formatMessage('Words')],
  ['chars-no-spaces', () => formatMessage('Characters (no spaces)')],
  ['chars', () => formatMessage('Characters')],
]

export const generateRows = (ed: Editor): CountRow[] => {
  return ROW_LABELS.map(([category, getLabel]) => ({
    label: getLabel(),
    documentCount: countContent(ed, 'body', category),
    selectionCount: countContent(ed, 'selection', category),
  }))
}
