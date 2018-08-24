/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import PropTypes from 'prop-types';

import React from 'react';
import keycode from 'keycode'
import I18n from 'i18n!act_as'

import Modal, {ModalBody} from '../shared/components/InstuiModal'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import View from '@instructure/ui-layout/lib/components/View'
import Text from '@instructure/ui-elements/lib/components/Text'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Avatar from '@instructure/ui-elements/lib/components/Avatar'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import Table from '@instructure/ui-elements/lib/components/Table'

import ActAsMask from './ActAsMask'
import ActAsPanda from './ActAsPanda'

export default class ActAsModal extends React.Component {
  static propTypes = {
    user: PropTypes.shape({
      name: PropTypes.string,
      short_name: PropTypes.string,
      id: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
      avatar_image_url: PropTypes.string,
      sortable_name: PropTypes.string,
      email: PropTypes.string,
      pseudonyms: PropTypes.arrayOf(PropTypes.shape({
        login_id: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
        sis_id: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
        integration_id: PropTypes.oneOfType([PropTypes.number, PropTypes.string])
      }))
    }).isRequired
  }

  constructor (props) {
    super(props)

    this.state = {
      isLoading: false
    }

    this._button = null
  }

  componentWillMount () {
    if (window.location.href === document.referrer) {
      this.setState({isLoading: true})
      window.location.href = '/'
    }
  }

  componentDidMount() {
    if (this.closeButton) this.closeButton.focus()
  }

  handleModalRequestClose = () => {
    const defaultUrl = '/'

    if (!document.referrer) {
      window.location.href = defaultUrl
    } else {
      const currentPage = window.location.href
      window.history.back()
      // if we go nowhere, modal was opened in new tab,
      // and we return to the dashboard by default
      setTimeout(() => {
        if (window.location.href === currentPage) {
          window.location.href = defaultUrl
        }
      }, 1000)
    }
    this.setState({isLoading: true})
  }

  handleClick = (e) => {
    if (e.keyCode && (e.keyCode === keycode.codes.space || e.keyCode === keycode.codes.enter)) {
      // for the data to post correctly, we need an actual click
      // on enter and space press, we simulate a click event and return
      e.target.click()
      return
    }
    this.setState({isLoading: true})
  }

  renderInfoTable (caption, renderRows) {
    return (
      <Table caption={<ScreenReaderContent>{caption}</ScreenReaderContent>}>
        <thead>
          <tr>
            <th><ScreenReaderContent>{I18n.t('Category')}</ScreenReaderContent></th>
            <th><ScreenReaderContent>{I18n.t('User information')}</ScreenReaderContent></th>
          </tr>
        </thead>
        {renderRows()}
      </Table>
    )
  }

  renderUserInfoRows = () => {
    const user = this.props.user
    return (
      <tbody>
        {this.renderUserRow(I18n.t('Full Name:'), user.name)}
        {this.renderUserRow(I18n.t('Display Name:'), user.short_name)}
        {this.renderUserRow(I18n.t('Sortable Name:'), user.sortable_name)}
        {this.renderUserRow(I18n.t('Default Email:'), user.email)}
      </tbody>
    )
  }

  renderLoginInfoRows = pseudonym => (
    <tbody>
      {this.renderUserRow(I18n.t('Login ID:'), pseudonym.login_id)}
      {this.renderUserRow(I18n.t('SIS ID:'), pseudonym.sis_id)}
      {this.renderUserRow(I18n.t('Integration ID:'), pseudonym.integration_id)}
    </tbody>
  )

  renderUserRow (category, info) {
    return (
      <tr>
        <td>
          <Text size="small">{category}</Text>
        </td>
        <td>
          <View
            as="div"
            textAlign="end"
          >
            <Text
              size="small"
              weight="bold"
            >
              {info}
            </Text>
          </View>
        </td>
      </tr>
    )
  }

  render () {
    const user = this.props.user

    return (
      <div>
        <Modal
          onDismiss={this.handleModalRequestClose}
          transition="fade"
          size="fullscreen"
          label={I18n.t('Act as User')}
          open
        >
          <ModalBody>
            {this.state.isLoading ?
              <div className="ActAs__loading">
                <Spinner title={I18n.t('Loading')} />
              </div>
            :
              <div className="ActAs__body">
                <div className="ActAs__svgContainer">
                  <div className="ActAs__svg">
                    <ActAsPanda />
                  </div>
                  <div className="ActAs__svg">
                    <ActAsMask />
                  </div>
                </div>
                <div className="ActAs__text">
                  <View
                    as="div"
                    size="small"
                  >
                    <View
                      as="div"
                      textAlign="center"
                      padding="0 0 x-small 0"
                    >
                      <Text
                        size="x-large"
                        weight="light"
                      >
                        {I18n.t('Act as %{name}', { name: user.short_name })}
                      </Text>
                    </View>
                    <View
                      as="div"
                      textAlign="center"
                    >
                      <Text
                        lineHeight="condensed"
                        size="small"
                      >
                        {I18n.t('"Act as" is essentially logging in as this user ' +
                          'without a password. You will be able to take any action ' +
                          'as if you were this user, and from other users\' points ' +
                          'of views, it will be as if this user performed them. However, ' +
                          'audit logs record that you were the one who performed the ' +
                          'actions on behalf of this user.'
                        )}
                      </Text>
                    </View>
                    <View
                      as="div"
                      textAlign="center"
                    >
                      <Avatar
                        name={user.short_name}
                        src={user.avatar_image_url}
                        size="small"
                        margin="medium 0 x-small 0"
                      />
                    </View>
                    <View
                      as="div"
                      textAlign="center"
                    >
                      {this.renderInfoTable(I18n.t('User details'), this.renderUserInfoRows)}
                    </View>
                    {user.pseudonyms.map(pseudonym => (
                        <View
                          as="div"
                          textAlign="center"
                          margin="large 0 0 0"
                          key={pseudonym.login_id}
                        >
                          {this.renderInfoTable(I18n.t('Login info'), () => this.renderLoginInfoRows(pseudonym))}
                        </View>
                      )
                    )}
                    <View
                      as="div"
                      textAlign="center"
                    >
                      <Button
                        variant="primary"
                        href={`/users/${user.id}/masquerade`}
                        data-method="post"
                        onClick={this.handleClick}
                        margin="large 0 0 0"
                        buttonRef={(el) => this.proceedButton = el}
                      >
                        {I18n.t('Proceed')}
                      </Button>
                    </View>
                  </View>
                </div>
              </div>
            }
          </ModalBody>
        </Modal>
      </div>
    )
  }
}
