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
import {useScope as createI18nScope} from '@canvas/i18n'

import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import LoadingWrapper from './LoadingWrapper'
import LoadingSkeleton from './LoadingSkeleton'

import ImportantInfo, {ImportantInfoData, ImportantInfoEditHeader} from './ImportantInfo'

const I18n = createI18nScope('important_info_announcement')

interface ImportantInfoLayoutProps {
  isLoading: boolean
  importantInfos: ImportantInfoData[]
  courseId?: string
}

const ImportantInfoLayout: React.FC<ImportantInfoLayoutProps> = ({
  isLoading,
  importantInfos,
  courseId,
}) => {
  const sectionHeading = <Heading level="h2">{I18n.t('Important Info')}</Heading>

  const renderImportantInfoLoadingContainer = (skeletons: React.ReactNode[]) => (
    <div>
      {skeletons.length > 0 && (
        <LoadingSkeleton
          screenReaderLabel={I18n.t('Loading section header')}
          height="1.75rem"
          width="9rem"
          margin="medium 0 0"
        />
      )}
      {skeletons}
    </div>
  )

  return (
    <LoadingWrapper
      id={`important-info-${courseId || 'dashboard'}`}
      isLoading={isLoading}
      skeletonsNum={importantInfos?.length}
      screenReaderLabel={I18n.t('Loading important info')}
      renderSkeletonsContainer={renderImportantInfoLoadingContainer}
      height="8em"
      width="100%"
      margin="medium 0 0"
    >
      {importantInfos.length > 0 &&
        (importantInfos.length === 1 ? (
          <ImportantInfoEditHeader margin="medium 0 0" {...importantInfos[0]}>
            {sectionHeading}
          </ImportantInfoEditHeader>
        ) : (
          <View as="div" margin="medium 0 0">
            {sectionHeading}
          </View>
        ))}
      {importantInfos?.map((info, i) => (
        <ImportantInfo
          key={`important-info-${info.courseId}`}
          showTitle={importantInfos.length > 1}
          titleMargin={i === 0 ? 'small 0 0' : 'medium 0 0'}
          infoDetails={info}
        />
      ))}
    </LoadingWrapper>
  )
}

export default ImportantInfoLayout
