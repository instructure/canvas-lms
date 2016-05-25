define([
  'react'
], (React) => {
  class CollaborationsApp extends React.Component {
    static propTypes: {
      applicationState: React.PropTypes.object,
      actions: React.PropTypes.object
    }

    render () {
      return (
        <div className='CollaborationsApp'>
          We've got ourselves a placeholder
        </div>
      );
    }
  };

  return CollaborationsApp;
});
