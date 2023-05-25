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

import React, {useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'
import numberHelper from '@canvas/i18n/numberHelper'
// @ts-expect-error -- TODO: remove once we're on InstUI 8
import {IconPlusLine, IconTrashLine} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {GradingSchemeDataRow} from '../../../gradingSchemeApiModel'

import {decimalToRoundedPercent} from '../../helpers/decimalToRoundedPercent'
import {roundToTwoDecimalPlaces} from '../../helpers/roundToTwoDecimalPlaces'

const I18n = useI18nScope('GradingSchemeManagement')

// Doing this to avoid TS2339 errors -- TODO: remove once we're on InstUI 8
const {Item} = Flex as any

interface ComponentProps {
  dataRow: GradingSchemeDataRow
  maxScore: number
  isFirstRow: boolean
  isLastRow: boolean
  onRowLetterGradeChange: (letterGrade: string) => any
  onRowMinScoreChange: (minScore: number) => any
  onRowDeleteRequested: () => any
  onRowAddRequested: () => any
}

export const GradingSchemeDataRowInput: React.FC<ComponentProps> = ({
  dataRow,
  maxScore,
  isFirstRow,
  isLastRow,
  onRowMinScoreChange,
  onRowLetterGradeChange,
  onRowAddRequested,
  onRowDeleteRequested,
}) => {
  const [minScore, setMinScore] = useState<number>(dataRow.value)
  const [minScoreInputBuffer, setMinScoreInputBuffer] = useState<string | undefined>(undefined)
  const [minScoreInvalid, setMinScoreInvalid] = useState<boolean>(false)
  // @ts-expect-error -- TODO: remove once we're on InstUI 8
  const triggerLetterGradeChange = event => {
    onRowLetterGradeChange(event.target.value)
  }

  const triggerRowMinScoreBlur = () => {
    if (!minScoreInputBuffer) return

    const inputVal = numberHelper.parse(minScoreInputBuffer)

    if (!Number.isNaN(Number(inputVal)) && inputVal >= 0 && inputVal <= 100) {
      setMinScoreInvalid(false)
      const minScoreRounded = roundToTwoDecimalPlaces(Number(inputVal))
      setMinScoreInputBuffer(undefined)
      setMinScore(minScoreRounded / 100)
      onRowMinScoreChange(minScoreRounded / 100)
    } else {
      setMinScoreInvalid(true)
    }
  }

  // @ts-expect-error -- TODO: remove once we're on InstUI 8
  const triggerRowMinScoreChange = event => {
    const scoreInput = event.target.value
    setMinScoreInputBuffer(scoreInput)

    const inputVal = numberHelper.parse(scoreInput)
    if (!Number.isNaN(Number(inputVal)) && inputVal >= 0 && inputVal <= 100) {
      setMinScoreInvalid(false)
      onRowMinScoreChange(Number(inputVal) / 100)
    } else {
      setMinScoreInvalid(true)
    }
  }

  function renderMinScore() {
    return String(
      // TODO JS: I18n for numbers (decimals)?
      minScoreInputBuffer !== undefined ? minScoreInputBuffer : decimalToRoundedPercent(minScore)
    )
  }

  const minScoreValidationMessageState = minScoreInvalid ? 'error' : 'hint'

  return (
    <>
      <tr>
        <td>
          {' '}
          <IconButton
            withBackground={false}
            withBorder={false}
            screenReaderLabel={I18n.t('Add new row to grading scheme after this row')}
            onClick={onRowAddRequested}
          >
            <IconPlusLine />
          </IconButton>
        </td>
        <td>
          <TextInput
            isRequired={true}
            renderLabel={<ScreenReaderContent>{I18n.t('Letter Grade')}</ScreenReaderContent>}
            display="inline-block"
            width="6rem"
            onChange={triggerLetterGradeChange}
            defaultValue={dataRow.name}
            messages={[{text: <></>, type: 'hint'}]}
          />
        </td>
        <td>
          <Flex display="inline-flex">
            <Item>
              <span aria-label={I18n.t('Upper limit of range')}>
                {isFirstRow ? '' : '< '}
                {decimalToRoundedPercent(maxScore)}%
              </span>
            </Item>
            <Item padding="x-small">{I18n.t('to')}</Item>
            <Item>
              <span aria-label={I18n.t('Lower limit of range')}>
                {isLastRow ? (
                  <>0%</>
                ) : (
                  <>
                    <TextInput
                      isRequired={true}
                      renderLabel={
                        <ScreenReaderContent>{I18n.t('Lower limit of range')}</ScreenReaderContent>
                      }
                      display="inline-block"
                      width="4.5rem"
                      htmlSize={3}
                      onChange={triggerRowMinScoreChange}
                      onBlur={triggerRowMinScoreBlur}
                      value={renderMinScore()}
                      messages={[{text: <></>, type: minScoreValidationMessageState}]}
                    />
                    %
                  </>
                )}
              </span>
            </Item>
          </Flex>
        </td>
        <td>
          <Flex justifyItems="end">
            <Item>
              <IconButton
                withBackground={false}
                withBorder={false}
                screenReaderLabel={I18n.t('Delete row')}
                onClick={onRowDeleteRequested}
              >
                <IconTrashLine />
              </IconButton>
            </Item>
          </Flex>
        </td>
      </tr>
    </>
  )
}
