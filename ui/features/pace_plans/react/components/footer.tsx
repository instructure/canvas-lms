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
import {connect} from 'react-redux'
// @ts-ignore: TS doesn't understand i18n scoped imports
import I18n from 'i18n!pace_plans_footer'

import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'

import {StoreState} from '../types'
import {getAutoSaving, getPlanPublishing, getShowLoadingOverlay} from '../reducers/ui'
import {pacePlanActions} from '../actions/pace_plans'
import {getUnpublishedChangeCount} from '../reducers/pace_plans'

interface StoreProps {
  readonly autoSaving: boolean
  readonly planPublishing: boolean
  readonly showLoadingOverlay: boolean
  readonly unpublishedChanges: boolean
}

interface DispatchProps {
  publishPlan: typeof pacePlanActions.publishPlan
  resetPlan: typeof pacePlanActions.resetPlan
}

type ComponentProps = StoreProps & DispatchProps

export const Footer: React.FC<ComponentProps> = ({
  autoSaving,
  planPublishing,
  publishPlan,
  resetPlan,
  showLoadingOverlay,
  unpublishedChanges
}) => {
  const disabled = autoSaving || planPublishing || showLoadingOverlay || !unpublishedChanges
  // This wrapper div attempts to roughly match the dimensions of the publish button
  const publishLabel = planPublishing ? (
    <div style={{display: 'inline-block', margin: '-0.5rem 0.9rem'}}>
      <Spinner size="x-small" renderTitle={I18n.t('Publishing plan...')} />
    </div>
  ) : (
    I18n.t('Publish')
  )
  return (
    <Flex as="section" justifyItems="end">
      <Button
        color="secondary"
        interaction={disabled ? 'disabled' : 'enabled'}
        onClick={resetPlan}
        margin="0 small 0"
      >
        {I18n.t('Cancel')}
      </Button>
      <Button color="primary" interaction={disabled ? 'disabled' : 'enabled'} onClick={publishPlan}>
        {publishLabel}
      </Button>
    </Flex>
  )
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    autoSaving: getAutoSaving(state),
    planPublishing: getPlanPublishing(state),
    showLoadingOverlay: getShowLoadingOverlay(state),
    unpublishedChanges: getUnpublishedChangeCount(state) !== 0
  }
}

export default connect(mapStateToProps, {
  publishPlan: pacePlanActions.publishPlan,
  resetPlan: pacePlanActions.resetPlan
})(Footer)
