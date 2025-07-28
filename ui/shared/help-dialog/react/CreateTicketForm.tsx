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

import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Link} from '@instructure/ui-link'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'
import React, {FormEvent, forwardRef, useEffect, useImperativeHandle, useRef, useState} from 'react'

const I18n = createI18nScope('createTicketForm')

type Props = {
  onCancel: () => void
  onSubmit: (event?: Event) => void
}

type FormData = {
  subject: string
  comments: string
  userPerceivedSeverity: string
  email?: string
}

type CreateTicketResponse = {
  message: string
}

const CreateTicketForm = forwardRef(function CreateTicketForm(
  {onSubmit, onCancel}: Props,
  ref: React.Ref<{resetForm: () => void}>,
) {
  const [formData, setFormData] = useState<FormData>({
    subject: '',
    comments: '',
    userPerceivedSeverity: '',
    email: '',
  })
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  const [subjectError, setSubjectError] = useState<string | null>(null)
  const [commentsError, setCommentsError] = useState<string | null>(null)
  const [severityError, setSeverityError] = useState<string | null>(null)
  const [emailError, setEmailError] = useState<string | null>(null)

  const subjectInputRef = useRef<HTMLInputElement | null>(null)
  const descriptionTextareaRef = useRef<HTMLTextAreaElement | null>(null)
  const emailInputRef = useRef<HTMLInputElement | null>(null)

  const resetForm = () => {
    setFormData({
      subject: '',
      comments: '',
      userPerceivedSeverity: '',
      email: '',
    })
    setErrorMessage(null)
    setIsSubmitting(false)
  }

  // expose this method to the parent to optionally be used if/when needed
  useImperativeHandle(ref, () => ({
    resetForm,
  }))

  useEffect(() => {
    subjectInputRef?.current?.focus()

    if (!window.ENV.current_user_id) {
      const head = document.querySelector('head')
      const script = document.createElement('script')
      script.setAttribute('src', 'https://www.google.com/recaptcha/api.js')
      head?.appendChild(script)
      return () => {
        head?.removeChild(script)
      }
    }
  }, [])

  const validateForm = (): boolean => {
    setSubjectError(null)
    setCommentsError(null)
    setSeverityError(null)
    setEmailError(null)

    if (!formData.subject.trim()) {
      setSubjectError(I18n.t('Subject is required.'))
      subjectInputRef?.current?.focus()
      return false
    }

    if (!formData.comments.trim()) {
      setCommentsError(I18n.t('Description is required.'))
      descriptionTextareaRef?.current?.focus()
      return false
    }

    if (!formData.userPerceivedSeverity) {
      setSeverityError(I18n.t('Please select an option.'))
      return false
    }

    if (formData.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      setEmailError(I18n.t('Please provide a valid email address.'))
      emailInputRef?.current?.focus()
      return false
    }

    return true
  }

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setErrorMessage(null)

    if (!validateForm()) {
      return
    }

    setIsSubmitting(true)

    try {
      const result = await doFetchApi<CreateTicketResponse>({
        path: '/error_reports',
        method: 'POST',
        body: {
          error: {
            subject: formData.subject,
            comments: formData.comments,
            user_perceived_severity: formData.userPerceivedSeverity,
            email: formData.email,
            url: window.location.toString(),
            context_asset_string: window.ENV.context_asset_string,
            user_roles: window.ENV.current_user_roles?.join(','),
          },
          'g-recaptcha-response': window.grecaptcha && window.grecaptcha.getResponse(),
        },
      })

      if (result.response.status === 200) {
        showFlashAlert({message: I18n.t('Ticket successfully submitted.'), type: 'success'})
        onSubmit()
      } else {
        setErrorMessage(result.json?.message || I18n.t('Error submitting ticket'))
      }
    } catch (_error) {
      setErrorMessage(I18n.t('An unexpected error occurred. Please try again later.'))
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleCancel = () => {
    setFormData({
      subject: '',
      comments: '',
      userPerceivedSeverity: '',
      email: '',
    })
    setSubjectError(null)
    setCommentsError(null)
    setSeverityError(null)
    setEmailError(null)
    setErrorMessage(null)

    onCancel()
  }

  // the guides_home link is language contextual, so it’s been translated
  const guidesLink = I18n.t('#community.guides_home')
  const translatedGuidesText = I18n.t(
    'For an instant answer, see if your issue is addressed in the %{guidesLink}.',
    {
      guidesLink: 'GUIDES_LINK',
    },
  )
  const splitText = translatedGuidesText.split(/GUIDES_LINK/)

  return (
    <form onSubmit={handleSubmit} noValidate={true}>
      <input
        type="hidden"
        name="error[user_roles]"
        value={window.ENV.current_user_roles?.join(',') || undefined}
      />

      {/* this is a honeypot field (as copied from the old code) … it's hidden via css, but spam bots don’t know that … */}
      <input
        style={{
          position: 'absolute',
          left: '-9999px',
          visibility: 'hidden',
          pointerEvents: 'none',
        }}
        name="error[username]"
        tabIndex={-1}
        aria-hidden="true"
        defaultValue=""
      />

      <FormFieldGroup
        description={
          <Text>{I18n.t('File a ticket for a personal response from our support team.')}</Text>
        }
        layout="stacked"
      >
        {errorMessage && (
          <Alert
            data-testid="error-message"
            hasShadow={false}
            liveRegionPoliteness="assertive"
            onDismiss={() => setErrorMessage(null)}
            renderCloseButtonLabel={I18n.t('Dismiss error message')}
            variant="error"
          >
            {errorMessage}
          </Alert>
        )}

        <Text>
          {splitText[0]}
          <Link href={guidesLink} target="_blank">
            {I18n.t('Canvas Guides')}
          </Link>
          {splitText[1]}
        </Text>

        <TextInput
          data-testid="subject-input"
          disabled={isSubmitting}
          inputRef={inputElement => (subjectInputRef.current = inputElement)}
          isRequired={true}
          messages={subjectError ? [{text: subjectError, type: 'newError'}] : []}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            setFormData(prev => ({...prev, subject: e.target.value}))
          }
          renderLabel={I18n.t('Subject')}
          value={formData.subject}
        />

        <TextArea
          data-testid="description-input"
          disabled={isSubmitting}
          label={I18n.t('Description')}
          messages={[
            {
              text: I18n.t('If you’re able, include a link to a screencast/screenshot.'),
              type: 'hint',
            },
            ...(commentsError ? [{text: commentsError, type: 'newError'} as const] : []),
          ]}
          onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) =>
            setFormData(prev => ({...prev, comments: e.target.value}))
          }
          required
          textareaRef={textarea => (descriptionTextareaRef.current = textarea)}
          value={formData.comments}
        />

        <SimpleSelect
          data-testid="severity-select"
          disabled={isSubmitting}
          isRequired={true}
          value={formData.userPerceivedSeverity || ''}
          onChange={(_event, data) => {
            setFormData(prev => ({...prev, userPerceivedSeverity: data.value as string}))
            setSeverityError(null)
          }}
          renderLabel={I18n.t('How is this affecting you?')}
          messages={severityError ? [{text: severityError, type: 'error'}] : []}
        >
          <SimpleSelect.Option id="placeholder" value="" isDisabled>
            {I18n.t('Please select one …')}
          </SimpleSelect.Option>
          <SimpleSelect.Option id="just_a_comment" value="just_a_comment">
            {I18n.t('Just a casual question, comment, idea, or suggestion')}
          </SimpleSelect.Option>
          <SimpleSelect.Option id="not_urgent" value="not_urgent">
            {I18n.t('I need some help, but it is not urgent')}
          </SimpleSelect.Option>
          <SimpleSelect.Option id="workaround_possible" value="workaround_possible">
            {I18n.t('Something is broken, but I can work around it for now')}
          </SimpleSelect.Option>
          <SimpleSelect.Option id="blocks_what_i_need_to_do" value="blocks_what_i_need_to_do">
            {I18n.t('I cannot get things done until I hear back from you')}
          </SimpleSelect.Option>
          <SimpleSelect.Option id="extreme_critical_emergency" value="extreme_critical_emergency">
            {I18n.t('EXTREME CRITICAL EMERGENCY!')}
          </SimpleSelect.Option>
        </SimpleSelect>

        {!window.ENV.current_user_id && (
          <>
            <TextInput
              data-testid="email-input"
              disabled={isSubmitting}
              inputRef={inputElement => (emailInputRef.current = inputElement)}
              messages={emailError ? [{text: emailError, type: 'newError'}] : []}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                setFormData(prev => ({...prev, email: e.target.value}))
              }
              renderLabel={I18n.t('Your email address')}
              type="email"
              value={formData.email}
            />
            <Flex>
              <Flex.Item padding="small">
                <div className="g-recaptcha" data-sitekey={window.ENV.captcha_site_key}></div>
              </Flex.Item>
            </Flex>
          </>
        )}

        <Flex justifyItems="end" margin="small 0">
          <Flex.Item margin="0 small 0 0">
            <Button data-testid="cancel-button" onClick={handleCancel} type="button">
              {I18n.t('Cancel')}
            </Button>
          </Flex.Item>

          <Flex.Item>
            <Button
              data-testid="submit-button"
              color="primary"
              disabled={isSubmitting}
              renderIcon={
                isSubmitting
                  ? () => <Spinner size="x-small" renderTitle={I18n.t('Submitting …')} />
                  : undefined
              }
              type="submit"
            >
              {isSubmitting ? I18n.t('Submitting …') : I18n.t('Submit Ticket')}
            </Button>
          </Flex.Item>
        </Flex>
      </FormFieldGroup>
    </form>
  )
})

export default CreateTicketForm
