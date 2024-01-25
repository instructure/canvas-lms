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

import React, {useRef, useEffect, useState} from 'react'
import PropTypes from 'prop-types'
import {Button} from '@instructure/ui-buttons'
import {CSVLink} from 'react-csv'
import {IconExportLine} from '@instructure/ui-icons'
import useCSVExport, {EXPORT_COMPLETE, EXPORT_FAILED, EXPORT_PENDING} from './hooks/useCSVExport'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('learning_mastery_gradebook')

const ExportCSVButton = ({courseId, gradebookFilters}) => {
  const csvElementRef = useRef(null)
  const exportCSV = () => csvElementRef.current?.click()

  const {exportGradebook, exportState, exportData} = useCSVExport({courseId, gradebookFilters})
  const [interaction, setInteraction] = useState('enabled')

  const onButtonClick = () => {
    setInteraction('disabled')
    exportGradebook()
  }

  useEffect(() => {
    if (exportState === EXPORT_COMPLETE) {
      exportCSV()
      setInteraction('enabled')
    } else if (exportState === EXPORT_FAILED) {
      setInteraction('enabled')
    }
  }, [exportState])

  return (
    <>
      <Button
        renderIcon={IconExportLine}
        onClick={onButtonClick}
        interaction={interaction}
        data-testid="export-button"
      >
        {exportState === EXPORT_PENDING ? I18n.t('Exporting') : I18n.t('Export')}
      </Button>
      <CSVLink
        data={exportData}
        filename={`course-${courseId}-gradebook-export.csv`}
        data-testid="csv-link"
      >
        <span ref={csvElementRef}/>
      </CSVLink>
    </>
  )
}

ExportCSVButton.propTypes = {
  courseId: PropTypes.string.isRequired,
  gradebookFilters: PropTypes.arrayOf(PropTypes.string),
}

export default ExportCSVButton
