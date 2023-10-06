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

import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'
import {Form} from 'react-final-form'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {InstUISettingsProvider} from '@instructure/emotion'
import {Flex} from '@instructure/ui-flex'
import {Mask} from '@instructure/ui-overlays'
import {
  composeValidators,
  maxLengthValidator,
  requiredValidator,
} from '@canvas/outcomes/react/validators/finalFormValidators'
import LabeledTextField from '../shared/LabeledTextField'
import LabeledRceField from '../shared/LabeledRceField'

const I18n = useI18nScope('FindOutcomesModal')

const titleValidator = composeValidators(requiredValidator, maxLengthValidator(255))

const componentOverrides = {
  Mask: {
    zIndex: '1000',
  },
}

const GroupEditForm = ({initialValues, onSubmit, isOpen, onCloseHandler}) => {
  return (
    <Form
      onSubmit={onSubmit}
      initialValues={initialValues}
      render={({handleSubmit, form}) => {
        const {valid, dirty} = form.getState()

        return (
          <InstUISettingsProvider theme={{componentOverrides}}>
            <Modal
              label={I18n.t('Edit Group')}
              open={isOpen}
              onDismiss={onCloseHandler}
              size="medium"
              shouldReturnFocus={true}
              shouldCloseOnDocumentClick={false}
              data-testid="outcome-management-edit-modal"
            >
              <Modal.Body>
                <Flex as="div" alignItems="start" padding="small 0" height="7rem">
                  <Flex.Item size="50%" padding="0 xx-small 0 0">
                    <LabeledTextField
                      name="title"
                      renderLabel={I18n.t('Group Name')}
                      type="text"
                      size="medium"
                      validate={titleValidator}
                    />
                  </Flex.Item>
                </Flex>
                <View as="div" padding="medium 0">
                  <LabeledRceField name="description" label={I18n.t('Group Description')} />
                </View>
              </Modal.Body>
              <Modal.Footer>
                <Button
                  type="button"
                  color="secondary"
                  margin="0 x-small 0 0"
                  onClick={onCloseHandler}
                >
                  {I18n.t('Cancel')}
                </Button>
                &nbsp;
                <Button
                  onClick={handleSubmit}
                  type="button"
                  color="primary"
                  margin="0 x-small 0 0"
                  interaction={valid && dirty ? 'enabled' : 'disabled'}
                >
                  {I18n.t('Save')}
                </Button>
              </Modal.Footer>
            </Modal>
          </InstUISettingsProvider>
        )
      }}
    />
  )
}

GroupEditForm.propTypes = {
  initialValues: PropTypes.shape({
    title: PropTypes.string,
    description: PropTypes.string,
  }),
  onSubmit: PropTypes.func.isRequired,
  isOpen: PropTypes.bool.isRequired,
  onCloseHandler: PropTypes.func.isRequired,
}

export default GroupEditForm
