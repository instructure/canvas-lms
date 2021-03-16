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

import React from 'react'
import I18n from 'i18n!feature_flags'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {Heading} from '@instructure/ui-heading'
import {Table} from '@instructure/ui-table'
import {Pill} from '@instructure/ui-pill'
import FeatureFlagButton from './FeatureFlagButton'

const {Head, Body, ColHeader, Row, Cell} = Table

export default function FeatureFlagTable({title, rows, disableDefaults}) {
  rows.sort((a, b) => a.display_name.localeCompare(b.display_name))
  return (
    <>
      <Heading as="h2" level="h3" data-testid="ff-table-heading">
        {title}
      </Heading>
      <Table caption={title} margin="medium 0">
        <Head>
          <Row>
            <ColHeader id="display_name" width="100%">
              {I18n.t('Feature')}
            </ColHeader>
            <ColHeader id="state">{I18n.t('State')}</ColHeader>
          </Row>
        </Head>
        <Body>
          {rows.map(feature => (
            <Row key={feature.feature} data-testid="ff-table-row">
              <Cell>
                <ToggleDetails
                  summary={
                    <>
                      {feature.display_name}
                      {feature.feature_flag.hidden ? (
                        <Pill margin="0 x-small" text={I18n.t('Hidden')} />
                      ) : null}
                      {feature.beta ? (
                        <Pill variant="primary" margin="0 x-small" text={I18n.t('Beta')} />
                      ) : null}
                    </>
                  }
                  defaultExpanded={feature.autoexpand}
                >
                  <div dangerouslySetInnerHTML={{__html: feature.description}} />
                </ToggleDetails>
              </Cell>
              <Cell>
                <FeatureFlagButton
                  displayName={feature.display_name}
                  featureFlag={feature.feature_flag}
                  disableDefaults={disableDefaults}
                />
              </Cell>
            </Row>
          ))}
        </Body>
      </Table>
    </>
  )
}
