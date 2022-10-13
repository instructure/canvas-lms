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

import React, {useState, useRef} from 'react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as useI18nScope} from '@canvas/i18n'
import {arrayOf, bool, func, number, shape, string} from 'prop-types'
import {Checkbox} from '@instructure/ui-checkbox'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Modal} from '@instructure/ui-modal'
import {List} from '@instructure/ui-list'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {IconInfoLine} from '@instructure/ui-icons'

const I18n = useI18nScope('course_template_details')

const getLiveRegion = () => document.getElementById('flash_screenreader_holder')

const AssociatedText = ({count, onClick}) => (
  <Link data-testid="result-n-assoc" onClick={count > 0 ? onClick : undefined}>
    <Text size="small">
      {count > 10
        ? I18n.t('Associated with 10+ accounts')
        : I18n.t(
            {
              zero: 'Not associated with any accounts',
              one: 'Associated with one account',
              other: 'Associated with %{count} accounts',
            },
            {count}
          )}
    </Text>
    {count > 0 && (
      <View margin="none none none x-small">
        <IconInfoLine size="x-small" />
      </View>
    )}
  </Link>
)

AssociatedText.propTypes = {
  count: number.isRequired,
  onClick: func.isRequired,
}

// Return a list of the names of the given accounts.
// Truncate the list at 10
const AssociatedAccounts = ({accounts}) => (
  <List margin="none none small none">
    {accounts.slice(0, 10).map(a => (
      <List.Item key={a.name}>{a.name}</List.Item>
    ))}
  </List>
)

AssociatedAccounts.propTypes = {
  accounts: arrayOf(
    shape({
      id: string,
      name: string,
    }).isRequired
  ),
}

const CourseTemplateDetails = ({isEditable}) => {
  const [checked, setChecked] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [modalVisible, setModalVisible] = useState(false)
  const dataRequested = useRef(false)
  const [templatedAccounts, setTemplatedAccounts] = useState(undefined)

  async function getCourseSettings() {
    try {
      const {json} = await doFetchApi({
        path: `/api/v1${ENV.CONTEXT_BASE_URL}?include[]=templated_accounts`,
      })
      setChecked(json.template)
      setTemplatedAccounts(json.templated_accounts)
    } catch (err) {
      setError(err)
    } finally {
      setLoading(false)
    }
  }

  function toggleEnabled() {
    setChecked(!checked)
  }

  function showModal() {
    setModalVisible(true)
  }

  function hideModal() {
    setModalVisible(false)
  }

  // It's safe to call getCourseSettings immediately because it does
  // not need any part of the rendered component, it only sets state.
  // Be sure to do it exactly once, though.
  if (!dataRequested.current) {
    dataRequested.current = true
    getCourseSettings()
  }

  if (loading)
    return <Spinner data-testid="loading-spinner" size="x-small" renderTitle={I18n.t('Loading')} />
  if (error) throw new Error(error)

  const modalLabel = I18n.t('Associated Accounts')

  return (
    <div className="bcs_check-box" data-testid="result-div">
      <input type="hidden" name="course[template]" value="off" />
      <Checkbox
        name="course[template]"
        data-testid="result-checkbox"
        checked={checked}
        disabled={!isEditable}
        onChange={toggleEnabled}
        label={I18n.t('Enable course as a Course Template')}
        size="small"
        value={checked ? 'on' : 'false'}
      />
      {Array.isArray(templatedAccounts) && (
        <AssociatedText count={templatedAccounts.length} onClick={showModal} />
      )}
      <Modal
        data-testid="result-modal"
        liveRegion={getLiveRegion}
        open={modalVisible}
        onDismiss={hideModal}
        label={modalLabel}
        size="auto"
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="medium"
            onClick={hideModal}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading level="h3" as="h2">
            {modalLabel}
          </Heading>
        </Modal.Header>
        <Modal.Body>
          <AssociatedAccounts accounts={templatedAccounts} />
          {templatedAccounts?.length > 10 && <Text size="small">(more not shown)</Text>}
        </Modal.Body>
      </Modal>
    </div>
  )
}

CourseTemplateDetails.propTypes = {
  isEditable: bool,
}

CourseTemplateDetails.defaultProps = {
  isEditable: false,
}

export default CourseTemplateDetails
