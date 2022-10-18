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

import React from 'react'
import PropTypes from 'prop-types'
import formatMessage from '../../../../format-message'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'

const CONTENT_OPTIONS = [
  {
    display: formatMessage('Choose usage rights...'),
    value: 'choose',
  },
  {
    display: formatMessage('I hold the copyright'),
    value: 'own_copyright',
  },
  {
    display: formatMessage('I have obtained permission to use this file.'),
    value: 'used_by_permission',
  },
  {
    display: formatMessage('The material is in the public domain'),
    value: 'public_domain',
  },
  {
    display: formatMessage(
      'The material is subject to an exception - e.g. fair use, the right to quote, or others under applicable copyright laws'
    ),
    value: 'fair_use',
  },
  {
    display: formatMessage('The material is licensed under Creative Commons'),
    value: 'creative_commons',
  },
]

const ShowCreativeCommonsOptions = ({ccLicense, setCCLicense, licenseOptions}) => {
  const onlyCC = licenseOptions.filter(license => license.id.indexOf('cc') === 0)

  return (
    <View as="div" margin="medium 0">
      <SimpleSelect
        renderLabel={formatMessage('Creative Commons License:')}
        assistiveText={formatMessage('Use arrow keys to navigate options.')}
        value={ccLicense}
        onChange={(e, {id}) => setCCLicense(id)}
      >
        {onlyCC.map(license => (
          <SimpleSelect.Option key={license.id} id={license.id} value={license.id}>
            {license.name}
          </SimpleSelect.Option>
        ))}
      </SimpleSelect>
    </View>
  )
}

const ShowMessage = () => {
  return (
    <div className="alert">
      <span>
        <i className="icon-warning" />
        <span style={{paddingLeft: '10px'}}>
          {formatMessage(
            "If you do not select usage rights now, this file will be unpublished after it's uploaded."
          )}
        </span>
      </span>
    </div>
  )
}

const UsageRightsSelectBox = ({
  contextType,
  contextId,
  showMessage: showMessageProp,
  usageRightsState,
  setUsageRightsState,
}) => {
  const {usageRight, ccLicense, copyrightHolder} = usageRightsState
  const showCreativeCommonsOptions = usageRight === 'creative_commons'
  const [licenseOptions, setLicenseOptions] = React.useState([])
  const [showMessage, setShowMessage] = React.useState(showMessageProp)
  React.useEffect(() => {
    function getUsageRightsOptions() {
      fetch(apiUrl())
        .then(res => res.text())
        .then(res => setLicenseOptions(JSON.parse(res)))
        .catch(() => {})
    }

    function apiUrl() {
      const context = contextType.replace(/([^s])$/, '$1s') // pluralize
      return `/api/v1/${context}/${contextId}/content_licenses`
    }
    getUsageRightsOptions()
  }, [contextType, contextId])

  function handleChange(value) {
    setUsageRightsState(state => ({...state, usageRight: value}))
    setShowMessage(showMessageProp && value === 'choose')
  }

  return (
    <View as="div">
      <View as="div" margin="medium 0">
        <SimpleSelect
          renderLabel={formatMessage('Usage Right:')}
          assistiveText={formatMessage('Use arrow keys to navigate options.')}
          onChange={(e, {id}) => {
            handleChange(id)
          }}
          value={usageRight}
        >
          {CONTENT_OPTIONS.map(contentOption => (
            <SimpleSelect.Option
              key={contentOption.value}
              id={contentOption.value}
              value={contentOption.value}
            >
              {contentOption.display}
            </SimpleSelect.Option>
          ))}
        </SimpleSelect>
      </View>

      {showCreativeCommonsOptions && (
        <ShowCreativeCommonsOptions
          ccLicese={ccLicense}
          setCCLicense={license => setUsageRightsState(state => ({...state, ccLicense: license}))}
          licenseOptions={licenseOptions}
        />
      )}
      <View as="div" margin="medium 0">
        <TextInput
          renderLabel={formatMessage('Copyright Holder:')}
          value={copyrightHolder}
          onChange={(e, value) =>
            setUsageRightsState(state => ({...state, copyrightHolder: value}))
          }
          placeholder={formatMessage('(c) 2001 Acme Inc.')}
        />
      </View>
      <View as="div" margin="medium 0">
        {showMessage && <ShowMessage />}
      </View>
    </View>
  )
}

UsageRightsSelectBox.propTypes = {
  usageRightsState: PropTypes.shape({
    ccLicense: PropTypes.string,
    usageRight: PropTypes.oneOf(Object.values(CONTENT_OPTIONS).map(o => o.value)),
    copyrightHolder: PropTypes.string,
  }),
  setUsageRightsState: PropTypes.func,
  showMessage: PropTypes.bool,
  contextType: PropTypes.string,
  contextId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
}

export default UsageRightsSelectBox
