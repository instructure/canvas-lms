/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('assignments.never_drop')

interface Assignment {
  id: string
  name: string
}

interface NeverDropProps {
  canChangeDropRules: boolean
  chosen?: string
  chosen_id?: string
  assignments?: Assignment[]
  label_id?: string
  onRemove: () => void
  onChange?: (chosenId: string) => void
}

export default function NeverDrop({
  canChangeDropRules,
  chosen,
  chosen_id,
  assignments = [],
  label_id,
  onRemove,
  onChange,
}: NeverDropProps) {
  const buttonTitle = chosen
    ? `${I18n.t('Remove never drop rule')} ${chosen}`
    : I18n.t('Remove unsaved never drop rule')

  const handleSelectChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    if (canChangeDropRules && onChange) {
      onChange(e.target.value)
    }
  }

  const handleRemoveClick = (e: React.MouseEvent<HTMLButtonElement>) => {
    e.preventDefault()
    if (canChangeDropRules) {
      onRemove()
    }
  }

  return (
    <div className="never_drop_rule" data-testid="never-drop-rule">
      <button
        className={`remove_never_drop btn btn-link${!canChangeDropRules ? ' disabled' : ''}`}
        type="button"
        title={buttonTitle}
        aria-label={buttonTitle}
        aria-disabled={!canChangeDropRules}
        onClick={handleRemoveClick}
        data-testid="remove-never-drop-button"
      >
        <i className="icon-end" />
      </button>

      {!chosen && (
        <select
          name="rules[never_drop][]"
          aria-labelledby={`ag_${label_id}_never_drop`}
          disabled={!canChangeDropRules}
          onChange={handleSelectChange}
          value={chosen_id}
          data-testid="never-drop-select"
        >
          {assignments.map(assignment => (
            <option key={assignment.id} value={assignment.id}>
              {assignment.name}
            </option>
          ))}
        </select>
      )}

      {chosen && (
        <>
          <span data-testid="chosen-assignment">{chosen}</span>
          <input type="hidden" name="rules[never_drop][]" value={chosen_id} />
        </>
      )}
    </div>
  )
}
