define([
  'react',
  './Collaboration'
], (React, Collaboration) => {
  class CollaborationsList extends React.Component {
    render () {
      return (
        <div className='CollaborationsList'>
          {this.props.collaborations.map(c => (
            <Collaboration key={c.id} collaboration={c} />
          ))}
        </div>
      )
    }
  };

  CollaborationsList.propTypes = {
    collaborations: React.PropTypes.array
  };

  return CollaborationsList
})
