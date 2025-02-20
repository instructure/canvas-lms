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

import {HorizonToggle} from './HorizonToggle'
import {HorizonEnabled} from './HorizonEnabled'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Button} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {assignLocation} from '@canvas/util/globalUtils'

const I18n = createI18nScope('horizon_toggle_page')

export const Main = () => {
  const isHorizonCourse = window.ENV?.horizon_course
  const handlePreview = () => {
    assignLocation(`/courses/${ENV.COURSE_ID}/student_view?preview=true`)
  }

  return (
    <View as="div">
      <Flex margin="medium 0 small 0" justifyItems="space-between">
        <Heading level="h2">{I18n.t('Switch Learner Experience to Canvas Career')}</Heading>
        <Button onClick={handlePreview}>{I18n.t('Learner Preview')}</Button>
      </Flex>
      {isHorizonCourse ? <HorizonEnabled /> : <HorizonToggle />}
    </View>
  )
}
