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

import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Spacing} from '@instructure/emotion'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import * as React from 'react'
import {unstable_usePrompt, useNavigate, useOutletContext} from 'react-router-dom'
import {formatApiResultError, isSuccessful} from '../../../../common/lib/apiResult/ApiResult'
import {OverrideURIsConfirmation} from '../../../../manage/registration_wizard_forms/OverrideURIsConfirmation'
import {UpdateRegistration} from '../../../api/registrations'
import {convertToLtiConfigurationOverlay} from '../../../registration_overlay/Lti1p3RegistrationOverlayStateHelpers'
import {createLti1p3RegistrationOverlayStore} from '../../../registration_overlay/Lti1p3RegistrationOverlayStore'
import {
  getInputIdForField,
  validateLti1p3RegistrationOverlayState,
} from '../../../registration_overlay/validateLti1p3RegistrationOverlayState'
import {LaunchSettingsConfirmation} from '../../../registration_wizard_forms/LaunchSettingsConfirmation'
import {ToolDetailsOutletContext} from '../ToolDetails'
import {IconConfirmationPerfWrapper} from './IconConfirmationPerfWrapper'
import {NamingConfirmationPerfWrapper} from './NamingConfirmationPerfWrapper'
import {PermissionConfirmationPerfWrapper} from './PermissionConfirmationPerfWrapper'
import {PlacementsConfirmationPerfWrapper} from './PlacementsConfirmationPerfWrapper'
import {PrivacyConfirmationPerfWrapper} from './PrivacyConfirmationPerfWrapper'
import {ToolConfigurationFooter} from './ToolConfigurationFooter'

const I18n = createI18nScope('lti_registrations')

const Section = ({
  title,
  children,
  margin = '0 small medium small',
  subtitle,
}: {
  title?: string
  children: React.ReactNode
  margin?: Spacing
  subtitle?: React.ReactNode
}) => {
  return (
    <View
      borderRadius="large"
      borderColor="secondary"
      borderWidth="small"
      margin={margin}
      as="div"
      padding="medium"
    >
      {title ? <Heading level="h3">{title}</Heading> : null}
      {subtitle}
      {children}
    </View>
  )
}

type SaveState =
  | {
      tag: 'initial'
    }
  | {
      tag: 'saving'
    }
  | {
      tag: 'errors'
      errors: string[]
    }

const onBeforeUnload = (formIsDirty: boolean) => async (e: BeforeUnloadEvent) => {
  if (formIsDirty) {
    e.preventDefault()
    return ''
  }
}

