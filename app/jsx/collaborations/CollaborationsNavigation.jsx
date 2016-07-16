define([
  'react',
  'i18n!react_collaborations',
  'jsx/collaborations/NewCollaborationsDropDown',
  'compiled/str/splitAssetString'
], (React, I18n, NewCollaborationsDropDown, splitAssetString) => {
  class CollaborationsNavigation extends React.Component {

    renderNewCollaborationsDropDown () {
      if(this.props.ltiCollaborators.ltiCollaboratorsData.length > 0) {
        return (<NewCollaborationsDropDown
                  ltiCollaborators={this.props.ltiCollaborators.ltiCollaboratorsData}
                  onItemClicked={this.props.onItemClicked} />)
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

  return CollaborationsNavigation;
});
