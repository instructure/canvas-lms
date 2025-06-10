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
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'

import {useScope as createI18nScope} from '@canvas/i18n'
import {Responsive} from '@instructure/ui-responsive'
import {responsiveQuerySizes} from '@canvas/discussions/react/utils'
import {GlobalEnv} from '@canvas/global/env/GlobalEnv'
import {useManageThreadedRepliesStore} from '../../hooks/useManageThreadedRepliesStore'

const I18n = createI18nScope('discussions_v2')

declare const ENV: GlobalEnv & {
  AMOUNT_OF_SIDE_COMMENT_DISCUSSIONS?: string
}

interface ManageThreadedRepliesAlertProps {
  onOpen: () => void
}

const ManageThreadedRepliesAlert: React.FC<ManageThreadedRepliesAlertProps> = ({onOpen}) => {
  const count = ENV?.AMOUNT_OF_SIDE_COMMENT_DISCUSSIONS || 0
  const showAlert = useManageThreadedRepliesStore(state => state.showAlert)

  if (!count) {
    return null
  }

  const alertTitle = I18n.t(
    {
      one: 'You have *%{count} decision* to make',
      other: 'You have *%{count} decisions* to make',
    },
    {
      count,
      wrappers: [`<strong>$1</strong>`],
    },
  )

  const linkHref =
    'https://community.canvaslms.com/t5/The-Product-Blog/Temporary-button-to-uncheck-the-Disallow-Threaded-Replies-option/ba-p/615349'
  const alertText = I18n.t(
    'Following the *issue* related to disallowing threaded replies, we now provide a quick and easy way to update and manage all your discussions to allow or disallow threaded replies.',
    {
      wrappers: [`<a target="_blank" href="${linkHref}">$1</a>`],
    },
  )

  return (
    <Alert variant="warning" margin="mediumSmall 0" open={showAlert}>
      <Flex gap="x-small" direction="column">
        <Text dangerouslySetInnerHTML={{__html: alertTitle}} />
        <Text dangerouslySetInnerHTML={{__html: alertText}} />
        <Responsive
          match="media"
          query={{...responsiveQuerySizes({mobile: true, desktop: true})}}
          props={{
            mobile: {display: 'block'},
            desktop: {display: 'unset'},
          }}
          render={matchProps => (
            <Flex justifyItems="end">
              <Button
                id="manage-threaded-discussions"
                data-testid="manage-threaded-discussions"
                color="primary"
                display={matchProps?.display}
                onClick={onOpen}
              >
                {I18n.t('Manage Discussions')}
              </Button>
            </Flex>
          )}
        />
      </Flex>
    </Alert>
  )
}

export default ManageThreadedRepliesAlert
