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

import React, {useEffect, useRef, createRef, useCallback} from 'react'
import moment from 'moment'
import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'
import {IconAddSolid} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import Backbone from '@canvas/backbone'
import ConverterViewControl from '@canvas/content-migrations/backbone/views/ConverterViewControl'
import type {onSubmitMigrationFormCallback} from '../types'
import {humanReadableSize} from '../utils'

const I18n = useI18nScope('content_migrations_redesign')

type LegacyMigratorWrapperProps = {
  value: string
  onSubmit: onSubmitMigrationFormCallback
  onCancel: () => void
}

// A replacement for $(form).toJSON() without jQuery
function formToJson(form: HTMLFormElement): {[key: string]: any} {
  const formData = new FormData(form)
  const jsonObject: {[key: string]: any} = {}

  formData.forEach((value, key) => {
    // Split the key into parts using '[' and ']' as delimiters
    const keys = key.split(/\[|\]/).filter(Boolean)
    let currentObj = jsonObject
    for (let i = 0; i < keys.length; i++) {
      if (i === keys.length - 1) {
        currentObj[keys[i]] = value
      } else {
        currentObj[keys[i]] = currentObj[keys[i]] || {}
        currentObj = currentObj[keys[i]]
      }
    }
  })

  return jsonObject
}

function formatDate(dateString?: string | null): string | null {
  return dateString
    ? moment.utc(dateString, 'MMM DD, YYYY').format('YYYY-MM-DDTHH:mm:ss.SSS[Z]')
    : null
}

const LegacyMigratorWrapper = ({value, onSubmit, onCancel}: LegacyMigratorWrapperProps) => {
  const wrapper = createRef<HTMLFormElement>()
  const backboneView = useRef<any>(null)

  const renderConverter = useCallback(
    view => {
      const wrapperElement = wrapper.current
      backboneView.current = view
      if (wrapperElement) {
        wrapperElement.firstChild && wrapperElement.removeChild(wrapperElement.firstChild)
        wrapperElement.appendChild(view.render().el)
      }
    },
    [wrapper]
  )

  const handleSubmit = useCallback(() => {
    if (!wrapper.current || !backboneView.current) return

    // Similar logic like ValidatedFormView.prototype.submit
    const errors = backboneView.current.validateBeforeSave()
    const errorsList = Object.keys(errors)
    if (errorsList.length > 0) {
      backboneView.current.el.querySelector(`[name="${errorsList[0]}"]`)?.focus()
      errorsList.forEach(errorName =>
        errors[errorName].forEach(({message}: any) => showFlashError(message)())
      )
      return
    }

    const formData = formToJson(wrapper.current)
    const model = ConverterViewControl.getModel().toJSON()

    const data: any = {
      selective_import: false,
      date_shift_options: {},
      settings: {...model.settings, import_quizzes_next: false},
    }

    if (formData.adjust_dates) {
      const {operation, enabled} = formData.adjust_dates
      data.date_shift_options[operation] = enabled
    }

    if (formData.date_shift_options) {
      const {new_end_date, new_start_date, old_end_date, old_start_date, day_substitutions} =
        formData.date_shift_options
      data.date_shift_options.new_end_date = formatDate(new_end_date)
      data.date_shift_options.new_start_date = formatDate(new_start_date)
      data.date_shift_options.old_end_date = formatDate(old_end_date)
      data.date_shift_options.old_start_date = formatDate(old_start_date)

      if (day_substitutions) {
        data.date_shift_options.day_substitutions = day_substitutions
        data.daySubCollection = day_substitutions
      }
    }

    if (formData.file) {
      data.pre_attachment = {
        name: formData.file.name,
        size: formData.file.size,
        no_redirect: true,
      }
    }

    onSubmit(data, formData.file)
  }, [onSubmit, wrapper])

  useEffect(() => {
    const migrationConverter = {
      renderConverter,
    }
    ConverterViewControl.getModel().on(
      'change:pre_attachment',
      (model: Backbone.Model, pre_attachment: any) => {
        if (pre_attachment && ENV.UPLOAD_LIMIT && pre_attachment.size > ENV.UPLOAD_LIMIT) {
          model.unset('pre_attachment')
          showFlashError(
            I18n.t('Your migration can not exceed %{file_size}', {
              file_size: humanReadableSize(1000),
            })
          )()
        }
      }
    )
    ConverterViewControl.renderView({value, migrationConverter})

    // Resets model on unmount
    return () => ConverterViewControl.getModel().resetModel()
  }, [value, renderConverter])

  return (
    <>
      <form id="migrationConverterContainer" className="form-horizontal" ref={wrapper} />
      <View as="div" margin="medium none none none">
        <Button onClick={onCancel}>{I18n.t('Cancel')}</Button>
        <Button data-testid="submitMigration" onClick={handleSubmit} margin="small" color="primary">
          <IconAddSolid /> &nbsp;
          {I18n.t('Add to Import Queue')}
        </Button>
      </View>
    </>
  )
}

export default LegacyMigratorWrapper
