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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {LtiPlacements, type LtiPlacement} from '../model/LtiPlacement'
import {i18nLtiPlacement} from '../model/i18nLtiPlacement'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Checkbox} from '@instructure/ui-checkbox'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import {IconButton} from '@instructure/ui-buttons'
import {IconInfoLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'
import {Img} from '@instructure/ui-img'
import {Responsive} from '@instructure/ui-responsive'

export type PlacementsConfirmationProps = {
  /**
   * The name of the application that is being registered.
   */
  appName: string
  /**
   * The list of placements that are currently enabled.
   */
  enabledPlacements: LtiPlacement[]
  /**
   * The full list of placements that should be
   * _possible_ to be toggled
   * in the placements confirmation screen.
   */
  availablePlacements: readonly LtiPlacement[]

  /**
   * A boolean that determines if the course navigation placement is hidden by default.
   */
  courseNavigationDefaultHidden: boolean

  /**
   * A callback for whenever a placement's checkbox is toggled.
   */
  onTogglePlacement: (placement: LtiPlacement) => void
  /**
   * A callback for whenever the default hidden checkbox is toggled. This is only applicable to the course navigation placement.
   */
  onToggleDefaultDisabled: () => void
}

const I18n = createI18nScope('lti_registration.wizard')

/**
 * These placements don't have images in the API docs, so we don't show the tooltip.
 * We have purposefully chosen to leave them undocumented.
 */
export const UNDOCUMENTED_PLACEMENTS = [
  LtiPlacements.ConferenceSelection, // Locked behind a Site Admin FF that's off
  LtiPlacements.SimilarityDetection, // Only really relevant for LTI 2
]

export const PlacementsConfirmation = React.memo(
  ({
    appName,
    enabledPlacements,
    courseNavigationDefaultHidden,
    availablePlacements,
    onTogglePlacement,
    onToggleDefaultDisabled,
  }: PlacementsConfirmationProps) => {
    return (
      <>
        <Heading level="h3" margin="0 0 x-small 0">
          {I18n.t('Placements')}
        </Heading>
        <Text
          dangerouslySetInnerHTML={{
            __html: I18n.t(
              'Choose where *%{appName}* may be accessed from. Find more details in the **placements documentation.**',
              {
                appName,
                wrappers: [
                  '<strong>$1</strong>',
                  "<a id='placements-documentation-link' href='https://canvas.instructure.com/doc/api/file.placements_overview.html' style='text-decoration: underline' target='_blank'>$1</a>",
                ],
              },
            ),
          }}
        />
        {availablePlacements.length === 0 ? (
          <Text>
            {I18n.t(
              "This tool has not requested access to any placements. If installed, it will have access to the LTI APIs but won't be visible for users to launch. The app can be managed via the Manage Apps page.",
            )}
          </Text>
        ) : (
          <Flex gap="medium" direction="column" margin="medium 0 medium 0">
            {availablePlacements.toSorted().map(p => {
              return (
                <PlacementCheckbox
                  key={p}
                  placement={p}
                  enabled={enabledPlacements.includes(p)}
                  onTogglePlacement={onTogglePlacement}
                  courseNavigationDefaultHidden={courseNavigationDefaultHidden}
                  onToggleDefaultDisabled={onToggleDefaultDisabled}
                />
              )
            })}
          </Flex>
        )}
      </>
    )
  },
)

type PlacementCheckboxProps = {
  placement: LtiPlacement
  enabled: boolean
  onTogglePlacement: (placement: LtiPlacement) => void
  courseNavigationDefaultHidden: boolean
  onToggleDefaultDisabled: () => void
}

const PlacementCheckbox = React.memo(
  ({
    placement,
    enabled,
    onTogglePlacement,
    courseNavigationDefaultHidden,
    onToggleDefaultDisabled,
  }: PlacementCheckboxProps) => {
    const checkbox = (
      <Flex direction="row" gap="x-small" justifyItems="start" alignItems="center" key={placement}>
        <Flex.Item>
          <Checkbox
            data-pendo="lti-placement-checkbox"
            data-testid={`placement-checkbox-${placement}`}
            labelPlacement="end"
            label={<Text>{i18nLtiPlacement(placement)}</Text>}
            checked={enabled}
            onChange={() => {
              onTogglePlacement(placement)
            }}
          />
        </Flex.Item>
        {!UNDOCUMENTED_PLACEMENTS.includes(
          placement as (typeof UNDOCUMENTED_PLACEMENTS)[number],
        ) && (
          <Flex.Item>
            <Tooltip
              placement="top"
              constrain="parent"
              renderTip={
                <Responsive
                  match="media"
                  query={{
                    small: {maxWidth: 500},
                    medium: {minWidth: 500},
                    large: {minWidth: 1000},
                  }}
                  props={{
                    small: {width: '15rem'},
                    medium: {width: '30rem'},
                    large: {width: '35rem'},
                  }}
                  render={props => {
                    return (
                      <Img
                        {...props}
                        data-testid={`placement-img-${placement}`}
                        constrain="contain"
                        src={`/doc/api/images/placements/${placement}.png`}
                        alt={I18n.t('An image showing the %{placement} placement within Canvas', {
                          placement: i18nLtiPlacement(placement),
                        })}
                      />
                    )
                  }}
                />
              }
            >
              <IconButton
                withBackground={false}
                withBorder={false}
                renderIcon={IconInfoLine}
                size="small"
                screenReaderLabel={I18n.t('Tooltip for the %{placement} placement', {
                  placement,
                })}
              />
            </Tooltip>
          </Flex.Item>
        )}
      </Flex>
    )
    if (placement === LtiPlacements.CourseNavigation) {
      return (
        <FormFieldGroup
          rowSpacing="medium"
          key={placement}
          name={`${placement}-toggle`}
          description={
            <ScreenReaderContent>
              {I18n.t('Modify the %{placement} placement', {
                placement: i18nLtiPlacement(placement),
              })}
            </ScreenReaderContent>
          }
        >
          {checkbox}
          {enabled && (
            <View padding="0 0 0 medium" display="block" as="div">
              <Checkbox
                data-pendo="lti-course-navigation-default-checkbox"
                checked={courseNavigationDefaultHidden}
                label={I18n.t('Default to Hidden')}
                onChange={() => {
                  onToggleDefaultDisabled()
                }}
              />
            </View>
          )}
        </FormFieldGroup>
      )
    }
    return checkbox
  },
)
