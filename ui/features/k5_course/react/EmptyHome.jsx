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
import {useScope as useI18nScope} from '@canvas/i18n'

import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import PropTypes from 'prop-types'

import emptyHomeUrl from '../images/empty-home.svg'

const I18n = useI18nScope('empty_home')

const EmptyHome = ({pagesPath, hasWikiPages, courseName, canManage}) => (
  <Flex
    as="div"
    direction="column"
    alignItems="center"
    textAlign="center"
    height="50vh"
    justifyItems="center"
    margin="x-large large"
  >
    <Img src={emptyHomeUrl} data-testid="empty-home-panda" />
    <View width="25rem" margin="x-large none small none">
      <Text size="large">{I18n.t('This is where you’ll land when your home is complete.')}</Text>
    </View>
    {canManage && (
      <Button
        id="k5-manage-home-btn"
        data-testid="manage-home-button"
        href={hasWikiPages ? pagesPath : `${pagesPath}/home`}
      >
        <AccessibleContent alt={I18n.t('Manage home for %{courseName}', {courseName})}>
          {I18n.t('Manage Home')}
        </AccessibleContent>
      </Button>
    )}
  </Flex>
)

EmptyHome.propTypes = {
  pagesPath: PropTypes.string.isRequired,
  hasWikiPages: PropTypes.bool.isRequired,
  canManage: PropTypes.bool.isRequired,
  courseName: PropTypes.string.isRequired,
}
export default EmptyHome
