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

import {Flex} from '@instructure/ui-flex'
import DefaultAccountQuotas from './DefaultAccountQuotas'
import ManuallySettableQuotas from './ManuallySettableQuotas'
import {AccountWithQuotas} from './common'
import {lazy, Suspense} from 'react'
import extensions from '@canvas/bundles/extensions'

type Extensions = {
  [key: string]: any
}

const SiteAdminQuotas = lazy(async () => {
  const extension = (extensions as Extensions)['ui/features/account_settings/index.jsx']
  const EmptyComponent = () => <></>

  if (extension) {
    try {
      return await extension()
    } catch (error) {
      console.error('Failed to load extension for ui/features/account_settings/index.jsx', error)
      return {default: EmptyComponent}
    }
  } else {
    return {default: EmptyComponent}
  }
})

interface QuotasTabContentProps {
  accountWithQuotas: AccountWithQuotas
}

const QuotasTabContent = ({accountWithQuotas}: QuotasTabContentProps) => {
  return (
    <Flex as="section" direction="column" gap="large" margin="medium 0 0 0" width={500}>
      <DefaultAccountQuotas accountWithQuotas={accountWithQuotas} />
      <Suspense>
        <SiteAdminQuotas />
      </Suspense>
      <ManuallySettableQuotas />
    </Flex>
  )
}

export default QuotasTabContent
