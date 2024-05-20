/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {createRef, useCallback, useEffect, useMemo, useRef, useState} from 'react'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Button} from '@instructure/ui-buttons'
import {IconAddLine} from '@instructure/ui-icons'
import type {Module} from './types'
import PrerequisiteSelector from './PrerequisiteSelector'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('differentiated_modules')

export interface PrerequisiteFormProps {
  prerequisites: Module[]
  availableModules: Module[]
  onAddPrerequisite: (module: Module) => void
  onDropPrerequisite: (index: number) => void
  onUpdatePrerequisite: (module: Module, index: number) => void
}

export default function PrerequisiteForm({
  prerequisites,
  availableModules,
  onAddPrerequisite,
  onDropPrerequisite,
  onUpdatePrerequisite,
}: PrerequisiteFormProps) {
  const addPrerequisiteButton = createRef<Button>()
  const internalLastAction = useRef<{action: 'add' | 'delete'; index: number} | null>(null)
  const [focus, setFocus] = useState<{type: 'dropdown' | 'button'; index: number} | null>()

  const options = useMemo(() => {
    const prerequisiteIds = new Set(prerequisites.map(prereq => prereq.id))
    return availableModules.filter(module => !prerequisiteIds.has(module.id))
  }, [availableModules, prerequisites])

  const filterOptions = useCallback(
    (module: Module) =>
      ([module, ...options] as Module[]).reduce<Module[]>((selected, current) => {
        if (!selected.find(prerequisite => prerequisite.id === current.id)) {
          selected.push(current)
        }
        return selected
      }, []),
    [options]
  )

  // This avoids re-focusing after re-renders
  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => {
    setFocus(null)
  })

  useEffect(() => {
    if (internalLastAction.current?.action === 'add' && prerequisites.length > 0) {
      setFocus({type: 'dropdown', index: prerequisites.length - 1})
    } else if (internalLastAction.current?.action === 'delete' && prerequisites.length > 0) {
      const deletedIndex = internalLastAction.current?.index
      setFocus({type: 'button', index: deletedIndex > 0 ? deletedIndex - 1 : 0})
    } else if (internalLastAction.current?.action === 'delete' && prerequisites.length === 0) {
      addPrerequisiteButton.current?.focus()
    }
    internalLastAction.current = null
  }, [addPrerequisiteButton, prerequisites.length])

  return (
    <FormFieldGroup
      description={I18n.t('Prerequisites')}
      layout="stacked"
      data-testid="prerequisite-form"
    >
      {prerequisites.map((module, index) => (
        <PrerequisiteSelector
          // This is needed to keep focus in the component after re-rendering when module changed
          // eslint-disable-next-line react/no-array-index-key
          key={`module-${index}`}
          selection={module.name}
          options={filterOptions(module)}
          onDropPrerequisite={i => {
            internalLastAction.current = {action: 'delete', index: i}
            onDropPrerequisite(i)
          }}
          onUpdatePrerequisite={onUpdatePrerequisite}
          index={index}
          focusDropdown={focus?.type === 'dropdown' && focus?.index === index}
          focusDeleteButton={focus?.type === 'button' && focus?.index === index}
        />
      ))}
      {options.length > 0 && (
        <Button
          ref={addPrerequisiteButton}
          onClick={() => {
            internalLastAction.current = {action: 'add', index: prerequisites.length}
            onAddPrerequisite(options[0])
          }}
          renderIcon={<IconAddLine />}
        >
          {I18n.t('Prerequisite')}
        </Button>
      )}
    </FormFieldGroup>
  )
}
