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

import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {IconAiColoredSolid, IconAiSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {SimpleSelect, SimpleSelectOption} from '@instructure/ui-simple-select'
import {Checkbox} from '@instructure/ui-checkbox'
import {Button} from '@instructure/ui-buttons'
import {useState} from 'react'
import {TextInput} from '@instructure/ui-text-input'
import {TextArea} from '@instructure/ui-text-area'
import type {GenerateCriteriaFormProps} from '../../types/RubricForm'

const I18n = createI18nScope('rubrics-form-generated-criteria')

export const defaultGenerateCriteriaForm: GenerateCriteriaFormProps = {
  criteriaCount: 5,
  ratingCount: 4,
  pointsPerCriterion: '20',
  useRange: false,
  additionalPromptInfo: '',
  gradeLevel: 'higher-ed',
  standard: '',
}

const gradeLevels = {
  ['higher-ed']: I18n.t('Higher Education'),
  twelfth: I18n.t('12th Grade'),
  eleventh: I18n.t('11th Grade'),
  tenth: I18n.t('10th Grade'),
  ninth: I18n.t('9th Grade'),
  eighth: I18n.t('8th Grade'),
  seventh: I18n.t('7th Grade'),
  sixth: I18n.t('6th Grade'),
  fifth: I18n.t('5th Grade'),
  fourth: I18n.t('4th Grade'),
  third: I18n.t('3rd Grade'),
  second: I18n.t('2nd Grade'),
  first: I18n.t('1st Grade'),
  kindergarten: I18n.t('Kindergarten'),
}

type GeneratedCriteriaFormProps = {
  criterionUseRangeEnabled: boolean
  criteriaBeingGenerated: boolean
  generateCriteriaMutation: () => void
  onFormOptionsChange?: (options: GenerateCriteriaFormProps) => void
}
export const GeneratedCriteriaForm = ({
  criterionUseRangeEnabled,
  criteriaBeingGenerated,
  generateCriteriaMutation,
  onFormOptionsChange,
}: GeneratedCriteriaFormProps) => {
  const [generateCriteriaForm, setGenerateCriteriaForm] = useState<GenerateCriteriaFormProps>(
    defaultGenerateCriteriaForm,
  )

  const updateGenerateCriteriaForm = (newForm: GenerateCriteriaFormProps) => {
    setGenerateCriteriaForm(newForm)
    onFormOptionsChange?.(newForm)
  }

  const handleGenerateButton = () => {
    const points = parseFloat(generateCriteriaForm.pointsPerCriterion)
    if (isNaN(points) || points < 0) {
      showFlashError(I18n.t('Points per criterion must be a valid number'))()
      return
    }
    generateCriteriaMutation()
  }

  return (
    <View
      as="div"
      margin="medium 0 small 0"
      padding="small"
      borderRadius="medium"
      background="secondary"
      data-testid="generate-criteria-form"
    >
      <Heading level="h4">
        <Flex alignItems="center" gap="small">
          <IconAiColoredSolid />
          <Text>{I18n.t('Auto-Generate Criteria')}</Text>
        </Flex>
      </Heading>
      <Flex alignItems="end" gap="medium" margin="medium 0 0">
        <Flex.Item shouldShrink={true}>
          <SimpleSelect
            data-testid="grade-level-input"
            renderLabel={I18n.t('Grade Level')}
            value={generateCriteriaForm.gradeLevel}
            onChange={(_event, {value}) => {
              if (value) {
                updateGenerateCriteriaForm({
                  ...generateCriteriaForm,
                  gradeLevel: value.toString(),
                })
              }
            }}
          >
            {Object.entries(gradeLevels).map(([key, value]) => {
              return (
                <SimpleSelectOption key={key} id={`criteria-count-${key}`} value={key}>
                  {value}
                </SimpleSelectOption>
              )
            })}
          </SimpleSelect>
        </Flex.Item>
        <Flex.Item shouldShrink={true}>
          <SimpleSelect
            data-testid="criteria-count-input"
            renderLabel={I18n.t('Number of Criteria')}
            value={generateCriteriaForm.criteriaCount.toString()}
            onChange={(_event, {value}) =>
              updateGenerateCriteriaForm({
                ...generateCriteriaForm,
                criteriaCount: value ? parseInt(value.toString(), 10) : 0,
              })
            }
          >
            {[2, 3, 4, 5, 6, 7, 8].map(num => {
              const value = num.toString()
              return (
                <SimpleSelectOption key={value} id={`criteria-count-${value}`} value={value}>
                  {value}
                </SimpleSelectOption>
              )
            })}
          </SimpleSelect>
        </Flex.Item>
        <Flex.Item shouldShrink={true}>
          <SimpleSelect
            data-testid="rating-count-input"
            renderLabel={I18n.t('Number of Ratings')}
            value={generateCriteriaForm.ratingCount.toString()}
            onChange={(_event, {value}) =>
              updateGenerateCriteriaForm({
                ...generateCriteriaForm,
                ratingCount: value ? parseInt(value.toString(), 10) : 0,
              })
            }
          >
            {[2, 3, 4, 5, 6, 7, 8].map(num => {
              const value = num.toString()
              return (
                <SimpleSelectOption key={value} id={`rating-count-${value}`} value={value}>
                  {value}
                </SimpleSelectOption>
              )
            })}
          </SimpleSelect>
        </Flex.Item>
        <Flex.Item shouldShrink={true}>
          <TextInput
            data-testid="points-per-criterion-input"
            renderLabel={I18n.t('Points per Criterion')}
            value={generateCriteriaForm.pointsPerCriterion}
            onChange={(_event, value) =>
              updateGenerateCriteriaForm({
                ...generateCriteriaForm,
                pointsPerCriterion: value,
              })
            }
            type="text"
          />
        </Flex.Item>
        {criterionUseRangeEnabled && (
          <Flex.Item padding="0 0 x-small 0">
            <Checkbox
              data-testid="use-range-input"
              label={I18n.t('Enable Range')}
              checked={generateCriteriaForm.useRange}
              onChange={_event =>
                updateGenerateCriteriaForm({
                  ...generateCriteriaForm,
                  useRange: !generateCriteriaForm.useRange,
                })
              }
            />
          </Flex.Item>
        )}
        <Flex.Item shouldGrow={true}></Flex.Item>
      </Flex>
      <Flex alignItems="end" gap="medium" margin="medium 0 0">
        <Flex.Item shouldGrow={true} overflowX="visible" overflowY="visible">
          <Flex direction="column" gap="medium">
            <Flex.Item overflowX="visible" overflowY="visible">
              <TextArea
                data-testid="standard-objective-input"
                label={I18n.t('Standard / Outcome Information')}
                placeholder={I18n.t(
                  'Optional. Place standard or outcome here. For example, "Students will analyze primary sources".',
                )}
                value={generateCriteriaForm.standard}
                onChange={event =>
                  updateGenerateCriteriaForm({
                    ...generateCriteriaForm,
                    standard: event.target.value,
                  })
                }
                messages={
                  generateCriteriaForm.standard.length > 1000
                    ? [
                        {
                          text: I18n.t(
                            'Standard and Outcome information must be less than 1000 characters',
                          ),
                          type: 'error',
                        },
                      ]
                    : undefined
                }
                height="4rem"
              />
            </Flex.Item>
            <Flex.Item overflowX="visible" overflowY="visible">
              <TextArea
                data-testid="additional-prompt-info-input"
                label={I18n.t('Additional Prompt Information')}
                placeholder={I18n.t(
                  'Optional. For example, "Target a college-level seminar." or "Focus on argument substance." or "Be lenient."',
                )}
                value={generateCriteriaForm.additionalPromptInfo}
                onChange={event =>
                  updateGenerateCriteriaForm({
                    ...generateCriteriaForm,
                    additionalPromptInfo: event.target.value,
                  })
                }
                messages={
                  generateCriteriaForm.additionalPromptInfo.length > 1000
                    ? [
                        {
                          text: I18n.t(
                            'Additional prompt information must be less than 1000 characters',
                          ),
                          type: 'error',
                        },
                      ]
                    : undefined
                }
                height="4rem"
              />
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item>
          <Button
            onClick={handleGenerateButton}
            data-testid="generate-criteria-button"
            color="ai-primary"
            renderIcon={<IconAiSolid />}
            disabled={
              generateCriteriaForm.additionalPromptInfo.length > 1000 ||
              generateCriteriaForm.standard.length > 1000 ||
              criteriaBeingGenerated
            }
          >
            {I18n.t('Generate Criteria')}
          </Button>
        </Flex.Item>
      </Flex>
    </View>
  )
}
