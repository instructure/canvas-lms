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

import {useScope as useI18nScope} from '@canvas/i18n'
import {bool} from 'prop-types'
import React, {useEffect, useState, useRef} from 'react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {colors as hcmColors} from '@instructure/canvas-high-contrast-theme'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {Tooltip} from '@instructure/ui-tooltip'
import {Checkbox} from '@instructure/ui-checkbox'
import {IconButton} from '@instructure/ui-buttons'
import {IconInfoLine} from '@instructure/ui-icons'

const I18n = useI18nScope('ProfileTray')

const {porcelain, licorice, shamrock, brand} = hcmColors.values

// The checkbox toggle is the only thing we have to worry about here,
// as all the other page elements are just primary-color text, which is
// the same in both the normal Canvas theme and the Canvas High Contrast
// theme.
const checkboxThemeOverrides = {
  color: porcelain,
  toggleBackground: porcelain,
  labelColor: licorice,
  background: licorice,
  borderColor: licorice,
  uncheckedIconColor: licorice,
  checkedBackground: shamrock,
  checkedIconColor: shamrock,
  focusOutlineColor: brand,
}

type HighContrastLabelProps = {
  loading: boolean
  isMobile: boolean
}

type TipTrigger = 'click' | 'hover' | 'focus'

const HighContrastLabel = ({loading, isMobile}: HighContrastLabelProps) => {
  const labelText = isMobile ? I18n.t('Hi-contrast') : I18n.t('Use High Contrast UI')
  const mobileTipText = I18n.t('Enhance color contrast of content')
  const dekstopTipText = I18n.t('Enhances the color contrast of text, buttons, etc.')
  const tipText = isMobile ? mobileTipText : dekstopTipText
  const tipTriggers: TipTrigger[] = ['click']

  // Show a spinner after a delay in case API calls take an excessive amount of time,
  // but only do this in development or production environments, not in tests
  const spinnerDelay =
    process.env.NODE_ENV === 'test' || typeof process.env.NODE_ENV === 'undefined' ? undefined : 300

  if (!isMobile) {
    tipTriggers.push('hover')
    tipTriggers.push('focus')
  }

  const [tipTextState, setTipTextState] = useState(tipText)

  const handleResize = () => {
    if (window.devicePixelRatio >= 4) {
      setTipTextState(mobileTipText)
    } else if (window.devicePixelRatio < 4 && !isMobile) {
      setTipTextState(dekstopTipText)
    }
  }

  /* eslint-disable react-hooks/exhaustive-deps */
  useEffect(() => {
    window.addEventListener('resize', handleResize)

    return () => {
      window.removeEventListener('resize', handleResize)
    }
  }, [])
  /* eslint-enable react-hooks/exhaustive-deps */

  return (
    <View as="span">
      <Text>{labelText}</Text>
      <Tooltip renderTip={tipTextState} on={tipTriggers} placement="bottom start">
        <IconButton
          renderIcon={IconInfoLine}
          size="small"
          margin="none none xx-small xx-small"
          withBackground={false}
          withBorder={false}
          screenReaderLabel={I18n.t('Toggle tooltip')}
        />
      </Tooltip>
      {loading && (
        <Spinner
          delay={spinnerDelay}
          data-testid="hcm-change-spinner"
          size="x-small"
          renderTitle={I18n.t('Waiting for change to complete')}
          margin="none none xx-small none"
        />
      )}
    </View>
  )
}

HighContrastLabel.propTypes = {
  loading: bool.isRequired,
  isMobile: bool.isRequired,
}

type HighContrastModeToggleProps = {
  isMobile: boolean
}

export default function HighContrastModeToggle({isMobile}: HighContrastModeToggleProps) {
  const originalSetting = useRef(ENV.use_high_contrast)
  const [enabled, setEnabled] = useState(ENV.use_high_contrast)
  const [loading, setLoading] = useState(false)
  const path = `/api/v1/users/${ENV.current_user_id}/features/flags/high_contrast`
  const changed = originalSetting.current !== enabled
  const margins = isMobile ? 'none none none small' : 'none'

  // Toggles the high_contrast feature flag to the opposite state from where it
  // is currently at. Note that this only updates the back-end and the current page
  // will remain on the old setting until a new Canvas page load happens (or this
  // page is manually reloaded by the user), so the currently loaded CSS and thus
  // the HCM state of the browser screen will be out of sync with the persistence
  // layer until that happens.
  async function toggleHiContrast() {
    const newState = enabled ? 'off' : 'on'
    setLoading(true)
    try {
      const {json} = await doFetchApi({
        path,
        method: 'PUT',
        body: {feature: 'high_contrast', state: newState},
      })
      if (json.feature !== 'high_contrast') throw new Error('Unexpected response from API call')
      setEnabled(json.state === 'on')
      ENV.use_high_contrast = json.state === 'on'
    } catch (err) {
      if (err instanceof Error) {
        showFlashAlert({
          message: I18n.t('An error occurred while trying to change the UI'),
          err,
        })
      }
    } finally {
      setLoading(false)
    }
  }

  // By definition this control for turning on HCM has to be in HCM all the time,
  // regardless of the global theme, so we have to apply some overrides.
  return (
    <View as="div" margin={margins}>
      <Checkbox
        themeOverride={checkboxThemeOverrides}
        variant="toggle"
        size="small"
        label={<HighContrastLabel loading={loading} isMobile={isMobile} />}
        checked={enabled}
        readOnly={loading}
        onChange={toggleHiContrast}
      />
      {changed && (
        <Text size="small">
          {I18n.t('Reload the page or navigate to a new page for this change to take effect.')}
        </Text>
      )}
    </View>
  )
}

HighContrastModeToggle.defaultProps = {
  isMobile: false,
}
