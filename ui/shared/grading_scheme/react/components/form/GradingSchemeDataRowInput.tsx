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
// @ts-expect-error -- TODO: remove once we're on InstUI 8
import {Tooltip} from '@instructure/ui-tooltip'

import {GradingSchemeDataRow} from '../../../gradingSchemeApiModel'
import {decimalToRoundedPercent} from '../../helpers/decimalToRoundedPercent'
import {roundToTwoDecimalPlaces} from '../../helpers/roundToTwoDecimalPlaces'

const I18n = useI18nScope('GradingSchemeManagement')

// Doing this to avoid TS2339 errors -- TODO: remove once we're on InstUI 8
const {Item} = Flex as any

interface ComponentProps {
  dataRow: GradingSchemeDataRow
  highRange: number
  isFirstRow: boolean
  isLastRow: boolean
  onRowLetterGradeChange: (letterGrade: string) => any
  onLowRangeChange: (lowRange: number) => any
  onLowRangeInputInvalidNumber: () => any
  onRowDeleteRequested: () => any
  onRowAddRequested: () => any
}

export const GradingSchemeDataRowInput = ({
  dataRow,
  highRange,
  isFirstRow,
  isLastRow,
  onLowRangeChange,
  onLowRangeInputInvalidNumber,
  onRowLetterGradeChange,
  onRowAddRequested,
  onRowDeleteRequested,
}: ComponentProps) => {
  const [lowRange, setLowRange] = useState<number>(dataRow.value)
  const [lowRangeInputBuffer, setLowRangeInputBuffer] = useState<string | undefined>(undefined)
  const [lowRangeInvalid, setLowRangeInvalid] = useState<boolean>(false)
  const [addButtonHovering, setAddButtonHovering] = useState<boolean>(false)

  // @ts-expect-error -- TODO: remove once we're on InstUI 8
  const triggerLetterGradeChange = event => {
    onRowLetterGradeChange(event.target.value)
  }

  const triggerRowLowRangeBlur = () => {
    if (!lowRangeInputBuffer) return

    const inputVal = numberHelper.parse(lowRangeInputBuffer)

    if (!Number.isNaN(Number(inputVal)) && inputVal >= 0 && inputVal <= 100) {
      setLowRangeInvalid(false)
      const lowRangeRounded = roundToTwoDecimalPlaces(Number(inputVal))
      setLowRangeInputBuffer(undefined)
      setLowRange(lowRangeRounded / 100)
      onLowRangeChange(lowRangeRounded / 100)
    } else {
      setLowRangeInvalid(true)
      onLowRangeInputInvalidNumber()
    }
  }

  // @ts-expect-error -- TODO: remove once we're on InstUI 8
  const triggerRowLowRangeChange = event => {
    const scoreInput = event.target.value
    setLowRangeInputBuffer(scoreInput)

    const inputVal = numberHelper.parse(scoreInput)
    if (!Number.isNaN(Number(inputVal)) && inputVal >= 0 && inputVal <= 100) {
      setLowRangeInvalid(false)
      onLowRangeChange(Number(inputVal) / 100)
    } else {
      setLowRangeInvalid(true)
      onLowRangeInputInvalidNumber()
    }
  }

  function renderLowRange() {
    return String(
      // TODO JS: I18n for numbers (decimals)?
      lowRangeInputBuffer !== undefined ? lowRangeInputBuffer : decimalToRoundedPercent(lowRange)
    )
  }

  const lowRangeValidationMessageState = lowRangeInvalid ? 'error' : 'hint'

  return (
    <>
      <tr>
        <td>
          <Tooltip renderTip={I18n.t('add a letter grade')}>
            <IconButton
              withBackground={false}
              withBorder={false}
              screenReaderLabel={I18n.t(
                'Add new row for a letter grade to grading scheme after this row'
              )}
              onClick={onRowAddRequested}
              elementRef={(buttonRef: HTMLButtonElement) => {
                if (!buttonRef) return
                buttonRef.onmouseover = () => setAddButtonHovering(true)
                buttonRef.onmouseout = () => setAddButtonHovering(false)
              }}
            >
              <IconPlusLine />
            </IconButton>
          </Tooltip>
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
        <td style={{width: '25%'}}>
          <span aria-label={I18n.t('Upper limit of range')}>
            {isFirstRow ? '' : '< '}
            {decimalToRoundedPercent(highRange)}%
          </span>
        </td>
        <td style={{width: '25%'}}>
          <Flex display="inline-flex">
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
                      onChange={triggerRowLowRangeChange}
                      onBlur={triggerRowLowRangeBlur}
                      value={renderLowRange()}
                      messages={[{text: <></>, type: lowRangeValidationMessageState}]}
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
                screenReaderLabel={I18n.t('Remove letter grade row')}
                onClick={onRowDeleteRequested}
              >
                <IconTrashLine />
              </IconButton>
            </Item>
          </Flex>
        </td>
      </tr>

      <tr>
        <td colSpan={5}>
          <div style={{height: '5px'}}>
            {addButtonHovering ? (
              <hr style={{margin: 0, border: 'none', borderTop: '1px dashed grey'}} />
            ) : (
              <></>
            )}
          </div>
        </td>
      </tr>
    </>
  )
}
