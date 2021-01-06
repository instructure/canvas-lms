/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {Button} from '@instructure/ui-buttons'
import {IconImportLine, IconPlusSolid, IconSearchLine} from '@instructure/ui-icons'
import I18n from 'i18n!OutcomeManagement'
import React from 'react'
import {showImportOutcomesModal} from './ImportOutcomesModal'

const ManagementHeader = () => {
  const noop = () => {}

  return (
    <div className="management-header" data-testid="managementHeader">
      <div>
        <h2 className="title">{I18n.t('Outcomes')}</h2>
      </div>

      <div>
        <Button onClick={showImportOutcomesModal} renderIcon={IconImportLine} margin="x-small">
          {I18n.t('Import')}
        </Button>
        <Button onClick={noop} renderIcon={IconPlusSolid} margin="x-small">
          {I18n.t('Create')}
        </Button>
        <Button onClick={noop} renderIcon={IconSearchLine} margin="x-small">
          {I18n.t('Find')}
        </Button>
      </div>
    </div>
  )
}

export default ManagementHeader
