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

import React, { useCallback, useEffect, useRef, useState } from 'react'
import { connect } from 'react-redux'
import { useScope as createI18nScope } from '@canvas/i18n'
import { Alert } from '@instructure/ui-alerts'
import { Tray } from '@instructure/ui-tray'
import { View } from '@instructure/ui-view'
import { Flex } from '@instructure/ui-flex'
import { Button, CloseButton } from '@instructure/ui-buttons'
import { Text } from '@instructure/ui-text'
import { Heading } from '@instructure/ui-heading'
import { IconAssignmentLine, IconQuizLine, IconDiscussionLine, IconDocumentLine } from '@instructure/ui-icons'
import { NumberInput } from '@instructure/ui-number-input'
import { Link } from '@instructure/ui-link'
import { getCoursePace, getCoursePaceItems } from '../../../reducers/course_paces'
import { actions } from '../../../actions/course_pace_items'
import { CoursePace, StoreState, CoursePaceItem, AssignmentWeightening } from '../../../types'
import { coursePaceActions } from '../../../actions/course_paces'
import { calculatePaceItemDuration, isTimeToCompleteCalendarDaysValid } from '../../../utils/utils'
import { BlackoutDate } from '../../../shared/types'
import { getBlackoutDates } from '../../../shared/reducers/blackout_dates'
import { actions as uiActions } from '../../../actions/ui'
import { getShowWeightedAssignmentsTray } from '../../../reducers/ui'
import {Focusable} from '@instructure/ui-focusable'

const I18n = createI18nScope('course_paces_settings')

interface DurationSetElementProps {
  readonly label: string
  readonly durationIcon: React.ReactNode
  readonly item: keyof AssignmentWeightening
}

interface StoreProps {
  readonly coursePace: CoursePace
  readonly coursePaceItems: CoursePaceItem[]
  readonly blackoutDates: BlackoutDate[]
  readonly opened: boolean
}

interface DispatchProps {
  readonly setWeightedAssignments: typeof coursePaceActions.setWeightedAssignments
  readonly setPaceItemWeightedDuration: typeof coursePaceActions.setPaceItemWeightedDuration
  readonly onDismiss: typeof uiActions.hideWeightedAssignmentsTray
}

export interface AlertMessage {
  readonly message: string
  readonly type: 'error' | 'warning'
}

type WeightedAssignmentsTrayProps = StoreProps & DispatchProps

