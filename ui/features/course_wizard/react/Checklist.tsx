/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import React from 'react'
import ChecklistItem from './ChecklistItem'
import ListItems from './ListItems'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('course_wizard')

export interface ChecklistProps {
  selectedItem: string
  clickHandler: (stepKey: string) => void
  className: string
}

export default function Checklist({
  selectedItem,
  clickHandler,
  className,
}: ChecklistProps): React.JSX.Element {
  return (
    <div className={className}>
      <h2 className="screenreader-only">{I18n.t('Setup Checklist')}</h2>
      <ul className="ic-wizard-box__nav-checklist">
        {ListItems.map(item => {
          const isSelected = selectedItem === item.key
          const id = `wizard_${item.key}`
          return (
            <ChecklistItem
              complete={item.complete}
              id={id}
              key={item.key}
              stepKey={item.key}
              title={item.title}
              onClick={clickHandler}
              isSelected={isSelected}
            />
          )
        })}
      </ul>
    </div>
  )
}
