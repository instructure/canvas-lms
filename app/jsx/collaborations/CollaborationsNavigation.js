import React from 'react'
import I18n from 'i18n!react_collaborations'
import NewCollaborationsDropDown from 'jsx/collaborations/NewCollaborationsDropDown'
import splitAssetString from 'compiled/str/splitAssetString'
  class CollaborationsNavigation extends React.Component {

    renderNewCollaborationsDropDown () {
      if(this.props.ltiCollaborators.ltiCollaboratorsData.length > 0) {
        return (<NewCollaborationsDropDown
                  ltiCollaborators={this.props.ltiCollaborators.ltiCollaboratorsData} />)
      }
    }

    render () {
      const splitString = splitAssetString(ENV.context_asset_string)
      const url = `/${splitString[0]}/${splitString[1]}/collaborations`;
      return (
        <div className="ic-Action-header">
          <div className="ic-Action-header__Secondary">
            {this.renderNewCollaborationsDropDown()}
          </div>
        </div>
      )
    }
  };

  CollaborationsNavigation.propTypes = {
    ltiCollaborators: React.PropTypes.object.isRequired,
    actions: React.PropTypes.object
  };

export default CollaborationsNavigation
