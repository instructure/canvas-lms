/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {Component} from 'react'
import ReactDOM from 'react-dom'
import {func, instanceOf, array} from 'prop-types'

import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'

const I18n = useI18nScope('wiki_pages')

export function showConfirmDelete(props) {
  const parent = document.createElement('div')
  document.body.appendChild(parent)

  function showConfirmDeleteRef(modal) {
    if (modal) modal.show()
  }

  ReactDOM.render(
    <ConfirmDeleteModal {...props} parent={parent} ref={showConfirmDeleteRef} />,
    parent
  )
}

export default class ConfirmDeleteModal extends Component {
  static propTypes = {
    pageTitles: array.isRequired,
    onConfirm: func.isRequired,
    onCancel: func,
    onHide: func,
    parent: instanceOf(Element),
  }

  static defaultProps = {
    onCancel: null,
    onHide: null,
    parent: null,
  }

  state = {
    show: false,
    inProgress: false,
  }

  onCancel = () => {
    if (this.props.onCancel) setTimeout(this.props.onCancel)
    this.hide(false)
  }

  onConfirm = () => {
    this.setState({inProgress: true}, () => {
      this.props
        .onConfirm()
        .then(results => {
          this.hide(true, results.failures.length > 0)
        })
        .catch(_error => {
          this.hide(true, true)
        })
    })
  }

  show() {
    this.setState({show: true})
  }

  hide(confirmed, error = false) {
    this.setState({show: false, inProgress: false}, () => {
      if (this.props.onHide) setTimeout(() => this.props.onHide(confirmed, error))
      if (this.props.parent) ReactDOM.unmountComponentAtNode(this.props.parent)
    })
  }

  renderSpinner() {
    return (
      <Flex justifyItems="center">
        <Flex.Item>
          <Spinner renderTitle={I18n.t('Delete in progress')} />
        </Flex.Item>
      </Flex>
    )
  }

  renderConfirmation() {
    const message = I18n.t(
      {
        one: '%{count} page selected for deletion',
        other: '%{count} pages selected for deletion',
      },
      {
        count: this.props.pageTitles.length,
      }
    )
    return (
      <>
        <div className="delete-wiki-pages-header">{message}</div>
        {this.props.pageTitles.map((title, index) => (
          // eslint-disable-next-line react/no-array-index-key
          <div className="wiki-page-title" key={index}>
            {title}
          </div>
        ))}
      </>
    )
  }

  render() {
    const {show, inProgress} = this.state
    return (
      <Modal open={show} onDismiss={this.onCancel} size="small" label={I18n.t('Confirm Delete')}>
        <Modal.Body>{inProgress ? this.renderSpinner() : this.renderConfirmation()}</Modal.Body>
        <Modal.Footer>
          <Button
            interaction={inProgress ? 'disabled' : 'enabled'}
            ref={c => {
              this.cancelBtn = c
            }}
            onClick={this.onCancel}
          >
            {I18n.t('Cancel')}
          </Button>
          &nbsp;
          <Button
            id="confirm_delete_wiki_pages"
            interaction={inProgress ? 'disabled' : 'enabled'}
            ref={c => {
              this.confirmBtn = c
            }}
            onClick={this.onConfirm}
            color="danger"
          >
            {I18n.t('Delete')}
          </Button>
        </Modal.Footer>
      </Modal>
    )
  }
}
