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
import PropTypes from 'prop-types'

import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'

import SpacePandaUrl from '@canvas/images/SpacePanda.svg'

const I18n = useI18nScope('empty_course')

export default function EmptyCourse({canManage, name, id}) {
  return (
    <Flex
      as="div"
      height="45vh"
      direction="column"
      alignItems="center"
      justifyItems="center"
      margin="x-large large"
    >
      <Img src={SpacePandaUrl} margin="0 0 x-large 0" data-testid="space-panda" />
      <Text size="large">{I18n.t('Welcome to the cold, dark void of %{name}.', {name})}</Text>
      <Text size="medium">{I18n.t('All subject navigation has been disabled.')}</Text>
      {canManage && (
        <Button href={`/courses/${id}/settings#tab-navigation`} margin="medium 0 0 0">
          {I18n.t('Reestablish your world')}
        </Button>
      )}
    </Flex>
  )
}

EmptyCourse.propTypes = {
  name: PropTypes.string.isRequired,
  id: PropTypes.string.isRequired,
  canManage: PropTypes.bool.isRequired,
}
