/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import I18n from 'i18n!AccounntsTray'
import React from 'react'
import {bool, arrayOf, shape, string} from 'prop-types'
import {View} from '@instructure/ui-view'
import {List} from '@instructure/ui-list'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Link} from '@instructure/ui-link'

export default function AccountsTray({accounts, hasLoaded}) {
  return (
    <View as="div" padding="medium">
      <Heading level="h3" as="h2">
        {I18n.t('Admin')}
      </Heading>
      <hr role="presentation" />
      <List variant="unstyled" margin="small 0" itemSpacing="small">
        {hasLoaded ? (
          accounts
            .map(account => (
              <List.Item key={account.id}>
                <Link isWithinText={false} href={`/accounts/${account.id}`}>
                  {account.name}
                </Link>
              </List.Item>
            ))
            .concat([
              <List.Item key="hr">
                <hr role="presentation" />
              </List.Item>,
              <List.Item key="all">
                <Link isWithinText={false} href="/accounts">
                  {I18n.t('All Accounts')}
                </Link>
              </List.Item>
            ])
        ) : (
          <List.Item>
            <Spinner size="small" renderTitle={I18n.t('Loading')} />
          </List.Item>
        )}
      </List>
    </View>
  )
}

AccountsTray.propTypes = {
  accounts: arrayOf(
    shape({
      id: string.isRequired,
      name: string.isRequired
    })
  ).isRequired,
  hasLoaded: bool.isRequired
}

AccountsTray.defaultProps = {
  accounts: []
}
