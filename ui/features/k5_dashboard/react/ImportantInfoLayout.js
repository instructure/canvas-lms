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
import I18n from 'i18n!k5_dashboard_ImportantInfoLayout'
import PropTypes from 'prop-types'

import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'

import ImportantInfo, {
  ImportantInfoShape,
  ImportantInfoEditHeader
} from '@canvas/k5/react/ImportantInfo'

const ImportantInfoLayout = ({isLoading, importantInfos}) => {
  const sectionHeading = <Heading level="h2">{I18n.t('Important Info')}</Heading>

  return (
    <>
      {(isLoading || importantInfos.length > 0) &&
        (importantInfos.length === 1 ? (
          <ImportantInfoEditHeader margin="medium 0 0" {...importantInfos[0]}>
            {sectionHeading}
          </ImportantInfoEditHeader>
        ) : (
          <View as="div" margin="medium 0 0">
            {sectionHeading}
          </View>
        ))}

      {isLoading ? (
        <ImportantInfo isLoading />
      ) : (
        importantInfos.map((info, i) => (
          <ImportantInfo
            key={`important-info-${info.courseId}`}
            isLoading={false}
            showTitle={importantInfos.length > 1}
            titleMargin={i === 0 ? 'small 0 0' : 'medium 0 0'}
            infoDetails={info}
          />
        ))
      )}
    </>
  )
}

ImportantInfoLayout.propTypes = {
  isLoading: PropTypes.bool.isRequired,
  importantInfos: PropTypes.arrayOf(PropTypes.shape(ImportantInfoShape)).isRequired
}

export default ImportantInfoLayout
