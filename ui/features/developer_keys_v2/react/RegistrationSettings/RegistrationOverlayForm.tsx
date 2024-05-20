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

import {useScope as useI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Grid} from '@instructure/ui-grid'
import {IconResetLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import * as React from 'react'
import type {StoreApi} from 'zustand'
import {type LtiPlacement, i18nLtiPlacement} from '../../model/LtiPlacements'
import type {LtiRegistration} from '../../model/LtiRegistration'
import {i18nLtiScope} from '../../model/LtiScopes'
import {
  canvasPlatformSettings,
  type PlacementOverlay,
  type RegistrationOverlayStore,
} from './RegistrationOverlayState'
import {RegistrationPrivacyField} from './RegistrationPrivacyField'

const I18n = useI18nScope('react_developer_keys')

export const RegistrationOverlayForm = (props: {
  ltiRegistration: LtiRegistration
  store: StoreApi<RegistrationOverlayStore>
}) => {
  const configuration = props.ltiRegistration.default_configuration

  const [{state, ...actions}, setState] = React.useState(props.store.getState())

  const {
    toggleDisabledScope,
    toggleDisabledPlacement,
    updatePlacement,
    resetOverlays,
    updatePrivacyLevel,
  } = React.useMemo(() => actions, [actions])

  React.useEffect(() => {
    props.store.subscribe(state => {
      setState(state)
    })
    return () => {
      props.store.destroy()
    }
  }, [props.store])

  const placements = canvasPlatformSettings(configuration)?.settings.placements || []

  const scopes = configuration.scopes || []

  return (
    <>
      <Flex justifyItems="space-between" alignItems="center">
        <Flex.Item>
          <Text as="div" size="x-large" transform="capitalize">
            {state.developerKeyName} {I18n.t('Settings')}
          </Text>
        </Flex.Item>
        <Flex.Item>
          <Button
            renderIcon={IconResetLine}
            margin="0 0 0 small"
            onClick={() => {
              resetOverlays(configuration)
            }}
          >
            {I18n.t('Restore Defaults')}
          </Button>
        </Flex.Item>
      </Flex>
      <View margin="medium 0" as="div">
        <FormFieldGroup description={I18n.t('Permissions')}>
          {scopes.length > 0 ? (
            scopes.map(scope => (
              <Checkbox
                key={scope}
                checked={!state.registration.disabledScopes.includes(scope)}
                label={i18nLtiScope(scope)}
                onChange={() => toggleDisabledScope(scope)}
              />
            ))
          ) : (
            <Text fontStyle="italic">{I18n.t('This tool requires no permissions')}</Text>
          )}
        </FormFieldGroup>
      </View>
      <View margin="medium 0" as="div">
        <RegistrationPrivacyField
          value={state.registration.privacy_level}
          onChange={updatePrivacyLevel}
        />
      </View>
      <View margin="medium 0" as="div">
        <FormFieldGroup description={I18n.t('Placements')} size={10}>
          {placements.length === 0 ? (
            <Text fontStyle="italic">{I18n.t('This tool has no placements')}</Text>
          ) : null}
          {placements
            .map(placement => {
              const placementOverlay = state.registration.placements.find(
                p => p.type === placement.placement
              )
              if (!placementOverlay) {
                return [placement, {type: placement.placement}] as const
              } else {
                return [placement, placementOverlay] as const
              }
            })
            .map(([placement, placementOverlay]) => {
              const disabled = state.registration.disabledPlacements.includes(placementOverlay.type)
              return (
                <div>
                  <PlacementOverlayForm
                    key={placementOverlay.type}
                    updatePlacement={updatePlacement}
                    placementOverlay={placementOverlay}
                    placementDisabled={disabled}
                    toggleDisabledPlacement={toggleDisabledPlacement}
                    borders={true}
                  />
                </div>
              )
            })}
        </FormFieldGroup>
      </View>
    </>
  )
}

type PlacementOverlayFormProps = {
  placementOverlay: PlacementOverlay
  placementDisabled: boolean
  toggleDisabledPlacement: (placementType: LtiPlacement) => void
  updatePlacement: (
    placement_type: LtiPlacement
  ) => (fn: (placementOverlay: PlacementOverlay) => PlacementOverlay) => void
  borders: boolean
}
const PlacementOverlayForm = React.memo((props: PlacementOverlayFormProps) => {
  const {placementOverlay, placementDisabled, updatePlacement} = props

  return (
    <View
      as="div"
      borderWidth={props.borders ? 'small' : '0'}
      padding={props.borders ? 'small' : '0'}
    >
      <Grid>
        <Grid.Row>
          <Grid.Col>
            <Checkbox
              name={`${props.placementOverlay.type}-enabled`}
              inline={true}
              checked={!placementDisabled}
              label={i18nLtiPlacement(placementOverlay.type)}
              variant="toggle"
              onChange={() => props.toggleDisabledPlacement(placementOverlay.type)}
            />

            {/* TODO: add a tooltip w/ screenshot of where this placement is
            <View margin="0 0 0 small">
            <Tooltip
              renderTip={() => ('description')}
              onShowContent={() => console.log('showing')}
              onHideContent={() => console.log('hidden')}
            >
              <IconInfoLine color='primary'/>
            </Tooltip>
            </View> */}
          </Grid.Col>
        </Grid.Row>
        {/* Grid expects Grid.Row to be direct children, so a fragment here wouldn't help */}
        {placementDisabled ? null : (
          <Grid.Row>
            <Grid.Col>
              <Grid>
                <Grid.Row>
                  <Grid.Col>
                    <TextInput
                      renderLabel={I18n.t('Title')}
                      value={placementOverlay.label}
                      onChange={(event, value) => {
                        updatePlacement(placementOverlay.type)(placementOverlay => ({
                          ...placementOverlay,
                          label: value,
                        }))
                      }}
                    />
                  </Grid.Col>
                  <Grid.Col>
                    <TextInput
                      renderLabel={I18n.t('Icon URL')}
                      value={placementOverlay.icon_url}
                      onChange={(event, value) => {
                        updatePlacement(placementOverlay.type)(placementOverlay => ({
                          ...placementOverlay,
                          icon_url: value,
                        }))
                      }}
                    />
                  </Grid.Col>
                </Grid.Row>
                {/* TODO: add launch_height/launch_width overlay */}
                {/* <Grid.Row>
                  <Grid.Col>
                    <TextInput
                      renderLabel={I18n.t('Launch Height')}
                      disabled={placementDisabled}
                      onChange={(event, value) => {
                        updatePlacement(placementOverlay.type)(placementOverlay => ({
                          ...placementOverlay,
                          launch_height: value,
                        }))
                      }}
                    />
                  </Grid.Col>
                  <Grid.Col>
                    <TextInput
                      renderLabel={I18n.t('Launch Width')}
                      disabled={placementDisabled}
                      onChange={(event, value) => {
                        updatePlacement(placementOverlay.type)(placementOverlay => ({
                          ...placementOverlay,
                          launch_width: value,
                        }))
                      }}
                    />
                  </Grid.Col>
                </Grid.Row> */}
              </Grid>
            </Grid.Col>
          </Grid.Row>
        )}
      </Grid>
    </View>
  )
})
