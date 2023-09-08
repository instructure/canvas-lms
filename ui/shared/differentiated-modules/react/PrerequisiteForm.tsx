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

import React from 'react'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Link} from '@instructure/ui-link'
// @ts-expect-error -- remove once on InstUI 8
import {IconAddLine} from '@instructure/ui-icons'
import type {Module} from './types'
import PrerequisiteSelector from './PrerequisiteSelector'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('differentiated_modules')

const DEFAULT_OPTION = {id: '-1', name: `[ ${I18n.t('Select Module')} ]`}

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
  return (
    <FormFieldGroup
      description={I18n.t('Prerequisites')}
      layout="stacked"
      data-testid="prerequisite-form"
    >
      {prerequisites.map((module, index) => (
        <PrerequisiteSelector
          key={module.name}
          selection={module.name}
          options={[DEFAULT_OPTION, ...availableModules]}
          onDropPrerequisite={onDropPrerequisite}
          onUpdatePrerequisite={onUpdatePrerequisite}
          index={index}
        />
      ))}
      <Link
        role="button"
        onClick={() => onAddPrerequisite(DEFAULT_OPTION)}
        isWithinText={false}
        renderIcon={<IconAddLine />}
      >
        {I18n.t('Add Prerequisite')}
      </Link>
    </FormFieldGroup>
  )
}
