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
import axios from 'axios'
import Modal, {ModalHeader, ModalBody, ModalFooter} from '@instructure/ui-core/lib/components/Modal'
import Heading from '@instructure/ui-core/lib/components/Heading'
import RadioInputGroup from '@instructure/ui-core/lib/components/RadioInputGroup'
import RadioInput from '@instructure/ui-core/lib/components/RadioInput'
import Button from '@instructure/ui-core/lib/components/Button'
import Text from '@instructure/ui-core/lib/components/Text'
import Link from '@instructure/ui-core/lib/components/Link'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'
import AccessibleContent from '@instructure/ui-core/lib/components/AccessibleContent'
import I18n from 'i18n!course_home_dialog'
import plainStoreShape from '../shared/proptypes/plainStoreShape'

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
    returnFocusTo: PropTypes.instanceOf(Element),
  }

  static defaultProps = {
    onSubmit: () => { window.location.reload() },
    wikiFrontPageTitle: null,
  }

  constructor (props) {
    super(props)
    this.state = props.store.getState()
  }

  renderWikiLabelContent () {
    const {wikiUrl, wikiFrontPageTitle} = this.props
    if (wikiFrontPageTitle) {
      return (
        <span>
          <Text size="small" color="secondary">
            &nbsp;&nbsp;
            <i>{wikiFrontPageTitle}</i>
            &nbsp;
            [<Link href={wikiUrl}>{I18n.t('Change')}</Link>]
          </Text>
        </span>
      )
    }
    return (
      <span>
        <AccessibleContent>*</AccessibleContent>
        <ScreenReaderContent>
          <Link href={wikiUrl}>
            {I18n.t('Front page must be set first')}
          </Link>
        </ScreenReaderContent>
      </span>
    )
  }

  renderWikiLabel () {
    return (
      <span>
        {I18n.t('Pages Front Page')}
        {this.renderWikiLabelContent()}
      </span>
    )
  }

  render () {
    const {selectedDefaultView} = this.state
    const {wikiFrontPageTitle, wikiUrl} = this.props

    const inputs = [
      {
        value: 'feed',
        label: I18n.t('Course Activity Stream'),
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
        label: I18n.t('Course Modules'),
        checked: selectedDefaultView === 'modules'
      },
      {
        value: 'assignments',
        label: I18n.t('Assignments List'),
        checked: selectedDefaultView === 'assignments'
      },
      {
        value: 'syllabus',
        label: I18n.t('Syllabus'),
        checked: selectedDefaultView === 'syllabus'
      }
    ]

    const instructions = this.props.isPublishing ?
      I18n.t('Before publishing your course, you must either publish a module in the Modules page, or choose a different home page.') :
      I18n.t("Select what you'd like to display on the home page.")

    return (
      <Modal
        open={this.props.open}
        transition="fade"
        label={I18n.t('Choose Course Home Page')}
        closeButtonLabel={I18n.t('Close')}
        applicationElement={() => document.getElementById('application')}
        onDismiss={this.props.onRequestClose}
        onClose={this.onClose}
      >
        <ModalHeader>
          <Heading tag="h2" level="h3">{I18n.t('Choose Home Page')}</Heading>
        </ModalHeader>
        <ModalBody>
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
            onChange={this.onChange}
            defaultValue={selectedDefaultView}
          >
            {inputs.map(input =>
              <RadioInput
                key={input.value}
                checked={input.checked}
                value={input.value}
                label={input.label}
                disabled={input.disabled}
              />)
            }
          </RadioInputGroup>

          {
            wikiFrontPageTitle ? (
              null
            ) : (
              <div className="content-box-mini">
              * <Link href={wikiUrl}>{I18n.t('Front page must be set first')}
              </Link></div>
            )
          }

        </ModalBody>

        <ModalFooter>
          <Button onClick={this.props.onRequestClose}>{I18n.t('Cancel')}</Button>&nbsp;
          <Button
            onClick={this.onSubmit}
            disabled={this.props.isPublishing && this.state.selectedDefaultView === 'modules'}
            variant="primary"
          >{
            this.props.isPublishing ? I18n.t('Choose and Publish') : I18n.t('Save')
          }</Button>
        </ModalFooter>
      </Modal>
    );
  }

  componentDidMount () {
    this.props.store.addChangeListener(this.onStoreChange)
  }

  componentWillUnmount () {
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
      savingPromise = axios.put(`/api/v1/courses/${this.props.courseId}`, {
        course: {default_view: this.state.selectedDefaultView}
      }).then(({data: course}) => course.default_view)
    } else {
      savingPromise = Promise.resolve(savedDefaultView)
    }

    savingPromise.then((newDefaultView) => {
      this.props.store.setState({savedDefaultView: newDefaultView})
      this.props.onSubmit()
    })
  }

  onChange = (value) => {
    this.props.store.setState({selectedDefaultView: value})
  }
}

export default CourseHomeDialog
