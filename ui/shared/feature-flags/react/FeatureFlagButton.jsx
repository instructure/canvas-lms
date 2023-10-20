/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React, {useState, useRef, useEffect} from 'react'
import {bool, object, string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {
  IconPublishSolid,
  IconTroubleLine,
  IconLockSolid,
  IconUnlockLine,
} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {IconButton} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-spinner'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {showConfirmationDialog} from './ConfirmationDialog'

import * as flagUtils from './util'

const I18n = useI18nScope('feature_flags')

function setFlag(flagName, state) {
  return doFetchApi({
    method: 'PUT',
    path: `/api/v1${ENV.CONTEXT_BASE_URL}/features/flags/${flagName}`,
    body: {state},
  })
}

function removeFlag(flagName) {
  return doFetchApi({
    method: 'DELETE',
    path: `/api/v1${ENV.CONTEXT_BASE_URL}/features/flags/${flagName}`,
  })
}

function FeatureFlagButton({featureFlag, disableDefaults, displayName}) {
  const [updatedFlag, setUpdatedFlag] = useState(undefined)
  const [apiBusy, setApiBusy] = useState(false)
  const enclosingDivEl = useRef(null)
  const mustRefocus = useRef(false)
  const effectiveFlag = updatedFlag || featureFlag

  async function updateFlag(state) {
    if (apiBusy) return
    const message = flagUtils.transitionMessage(effectiveFlag, state)
    if (message) {
      const res = await showConfirmationDialog({
        label: displayName,
        body: message,
      })
      if (!res) {
        return
      }
    }
    setApiBusy(true)
    try {
      if (flagUtils.shouldDelete(effectiveFlag, allowsDefaults, state)) {
        const {json} = await removeFlag(effectiveFlag.feature)
        // Update to match the new state since this returns the old version not the new one
        json.state = json.parent_state
        setUpdatedFlag(json)
      } else {
        const {json} = await setFlag(effectiveFlag.feature, state)
        setUpdatedFlag(json)
      }
    } catch (e) {
      showFlashAlert({
        message: I18n.t('An error occurred updating the flag'),
        err: null,
        type: 'error',
      })
    } finally {
      setApiBusy(false)
      mustRefocus.current = true
    }
  }

  const isReadonly = ENV.PERMISSIONS?.manage_feature_flags === false || effectiveFlag.locked
  const isEnabled = flagUtils.isEnabled(effectiveFlag)

  // Only some FFs at some levels can be be overridden at lower levels
  // Show the appropriate text depending
  // Also if we are in a course context then our FFs can't ever be inherited
  const allowsDefaults = flagUtils.doesAllowDefaults(effectiveFlag, disableDefaults)
  const description = flagUtils.buildDescription(effectiveFlag, allowsDefaults)

  const isLocked = flagUtils.isLocked(effectiveFlag)

  // Hidden should just render as off...
  const isSelected = state =>
    state === (effectiveFlag.state === 'hidden' ? 'off' : effectiveFlag.state)

  const transitions = flagUtils.buildTransitions(effectiveFlag, allowsDefaults)

  function refocusOnButtonIfNecessary() {
    if (mustRefocus.current && enclosingDivEl.current) {
      const button = enclosingDivEl.current.querySelector('button')
      if (button) {
        button.focus()
        mustRefocus.current = false
      }
    }
  }

  useEffect(refocusOnButtonIfNecessary)

  return (
    <div ref={enclosingDivEl} title={description}>
      <Flex direction="row">
        <Menu
          trigger={
            <IconButton
              interaction={isReadonly || apiBusy ? 'disabled' : 'enabled'}
              size="medium"
              withBackground={false}
              withBorder={false}
              color={isEnabled ? 'success' : 'danger'}
              screenReaderLabel={`${displayName}, ${I18n.t('current state:')} ${description}`}
            >
              {isEnabled ? <IconPublishSolid /> : <IconTroubleLine />}
            </IconButton>
          }
        >
          <Menu.Item
            value={transitions.enabled}
            selected={isSelected(transitions.enabled) || isSelected('allowed_on')}
            disabled={flagUtils.transitionLocked(effectiveFlag, transitions.enabled)}
            onSelect={() => {
              updateFlag(transitions.enabled)
            }}
            type="checkbox"
          >
            {I18n.t('Enabled')}
          </Menu.Item>
          <Menu.Item
            value={transitions.disabled}
            selected={isSelected(transitions.disabled) || isSelected('allowed')}
            disabled={flagUtils.transitionLocked(effectiveFlag, transitions.disabled)}
            onSelect={() => {
              updateFlag(transitions.disabled)
            }}
            type="checkbox"
          >
            {I18n.t('Disabled')}
          </Menu.Item>
          {allowsDefaults ? <Menu.Separator /> : null}
          {allowsDefaults ? (
            <Menu.Item
              value={transitions.lock}
              selected={isLocked}
              disabled={flagUtils.transitionLocked(effectiveFlag, transitions.lock)}
              onSelect={() => {
                updateFlag(transitions.lock)
              }}
              type="checkbox"
            >
              {I18n.t('Lock')}
            </Menu.Item>
          ) : null}
        </Menu>
        <Flex direction="column" margin="none none none xx-small">
          {allowsDefaults && (
            <Flex.Item size="24px">
              <Text color="primary">{isLocked ? <IconLockSolid /> : <IconUnlockLine />}</Text>
            </Flex.Item>
          )}
          {apiBusy && (
            <Flex.Item size="24px" overflowX="visible" overflowY="visible">
              <Spinner size="x-small" renderTitle={I18n.t('Waiting for request to complete')} />
            </Flex.Item>
          )}
        </Flex>
      </Flex>
    </div>
  )
}

FeatureFlagButton.propTypes = {
  featureFlag: object.isRequired,
  displayName: string,
  disableDefaults: bool,
}

export default React.memo(FeatureFlagButton)
