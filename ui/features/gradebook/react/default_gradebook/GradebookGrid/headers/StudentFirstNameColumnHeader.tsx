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

import React from 'react'
import {Grid} from '@instructure/ui-grid'
import {View} from '@instructure/ui-view'

import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import ColumnHeader from './ColumnHeader'

const I18n = useI18nScope('gradebook')

type Props = {
  addGradebookElement?: any
  removeGradebookElement?: any
  onHeaderKeyDown?: any
}

type State = {
  hasFocus: boolean
}

export default class StudentFirstNameColumnHeader extends ColumnHeader<Props, State> {
  static propTypes = {
    ...ColumnHeader.propTypes,
  }

  static defaultProps = {
    ...ColumnHeader.defaultProps,
  }

  render() {
    return (
      <div
        className={`Gradebook__ColumnHeaderContent ${this.state.hasFocus ? 'focused' : ''}`}
        onBlur={this.handleBlur}
        onFocus={this.handleFocus}
      >
        <div style={{flex: 1, minWidth: '1px'}}>
          <Grid colSpacing="none" hAlign="space-between" vAlign="middle">
            <Grid.Row>
              <Grid.Col textAlign="start">
                <View
                  className="Gradebook__ColumnHeaderDetail Gradebook__ColumnHeaderDetail--OneLine"
                  padding="0 0 0 small"
                  data-testid="first-name-header"
                >
                  <Text fontStyle="normal" size="x-small" weight="bold">
                    {I18n.t('Student First Name')}
                  </Text>
                </View>
              </Grid.Col>
            </Grid.Row>
          </Grid>
        </div>
      </div>
    )
  }
}
