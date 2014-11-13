/** @jsx React.DOM */

define([
  'underscore',
  'react',
  'jsx/groups/mixins/InfiniteScroll'
], (_, React, InfiniteScroll) => {
  var PaginatedUserCheckList = React.createClass({
    mixins: [InfiniteScroll],

    loadMore() {
      this.props.loadMore();
    },

    _isChecked(id) {
      return _.contains(this.props.checked, id);
    },

    render() {
      listItems = this.props.users.map(u =>
                                       <li key={u.id}>
                                         <label className="checkbox">
                                           <input  checked={this._isChecked(u.id)}
                                                   onChange={(e) => this.props.onUserCheck(u, e.target.checked)}
                                                   type="checkbox" />
                                           {u.name}
                                         </label>
                                       </li>);

      return (
        <ul className="unstyled_list">
          {listItems}
        </ul>);
    }
  });

  return PaginatedUserCheckList;
});