export const ToolConfigurationEdit = (props: {
  updateLtiRegistration: UpdateRegistration
}) => {
  const {registration, refreshRegistration} = useOutletContext<ToolDetailsOutletContext>()
  const navigate = useNavigate()

  /**
   * This boolean determines whether or not we show an "exact" view of
   * the settings for a registration that the App developer has requested.
   * This is because we don't want the Admin to add configurations for
   * features that the app doesn't need or even support
   *
   * Currently, we don't show _all_ the settings for dynamic registration
   * because the user can't change them. We should also consider doing this
   * for inherited registrations, and manual registrations from LP.
   */
  const showAllSettings = registration.manual_configuration_id !== null

  const useOverlayState = React.useMemo(
    () =>
      createLti1p3RegistrationOverlayStore(
        registration.configuration,
        registration.admin_nickname || undefined,
        registration.overlay?.data || undefined,
      ),
    [registration],
  )

  const isDirty = useOverlayState(s => s.state.dirty)
  const unloadHandler = React.useCallback(onBeforeUnload(isDirty), [isDirty])
  React.useEffect(() => {
    window.addEventListener('beforeunload', unloadHandler)
    return () => {
      window.removeEventListener('beforeunload', unloadHandler)
    }
  }, [unloadHandler])
  unstable_usePrompt({
    message: I18n.t('You have unsaved changes. Are you sure you want to leave?'),
    when: isDirty,
  })

  const [saveState, setSaveState] = React.useState<SaveState>({tag: 'initial'})

  const save = React.useCallback(async () => {
    if (saveState.tag !== 'saving') {
      const {state, setDirty, setHasSubmitted} = useOverlayState.getState()
      setHasSubmitted(true)
      const errors = validateLti1p3RegistrationOverlayState(state)
      if (errors.length > 0) {
        // focus on the first invalid field
        document.getElementById(getInputIdForField(errors[0].field))?.focus()
        return
      }

      const {overlay, config} = convertToLtiConfigurationOverlay(state, registration.configuration)

      const result = await props.updateLtiRegistration({
        accountId: registration.account_id,
        registrationId: registration.id,
        overlay,
        adminNickname: state.naming.nickname,
        ...(showAllSettings ? {internalConfig: config} : {}),
      })

      if (isSuccessful(result)) {
        window.removeEventListener('beforeunload', unloadHandler)
        setDirty(false)
        refreshRegistration()
        // setTimeout here needed to wait one tick
        // for react router's unstable_usePrompt
        // to catch up to the dirty state
        setTimeout(() =>
          navigate(`/manage/${registration.id}/configuration`, {
            replace: true,
          }),
        )
      } else {
        showFlashAlert({
          message: I18n.t('An error occurred while updating the configuration.'),
          type: 'error',
          politeness: 'assertive',
        })
        setSaveState(() => ({
          tag: 'errors',
          errors: [formatApiResultError(result)],
        }))
      }
    }
  }, [registration, setSaveState, saveState, unloadHandler])

  return (
    <div>
      {
        // don't display this for DR Registrations
        showAllSettings ? (
          <Section>
            <LaunchSettingsConfirmation
              title={I18n.t('Launch Settings')}
              internalConfig={registration.configuration}
              overlayStore={useOverlayState}
            />
          </Section>
        ) : null
      }

      <Section>
        <PermissionConfirmationPerfWrapper
          overlayStore={useOverlayState}
          registration={registration}
          showAllSettings={showAllSettings}
        />
      </Section>

      <Section>
        <PrivacyConfirmationPerfWrapper
          registration={registration}
          overlayStore={useOverlayState}
        />
      </Section>

      <Section>
        <PlacementsConfirmationPerfWrapper
          overlayStore={useOverlayState}
          registration={registration}
          showAllSettings={showAllSettings}
        />
        {showAllSettings ? (
          <Text>
            {I18n.t(
              'Placements must be supported by the tool in order to work. Check with your Tool Vendor to ensure they support these functionalities.',
            )}
          </Text>
        ) : null}
      </Section>

      {showAllSettings ? (
        <Section>
          <OverrideURIsConfirmation
            overlayStore={useOverlayState}
            internalConfig={registration.configuration}
          />
        </Section>
      ) : null}

      <Section>
        <NamingConfirmationPerfWrapper
          overlayStore={useOverlayState}
          registration={registration}
          showAllSettings={showAllSettings}
        />
      </Section>

      <Section>
        <IconConfirmationPerfWrapper overlayStore={useOverlayState} registration={registration} />
      </Section>
      <Footer save={save} isSaving={saveState.tag === 'saving'} />
    </div>
  )
}

const Footer = React.memo(({save, isSaving}: {save: () => Promise<void>; isSaving: boolean}) => {
  const navigate = useNavigate()
  return (
    <ToolConfigurationFooter>
      <Flex direction="row" justifyItems="end" padding="0 small">
        <Flex.Item margin="small">
          <Button
            color="secondary"
            onClick={() => {
              navigate(-1)
            }}
          >
            {I18n.t('Cancel')}
          </Button>
        </Flex.Item>
        <Flex.Item>
          <Button color="primary" disabled={isSaving} onClick={save}>
            {I18n.t('Update Configuration')}
          </Button>
        </Flex.Item>
      </Flex>
    </ToolConfigurationFooter>
  )
})