const WeightedAssignmentsTray = (props: WeightedAssignmentsTrayProps) => {
  const {
    opened,
    coursePace,
    onDismiss,
    setWeightedAssignments: setWeightedAssignmentsCoursePace,
    coursePaceItems,
    setPaceItemWeightedDuration,
    blackoutDates,
  } = props

  const alertContainer = useRef<HTMLDivElement | null>(null)
  const [weightedAssignments, setWeightedAssignments] = useState<AssignmentWeightening>(coursePace.assignments_weighting)
  const [validationMessage, setValidationMessage] = useState<AlertMessage | undefined>(undefined)

  useEffect(() => {
    const weightedPaceItems = calculatePaceItemDuration(coursePaceItems, weightedAssignments)
    const weightedAssignmentsValid = isTimeToCompleteCalendarDaysValid(coursePace, weightedPaceItems, blackoutDates)

    setValidationMessage(undefined)

    if (!weightedAssignmentsValid) {
      setValidationMessage({
        message: 'The current assignment durations will cause the pace to exceed its set duration.',
        type: 'error'
      })
    }
  }, [weightedAssignments, blackoutDates, coursePace, coursePaceItems])

  const onApply = useCallback(() => {
    if (validationMessage !== undefined) {
      alertContainer.current?.focus()
      return
    }

    if (Object.values(weightedAssignments).every(duration => duration === undefined)) {
      setValidationMessage({
        message: 'To apply any changes one of the following durations must be changed.',
        type: 'error'
      })
      return
    }

    onDismiss()

    setPaceItemWeightedDuration(weightedAssignments, blackoutDates)
    setWeightedAssignmentsCoursePace(weightedAssignments)
  }, [weightedAssignments, validationMessage, onDismiss, setPaceItemWeightedDuration, setWeightedAssignmentsCoursePace])

  const DurationSetElement = ({ label, durationIcon, item }: DurationSetElementProps) => {
    const duration = weightedAssignments[item]
    const resetInteraction = duration !== undefined ? "enabled" : "disabled"

    const onIncrement = () => {
      const newDuration = duration === undefined ? 1 : duration + 1
      setWeightedAssignments({
        ...weightedAssignments,
        [item]: newDuration
      })
    }

    const onDecrement = () => {
      const newDuration = duration === 0 || duration === undefined ? undefined : duration - 1
      setWeightedAssignments({
        ...weightedAssignments,
        [item]: newDuration
      })
    }

    const onReset = () => {
      setWeightedAssignments({
        ...weightedAssignments,
        [item]: undefined
      })
    }

    return (
      <View as="div" margin="medium 0 0 0">
        <Flex as="div" direction="column">
          <Flex.Item>
            <Flex direction="row" gap="xxx-small">
              <Flex.Item align="start">
                {durationIcon}
              </Flex.Item>
              <Flex.Item>
                <Text>
                  <Heading
                    themeOverride={{ h1FontWeight: 700, lineHeight: 1.75, h1FontSize: '1rem' }}
                    level="h1"
                  >
                    {label}
                  </Heading>
                </Text>
              </Flex.Item>
            </Flex>
          </Flex.Item>

          <Flex.Item>
            <Flex direction="row" padding="x-small 0">
              <Flex.Item margin="0 xxx-small 0 0" padding="none none none xx-small">
                <span data-testid={`duration-${item}`}>
                  <NumberInput
                    renderLabel=""
                    display={'inline-block'}
                    width="14.063rem"
                    onIncrement={onIncrement}
                    onDecrement={onDecrement}
                    value={duration}
                    placeholder={I18n.t('Set Duration')}
                    showArrows={true}
                    allowStringValue={true}
                  />
                </span>
              </Flex.Item>
              <Flex.Item>
                <View margin="none none none xxx-small">
                  <Text>Days</Text>
                </View>
              </Flex.Item>
            </Flex>
          </Flex.Item>

          <Flex.Item padding="xx-small">
            <Link as="button" onClick={onReset} isWithinText={false} interaction={resetInteraction}>
              <Text>Reset</Text>
            </Link>
          </Flex.Item>
        </Flex>
      </View>
    )
  }

  const FormContainer = ({ children }: { children: React.ReactNode }) => {
    return (
      <View as="div" margin="medium">
        {children}
      </View>
    )
  }

  const validationAlert = validationMessage ? (
    <Focusable>
      {({ focused }: { focused: boolean }) => (
        <View
          withFocusOutline={focused}
          focusPosition="inset"
          position="relative"
          as="div"
          role="button"
          tabIndex={0}
          background="primary"
          display="block"
          width="100%"
          borderWidth="0 0 small 0"
          padding="xxx-small"
          elementRef={e => {
            if (e instanceof HTMLDivElement) {
              alertContainer.current = e
            }
          }}
          data-testid="validation-message"
        >
          <Alert variant={validationMessage.type} margin="xx-small" open={true} >
            <Text>{validationMessage.message}</Text>
          </Alert>
        </View>
      )}
    </Focusable>
  ) : null

  return (
    <Tray
      label={I18n.t('Weighted Assignments')}
      open={opened}
      placement="end"
      size="small"
      themeOverride={{ smallWidth: '21.175rem' }}
      data-testid="weighted-assignments-tray"
    >
      <View as="div">
        <FormContainer>
          <Flex as="div">
            <Flex.Item width="13.813rem" margin="0 small 0 0">
              <Heading
                themeOverride={{ h1FontWeight: 700, lineHeight: 1.75, h1FontSize: '1.375rem' }}
                level="h1"
              >
                {I18n.t('Weighted Assignment Duration')}
              </Heading>
            </Flex.Item>
            <Flex.Item align="start">
              <CloseButton onClick={onDismiss} screenReaderLabel={I18n.t('Close')} size="medium" />
            </Flex.Item>
          </Flex>
          <View as="div" margin="medium 0 medium 0">
            <Text>Set the weight of assignment types automatically when configuring pacing.</Text>
          </View>
        </FormContainer>

        {validationAlert}

        <FormContainer>
          <DurationSetElement
            label={I18n.t('Assignment Duration')}
            durationIcon={<IconAssignmentLine size="x-small" />}
            item="assignment"
          />
          <DurationSetElement
            label={I18n.t('Quiz Duration')}
            durationIcon={<IconQuizLine size="x-small" />}
            item="quiz"
          />
          <DurationSetElement
            label={I18n.t('Discussion Duration')}
            durationIcon={<IconDiscussionLine size="x-small" />}
            item="discussion"
          />
          <DurationSetElement
            label={I18n.t('Page Duration')}
            durationIcon={<IconDocumentLine size="x-small" />}
            item="page"
          />
        </FormContainer>
        <View as="div" margin="medium 0 0 0" insetBlockEnd="1rem" insetInlineEnd="2rem" position="absolute">
          <Flex gap="small">
            <Button type="button" color="secondary" onClick={onDismiss}>
              {I18n.t('Cancel')}
            </Button>
            <Button type="button" color="primary" onClick={onApply} data-testid="weighted-assignments-apply-button">
              {I18n.t('Apply')}
            </Button>
          </Flex>
        </View>
      </View>
    </Tray>
  )
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    coursePace: getCoursePace(state),
    coursePaceItems: getCoursePaceItems(state),
    blackoutDates: getBlackoutDates(state),
    opened: getShowWeightedAssignmentsTray(state),
  }
}

export default connect(mapStateToProps, {
  setWeightedAssignments: coursePaceActions.setWeightedAssignments,
  setPaceItemWeightedDuration: coursePaceActions.setPaceItemWeightedDuration,
  onDismiss: uiActions.hideWeightedAssignmentsTray,
})(WeightedAssignmentsTray)
