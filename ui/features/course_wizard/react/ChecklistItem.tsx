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

import React, {useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import classnames from 'classnames'

const I18n = createI18nScope('course_wizard')

export interface ChecklistItemProps {
  onClick: (stepKey: string) => void
  stepKey: string
  title: string
  complete: boolean
  isSelected: boolean
  id: string
}

export default function ChecklistItem({
  onClick,
  stepKey,
  title,
  complete,
  isSelected,
  id,
}: ChecklistItemProps): React.JSX.Element {
  const classNameString = useMemo(
    () =>
      classnames({
        'ic-wizard-box__content-trigger': true,
        'ic-wizard-box__content-trigger--checked': complete,
        'ic-wizard-box__content-trigger--active': isSelected,
      }),
    [complete, isSelected],
  )

  const handleClick = (event: React.MouseEvent<HTMLAnchorElement>): void => {
    event.preventDefault()
    onClick(stepKey)
  }

  const completionMessage = complete ? I18n.t('(Item Complete)') : I18n.t('(Item Incomplete)')

  return (
    <li>
      {/* TODO: use InstUI button */}
      {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
      <a
        href="#"
        id={id}
        className={classNameString}
        onClick={handleClick}
        aria-label={`Select task: ${title}`}
      >
        <span>
          {title}
          <span className="screenreader-only">{completionMessage}</span>
        </span>
      </a>
    </li>
  )
}
