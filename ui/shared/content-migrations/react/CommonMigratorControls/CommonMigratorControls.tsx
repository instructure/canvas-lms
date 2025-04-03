/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {type ComponentType, useCallback, useEffect, useState} from 'react'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Spinner} from '@instructure/ui-spinner'
import {Checkbox, CheckboxGroup} from '@instructure/ui-checkbox'
import {canvas} from '@instructure/ui-themes'
import {Button} from '@instructure/ui-buttons'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {InfoButton} from './InfoButton'
import {DateAdjustments} from './DateAdjustments'
import type {onSubmitMigrationFormCallback, DateAdjustmentConfig} from './types'
import {Flex} from '@instructure/ui-flex'
import {Responsive} from '@instructure/ui-responsive'

const I18n = createI18nScope('content_migrations_redesign')

type CommonMigratorControlsProps = {
  canSelectContent?: boolean
  canImportAsNewQuizzes?: boolean
  canOverwriteAssessmentContent?: boolean
  canAdjustDates?: boolean
  canImportBPSettings?: boolean
  onSubmit: onSubmitMigrationFormCallback
  onCancel: () => void
  fileUploadProgress: number | null
  isSubmitting: boolean
  setIsQuestionBankDisabled?: (isDisabled: boolean) => void
  oldStartDate?: string | null
  oldEndDate?: string | null
  newStartDate?: string | null
  newEndDate?: string | null
  SubmitLabel: ComponentType
  SubmittingLabel: ComponentType
  CancelLabel: ComponentType
}
const nqCheckboxId = 'existing_quizzes_as_new_quizzes'
const overwriteAssesmentCheckboxId = 'overwrite_assessment_content'
const adjustDatesCheckboxId = 'adjust_dates[enabled]'

const generateNewQuizzesLabel = () => {
  const isConvertQuizzes = ENV.NEW_QUIZZES_UNATTACHED_BANK_MIGRATIONS

  const labelText = isConvertQuizzes
    ? I18n.t('Convert content to New Quizzes')
    : I18n.t('Import existing quizzes as New Quizzes')
  const headingText = isConvertQuizzes ? I18n.t('Convert Quizzes') : I18n.t('New Quizzes')
  const bodyText = isConvertQuizzes
    ? I18n.t(
        'Existing question banks and classic quizzes will be imported as Item Banks and New Quizzes.',
      )
    : I18n.t('New Quizzes is the new assessment engine for Canvas.')
  const helpText = I18n.t('To learn more, please contact your system administrator or visit ')
  const guideLink = I18n.t('#community.instructor_guide')
  const guideText = I18n.t('Canvas Instructor Guide')
  const buttonLabel = I18n.t('Import assessment as New Quizzes Help Icon')
  const modalLabel = I18n.t('Import assessment as New Quizzes Help Modal')

  return (
    <>
      <Text>{labelText}</Text>
      <span style={{position: 'absolute', marginTop: '-0.55em'}}>
        <InfoButton
          heading={headingText}
          body={
            <>
              <Text>{bodyText}</Text>
              <br />
              <Text>{helpText}</Text>
              <Link href={guideLink} target="_blank" rel="noopener noreferrer">
                {guideText}
              </Link>
              <Text>.</Text>
            </>
          }
          buttonLabel={buttonLabel}
          modalLabel={modalLabel}
        />
      </span>
    </>
  )
}

