/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {Table} from '@instructure/ui-table'
import {ProgressBar} from '@instructure/ui-progress'
import {Tooltip} from '@instructure/ui-tooltip'
import {Link} from '@instructure/ui-link'
import {TruncateText} from '@instructure/ui-truncate-text'
import type {RubricAssessmentImportResponse} from '../queries/Queries'

const I18n = createI18nScope('rubrics-import')

type RubricAssessmentImportTableProps = {
  importsInProgress: RubricAssessmentImportResponse[]
  onClickImport: (rubricImport: RubricAssessmentImportResponse) => void
}

export const RubricAssessmentImportTable = ({
  importsInProgress,
  onClickImport,
}: RubricAssessmentImportTableProps) => {
  const renderSize = (sz: string | number) => {
    const size = Number(sz)
    if (size < 1024) {
      return `${size} bytes`
    } else if (size < 1024 * 1024) {
      return `${Math.round((size / 1024) * 10) / 10} KB`
    } else {
      return `${Math.round((size / (1024 * 1024)) * 10) / 10} MB`
    }
  }

  const showProgressBarStates = ['created', 'importing', 'failed']

  const truncateFilename = (rubricImport: RubricAssessmentImportResponse) => {
    const {filename} = rubricImport.attachment
    return (
      <Tooltip renderTip={filename}>
        <Link href="#" onClick={() => onClickImport(rubricImport)}>
          <TruncateText>{filename}</TruncateText>
        </Link>
      </Tooltip>
    )
  }

  return (
    <Table caption={I18n.t('Table of Imports in Progress')} layout="fixed">
      <Table.Head>
        <Table.Row>
          <Table.ColHeader id="import-name" width="170px">
            {I18n.t('File Name')}
          </Table.ColHeader>
          <Table.ColHeader id="import-size">{I18n.t('Size')}</Table.ColHeader>
        </Table.Row>
      </Table.Head>
      <Table.Body>
        {importsInProgress.map(importInProgress => {
          const {workflowState} = importInProgress
          const progress = workflowState === 'failed' ? 100 : importInProgress.progress
          const meterColor = workflowState === 'failed' ? 'danger' : 'info'

          return (
            <Table.Row key={importInProgress.id}>
              <Table.Cell data-testid={`rubric-import-job-filename-${importInProgress.id}`}>
                {truncateFilename(importInProgress)}
              </Table.Cell>
              {showProgressBarStates.includes(importInProgress.workflowState) ? (
                <Table.Cell>
                  <ProgressBar
                    size="small"
                    screenReaderLabel="Loading completion"
                    valueNow={progress}
                    meterColor={meterColor}
                    valueMax={100}
                  />
                </Table.Cell>
              ) : (
                <Table.Cell data-testid={`rubric-import-job-size-${importInProgress.id}`}>
                  {renderSize(importInProgress.attachment.size)}
                </Table.Cell>
              )}
            </Table.Row>
          )
        })}
      </Table.Body>
    </Table>
  )
}
