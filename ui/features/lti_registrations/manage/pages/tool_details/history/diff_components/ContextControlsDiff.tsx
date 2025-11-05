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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import type {DeploymentDiff} from '../differ'
import {ContextCard} from '../../availability/ContextCard'
import {Flex} from '@instructure/ui-flex'
import {Pill} from '@instructure/ui-pill'
import {IconArrowEndSolid} from '@instructure/ui-icons'
import {Grid} from '@instructure/ui-grid'
import {Heading} from '@instructure/ui-heading'
import {toUndefined} from '../../../../../common/lib/toUndefined'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {isRTL} from '@canvas/i18n/rtlHelper'

const I18n = createI18nScope('lti_registrations')

export type ContextControlsDiffProps = {
  deploymentDiffs: DeploymentDiff[]
}

/**
 * Display availability changes for context controls (Account/Course level)
 */
export const ContextControlsDiff: React.FC<ContextControlsDiffProps> = ({deploymentDiffs}) => {
  if (deploymentDiffs.length === 0) {
    return (
      <View as="div" textAlign="center" padding="large">
        <Text>
          {I18n.t(
            "We're unable to show a comparison for these changes. For a complete representation of changes, please use the API.",
          )}
        </Text>
      </View>
    )
  }

  const isRtl = isRTL()

  return (
    <>
      <Heading level="h3">{I18n.t('Availability & Exceptions')}</Heading>
      {deploymentDiffs.map(deployment => (
        <View
          key={deployment.id}
          as="div"
          borderRadius="medium"
          borderColor="secondary"
          borderWidth="small"
          padding="medium"
          margin="medium 0"
        >
          <Grid
            startAt="large"
            vAlign="middle"
            hAlign="start"
            colSpacing="small"
            rowSpacing="small"
          >
            <Grid.Row>
              <Grid.Col>
                <Flex direction="row" gap="small" alignItems="center">
                  <Heading level="h3">
                    {I18n.t('Installed in %{context_name}', {
                      context_name: deployment.context_name,
                    })}
                  </Heading>
                </Flex>
              </Grid.Col>
            </Grid.Row>
          </Grid>

          <div>
            <Text size="small">
              {I18n.t('Deployment ID: %{deployment_id}', {
                deployment_id: deployment.deployment_id,
              })}
            </Text>
          </div>

          <Flex direction="column" gap="small" margin="small 0 0 0">
            {deployment.controlDiffs.map(control => (
              <Flex.Item key={control.id}>
                <Flex direction="column" gap="small">
                  <Flex.Item>
                    <ContextCard
                      context_name={control.context_name}
                      course_id={toUndefined(control.course_id)}
                      account_id={toUndefined(control.account_id)}
                      inherit_note={false}
                      path_segments={control.display_path}
                      exception_counts={{
                        child_control_count: control.child_control_count,
                        course_count: control.course_count,
                        subaccount_count: control.subaccount_count,
                      }}
                    />
                  </Flex.Item>
                  <Flex.Item>
                    <ScreenReaderContent>{}</ScreenReaderContent>
                    <Flex
                      direction="row"
                      alignItems="center"
                      gap="x-small"
                      aria-label={I18n.t(
                        'The availability of this tool in %{contextName} was changed from %{oldValue} to %{newValue}',
                        {
                          contextName: control.context_name,
                          oldValue: translateAvailability(control.availabilityChange.oldValue),
                          newValue: translateAvailability(control.availabilityChange.newValue),
                        },
                      )}
                    >
                      <Flex.Item size="4" textAlign="center" aria-hidden="true">
                        <Pill>
                          {isRtl
                            ? translateAvailability(control.availabilityChange.newValue)
                            : translateAvailability(control.availabilityChange.oldValue)}
                        </Pill>
                      </Flex.Item>
                      <Flex.Item size="1" textAlign="center" aria-hidden="true">
                        {/* Handles flipping in RTL for us */}
                        <IconArrowEndSolid />
                      </Flex.Item>
                      <Flex.Item size="4" textAlign="center" aria-hidden="true">
                        <Pill>
                          {isRtl
                            ? translateAvailability(control.availabilityChange.oldValue)
                            : translateAvailability(control.availabilityChange.newValue)}
                        </Pill>
                      </Flex.Item>
                    </Flex>
                  </Flex.Item>
                </Flex>
              </Flex.Item>
            ))}
          </Flex>
        </View>
      ))}
    </>
  )
}

const translateAvailability = (available: boolean | undefined) => {
  if (available === undefined) {
    return I18n.t('No Value Set')
  } else if (available) {
    return I18n.t('Available')
  } else {
    return I18n.t('Not Available')
  }
}
