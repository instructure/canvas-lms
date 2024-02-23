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

import React, {useCallback, useMemo, useState} from 'react'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconAddSolid} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'
import {Checkbox, CheckboxGroup} from '@instructure/ui-checkbox'
import {Button} from '@instructure/ui-buttons'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {InfoButton} from './info_button'
import {DateAdjustments, remapSubstitutions} from '../date_adjustments'
import type {
  onSubmitMigrationFormCallback,
  DateAdjustmentConfig,
  submitMigrationFormData,
} from '../types'

const I18n = useI18nScope('content_migrations_redesign')

type CommonMigratorControlsProps = {
  canSelectContent?: boolean
  canImportAsNewQuizzes?: boolean
  canOverwriteAssessmentContent?: boolean
  canAdjustDates?: boolean
  canImportBPSettings?: boolean
  onSubmit: onSubmitMigrationFormCallback
  onCancel: () => void
  fileUploadProgress: number | null
}

const generateNewQuizzesLabel = () => (
  <>
    <Text>
      {I18n.t('Import existing quizzes as ')}
      <Text weight="bold">{I18n.t('New Quizzes')}</Text>
    </Text>
    <span style={{position: 'absolute', marginTop: '-0.55em'}}>
      <InfoButton
        heading={I18n.t('New Quizzes')}
        body={
          <>
            <Text>{I18n.t('New Quizzes is the new assessment engine for Canvas.')}</Text>
            <br />
            <Text>
              {I18n.t('To learn more, please contact your system administrator or visit ')}
            </Text>
            <Link href={I18n.t('#community.instructor_guide')}>
              {I18n.t('Canvas Instructor Guide')}
            </Link>
            <Text>.</Text>
          </>
        }
        buttonLabel={I18n.t('Import assessment as New Quizzes Help Icon')}
        modalLabel={I18n.t('Import assessment as New Quizzes Help Modal')}
      />
    </span>
  </>
)

const generateOverwriteLabel = () => (
  <>
    <Text>{I18n.t('Overwrite assessment content with matching IDs')}</Text>

    <span style={{position: 'absolute', marginTop: '-0.55em'}}>
      <InfoButton
        heading={I18n.t('Overwrite')}
        body={
          <Text>
            {I18n.t(
              'Some systems recycle their IDs for each new export. As a result, if you export two separate question banks they will have the same IDs. To prevent losing assessment data we treat these objects as different despite the IDs. Choosing this option will disable this safety feature and allow assessment data to overwrite existing data with the same IDs.'
            )}
          </Text>
        }
        buttonLabel={I18n.t('Overwrite Assessment Help Icon')}
        modalLabel={I18n.t('Overwrite Assessment Help Modal')}
      />
    </span>
  </>
)

