define([
  'react',
], (React) => {
  const PaginatedUserCheckList = React.createClass({
    getDefaultProps () {
      return {
        permanentUsers: [],
        checked: [],
      }
    },

    _isChecked (id) {
      return this.props.checked.includes(id)
    },

    render () {
      const permanentListItems = this.props.permanentUsers.map(u =>
        <li key={u.id}>
          <label className="checkbox">
            <input checked="true"
              type="checkbox"
              disabled="true"
              readOnly="true" />
           {u.name || u.display_name}
         </label>
       </li>
     )

      const listItems = this.props.users.map(u =>
        <li key={u.id}>
          <label className="checkbox">
            <input checked={this._isChecked(u.id)}
              onChange={(e) => this.props.onUserCheck(u, e.target.checked)}
              type="checkbox" />
          {u.name || u.display_name}
          </label>
        </li>
      )

      return (
        <ul className="unstyled_list">
          {permanentListItems}
          {listItems}
        </ul>
      )
    },
  })

  return PaginatedUserCheckList
})
