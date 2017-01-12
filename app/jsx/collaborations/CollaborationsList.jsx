define([
  'react',
  './Collaboration',
  '../shared/load-more',
  './store/store'
], (React, Collaboration, LoadMore, {dispatch}) => {
  class CollaborationsList extends React.Component {

    constructor (props) {
      super(props);
      this.loadMoreCollaborations = this.loadMoreCollaborations.bind(this);
    }

    loadMoreCollaborations () {
      React.findDOMNode(this.refs[`collaboration-${this.props.collaborationsState.list.length - 1}`]).focus();
      dispatch(this.props.getCollaborations(this.props.collaborationsState.nextPage));
    }

    render () {
      return (
        <div className='CollaborationsList'>
          <LoadMore
            isLoading={this.props.collaborationsState.listCollaborationsPending}
            hasMore={!!this.props.collaborationsState.nextPage}
            loadMore={this.loadMoreCollaborations} >
            {this.props.collaborationsState.list.map((c, index) => (
              <Collaboration ref={`collaboration-${index}`} key={c.id} collaboration={c} deleteCollaboration={this.props.deleteCollaboration} openModal={this.props.openModal} />
            ))}
          </LoadMore>
        </div>
      )
    }
  };

  CollaborationsList.propTypes = {
    collaborationsState: React.PropTypes.object.isRequired,
    deleteCollaboration: React.PropTypes.func.isRequired,
    getCollaborations: React.PropTypes.func.isRequired,
    openModal: React.PropTypes.func
  };

  return CollaborationsList;
})
