define([
  'react',
  'jsx/collaborations/GettingStartedCollaborations',
  'jsx/collaborations/CollaborationsNavigation',
  './CollaborationsList'
], (React, GettingStartedCollaborations, CollaborationsNavigation, CollaborationsList) => {
  class CollaborationsApp extends React.Component {
    static propTypes: {
      applicationState: React.PropTypes.object,
      actions: React.PropTypes.object
    }

    render () {
      let { list } = this.props.applicationState.listCollaborations;
      return (
        <div className="CollaborationsApp">
          <CollaborationsNavigation ltiCollaborators={this.props.applicationState.ltiCollaborators}/>
          {list.length
            ? <CollaborationsList collaborations={list} />
            : <GettingStartedCollaborations ltiCollaborators={this.props.applicationState.ltiCollaborators}/>
          }
        </div>
      );
    }
  };

  return CollaborationsApp;
});
