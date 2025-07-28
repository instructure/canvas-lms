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

import React, {useState, useContext} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import WithBreakpoints from '@canvas/with-breakpoints'
import LoadingIndicator from '@canvas/loading-indicator'
import AlertManager, {AlertManagerContext} from '@canvas/alerts/react/AlertManager'

import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Modal} from '@instructure/ui-modal'
import {Alert} from '@instructure/ui-alerts'
import {Button, CloseButton} from '@instructure/ui-buttons'

import {migrateDiscussionDisallowThreadedReplies} from '../apiClient'

const I18n = createI18nScope('discussions_v2')

function UpdateButton({onUpdateComplete}) {
  const [modalOpen, setModalOpen] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)

  const closeModal = () => setModalOpen(false)

  const onUpdateAll = async () => {
    try {
      setIsLoading(true)
      await migrateDiscussionDisallowThreadedReplies({contextId: ENV.COURSE_ID})
      closeModal()
      setOnSuccess(I18n.t('All discussions have successfully been updated to threaded.'), false)
      onUpdateComplete()
    } catch (error) {
      setOnFailure(
        I18n.t(
          'We’ve run into a problem while updating all discussions. Please try again or contact us to resolve this issue.',
        ),
      )
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <>
      <Button
        onClick={() => setModalOpen(true)}
        color="primary"
        id="disallow_threaded_fix_alert_update_all"
        data-testid="disallow_threaded_fix_alert_update_all"
      >
        {I18n.t('Make All Discussions Threaded')}
      </Button>
      <Modal open={modalOpen} size="medium" label={I18n.t('Confirm update')}>
        <Modal.Header>
          <Flex justifyItems="space-between" alignItems="center">
            <Flex.Item shouldGrow={true} shouldShrink={true}>
              <Text size="x-large">{I18n.t('Make All Discussions Threaded')}</Text>
            </Flex.Item>
            <Flex.Item>
              <CloseButton onClick={closeModal} screenReaderLabel={I18n.t('Close')} />
            </Flex.Item>
          </Flex>
        </Modal.Header>
        <Modal.Body>
          {isLoading ? (
            <LoadingIndicator />
          ) : (
            <Flex direction="column" gap="large">
              <Text>
                {I18n.t(
                  "By selecting 'Make All Discussions Threaded,' you will update all non-threaded discussions in the course to threaded. This action will uncheck the 'Disallow Threaded Replies' option, enabling threaded replies for all discussions.",
                )}
              </Text>
              <Text>
                {I18n.t(
                  'This change is irreversible and will affect all discussions in your course.',
                )}
              </Text>
            </Flex>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Flex gap="small">
            <Button disabled={isLoading} onClick={closeModal}>
              {I18n.t('Cancel')}
            </Button>
            <Button disabled={isLoading} onClick={onUpdateAll} color="primary">
              {I18n.t('Make All Discussions Threaded')}
            </Button>
          </Flex>
        </Modal.Footer>
      </Modal>
    </>
  )
}

function DisallowThreadedFixAlertBase({breakpoints}) {
  const localStorageBaseKey = 'disallow_threaded_fix_alert_dismissed'
  const localStorageKey = `${localStorageBaseKey}_${ENV.COURSE_ID}`

  // We have 2 different states to preserve the fade out transition, shouldShow triggers the animation
  // and shouldMount removes the component from the DOM once the animation is done
  const [shouldMount, setShouldMount] = useState(
    () => localStorage.getItem(localStorageKey) !== 'true',
  )
  const [shouldShow, setShouldShow] = useState(
    () => localStorage.getItem(localStorageKey) !== 'true',
  )

  const onDismiss = () => {
    localStorage.setItem(localStorageKey, 'true')
    setShouldShow(false)
  }

  const onUpdateComplete = () => {
    setShouldShow(false)
  }

  const userCanModerate = ENV?.permissions?.moderate
  const hasSideComment = ENV?.HAS_SIDE_COMMENT_DISCUSSIONS
  const inCourseContext = ENV?.current_context?.type === 'Course'

  // Don't show anything if user has no permission OR
  // There are no side_comments in the course OR
  // We are in a group context
  if (!userCanModerate || !hasSideComment || !inCourseContext || !shouldMount) {
    return null
  }

  const linkHref =
    'https://community.canvaslms.com/t5/The-Product-Blog/Temporary-button-to-uncheck-the-Disallow-Threaded-Replies-option/ba-p/615349'
  const alertText = I18n.t(
    'Following the *recent issues* around disallowing threaded replies, we provide a quick and easy way to update all of your discussions to be threaded.',
    {
      wrappers: [`<a target="_blank" href="${linkHref}">$1</a>`],
    },
  )

  return (
    <Alert
      variant="warning"
      margin="mediumSmall 0"
      open={shouldShow}
      onDismiss={() => setShouldMount(false)}
    >
      <Flex gap="x-small" direction="column">
        <Text dangerouslySetInnerHTML={{__html: alertText}} />
        <Flex gap="small" direction={breakpoints.mobileOnly ? 'column' : 'row'}>
          {/* We cannot use reverse wrap because that messes up tab order, so we show one of the buttons on mobile and on the other above */}
          {breakpoints.mobileOnly && <UpdateButton onUpdateComplete={onUpdateComplete} />}
          <Button
            onClick={onDismiss}
            id="disallow_threaded_fix_alert_dismiss"
            data-testid="disallow_threaded_fix_alert_dismiss"
          >
            {I18n.t('Dismiss')}
          </Button>
          {!breakpoints.mobileOnly && <UpdateButton onUpdateComplete={onUpdateComplete} />}
        </Flex>
      </Flex>
    </Alert>
  )
}

const DisallowThreadedFixAlertWithBreakpoints = WithBreakpoints(DisallowThreadedFixAlertBase)

export default function DisallowThreadedFixAlert() {
  return (
    <AlertManager>
      <DisallowThreadedFixAlertWithBreakpoints />
    </AlertManager>
  )
}
