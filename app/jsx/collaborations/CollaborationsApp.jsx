define([
  'react',
  'jsx/collaborations/GettingStartedCollaborations',
  'jsx/collaborations/CollaborationsNavigation'
], (React, GettingStartedCollaborations, CollaborationsNavigation) => {
  class CollaborationsApp extends React.Component {
    static propTypes: {
      applicationState: React.PropTypes.object,
      actions: React.PropTypes.object
    }

    render () {
      return (
        <div className="CollaborationsApp">
          <div id="wrapperCollaborations">
            <CollaborationsNavigation ltiCollaborators={this.props.applicationState.ltiCollaborators}/>
            <GettingStartedCollaborations ltiCollaborators={this.props.applicationState.ltiCollaborators}/>
          </div>
        </div>
      );
    }
  };

  return CollaborationsApp;
});
