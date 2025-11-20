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

import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useResubmitDiscussionNotices} from '../../dependenciesShims'
import {
  type ResubmitDiscussionNoticesParams,
  resubmitDiscussionNoticesPath,
} from '../mutations/resubmitDiscussionNotices'

const I18n = createI18nScope('lti_asset_processor')

interface Props extends ResubmitDiscussionNoticesParams {
  size: 'small' | 'medium'
}

export function ResubmitDiscussionNoticesButton(props: Props): JSX.Element {
  const resubmitMutation = useResubmitDiscussionNotices()

  const pendingOrAlreadyDone =
    !resubmitMutation.isIdle &&
    !resubmitMutation.isError &&
    resubmitMutation.variables &&
    resubmitDiscussionNoticesPath(resubmitMutation.variables) ===
      resubmitDiscussionNoticesPath(props)

  return (
    <Flex.Item>
      <Button
        id="asset-processor-resubmit-discussion-notices"
        size={props.size}
        disabled={pendingOrAlreadyDone}
        onClick={() => {
          resubmitMutation.mutate(props)
        }}
        data-pendo={`asset-reports-resubmit-all-replies-button-${props.size}`}
      >
        {I18n.t('Resubmit All Replies')}
      </Button>
    </Flex.Item>
  )
}
