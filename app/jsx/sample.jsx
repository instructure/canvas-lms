/** React.DOM */

// first person to actually save a .jsx file, please delete this file.

define(['React'], function(React) {

  var Thing = React.createClass({
    render () {
      return (
        <div>Look ma! no "function"</div>
      );
    }
  });

  React.renderComponent(<Thing/>, document.getElementById('content'));

});
