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
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'

import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {TextInput} from '@instructure/ui-text-input'
import {Heading} from '@instructure/ui-heading'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {
  IconFilesCopyrightSolid,
  IconFilesPublicDomainSolid,
  IconFilesObtainedPermissionSolid,
  IconFilesFairUseSolid,
  IconFilesCreativeCommonsSolid,
  IconWarningLine,
} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'

const I18n = useI18nScope('discussion_create')

const CONTENT_OPTIONS = [
  {
    display: I18n.t('Choose usage rights...'),
    value: 'choose',
  },
  {
    display: I18n.t('I hold the copyright'),
    value: 'own_copyright',
  },
  {
    display: I18n.t('I have obtained permission to use this file.'),
    value: 'used_by_permission',
  },
  {
    display: I18n.t('The material is in the public domain'),
    value: 'public_domain',
  },
  {
    display: I18n.t(
      'The material is subject to an exception - e.g. fair use, the right to quote, or others under applicable copyright laws'
    ),
    value: 'fair_use',
  },
  {
    display: I18n.t('The material is licensed under Creative Commons'),
    value: 'creative_commons',
  },
]

export const UsageRights = ({
  contextType,
  contextId,
  basicFileSystemData,
  onSaveUsageRights,
  isOpen,
  currentUsageRights,
}) => {
  const [open, setOpen] = useState(isOpen)
  // The value of the Copyright Holder input
  const [copyrightHolder, setCopyrightHolder] = useState(currentUsageRights?.copyrightHolder || '')
  // Usage Right selection
  const [selectedUsageRightsOption, setSelectedUsageRightsOption] = useState(
    currentUsageRights?.selectedUsageRightsOption
  )
  // Selected Creative Commons License:
  const [selectedCreativeLicense, setSelectedCreativeLicense] = useState(
    currentUsageRights?.selectedCreativeLicense
  )
  // Will be used as selectable options for the creative Commons Licenses
  const [ccLicenseOptions, setCCLicenseOptions] = useState([])

  // New state to save the initial values when the modal opens
  const [initialValues, setInitialValues] = useState({
    copyrightHolder: currentUsageRights?.copyrightHolder,
    selectedUsageRightsOption: currentUsageRights?.selectedUsageRightsOption,
    selectedCreativeLicense: currentUsageRights?.selectedCreativeLicense,
  })

  const saveAsInitial = () => {
    setInitialValues({
      copyrightHolder,
      selectedUsageRightsOption,
      selectedCreativeLicense,
    })
  }

  const revertToInitial = () => {
    setCopyrightHolder(initialValues.copyrightHolder)
    setSelectedUsageRightsOption(initialValues.selectedUsageRightsOption)
    setSelectedCreativeLicense(initialValues.selectedCreativeLicense)
  }

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
    if (open && ccLicenseOptions.length === 0) {
      getCreativeCommonsOptions()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, ccLicenseOptions])

  const handleSelect = (e, {value}) => {
    const newSelectedOption = CONTENT_OPTIONS.find(opt => opt?.value === value)
    if (newSelectedOption) {
      setSelectedUsageRightsOption(newSelectedOption)
    }
  }

  const handleCreativeSelect = (e, {value}) => {
    const newSelectedOption = ccLicenseOptions.find(opt => opt.id === value)
    if (newSelectedOption) {
      setSelectedCreativeLicense(newSelectedOption)
    }
  }

  const toggleModal = () => {
    if (!open) {
      saveAsInitial() // Save initial values when the modal is opening
    } else {
      revertToInitial() // Revert to the last saved initial state when modal is closing
    }
    setOpen(!open)
  }

  const handleSaveClick = e => {
    e.preventDefault()
    saveAsInitial()
    const newUsageRightsState = {
      selectedUsageRightsOption,
      copyrightHolder,
      basicFileSystemData,
    }
    if (selectedCreativeLicense) {
      newUsageRightsState.selectedCreativeLicense = selectedCreativeLicense
    }
    // Send current state to the parent component onSave
    onSaveUsageRights(newUsageRightsState)
    setOpen(false)
  }

  const handleCancelClick = e => {
    e.preventDefault()
    revertToInitial()
    setOpen(false)
  }

  const handleModalClose = () => {
    revertToInitial()
  }

  const renderCloseButton = () => {
    return (
      <CloseButton
        placement="end"
        offset="small"
        onClick={toggleModal}
        screenReaderLabel={I18n.t('Close')}
      />
    )
  }

  const renderCorrectIcon = () => {
    switch (selectedUsageRightsOption?.value) {
      case 'own_copyright':
        return <IconFilesCopyrightSolid />
      case 'public_domain':
        return <IconFilesPublicDomainSolid />
      case 'used_by_permission':
        return <IconFilesObtainedPermissionSolid />
      case 'fair_use':
        return <IconFilesFairUseSolid />
      case 'creative_commons':
        return <IconFilesCreativeCommonsSolid />
      default:
        return <IconWarningLine />
    }
  }

  return (
    <div>
      <Tooltip renderTip={I18n.t('Manage Usage Rights')} on={['hover', 'focus']} placement="bottom">
        <IconButton
          onClick={toggleModal}
          withBackground={false}
          withBorder={false}
          color="primary"
          screenReaderLabel={I18n.t('Manage Usage Rights')}
          data-testid="usage-rights-icon"
        >
          {renderCorrectIcon()}
        </IconButton>
      </Tooltip>
      <Modal
        as="form"
        open={open}
        onDismiss={() => {
          handleModalClose()
          setOpen(false)
        }}
        size="auto"
        label={I18n.t('Usage Rights')}
        shouldCloseOnDocumentClick={true}
      >
        <Modal.Header>
          {renderCloseButton()}
          <Heading>{I18n.t('Manage Usage Rights')}</Heading>
        </Modal.Header>
        <Modal.Body>
          <FormFieldGroup description="" rowSpacing="small">
            <SimpleSelect
              renderLabel={I18n.t('Usage Right:')}
              assistiveText={I18n.t('Use arrow keys to navigate options.')}
              value={selectedUsageRightsOption?.value}
              onChange={handleSelect}
              data-testid="usage-select"
            >
              {CONTENT_OPTIONS.map(opt => (
                <SimpleSelect.Option
                  key={opt?.value}
                  id={`opt-${opt?.value}`}
                  value={opt?.value}
                  data-testid="usage-rights-option"
                >
                  {opt.display}
                </SimpleSelect.Option>
              ))}
            </SimpleSelect>

            {selectedUsageRightsOption?.value === 'creative_commons' && (
              <SimpleSelect
                renderLabel={I18n.t('Creative Commons License:')}
                assistiveText={I18n.t('Use arrow keys to navigate options.')}
                value={selectedCreativeLicense?.id}
                onChange={handleCreativeSelect}
              >
                {ccLicenseOptions.map(opt => (
                  <SimpleSelect.Option key={opt.id} id={`opt-${opt.id}`} value={opt.id}>
                    {opt.name}
                  </SimpleSelect.Option>
                ))}
              </SimpleSelect>
            )}
            <TextInput
              renderLabel={I18n.t('Copyright Holder')}
              placeholder={I18n.t('(c) 2001 Acme Inc.')}
              value={copyrightHolder}
              onChange={e => setCopyrightHolder(e.target.value)}
            />
          </FormFieldGroup>
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={handleCancelClick} margin="0 x-small 0 0">
            {I18n.t('Cancel')}
          </Button>
          <Button color="primary" type="button" onClick={handleSaveClick}>
            {I18n.t('Save')}
          </Button>
        </Modal.Footer>
      </Modal>
    </div>
  )
}

UsageRights.propTypes = {
  contextType: PropTypes.string.isRequired, // used to fetch the available cc content_licenses
  contextId: PropTypes.string.isRequired, // used to fetch the available cc content_licenses
  basicFileSystemData: PropTypes.arrayOf(PropTypes.object), // represents the files or folder's who's usage rights object is being updated
  onSaveUsageRights: PropTypes.func, // When the user clicks save, this function is called with the new usage rights object
  currentUsageRights: PropTypes.object, // passes in the initial usage rights modal state
  isOpen: PropTypes.bool, // can be used to open the modal
}

UsageRights.defaultProps = {
  contextType: '',
  contextId: '',
  basicFileSystemData: [],
  onSaveUsageRights: () => {},
  isOpen: false,
}
