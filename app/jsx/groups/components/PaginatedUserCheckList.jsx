/** @jsx React.DOM */

define([
  'underscore',
  'old_unsupported_dont_use_react',
], (_, React) => {
  var PaginatedUserCheckList = React.createClass({
    getDefaultProps() {
      return {
        permanentUsers: [],
        checked: []
      };
    },

    _isChecked(id) {
      return _.contains(this.props.checked, id);
    },

    render() {
      var permanentListItems = this.props.permanentUsers.map(u =>
                                                             <li key={u.id}>
                                                               <label className="checkbox">
                                                                 <input  checked="true"
                                                                         type="checkbox"
                                                                         disabled="true"
                                                                         readOnly="true"/>
                                                                 {u.name || u.display_name}
                                                               </label>
                                                             </li>);
      var listItems = this.props.users.map(u =>
                                           <li key={u.id}>
                                             <label className="checkbox">
                                               <input  checked={this._isChecked(u.id)}
                                                       onChange={(e) => this.props.onUserCheck(u, e.target.checked)}
                                                       type="checkbox" />
                                               {u.name || u.display_name}
                                             </label>
                                           </li>);

      return (
        <ul className="unstyled_list">
          {permanentListItems}
          {listItems}
        </ul>);
    }
  });

  return PaginatedUserCheckList;
});
