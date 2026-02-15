/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {Component} from 'react'
import {connect} from 'react-redux'

import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {PresentationContent} from '@instructure/ui-a11y-content'

import ChangeLogRow, {ChangeRow} from './ChangeLogRow'
import SyncHistoryItem from '@canvas/blueprint-courses/react/components/SyncHistoryItem'

import LoadStates from '@canvas/blueprint-courses/react/loadStates'
import type {BlueprintState, Migration, LoadState} from '@canvas/blueprint-courses/react/types'

const I18n = createI18nScope('blueprint_coursesChildChangeLog')

export interface ChildChangeLogProps {
  status: LoadState | null
  migration: Migration | null
}

export default class ChildChangeLog extends Component<ChildChangeLogProps> {
  static defaultProps = {
    migration: null,
    status: null,
  }

  renderLoading(): React.JSX.Element | null {
    // @ts-expect-error - LoadStates is untyped JS module
    if (this.props.status && LoadStates.isLoading(this.props.status)) {
      const title = I18n.t('Loading Change Log')
      return (
        <div className="bcc__change-log__loading" style={{textAlign: 'center'}}>
          <Spinner renderTitle={title} />
          <PresentationContent>
            <Text as="p">{title}</Text>
          </PresentationContent>
        </div>
      )
    }

    return null
  }

  renderChanges(): React.JSX.Element | null {
    const {migration} = this.props
    if (migration) {
      return (
        <SyncHistoryItem
          migration={migration}
          heading={
            <ChangeLogRow
              isHeading={true}
              col1={I18n.t('Learning Object')}
              col2={I18n.t('Object Type')}
              col3={I18n.t('Change Applied')}
              col4={I18n.t('Applied')}
            />
          }
          ChangeComponent={ChangeRow}
        />
      )
    }

    return null
  }

  render(): React.JSX.Element {
    return <div className="bcc__change-log">{this.renderLoading() || this.renderChanges()}</div>
  }
}

const connectState = (state: BlueprintState) => ({
  status: state.selectedChangeLog && state.changeLogs[state.selectedChangeLog]?.status,
  migration: state.selectedChangeLog && state.changeLogs[state.selectedChangeLog]?.data,
})

const connectActions = () => ({})

// @ts-expect-error - Redux connect type inference issue with optional props
export const ConnectedChildChangeLog = connect(connectState, connectActions)(ChildChangeLog)
