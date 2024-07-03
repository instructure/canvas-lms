/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import React, {useEffect, useRef} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import '@canvas/jquery/jquery.instructure_forms'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('createTicketForm')

type Props = {
  onCancel: () => void
  onSubmit: (event?: Event) => void
}

function CreateTicketForm({onSubmit, onCancel}: Props) {
  const subjectRef = useRef<HTMLInputElement>(null)
  const formRef = useRef<HTMLFormElement>(null)

  const focus = () => {
    subjectRef.current?.focus()
  }

  useEffect(() => {
    focus()

    if (formRef.current instanceof HTMLFormElement) {
      $(formRef.current).formSubmit({
        formErrors: false,
        disableWhileLoading: true,
        required: ['error[subject]', 'error[comments]', 'error[user_perceived_severity]'],
        success: _data => {
          $.flashMessage(I18n.t('Ticket successfully submitted.'))
          onSubmit()
        },
        error: response => {
          formRef.current?.formErrors(JSON.parse(response.responseText))
          focus()
        },
      })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleCancelClick = () => {
    formRef.current?.reset()
    onCancel()
  }

  const guidesLink = I18n.t('#community.guides_home')

  const wrapperLink = document.createElement('a')
  wrapperLink.setAttribute('target', '_blank')
  wrapperLink.setAttribute('href', guidesLink)
  wrapperLink.textContent = '$1'

  // xsslint safeString.identifier guidesLink
  return (
    <form ref={formRef} action="/error_reports" method="POST">
      <fieldset className="ic-Form-group ic-HelpDialog__form-fieldset">
        <legend className="ic-HelpDialog__form-legend">
          {I18n.t('File a ticket for a personal response from our support team.')}
        </legend>

        <p
          dangerouslySetInnerHTML={{
            __html: I18n.t(
              'For an instant answer, see if your issue is addressed in the *Canvas Guides*.',
              {
                wrappers: [wrapperLink.outerHTML],
              }
            ),
          }}
        />

        {/* eslint-disable-next-line jsx-a11y/label-has-associated-control */}
        <label className="ic-Form-control">
          <span className="ic-Label">{I18n.t('Subject')}</span>
          <input
            ref={subjectRef}
            type="text"
            required={true}
            maxLength={200}
            aria-required="true"
            className="ic-Input"
            name="error[subject]"
          />
        </label>

        {/* eslint-disable-next-line jsx-a11y/label-has-associated-control */}
        <label className="ic-Form-control">
          <span className="ic-Label">{I18n.t('Description')}</span>
          <textarea
            className="ic-Input"
            required={true}
            aria-required="true"
            name="error[comments]"
          />
          <span
            className="ic-Form-help-text"
            dangerouslySetInnerHTML={{
              __html: I18n.t(
                'Include a link to a screencast/screenshot using something like *Jing*.',
                {
                  wrappers: [
                    '<a target="_blank" href="http://www.techsmith.com/download/jing">$1</a>',
                  ],
                }
              ),
            }}
          />
        </label>

        {/* eslint-disable-next-line jsx-a11y/label-has-associated-control */}
        <label className="ic-Form-control">
          <span className="ic-Label">{I18n.t('How is this affecting you?')}</span>
          <select
            className="ic-Input"
            required={true}
            aria-required="true"
            name="error[user_perceived_severity]"
          >
            <option value="">{I18n.t('Please select one')}</option>
            <option value="just_a_comment">
              {I18n.t('Just a casual question, comment, idea, or suggestion')}
            </option>
            <option value="not_urgent">{I18n.t('I need some help, but it is not urgent')}</option>
            <option value="workaround_possible">
              {I18n.t('Something is broken, but I can work around it for now')}
            </option>
            <option value="blocks_what_i_need_to_do">
              {I18n.t('I cannot get things done until I hear back from you')}
            </option>
            <option value="extreme_critical_emergency">
              {I18n.t('EXTREME CRITICAL EMERGENCY!')}
            </option>
          </select>
        </label>

        {!window.ENV.current_user_id ? (
          // eslint-disable-next-line jsx-a11y/label-has-associated-control
          <label className="ic-Form-control">
            <span className="ic-Label">{I18n.t('Your email address')}</span>
            <input className="ic-Input" type="email" name="error[email]" />
          </label>
        ) : null}

        <input type="hidden" name="error[url]" value={String(window.location)} />
        <input
          type="hidden"
          name="error[context_asset_string]"
          value={window.ENV.context_asset_string}
        />
        <input type="hidden" name="error[user_roles]" value={window.ENV.current_user_roles} />
        {/* this is a honeypot field. it's hidden via css, but spambots don't know that. */}
        <input className="hidden" name="error[username]" />

        <div className="ic-HelpDialog__form-actions">
          <button type="button" className="Button" onClick={handleCancelClick}>
            {I18n.t('Cancel')}
          </button>
          &nbsp;
          <button type="submit" className="Button Button--primary">
            {I18n.t('Submit Ticket')}
          </button>
        </div>
      </fieldset>
    </form>
  )
}

export default CreateTicketForm
