/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useState, useEffect, useContext} from 'react'
import PropTypes from 'prop-types'
import {UsageRights} from '../../components/DiscussionOptions/UsageRights'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {defaultUsageRights} from '../../util/usageRightsConstants'

export const UsageRightsContainer = ({
  contextType,
  contextId,
  onSaveUsageRights,
  initialUsageRights,
  errorState,
}) => {
  // Will be used as selectable options for the creative Commons Licenses
  const [ccLicenseOptions, setCCLicenseOptions] = useState([])

  const {setOnFailure} = useContext(AlertManagerContext)

  // Retrieve the content_licenses that are selected for a given context
  const getCreativeCommonsOptions = async () => {
    try {
      const pluralized_contextType = contextType.replace(/([^s])$/, '$1s')
      const res = await fetch(`/api/v1/${pluralized_contextType}/${contextId}/content_licenses`)
      let ccData = await res.json()
      ccData = ccData.filter(obj => obj.id.startsWith('cc'))

      setCCLicenseOptions(ccData)
    } catch (error) {
      setOnFailure(error)
    }
  }

  // Logic to prevent the content_license from being fetched multiple times
  useEffect(() => {
    if (ccLicenseOptions.length === 0) {
      getCreativeCommonsOptions()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [ccLicenseOptions])

  return (
    <UsageRights
      onSaveUsageRights={onSaveUsageRights}
      initialUsageRights={initialUsageRights}
      errorState={errorState}
      creativeCommonsOptions={ccLicenseOptions}
      usageRightsOptions={defaultUsageRights}
    />
  )
}

UsageRightsContainer.propTypes = {
  contextType: PropTypes.string.isRequired, // used to fetch the available cc content_licenses
  contextId: PropTypes.string.isRequired, // used to fetch the available cc content_licenses
  onSaveUsageRights: PropTypes.func, // When the user clicks save, this function is called with the new usage rights object
  initialUsageRights: PropTypes.shape({
    legalCopyright: PropTypes.string,
    license: PropTypes.string,
    useJustification: PropTypes.string,
  }),
  errorState: PropTypes.bool, // can be used to show an error state
}

UsageRightsContainer.defaultProps = {
  contextType: '',
  contextId: '',
  onSaveUsageRights: () => {},
  errorState: false,
}