const generateOverwriteLabel = () => (
  <>
    <Text>{I18n.t('Overwrite assessment content with matching IDs')}</Text>

    <span style={{position: 'absolute', marginTop: '-0.55em'}}>
      <InfoButton
        heading={I18n.t('Overwrite')}
        body={
          <Text>
            {I18n.t(
              'Some systems recycle their IDs for each new export. As a result, if you export two separate question banks they will have the same IDs. To prevent losing assessment data we treat these objects as different despite the IDs. Choosing this option will disable this safety feature and allow assessment data to overwrite existing data with the same IDs.',
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
  isSubmitting,
  setIsQuestionBankDisabled,
  oldStartDate,
  oldEndDate,
  newStartDate,
  newEndDate,
  SubmitLabel,
  SubmittingLabel,
  CancelLabel,
}: CommonMigratorControlsProps) => {
  const [selectiveImport, setSelectiveImport] = useState<null | boolean>(false)
  const [importBPSettings, setImportBPSettings] = useState<null | boolean>(null)
  const [importAsNewQuizzes, setImportAsNewQuizzes] = useState<boolean>(
    !!ENV.NEW_QUIZZES_MIGRATION_DEFAULT,
  )
  const [overwriteAssessmentContent, setOverwriteAssessmentContent] = useState<boolean>(false)
  const [showAdjustDates, setShowAdjustDates] = useState<boolean>(false)
  const [dateAdjustmentConfig, setDateAdjustmentConfig] = useState<DateAdjustmentConfig>({
    adjust_dates: {
      enabled: false,
      operation: 'shift_dates',
    },
    date_shift_options: {
      old_start_date: oldStartDate || '',
      new_start_date: newStartDate || '',
      old_end_date: oldEndDate || '',
      new_end_date: newEndDate || '',
      day_substitutions: [],
    },
  })
  const [contentError, setContentError] = useState<boolean>(false)

  useEffect(() => {
    setDateAdjustmentConfig(prevState => ({
      ...prevState,
      date_shift_options: {
        ...prevState.date_shift_options,
        old_start_date: oldStartDate || '',
        new_start_date: newStartDate || '',
        old_end_date: oldEndDate || '',
        new_end_date: newEndDate || '',
      },
    }))
  }, [oldStartDate, newStartDate, oldEndDate, newEndDate])

  const onCanImportAsNewQuizzesChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const target = e.target as HTMLInputElement
      setImportAsNewQuizzes(target.checked)
      setIsQuestionBankDisabled?.(target.checked)
    },
    [setImportAsNewQuizzes, setIsQuestionBankDisabled],
  )

  const handleSubmit = useCallback(() => {
    const data: any = {settings: {}}
    setContentError(selectiveImport === null)
    data.errored = canSelectContent && selectiveImport === null // So the parent form can guard submit and show it's own errors
    canSelectContent && (data.selective_import = selectiveImport)
    canImportBPSettings && (data.settings.import_blueprint_settings = importBPSettings)
    if (canAdjustDates && dateAdjustmentConfig) {
      dateAdjustmentConfig.adjust_dates && (data.adjust_dates = dateAdjustmentConfig.adjust_dates)
      data.date_shift_options = dateAdjustmentConfig.date_shift_options
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
    dateAdjustmentConfig,
    canImportAsNewQuizzes,
    importAsNewQuizzes,
    canOverwriteAssessmentContent,
    overwriteAssessmentContent,
    onSubmit,
  ])

  const defaultChecks = []

  if (ENV.NEW_QUIZZES_MIGRATION_DEFAULT) {
    defaultChecks.push('existing_quizzes_as_new_quizzes')
  }

  const options = [
    ...(canImportAsNewQuizzes
      ? [
          <Checkbox
            key={nqCheckboxId}
            name={nqCheckboxId}
            value={nqCheckboxId}
            label={generateNewQuizzesLabel()}
            disabled={
              !ENV.QUIZZES_NEXT_ENABLED || ENV.NEW_QUIZZES_MIGRATION_REQUIRED || isSubmitting
            }
            onChange={onCanImportAsNewQuizzesChange}
          />,
        ]
      : []),
    ...(canOverwriteAssessmentContent
      ? [
          <Checkbox
            key={overwriteAssesmentCheckboxId}
            name={overwriteAssesmentCheckboxId}
            value={overwriteAssesmentCheckboxId}
            disabled={isSubmitting}
            label={generateOverwriteLabel()}
            onChange={e => setOverwriteAssessmentContent(e.target.checked)}
          />,
        ]
      : []),
    ...(canAdjustDates
      ? [
          <Checkbox
            key={adjustDatesCheckboxId}
            name={adjustDatesCheckboxId}
            value={adjustDatesCheckboxId}
            disabled={isSubmitting}
            label={I18n.t('Adjust events and due dates')}
            data-testid="date-adjust-checkbox"
            onChange={({target}) => {
              setShowAdjustDates(target.checked)
              const tmp = JSON.parse(JSON.stringify(dateAdjustmentConfig))
              tmp.adjust_dates.enabled = target.checked ? 1 : 0
              setDateAdjustmentConfig(tmp)
            }}
          />,
        ]
      : []),
  ]

  const allContentText = (
    <>
      <Text size="medium" color="primary">
        {I18n.t('All content')}
      </Text>
      <br />
      <View as="div" margin="x-small 0 0 0">
        <Text size="small" color="primary">
          {I18n.t(
            'Note the following content types will be imported: Course Settings, Syllabus Body, Modules, Assignments, Quizzes, Question Banks, Discussion Topics, Pages, Announcements, Rubrics, Files, and Calendar Events.',
          )}
        </Text>
      </View>
    </>
  )

  return (
    <>
      {canSelectContent && (
        <View as="div" margin="medium none none none" width="100%" maxWidth="46.5rem">
          <RadioInputGroup
            name="selective_import"
            description={I18n.t('Content')}
            defaultValue="non_selective"
            isRequired
            messages={
              contentError
                ? [{text: I18n.t('You must choose a content option'), type: 'newError'}]
                : []
            }
          >
            <RadioInput
              value="non_selective"
              label={allContentText}
              onChange={(e: React.SyntheticEvent<Element, Event>) => {
                const target = e.target as HTMLInputElement
                setSelectiveImport(!target.checked)
              }}
              checked={selectiveImport === true}
              disabled={isSubmitting}
            />
            <>
              {selectiveImport === false && canImportBPSettings ? (
                <View as="div" padding="0 medium">
                  <Checkbox
                    label={I18n.t('Import Blueprint Course settings')}
                    value="medium"
                    disabled={isSubmitting}
                    onChange={(e: React.SyntheticEvent<Element, Event>) => {
                      const target = e.target as HTMLInputElement
                      setImportBPSettings(target.checked)
                    }}
                  />
                </View>
              ) : null}
            </>
            <RadioInput
              value="selective"
              label={I18n.t('Select specific content')}
              onChange={(e: React.SyntheticEvent<Element, Event>) => {
                const target = e.target as HTMLInputElement
                setSelectiveImport(target.checked)
              }}
              checked={selectiveImport === false}
              disabled={isSubmitting}
            />
          </RadioInputGroup>
        </View>
      )}

      {options.length > 0 && (
        <View as="div" margin="medium none none none">
          <CheckboxGroup
            disabled={isSubmitting}
            name={I18n.t('Options')}
            layout="stacked"
            description={I18n.t('Options')}
            defaultValue={defaultChecks}
          >
            {options}
          </CheckboxGroup>
          {showAdjustDates ? (
            <DateAdjustments
              dateAdjustmentConfig={dateAdjustmentConfig}
              setDateAdjustments={setDateAdjustmentConfig}
              disabled={isSubmitting}
            />
          ) : null}
        </View>
      )}

      <View as="div" margin="medium none none none">
        <Responsive
          match="media"
          query={{
            small: {maxWidth: canvas.breakpoints.medium},
          }}
        >
          {(_props, matches) => {
            const isMobileView = matches?.includes('small') || false
            return (
              <Flex as="div" direction={isMobileView ? 'column' : 'row'}>
                <Button
                  disabled={isSubmitting}
                  data-testid="clear-migration-button"
                  onClick={onCancel}
                  color="secondary"
                  width={isMobileView ? '100%' : '8.5rem'}
                  margin={isMobileView ? 'none none small none' : 'none small none none'}
                  textAlign="center"
                >
                  <CancelLabel />
                </Button>
                <Button
                  disabled={isSubmitting}
                  data-testid="submitMigration"
                  onClick={handleSubmit}
                  color="primary"
                  width={isMobileView ? '100%' : '8.5rem'}
                  textAlign="center"
                >
                  {isSubmitting ? (
                    <>
                      <Spinner size="x-small" renderTitle={<SubmittingLabel />} /> &nbsp;
                      <SubmittingLabel />
                    </>
                  ) : (
                    <SubmitLabel />
                  )}
                </Button>
              </Flex>
            )
          }}
        </Responsive>
      </View>
    </>
  )
}

export default CommonMigratorControls
