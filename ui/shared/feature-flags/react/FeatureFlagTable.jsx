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

import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {Heading} from '@instructure/ui-heading'
import {Table} from '@instructure/ui-table'
import StatusPill from './StatusPill'
import FeatureFlagButton from './FeatureFlagButton'

const I18n = createI18nScope('feature_flags')

const {Head, Body, ColHeader, Row, Cell} = Table

function FeatureFlagTable({title, rows, disableDefaults}) {
  const [stateChanges, setStateChanges] = useState({})

  rows.sort((a, b) => a.display_name.localeCompare(b.display_name))
  return (
    <>
      <Heading as="h2" level="h3" data-testid="ff-table-heading">
        {title}
      </Heading>
      <Table caption={title} margin="medium 0">
        <Head>
          <Row>
            <ColHeader id="display_name" width="50%">
              {I18n.t('Feature')}
            </ColHeader>
            <ColHeader id="status" width="50%">
              {I18n.t('Status')}
            </ColHeader>
            <ColHeader id="state">{I18n.t('State')}</ColHeader>
          </Row>
        </Head>
        <Body>
          {rows.map(feature => (
            <Row key={feature.feature} data-testid="ff-table-row">
              <Cell>
                <ToggleDetails summary={feature.display_name} defaultExpanded={feature.autoexpand}>
                  <div dangerouslySetInnerHTML={{__html: feature.description}} />
                </ToggleDetails>
              </Cell>
              <Cell>
                <StatusPill feature={feature} updatedState={stateChanges[feature.feature]} />
              </Cell>
              <Cell>
                <FeatureFlagButton
                  displayName={feature.display_name}
                  featureFlag={feature.feature_flag}
                  disableDefaults={disableDefaults}
                  appliesTo={feature.applies_to}
                  onStateChange={newState =>
                    setStateChanges({...stateChanges, [feature.feature]: newState})
                  }
                />
              </Cell>
            </Row>
          ))}
        </Body>
      </Table>
    </>
  )
}

export default React.memo(FeatureFlagTable)
