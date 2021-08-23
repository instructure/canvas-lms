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

import React from 'react'
import PropTypes from 'prop-types'
import axios from '@canvas/axios'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {Button} from '@instructure/ui-buttons'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {ScreenReaderContent, AccessibleContent} from '@instructure/ui-a11y-content'
import I18n from 'i18n!course_home_dialog'
import plainStoreShape from '@canvas/util/react/proptypes/plainStoreShape'

class CourseHomeDialog extends React.Component {
  static propTypes = {
    store: PropTypes.shape(plainStoreShape).isRequired,
    open: PropTypes.bool.isRequired,
    onRequestClose: PropTypes.func.isRequired,
    wikiFrontPageTitle: PropTypes.string,
    wikiUrl: PropTypes.string.isRequired,
    courseId: PropTypes.string.isRequired,
    isPublishing: PropTypes.bool.isRequired,
    onSubmit: PropTypes.func,
    returnFocusTo: PropTypes.instanceOf(Element)
  }

  static defaultProps = {
    onSubmit: () => {
      window.location.reload()
    },
    wikiFrontPageTitle: null
  }

  constructor(props) {
    super(props)
    this.state = props.store.getState()
  }

  renderWikiLabelContent() {
    const {wikiUrl, wikiFrontPageTitle} = this.props
    if (wikiFrontPageTitle) {
      return (
        <span>
          <Text size="small" color="secondary">
            &nbsp;&nbsp;
            <i>{wikiFrontPageTitle}</i>
            &nbsp; [<Link href={wikiUrl}>{I18n.t('Change')}</Link>]
          </Text>
        </span>
      )
    }
    return (
      <span>
        <AccessibleContent>*</AccessibleContent>
        <ScreenReaderContent>
          <Link href={wikiUrl}>{I18n.t('Front Page must be set first')}</Link>
        </ScreenReaderContent>
      </span>
    )
  }

  renderWikiLabel() {
    return (
      <span>
        {I18n.t('Pages Front Page')}
        {this.renderWikiLabelContent()}
      </span>
    )
  }

  render() {
    const {selectedDefaultView} = this.state
    const {wikiFrontPageTitle, wikiUrl} = this.props

    const inputs = [
      {
        value: 'feed',
        get label() {
          return I18n.t('Course Activity Stream')
        },
        checked: selectedDefaultView === 'feed'
      },
      {
        value: 'wiki',
        label: this.renderWikiLabel(),
        checked: selectedDefaultView === 'wiki',
        disabled: !wikiFrontPageTitle
      },
      {
        value: 'modules',
        get label() {
          return I18n.t('Course Modules')
        },
        checked: selectedDefaultView === 'modules'
      },
      {
        value: 'assignments',
        get label() {
          return I18n.t('Assignments List')
        },
        checked: selectedDefaultView === 'assignments'
      },
      {
        value: 'syllabus',
        get label() {
          return I18n.t('Syllabus')
        },
        checked: selectedDefaultView === 'syllabus'
      }
    ]

    const instructions = this.props.isPublishing
      ? I18n.t(
          'Before publishing your course, you must either publish a module in the Modules page, or choose a different home page.'
        )
      : I18n.t("Select what you'd like to display on the home page.")

    return (
      <Modal
        open={this.props.open}
        transition="fade"
        label={I18n.t('Choose Course Home Page')}
        onDismiss={this.props.onRequestClose}
        onClose={this.onClose}
      >
        <Modal.Body>
          <div className="content-box-mini" style={{marginTop: '0'}}>
            <AccessibleContent>
              <Text weight="bold" size="small">
                {instructions}
              </Text>
            </AccessibleContent>
          </div>
          <RadioInputGroup
            description={<ScreenReaderContent>{instructions}</ScreenReaderContent>}
            name="course[default_view]"
            onChange={(e, val) => this.onChange(val)}
            defaultValue={selectedDefaultView}
          >
            {inputs.map(input => (
              <RadioInput
                key={input.value}
                checked={input.checked}
                value={input.value}
                label={input.label}
                disabled={input.disabled}
              />
            ))}
          </RadioInputGroup>

          {wikiFrontPageTitle ? null : (
            <div className="content-box-mini">
              *
              <Button
                variant="link"
                href={wikiUrl}
                theme={{mediumPadding: '0', mediumHeight: '1.5rem'}}
              >
                {I18n.t('Front Page must be set first')}
              </Button>
            </div>
          )}
        </Modal.Body>

        <Modal.Footer>
          <Button onClick={this.props.onRequestClose} margin="0 x-small">
            {I18n.t('Cancel')}
          </Button>
          <Button
            onClick={this.onSubmit}
            disabled={this.props.isPublishing && this.state.selectedDefaultView === 'modules'}
            variant="primary"
          >
            {this.props.isPublishing ? I18n.t('Choose and Publish') : I18n.t('Save')}
          </Button>
        </Modal.Footer>
      </Modal>
    )
  }

  componentDidMount() {
    this.props.store.addChangeListener(this.onStoreChange)
  }

  componentWillUnmount() {
    this.props.store.removeChangeListener(this.onStoreChange)
  }

  onClose = () => {
    // this (unnecessary?) setTimeout fixes returning focus in ie11
    window.setTimeout(() => {
      const returnFocusTo = this.props.returnFocusTo
      returnFocusTo && returnFocusTo.focus()
    })
  }

  onStoreChange = () => {
    this.setState(this.props.store.getState())
  }

  onSubmit = () => {
    const {selectedDefaultView, savedDefaultView} = this.state
    let savingPromise
    if (selectedDefaultView !== savedDefaultView) {
      savingPromise = axios
        .put(`/api/v1/courses/${this.props.courseId}`, {
          course: {default_view: this.state.selectedDefaultView}
        })
        .then(({data: course}) => course.default_view)
    } else {
      savingPromise = Promise.resolve(savedDefaultView)
    }

    savingPromise.then(newDefaultView => {
      this.props.store.setState({savedDefaultView: newDefaultView})
      this.props.onSubmit()
    })
  }

  onChange = value => {
    this.props.store.setState({selectedDefaultView: value})
  }
}

export default CourseHomeDialog
