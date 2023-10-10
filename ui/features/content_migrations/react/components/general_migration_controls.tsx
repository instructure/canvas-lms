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

import {View} from '@instructure/ui-view'
import React, {useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconAddSolid} from '@instructure/ui-icons'
import {Checkbox, CheckboxGroup} from '@instructure/ui-checkbox'
import {Button} from '@instructure/ui-buttons'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {DateAdjustment} from './date_adjustment'
import {submitMigrationCallbackType} from './types'

const I18n = useI18nScope('content_migrations_redesign')

export const GeneralMigrationControls = ({
  submitMigration,
}: {
  submitMigration: submitMigrationCallbackType
}) => {
  const [selectiveImport, setSelectiveImport] = useState<boolean>(false)
  const [importAsNewQuizzes, setImportAsNewQuizzes] = useState<boolean>(false)
  const [adjustDates, setAdjustDates] = useState<boolean>(false)
  return (
    <>
      <View as="div" margin="medium none none none">
        <RadioInputGroup
          name={I18n.t('Selective import')}
          layout="stacked"
          description={I18n.t('Content')}
        >
          <RadioInput
            name="selective_import"
            value="non_selective"
            label={I18n.t('All content')}
            onChange={(e: React.SyntheticEvent<Element, Event>) => {
              const target = e.target as HTMLInputElement
              setSelectiveImport(!target.checked)
            }}
            checked={selectiveImport}
          />
          <RadioInput
            name="selective_import"
            value="selective"
            label={I18n.t('Select specific content')}
            onChange={(e: React.SyntheticEvent<Element, Event>) => {
              const target = e.target as HTMLInputElement
              setSelectiveImport(target.checked)
            }}
            checked={!selectiveImport}
          />
        </RadioInputGroup>
      </View>
      <View as="div" margin="large none none none">
        <CheckboxGroup name={I18n.t('Options')} layout="stacked" description={I18n.t('Options')}>
          <Checkbox
            name="existing_quizzes_as_new_quizzes"
            value="existing_quizzes_as_new_quizzes"
            label={I18n.t('Import existing quizzes as New Quizzes')}
            onChange={(e: React.SyntheticEvent<Element, Event>) => {
              const target = e.target as HTMLInputElement
              setImportAsNewQuizzes(target.checked)
            }}
          />
          <Checkbox
            name="adjust_dates[enabled]"
            value="adjust_dates[enabled]"
            label={I18n.t('Adjust events and due dates')}
            onChange={(e: React.SyntheticEvent<Element, Event>) => {
              const target = e.target as HTMLInputElement
              setAdjustDates(target.checked)
            }}
          />
        </CheckboxGroup>
        {adjustDates ? <DateAdjustment /> : null}
      </View>
      <View as="div" margin="medium none none none">
        <Button>{I18n.t('Cancel')}</Button>
        <Button
          onClick={() => {
            submitMigration({
              selectiveImport,
              importAsNewQuizzes,
              adjustDates,
            })
          }}
          margin="small"
          color="primary"
        >
          <IconAddSolid /> &nbsp;
          {I18n.t('Add to Import Queue')}
        </Button>
      </View>
      <hr />
    </>
  )
}

export default GeneralMigrationControls
