import React from 'react'
import I18n from 'i18n!react_collaborations'
import NewCollaborationsDropDown from 'jsx/collaborations/NewCollaborationsDropDown'

class CollaborationsNavigation extends React.Component {

  renderNewCollaborationsDropDown () {
    if (this.props.ltiCollaborators.ltiCollaboratorsData.length > 0) {
      return (
        <NewCollaborationsDropDown
          ltiCollaborators={this.props.ltiCollaborators.ltiCollaboratorsData}
        />
      )
    }
    return null;
  }

  render () {
    return (
      <div className="ic-Action-header">
        <div className="ic-Action-header__Primary">
          <h1 className="screenreader-only">{I18n.t('Collaborations')}</h1>
        </div>
        <div className="ic-Action-header__Secondary">
          {this.renderNewCollaborationsDropDown()}
        </div>
      </div>
    )
  }
}

CollaborationsNavigation.propTypes = {
  ltiCollaborators: React.PropTypes.object.isRequired,
  actions: React.PropTypes.object
};

export default CollaborationsNavigation
