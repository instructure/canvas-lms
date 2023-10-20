/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import {Link} from '@instructure/ui-link'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = useI18nScope('external_tools')

const Header = React.forwardRef(({children}, ref) => (
  <View as="header" margin="small none">
    <Flex>
      <Flex.Item shouldGrow={true}>
        <Heading margin="none">{I18n.t('External Apps')}</Heading>
      </Flex.Item>
      <Flex.Item align="end">{children}</Flex.Item>
    </Flex>
    <hr aria-hidden="true" style={{marginTop: '8px'}} />
    <p>
      {I18n.t(
        'Apps are an easy way to add new features to Canvas. They can be added to individual courses, or to all courses in an account. Once configured, you can link to them through course modules and create assignments for assessment tools.'
      )}
    </p>
    <p>
      <Link ref={ref} href="https://www.eduappcenter.com/">
        <ScreenReaderContent>{I18n.t('Link to lti tools.')}</ScreenReaderContent>
        {I18n.t('See some LTI tools that work great with Canvas.')}
      </Link>
    </p>
  </View>
))

export default Header
