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

import React, {useState} from 'react'
import I18n from 'i18n!course_settings'

import {Alert} from '@instructure/ui-alerts'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {ToggleGroup} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'

const IntegrationRow = ({
  name,
  enabled,
  loading,
  onChange,
  children,
  error,
  expanded,
  onToggle
}) => {
  const summary = () => (
    <Flex justifyItems="space-between">
      <Flex.Item>
        <Text>{name}</Text>
      </Flex.Item>
      <Flex.Item>
        <Flex>
          <Flex.Item>
            {loading && (
              <View as="div" textAlign="center">
                <Spinner
                  margin="none medium none none"
                  size="x-small"
                  renderTitle={I18n.t('Loading %{name} data', {name})}
                />
              </View>
            )}
          </Flex.Item>
          <Flex.Item>
            <Checkbox
              label={<ScreenReaderContent>{I18n.t('Toggle %{name}', {name})}</ScreenReaderContent>}
              variant="toggle"
              checked={enabled}
              onChange={onChange}
              disabled={loading}
            />
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
  const toggleLabel = () =>
    enabled ? I18n.t('Hide %{name} details', {name}) : I18n.t('Show %{name} details', {name})

  return (
    <ToggleGroup
      toggleLabel={toggleLabel()}
      summary={summary()}
      border={false}
      expanded={expanded}
      onToggle={onToggle}
    >
      <div role="region" aria-live="polite">
        {error && !loading && (
          <Alert variant="error" margin="small">
            <Text>{I18n.t('An error occurred, please try again. Error: %{error}', {error})}</Text>
          </Alert>
        )}
        {!enabled && !loading && (
          <Alert variant="info" margin="small">
            <Text>
              {I18n.t(
                'This integration is not enabled. Please enable it to interact with settings.'
              )}
            </Text>
          </Alert>
        )}
      </div>
      <View display="block" padding="small">
        {children}
      </View>
    </ToggleGroup>
  )
}

export default IntegrationRow
