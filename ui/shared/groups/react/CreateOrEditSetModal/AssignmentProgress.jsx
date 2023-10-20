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

import React, {useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {ProgressCircle} from '@instructure/ui-progress'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {func, string} from 'prop-types'

const I18n = useI18nScope('groups')
const pctFormat = new Intl.NumberFormat(ENV.LOCALE || navigator.language, {style: 'percent'}).format

const POLLING_INTERVAL = 1000

export const AssignmentProgress = ({url, onCompletion, apiCall}) => {
  const [progressPercent, setProgressPercent] = useState(0)

  function startPolling() {
    let timerId
    let progressURL = url

    // Keep polling the state of the Progress and updating the UI until it is no longer
    // running. Then fetch the new state of the Group Set and make the callback with that.
    // Then the main component will be back where it started, with the state of the newly-
    // created Group Set.
    async function poll() {
      timerId = undefined
      try {
        const {json} = await apiCall({path: progressURL})
        setProgressPercent(json.completion)
        if (['queued', 'running'].includes(json.workflow_state)) {
          progressURL = json.url
          timerId = setTimeout(poll, POLLING_INTERVAL)
          return
        }
        onCompletion(json.context_id)
      } catch (e) {
        showFlashError(
          I18n.t(
            "Couldn't track assigning students to groups, but it's still happening! Check the result manually later. (%{errorMessage})",
            {errorMessage: e.message}
          )
        )()
        onCompletion(null)
      }
    }

    poll()

    return () => {
      if (timerId) clearTimeout(timerId)
      timerId = undefined
    }
  }

  useEffect(startPolling, [])

  return (
    <Flex justifyItems="center">
      <Flex.Item>
        <Flex as="div" direction="column" textAlign="center">
          <Flex.Item margin="medium 0">
            <ProgressCircle
              screenReaderLabel={I18n.t('Percent complete')}
              size="large"
              valueNow={progressPercent}
              renderValue={v => {
                return <Text size="large">{pctFormat(v.valueNow / v.valueMax)}</Text>
              }}
              shouldAnimateOnMount={true}
            />
          </Flex.Item>
          <Flex.Item>
            <Text size="x-large">{I18n.t('Assigning students to groups')}</Text>
          </Flex.Item>
          <Flex.Item textAlign="start" margin="small x-large">
            <Text as="div">
              <p>
                {I18n.t(
                  'We are currently assigning your students into groups per your selections. This can take a while.'
                )}
              </p>
              <p>
                {I18n.t(
                  "You can close this dialog box to continue working if you don't want to wait; assigning will continue in the background."
                )}
              </p>
            </Text>
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}

AssignmentProgress.propTypes = {
  url: string.isRequired,
  onCompletion: func.isRequired,
  apiCall: func, // Used to override doFetchApi for storybook purposes
}
