// @ts-nocheck
/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import ReactDOM from 'react-dom'
import CustomColumnHeader from './CustomColumnHeader'
import type Gradebook from '../../Gradebook'
import type GridSupport from '../GridSupport'

const I18n = useI18nScope('gradebook')

function getProps(
  column: {
    title: string
    customColumnId: string
  },
  gradebook,
  options
) {
  const customColumn = gradebook.getCustomColumn(column.customColumnId)

  return {
    ref: options.ref,
    title: customColumn.teacher_notes ? I18n.t('Notes') : customColumn.title,
  }
}

export default class CustomColumnHeaderRenderer {
  gradebook: Gradebook

  constructor(gradebook: Gradebook) {
    this.gradebook = gradebook
  }

  render(column, $container: HTMLElement, _gridSupport: GridSupport, options) {
    const props = getProps(column, this.gradebook, options)
    ReactDOM.render(<CustomColumnHeader {...props} />, $container)
  }

  destroy(_column, $container: HTMLElement, _gridSupport: GridSupport) {
    ReactDOM.unmountComponentAtNode($container)
  }
}
