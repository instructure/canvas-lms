/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useMemo, useEffect} from 'react'
import PropTypes from 'prop-types'
import {ComposeInputWrapper} from '../../components/ComposeInputWrapper/ComposeInputWrapper'
import CourseSelect from '../../components/CourseSelect/CourseSelect'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IndividualMessageCheckbox} from '../../components/IndividualMessageCheckbox/IndividualMessageCheckbox'
import {Button} from '@instructure/ui-buttons'
import {reduceDuplicateCourses} from '../../../util/courses_helper'
import {SubjectInput} from '../../components/SubjectInput/SubjectInput'
import {Flex} from '@instructure/ui-flex'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {AddressBookContainer} from '../AddressBookContainer/AddressBookContainer'
import {Spinner} from '@instructure/ui-spinner'
import {Alert} from '@instructure/ui-alerts'

const I18n = createI18nScope('conversations_2')

const HeaderInputs = props => {
  let moreCourses
  if (!props.isReply && !props.isForward) {
    moreCourses = reduceDuplicateCourses(
      props.courses.enrollments,
      props.courses.favoriteCoursesConnection.nodes,
    )
  }

  const [modalContextCourseFilter, setModalContextCourseFilter] = React.useState(
    props.activeCourseFilter,
  )

  const isAllInDifferentiationTagSelected = useMemo(() => {
    return props.selectedRecipients?.some(
      recipient =>
        recipient.name?.startsWith('All in') && recipient.id?.includes('differentiation_tag'),
    )
  }, [props.selectedRecipients])

  useEffect(() => {
    if (isAllInDifferentiationTagSelected && !props.sendIndividualMessages) {
      props.onSendIndividualMessagesChange(true)
    }
  }, [
    isAllInDifferentiationTagSelected,
    props.sendIndividualMessages,
    props.onSendIndividualMessagesChange,
  ])

  const canIncludeObservers = useMemo(() => {
    if (ENV?.CONVERSATIONS?.CAN_MESSAGE_ACCOUNT_CONTEXT) {
      return true
    }
    const currentCourseAssetId = props?.activeCourseFilter?.contextID
    if (!currentCourseAssetId) {
      return false
    }

    const enrollmentsThatCanIncludeObservers = ['TeacherEnrollment', 'TaEnrollment']
    return props?.courses?.enrollments.some(
      enrollment =>
        enrollment?.course.assetString === currentCourseAssetId &&
        enrollmentsThatCanIncludeObservers.includes(enrollment.type),
    )
  }, [props.activeCourseFilter, props.courses])

  const onContextSelect = context => {
    if (context.contextID === null && context.contextName === null) {
      props.onSelectedIdsChange([])
    }
    setModalContextCourseFilter(context)
    props.onContextSelect(context)
  }

  const invalidRecipient = !!props.addressBookMessages?.length

  return (
    <Flex direction="column" width="100%" height="100%" padding="small">
      <Flex.Item>
        <ComposeInputWrapper
          title={
            <PresentationContent>
              <Text>{I18n.t('Course')}</Text>
            </PresentationContent>
          }
          input={
            props.isReply || props.isForward ? (
              <Text>{props.contextName}</Text>
            ) : (
              <CourseSelect
                mainPage={false}
                options={{
                  favoriteCourses: props.courses?.favoriteCoursesConnection.nodes,
                  moreCourses,
                  concludedCourses: [],
                  groups: props.courses?.favoriteGroupsConnection.nodes,
                }}
                onCourseFilterSelect={onContextSelect}
                activeCourseFilterID={modalContextCourseFilter?.contextID}
                courseMessages={props.courseMessages}
              />
            )
          }
        />
      </Flex.Item>
      {!props.isReply && !props.isForward && (
        <Flex.Item padding="none none small none">
          <ComposeInputWrapper
            shouldGrow={true}
            input={
              <IndividualMessageCheckbox
                onChange={
                  isAllInDifferentiationTagSelected || props.maxGroupRecipientsMet
                    ? () => {}
                    : props.onSendIndividualMessagesChange
                }
                checked={props.sendIndividualMessages}
                checkedAndDisabled={
                  isAllInDifferentiationTagSelected || props.maxGroupRecipientsMet
                }
              />
            }
          />
        </Flex.Item>
      )}
      {(!props.isReply || (props.isReply && !props?.isPrivateConversation)) && (
        <Flex.Item>
          <ComposeInputWrapper
            title={
              <PresentationContent>
                <Text id="address-book-form">{I18n.t('To')}</Text>
                <Text color={invalidRecipient ? 'danger' : 'primary'}>{' *'}</Text>
              </PresentationContent>
            }
            input={
              <AddressBookContainer
                includeCommonCourses={true}
                width="100%"
                open={props.addressBookContainerOpen}
                onSelectedIdsChange={ids => {
                  props.onSelectedIdsChange(ids)
                }}
                onInputValueChange={props.onAddressBookInputValueChange}
                activeCourseFilter={modalContextCourseFilter}
                hasSelectAllFilterOption={true}
                selectedRecipients={props.selectedRecipients}
                addressBookMessages={props.addressBookMessages}
                courseContextCode={props.selectedContext?.contextID || ''}
                placeholder={I18n.t('Insert or Select Names')}
                addressBookLabel={I18n.t('To')}
                renderingContext="compose-modal-header"
              />
            }
            shouldGrow={true}
          />
        </Flex.Item>
      )}
      {canIncludeObservers && props?.activeCourseFilter?.contextID && (
        <Flex.Item>
          <Button
            disabled={props.areObserversLoading}
            color="secondary"
            margin="xx-small"
            onClick={() => {
              props.getRecipientsObserver()
            }}
            data-testid="include-observer-button"
          >
            {I18n.t('Include Observers')}
            {props.areObserversLoading && (
              <div style={{display: 'inline-block', margin: '-0.5rem none'}}>
                <Spinner
                  renderTitle={I18n.t('Getting recipients observers')}
                  size="x-small"
                  margin="none none none x-small"
                  delay={300}
                />
              </div>
            )}
          </Button>
        </Flex.Item>
      )}
      {props.includeObserversMessages && (
        <Flex.Item>
          <Alert
            margin="x-small x-small small x-small"
            variant={props.includeObserversMessages?.type}
            onDismiss={() => {
              props.setIncludeObserversMessages(null)
            }}
            renderCloseButtonLabel="Close"
            hasShadow={false}
          >
            {props.includeObserversMessages?.text}
          </Alert>
        </Flex.Item>
      )}
      {props.isReply || props.isForward ? (
        <ComposeInputWrapper
          title={
            <PresentationContent>
              <Text>{I18n.t('Subject')}</Text>
            </PresentationContent>
          }
          input={<Text>{props.subject}</Text>}
        />
      ) : (
        <SubjectInput onChange={props.onSubjectChange} value={props.subject} />
      )}
    </Flex>
  )
}

HeaderInputs.propTypes = {
  contextName: PropTypes.string,
  courses: PropTypes.object,
  isReply: PropTypes.bool,
  isForward: PropTypes.bool,
  onContextSelect: PropTypes.func,
  onSelectedIdsChange: PropTypes.func,
  onSendIndividualMessagesChange: PropTypes.func,
  onSubjectChange: PropTypes.func,
  onAddressBookInputValueChange: PropTypes.func,
  sendIndividualMessages: PropTypes.bool,
  subject: PropTypes.string,
  activeCourseFilter: PropTypes.object,
  selectedRecipients: PropTypes.array,
  maxGroupRecipientsMet: PropTypes.bool,
  /**
   * Bool to control open/closed state of the AddressBookContainer menu for testing
   */
  addressBookContainerOpen: PropTypes.bool,
  addressBookMessages: PropTypes.array,
  courseMessages: PropTypes.array,
  isPrivateConversation: PropTypes.bool,
  selectedContext: PropTypes.object,
  getRecipientsObserver: PropTypes.func,
  areObserversLoading: PropTypes.bool,
  includeObserversMessages: PropTypes.object,
  setIncludeObserversMessages: PropTypes.func,
}

export default HeaderInputs
