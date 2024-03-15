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

import React, {useEffect, useState, useCallback} from 'react'
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

const I18n = useI18nScope('discussion_create')

export const UsageRights = ({
  onSaveUsageRights,
  isOpen,
  initialUsageRights,
  errorState,
  usageRightsOptions,
  creativeCommonsOptions,
}) => {
  const [open, setOpen] = useState(isOpen)
  // These are the realtime values used in the modal.
  // If the save button is not pressed, these values are lost
  const [copyrightHolder, setCopyrightHolder] = useState('')
  const [selectedUsageRightsOption, setSelectedUsageRightsOption] = useState()
  const [selectedCreativeLicense, setSelectedCreativeLicense] = useState()

  const findUsageRightsOption = useCallback(
    useJustification => {
      return usageRightsOptions.find(opt => opt.value === useJustification) || null
    },
    [usageRightsOptions]
  )

  const findCreativeLicenseOption = useCallback(
    license => {
      return creativeCommonsOptions.find(opt => opt.id === license) || null
    },
    [creativeCommonsOptions]
  )

  // Set Initial values
  useEffect(() => {
    setCopyrightHolder(initialUsageRights?.legalCopyright || '')
    setSelectedUsageRightsOption(findUsageRightsOption(initialUsageRights?.useJustification))
    setSelectedCreativeLicense(findCreativeLicenseOption(initialUsageRights?.license))
  }, [findCreativeLicenseOption, findUsageRightsOption, initialUsageRights])

  const revertToInitialValues = () => {
    setCopyrightHolder(initialUsageRights?.legalCopyright || '')
    setSelectedUsageRightsOption(
      usageRightsOptions.find(opt => opt.value === initialUsageRights?.useJustification) || null
    )
    setSelectedCreativeLicense(
      creativeCommonsOptions.find(opt => opt.id === initialUsageRights?.license) || null
    )
  }

  const handleSelect = (e, {value}) => {
    const newSelectedOption = findUsageRightsOption(value)
    if (newSelectedOption) {
      setSelectedUsageRightsOption(newSelectedOption)
    }
  }

  const handleCreativeSelect = (e, {value}) => {
    const newSelectedOption = findCreativeLicenseOption(value)
    if (newSelectedOption) {
      setSelectedCreativeLicense(newSelectedOption)
    }
  }

  const toggleModal = () => {
    if (open) {
      revertToInitialValues()
    }
    setOpen(!open)
  }

  const handleSaveClick = e => {
    e.preventDefault()

    const newUsageRightsState = {
      legalCopyright: copyrightHolder,
      useJustification: selectedUsageRightsOption.value,
    }
    // We only send the license information if the selected usage right is creative commons
    if (selectedUsageRightsOption?.value === 'creative_commons') {
      newUsageRightsState.license = selectedCreativeLicense?.id || 'cc_by'
    }

    // Send current state to the parent component onSave
    onSaveUsageRights(newUsageRightsState)
    setOpen(false)
  }

  const handleCancelClick = e => {
    e.preventDefault()
    revertToInitialValues()
    setOpen(false)
  }

  const handleModalClose = () => {
    revertToInitialValues()
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
          withBorder={errorState}
          color={errorState ? 'danger' : 'primary'}
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
              {usageRightsOptions.map(opt => (
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
                data-testid="cc-license-select"
              >
                {creativeCommonsOptions.map(opt => (
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
              data-testid="legal-copyright"
            />
          </FormFieldGroup>
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={handleCancelClick} margin="0 x-small 0 0">
            {I18n.t('Cancel')}
          </Button>
          <Button
            color="primary"
            type="button"
            onClick={handleSaveClick}
            data-testid="save-usage-rights"
          >
            {I18n.t('Save')}
          </Button>
        </Modal.Footer>
      </Modal>
    </div>
  )
}

UsageRights.propTypes = {
  onSaveUsageRights: PropTypes.func, // When the user clicks save, this function is called with the new usage rights object
  initialUsageRights: PropTypes.shape({
    legalCopyright: PropTypes.string,
    license: PropTypes.string,
    useJustification: PropTypes.string,
  }),
  isOpen: PropTypes.bool, // can be used to open the modal
  errorState: PropTypes.bool, // can be used to show an error state
  creativeCommonsOptions: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.string.isRequired,
      name: PropTypes.string.isRequired,
    })
  ), // Array of objects with id and name for creative commons options
  usageRightsOptions: PropTypes.arrayOf(
    PropTypes.shape({
      display: PropTypes.string.isRequired,
      value: PropTypes.string.isRequired,
    })
  ),
}

UsageRights.defaultProps = {
  onSaveUsageRights: () => {},
  isOpen: false,
  errorState: false,
}