export const CommonMigratorControls = ({
  canSelectContent = false,
  canImportAsNewQuizzes = false,
  canOverwriteAssessmentContent = false,
  canAdjustDates = false,
  canImportBPSettings = false,
  onSubmit,
  onCancel,
  fileUploadProgress,
}: CommonMigratorControlsProps) => {
  const [selectiveImport, setSelectiveImport] = useState<null | boolean>(null)
  const [importBPSettings, setImportBPSettings] = useState<null | boolean>(null)
  const [importAsNewQuizzes, setImportAsNewQuizzes] = useState<boolean>(false)
  const [overwriteAssessmentContent, setOverwriteAssessmentContent] = useState<boolean>(false)
  const [showAdjustDates, setShowAdjustDates] = useState<boolean>(false)
  const [dateAdjustments, setDateAdjustments] = useState<DateAdjustmentConfig>({
    adjust_dates: {
      enabled: false,
      operation: 'shift_dates',
    },
    date_shift_options: {
      substitutions: {},
      old_start_date: false,
      new_start_date: false,
      old_end_date: false,
      new_end_date: false,
      day_substitutions: [],
    },
  })
  const [contentError, setContentError] = useState<boolean>(false)

  const handleSubmit = useCallback(() => {
    const data: any = {settings: {}}
    setContentError(selectiveImport === null)
    data.errored = canSelectContent && selectiveImport === null // So the parent form can guard submit and show it's own errors
    canSelectContent && (data.selective_import = selectiveImport)
    canImportBPSettings && (data.settings.import_blueprint_settings = importBPSettings)
    if (canAdjustDates && dateAdjustments) {
      dateAdjustments.adjust_dates && (data.adjust_dates = dateAdjustments.adjust_dates)
      remapSubstitutions(data, dateAdjustments)
    }
    canImportAsNewQuizzes && (data.settings.import_quizzes_next = importAsNewQuizzes)
    canOverwriteAssessmentContent && (data.settings.overwrite_quizzes = overwriteAssessmentContent)
    onSubmit(data)
  }, [
    selectiveImport,
    canSelectContent,
    canImportBPSettings,
    importBPSettings,
    canAdjustDates,
    dateAdjustments,
    canImportAsNewQuizzes,
    importAsNewQuizzes,
    canOverwriteAssessmentContent,
    overwriteAssessmentContent,
    onSubmit,
  ])

  const options = useMemo(() => {
    const result = []
    canImportAsNewQuizzes &&
      result.push(
        <Checkbox
          key="existing_quizzes_as_new_quizzes"
          name="existing_quizzes_as_new_quizzes"
          value="existing_quizzes_as_new_quizzes"
          label={generateNewQuizzesLabel()}
          disabled={!ENV.QUIZZES_NEXT_ENABLED}
          defaultChecked={!!ENV.NEW_QUIZZES_MIGRATION_DEFAULT}
          onChange={(e: React.SyntheticEvent<Element, Event>) => {
            const target = e.target as HTMLInputElement
            setImportAsNewQuizzes(target.checked)
          }}
        />
      )
    canOverwriteAssessmentContent &&
      result.push(
        <Checkbox
          key="overwrite_assessment_content"
          name="overwrite_assessment_content"
          value="overwrite_assessment_content"
          label={generateOverwriteLabel()}
          onChange={(e: React.SyntheticEvent<Element, Event>) => {
            const target = e.target as HTMLInputElement
            setOverwriteAssessmentContent(target.checked)
          }}
        />
      )
    canAdjustDates &&
      result.push(
        <Checkbox
          key="adjust_dates[enabled]"
          name="adjust_dates[enabled]"
          value="adjust_dates[enabled]"
          label={I18n.t('Adjust events and due dates')}
          onChange={(e: React.SyntheticEvent<Element, Event>) => {
            const target = e.target as HTMLInputElement
            setShowAdjustDates(target.checked)

            const tmp = JSON.parse(JSON.stringify(dateAdjustments))
            tmp.adjust_dates.enabled = target.checked ? 1 : 0
            setDateAdjustments(tmp)
          }}
        />
      )
    return result
  }, [canImportAsNewQuizzes, canOverwriteAssessmentContent, canAdjustDates, dateAdjustments])

  return (
    <>
      {canSelectContent && (
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
              checked={selectiveImport === true}
            />
            <>
              {selectiveImport === false && canImportBPSettings ? (
                <View as="div" padding="0 medium">
                  <Checkbox
                    label={I18n.t('Import Blueprint Course settings')}
                    value="medium"
                    onChange={(e: React.SyntheticEvent<Element, Event>) => {
                      const target = e.target as HTMLInputElement
                      setImportBPSettings(target.checked)
                    }}
                  />
                </View>
              ) : null}
            </>
            <RadioInput
              name="selective_import"
              value="selective"
              label={I18n.t('Select specific content')}
              onChange={(e: React.SyntheticEvent<Element, Event>) => {
                const target = e.target as HTMLInputElement
                setSelectiveImport(target.checked)
              }}
              checked={selectiveImport === false}
            />
          </RadioInputGroup>
          {contentError && (
            <p>
              <Text color="danger">{I18n.t('You must choose a content option')}</Text>
            </p>
          )}
        </View>
      )}

      {options.length > 0 && (
        <View as="div" margin="medium none none none">
          <CheckboxGroup name={I18n.t('Options')} layout="stacked" description={I18n.t('Options')}>
            {options}
          </CheckboxGroup>
          {showAdjustDates ? (
            <DateAdjustments
              dateAdjustments={dateAdjustments}
              setDateAdjustments={setDateAdjustments}
            />
          ) : null}
        </View>
      )}

      <View as="div" margin="medium none none none">
        <Button onClick={onCancel}>{I18n.t('Cancel')}</Button>
        <Button
          disabled={!!(fileUploadProgress && fileUploadProgress < 100)}
          data-testid="submitMigration"
          onClick={handleSubmit}
          margin="small"
          color="primary"
        >
          {fileUploadProgress && fileUploadProgress < 100 ? (
            <>
              <Spinner size="x-small" renderTitle={I18n.t('Adding')} /> &nbsp;
              {I18n.t('Adding...')}
            </>
          ) : (
            <>
              <IconAddSolid /> &nbsp;
              {I18n.t('Add to Import Queue')}
            </>
          )}
        </Button>
      </View>
    </>
  )
}

export default CommonMigratorControls
