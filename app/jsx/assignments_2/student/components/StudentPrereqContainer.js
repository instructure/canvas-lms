/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import I18n from 'i18n!assignments_2'
import React from 'react'

import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'

import locked1SVG from '../../../../../public/images/assignments_2/Locked1.svg'
import StudentPrereq from './StudentPrereq'

// NOTE: We can easily move this dependency to Graphql one day
function StudentConditionalPrereq() {
  if (ENV && ENV.PREREQS && ENV.PREREQS.items && ENV.PREREQS.items.length === 0) {
    return
  }
  const preReqItem = ENV.PREREQS.items[0] && ENV.PREREQS.items[0].prev
  return <StudentPrereq preReqTitle={preReqItem.title} preReqLink={preReqItem.html_url} />
}

function StudentPrereqContainer() {
  return (
    <Flex textAlign="center" justifyItems="center" margin="0 0 large" direction="column">
      <FlexItem>
        <img alt={I18n.t('Assignment Locked with Prerequisite')} src={locked1SVG} />
      </FlexItem>
      {StudentConditionalPrereq()}
    </Flex>
  )
}

StudentPrereqContainer.propTypes = {}

export default React.memo(StudentPrereqContainer)
