/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import React, {useState} from 'react'
import $ from 'jquery'
import 'jquery.ajaxJSON'
import I18n from 'i18n!quiz_engine_modal'
import CanvasModal from 'jsx/shared/components/CanvasModal'
import {Link} from '@instructure/ui-link'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import getCookie from 'jsx/shared/helpers/getCookie'

const CLASSIC = 'classic'
const NEW = 'new'

function QuizEngineModal({setOpen, onDismiss}) {
  const [option, setOption] = useState()
  const [checked, setChecked] = useState(false)
  const authenticity_token = () => getCookie('_csrf_token')

  const link = (
    <Link href="https://community.canvaslms.com/docs/DOC-12115-quizzes-lti-feature-comparison">
      {I18n.t('Learn more about the differences.')}
    </Link>
  )
  const newQuizLabel = <Text weight="bold">{I18n.t('New Quizzes')}</Text>
  const classicLabel = <Text weight="bold">{I18n.t('Classic Quizzes')}</Text>
  const newDesc = (
    <div style={{paddingLeft: '1.75rem', maxWidth: '23.5rem'}}>
      <Text weight="light">
        {I18n.t(`This has more question types like hotspot,
        categorization, matching, and ordering. It also has
        more moderation and accommodation features.`)}
      </Text>
    </div>
  )
  const classicDesc = (
    <div style={{paddingLeft: '1.75rem', maxWidth: '23.5rem'}}>
      <Text weight="light">
        {I18n.t(`For the time being, if you need security from
        3rd-party tools, Speedgrader, or CSVs for student
        response analysis, this is the better choice.`)}
      </Text>
    </div>
  )
  const footer = (
    <div>
      <Button onClick={onDismiss} margin="0 x-small 0 0" variant="light">
        {I18n.t('Cancel')}
      </Button>
      <Button type="submit" onClick={handleSubmit} variant="primary" disabled={!option}>
        {I18n.t('Submit')}
      </Button>
    </div>
  )
  const description = (
    <div style={{paddingBottom: '1.5rem', maxWidth: '25rem'}}>
      <Text>
        {I18n.t(`Canvas now has two quiz engines. Please choose which
        you'd like to use.`)}
        &nbsp;{link}
      </Text>
    </div>
  )

  function post(path, params, method = 'post') {
    const form = document.createElement('form')
    form.method = method
    form.action = path
    for (const key in params) {
      if (params.hasOwnProperty(key)) {
        const hiddenField = document.createElement('input')
        hiddenField.type = 'hidden'
        hiddenField.name = key
        hiddenField.value = params[key]
        form.appendChild(hiddenField)
      }
    }
    document.body.appendChild(form)
    form.submit()
  }

  function saveQuizEngineSelection() {
    const newquizzes_engine = option === NEW
    $.ajaxJSON(
      ENV.URLS.new_quizzes_selection,
      'PUT',
      {
        newquizzes_engine_selected: newquizzes_engine
      },
      () => {
        window.location.reload()
        loadQuizEngine()
      }
    )
  }

  function loadQuizEngine() {
    if (option === CLASSIC) {
      post(ENV.URLS.new_quiz_url, {authenticity_token: authenticity_token()})
    } else if (option === NEW) {
      window.location.href = `${ENV.URLS.new_assignment_url}?quiz_lti`
    }
  }

  function handleSubmit() {
    if (checked) {
      saveQuizEngineSelection()
    } else {
      loadQuizEngine()
    }
  }

  function handleChange(e, value) {
    setOption(value)
  }

  function checkboxChange() {
    setChecked(!checked)
  }

  return (
    <CanvasModal
      open={setOpen}
      onDismiss={onDismiss}
      padding="medium"
      label={I18n.t('Choose a Quiz Engine')}
      footer={footer}
    >
      {description}
      <RadioInputGroup
        name="quizEngine"
        onChange={handleChange}
        defaultValue={option}
        description=""
      >
        <RadioInput key={CLASSIC} value={CLASSIC} label={classicLabel} size="large" />
        {classicDesc}
        <RadioInput key={NEW} value={NEW} label={newQuizLabel} size="large" />
        {newDesc}
      </RadioInputGroup>
      <hr />
      <p>
        <input
          name="persistSelection"
          type="checkbox"
          defaultChecked={checked}
          onChange={checkboxChange}
          style={{marginRight: '0.25rem', height: '1.5rem', width: '1.5rem'}}
        />
        <label htmlFor="persistSelection">{I18n.t(`Remember my choice for this course`)}</label>
      </p>
    </CanvasModal>
  )
}

export default QuizEngineModal
