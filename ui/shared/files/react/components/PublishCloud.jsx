/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import React, {useState, useEffect, useRef} from 'react'
import PropTypes from 'prop-types'
import ReactDOM from 'react-dom'
import $ from 'jquery'
import {useScope as createI18nScope} from '@canvas/i18n'
import customPropTypes from '../modules/customPropTypes'
import '@canvas/rails-flash-notifications'
import {datetimeString} from '@canvas/datetime/date-functions'
import 'jqueryui/dialog'

const I18n = createI18nScope('publish_cloud')

const PublishCloud = ({
  togglePublishClassOn,
  model,
  userCanEditFilesForContext,
  usageRightsRequiredForContext,
  fileName,
  disabled,
  onPublishChange,
}) => {
  const publishCloudRef = useRef(null)

  // Helper function to extract state from model
  const extractStateFromModel = modelObj => {
    return {
      published: !modelObj.get('locked'),
      restricted: !!modelObj.get('lock_at') || !!modelObj.get('unlock_at'),
      hidden: !!modelObj.get('hidden'),
    }
  }

  // Initialize state from model
  const [state, setState] = useState(() => extractStateFromModel(model))
  const modelLocked = model.get('locked')

  // Update publish class elements
  const updatePublishClassElements = () => {
    const el = togglePublishClassOn
    if (!el || !el.classList) return
    return el.classList[state.published ? 'add' : 'remove']('ig-published')
  }

  // Update publish class when state changes
  useEffect(() => {
    if (togglePublishClassOn) {
      updatePublishClassElements()
    }
  }, [state.published, togglePublishClassOn])

  // Listen to model changes
  useEffect(() => {
    const handleModelChange = () => {
      setState(extractStateFromModel(model))
    }

    model.on('change', handleModelChange, this)

    return () => {
      model.off('change', handleModelChange, this)
    }
  }, [model])

  // Update state when model locked changes
  useEffect(() => {
    setState(extractStateFromModel(model))
  }, [model, modelLocked])

  const getRestrictedText = () => {
    if (model.get('unlock_at') && model.get('lock_at')) {
      return I18n.t('Available after %{unlock_at} until %{lock_at}', {
        unlock_at: datetimeString(model.get('unlock_at')),
        lock_at: datetimeString(model.get('lock_at')),
      })
    } else if (model.get('unlock_at') && !model.get('lock_at')) {
      return I18n.t('Available after %{unlock_at}', {
        unlock_at: datetimeString(model.get('unlock_at')),
      })
    } else if (!model.get('unlock_at') && model.get('lock_at')) {
      return I18n.t('Available until %{lock_at}', {
        lock_at: datetimeString(model.get('lock_at')),
      })
    }
  }

  const openRestrictedDialog = () => {
    const buttonId = `publish-cloud-${model.id}`
    const originatorButton = $(`#${buttonId}`) ? $(`#${buttonId}`)[0] : null
    const $dialog = $('<div>').dialog({
      title: I18n.t('Editing permissions for: %{name}', {name: model.displayName()}),
      width: 800,
      minHeight: 300,
      close() {
        ReactDOM.unmountComponentAtNode(this)
        $(this).remove()
        setTimeout(() => {
          originatorButton?.focus()
        }, 0)
      },
      modal: true,
      zIndex: 1000,
    })

    import('./RestrictedDialogForm').then(({default: RestrictedDialogForm}) => {
      ReactDOM.render(
        <RestrictedDialogForm
          usageRightsRequiredForContext={usageRightsRequiredForContext}
          models={[model]}
          closeDialog={() => {
            $dialog.dialog('close')
          }}
          onPublishChange={onPublishChange}
        />,
        $dialog[0],
      )
    })
  }

  const fileNameDisplay = (model && model.displayName()) || fileName || I18n.t('This file')

  if (userCanEditFilesForContext) {
    if (state.published && state.restricted) {
      return (
        <button
          id={`publish-cloud-${model.id}`}
          data-testid="restricted-button"
          type="button"
          data-tooltip="left"
          onClick={openRestrictedDialog}
          ref={publishCloudRef}
          className="btn-link published-status restricted"
          title={getRestrictedText()}
          aria-label={I18n.t('%{fileName} is %{restricted} - Click to modify', {
            fileName: fileNameDisplay,
            restricted: getRestrictedText(),
          })}
          disabled={disabled}
        >
          <i className="icon-calendar-month icon-line" />
        </button>
      )
    } else if (state.published && state.hidden) {
      return (
        <button
          id={`publish-cloud-${model.id}`}
          data-testid="hidden-button"
          type="button"
          data-tooltip="left"
          onClick={openRestrictedDialog}
          ref={publishCloudRef}
          className="btn-link published-status hiddenState"
          title={I18n.t('Only available to students with link')}
          aria-label={I18n.t(
            '%{fileName} is only available to students with the link - Click to modify',
            {
              fileName: fileNameDisplay,
            },
          )}
          disabled={disabled}
        >
          <i className="icon-off icon-line" />
        </button>
      )
    } else if (state.published) {
      return (
        <button
          id={`publish-cloud-${model.id}`}
          data-testid="published-button"
          type="button"
          data-tooltip="left"
          onClick={openRestrictedDialog}
          ref={publishCloudRef}
          className="btn-link published-status published"
          title={I18n.t('Published')}
          aria-label={I18n.t('%{fileName} is Published - Click to modify', {
            fileName: fileNameDisplay,
          })}
          disabled={disabled}
        >
          <i className="icon-publish icon-Solid" />
        </button>
      )
    } else {
      return (
        <button
          id={`publish-cloud-${model.id}`}
          data-testid="unpublished-button"
          type="button"
          data-tooltip="left"
          onClick={openRestrictedDialog}
          ref={publishCloudRef}
          className="btn-link published-status unpublished"
          title={I18n.t('Unpublished')}
          aria-label={I18n.t('%{fileName} is Unpublished - Click to modify', {
            fileName: fileNameDisplay,
          })}
          disabled={disabled}
        >
          <i className="icon-unpublish" />
        </button>
      )
    }
  } else if (state.published && state.restricted) {
    return (
      <div
        data-testid="restricted-status"
        style={{marginRight: '12px'}}
        data-tooltip="left"
        ref={publishCloudRef}
        className="published-status restricted"
        title={getRestrictedText()}
        aria-label={I18n.t('%{fileName} is %{restricted}', {
          fileName: fileNameDisplay,
          restricted: getRestrictedText(),
        })}
        disabled={disabled}
      >
        <i className="icon-calendar-day" />
      </div>
    )
  } else {
    return <div style={{width: 28, height: 36}} />
  }
}

PublishCloud.propTypes = {
  togglePublishClassOn: PropTypes.object,
  model: customPropTypes.filesystemObject,
  userCanEditFilesForContext: PropTypes.bool.isRequired,
  usageRightsRequiredForContext: PropTypes.bool,
  fileName: PropTypes.string,
  disabled: PropTypes.bool,
  onPublishChange: PropTypes.func,
}

export default PublishCloud
