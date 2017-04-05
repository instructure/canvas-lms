import I18n from 'i18n!blueprint_settings'
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'

import Button from 'instructure-ui/lib/components/Button'
import Typography from 'instructure-ui/lib/components/Typography'

import propTypes from '../propTypes'
import actions from '../actions'
import BlueprintSidebar from './BlueprintSidebar'
import BlueprintModal from './BlueprintModal'
import { ConnectedBlueprintAssociations } from './BlueprintAssociations'

export default class CourseSidebar extends Component {
  static propTypes = {
    hasLoadedAssociations: PropTypes.bool.isRequired,
    hasLoadedCourses: PropTypes.bool.isRequired,
    associations: propTypes.courseList.isRequired,
    loadCourses: PropTypes.func.isRequired,
    loadAssociations: PropTypes.func.isRequired,
    saveAssociations: PropTypes.func.isRequired,
    clearAssociations: PropTypes.func.isRequired,
  }

  constructor (props) {
    super(props)
    this.state = {
      isModalOpen: false,
      modalId: null,
    }
  }

  onOpenSidebar = () => {
    if (!this.props.hasLoadedAssociations) {
      this.props.loadAssociations()
    }
  }

  modals = {
    associations: {
      props: {
        title: I18n.t('Associations'),
        onSave: this.props.saveAssociations,
        onCancel: () => this.closeModal(() => {
          this.asscBtn.focus()
          this.props.clearAssociations()
        }),
      },
      children: () => <ConnectedBlueprintAssociations />,
    }
  }

  closeModal = (cb) => {
    this.setState({ isModalOpen: false }, cb)
  }

  handleAssociationsClick = () => {
    if (!this.props.hasLoadedCourses) {
      this.props.loadCourses()
    }
    this.setState({
      isModalOpen: true,
      modalId: 'associations',
    })
  }

  renderModal () {
    const modal = this.modals[this.state.modalId] || { props: { onCancel: this.closeModal }, children: () => null }
    return <BlueprintModal {...modal.props} isOpen={this.state.isModalOpen}>{modal.children}</BlueprintModal>
  }

  render () {
    return (
      <BlueprintSidebar onOpen={this.onOpenSidebar}>
        <div className="bcs__row">
          <Button ref={(c) => { this.asscBtn = c }} variant="link" onClick={this.handleAssociationsClick}>
            <Typography>{I18n.t('Associations')}</Typography>
          </Button>
          <Typography><span className="bcs__row-right-content">{this.props.associations.length}</span></Typography>
        </div>
        {this.renderModal()}
      </BlueprintSidebar>
    )
  }
}

const connectState = state => ({
  associations: state.existingAssociations,
  hasLoadedAssociations: state.hasLoadedAssociations,
  hasLoadedCourses: state.hasLoadedCourses,
})
const connectActions = dispatch => bindActionCreators(actions, dispatch)

export const ConnectedCourseSidebar = connect(connectState, connectActions)(CourseSidebar)
