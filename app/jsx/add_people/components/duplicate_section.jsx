define([
  'i18n!roster',
  'react',
  './shapes',
  'instructure-ui/Table',
  'instructure-ui/ScreenReaderContent',
  'instructure-ui/TextInput',
  'instructure-ui/RadioInput',
  'instructure-ui/Typography',
  'instructure-ui/Link'
], (I18n, React, shapes, {default: Table}, {default: ScreenReaderContent},
    {default: TextInput}, {default: RadioInput}, {default: Typography}, {default: Link}) => {
  const CREATE_NEW = '__CREATE_NEW__';
  const SKIP = '__SKIP';
  const nameLabel = I18n.t("New user's name");
  const emailLabel = I18n.t('Required Email Address');

  function eatEvent (event) {
    event.stopPropagation();
  }

  class DuplicateSection extends React.Component {
    static propTypes = {
      duplicates: React.PropTypes.shape(shapes.duplicateSetShape).isRequired,
      onSelectDuplicate: React.PropTypes.func.isRequired,
      onNewForDuplicate: React.PropTypes.func.isRequired,
      onSkipDuplicate: React.PropTypes.func.isRequired,
      inviteUsersURL: React.PropTypes.string
    };
    static defaultProps = {
      inviteUsersURL: undefined
    }

    // event handlers ----------------------------------------
    // user has selected a user from the list of duplicates
    onSelectDuplicate = (event) => {
      const userId = event.target.value;
      const selectedUser = this.findUserById(userId);
      this.props.onSelectDuplicate(this.props.duplicates.address, selectedUser);
    }

    // user has chosen to create a new user for this group of duplicates
    // event comes either from the radio button or the adjacent link
    onSelectNewForDuplicate = (event) => {
      // if the event was not from the radio button, find and focus it
      if (!(event.target.tagName === 'input' && event.target.getAttribute('type') === 'radio')) {
        let elem = event.target;
        for (; elem.tagName !== 'TR'; elem = elem.parentElement);
        const radioButton = elem.querySelector('input[type="radio"]');
        radioButton.focus();
      }
      this.props.onNewForDuplicate(this.props.duplicates.address, this.props.duplicates.newUserInfo);
    }

    // when either of the TextInputs for creating a new user from a duplicate list
    // changes, we come here to collect the input
    // @param field: the field of the new user we're providig (sice TextInput doesn't have a name attr)
    //                will be either "name" or "email"
    // @param event: the event that triggered the change
    onNewForDuplicateChange = (event) => {
      const field = event.target.getAttribute('name');
      const newUserInfo = this.props.duplicates.newUserInfo;
      const newUser = {
        name: (newUserInfo && newUserInfo.name) || '',
        email: (newUserInfo && newUserInfo.email) || ''
      };
      newUser[field] = event.target.value;
      this.props.onNewForDuplicate(this.props.duplicates.address, newUser, false);
    }

    // when the user chooses not to include any user from this set of duplicates
    onSkipDuplicate = () => {
      this.props.onSkipDuplicate(this.props.duplicates.address);
    }

    // helper ------------------------------------
    findUserById (userId) {
      let retval = null;
      for (let i = 0; i < this.props.duplicates.userList.length; ++i) {
        const user = this.props.duplicates.userList[i];
        // match as string or number
        if (user.user_id == userId) { // eslint-disable-line eqeqeq
          retval = user;
          break;
        }
      }
      return retval;
    }

    // rendering ------------------------------------
    // render all the users in props.duplicates
    // @returns array of table rows
    renderDupeList () {
      const duplicateSet = this.props.duplicates;

      // first, render a row for each of the existing duplicate users
      const rows = duplicateSet.userList.map((dupe, i) => {
        const k = `dupe_${duplicateSet.address}_${i}`;
        const checked = duplicateSet.selectedUserId === dupe.user_id;
        return (
          <tr key={k}>
            <td>
              <RadioInput
                value={dupe.user_id} name={duplicateSet.address} onChange={this.onSelectDuplicate} checked={checked}
                label={<ScreenReaderContent>{I18n.t('Click to select user %{name}', {name: dupe.user_name})}</ScreenReaderContent>}
              />
            </td>
            <td>{dupe.user_name}</td>
            <td>{dupe.email}</td>
            <td>{dupe.login_id}</td>
            <td>{dupe.sis_user_id || ''}</td>
            <td>{dupe.account_name || ''}</td>
          </tr>
        )
      });
      if (this.props.inviteUsersURL) {
        // next, add a row for creating a new user for this login id
        if (duplicateSet.createNew) {
          // render the row as an editor
          rows.push(
            <tr key={duplicateSet.address + CREATE_NEW} className="create-new">
              <td>
                <RadioInput
                  value={CREATE_NEW}
                  name={duplicateSet.address}
                  onChange={eatEvent}
                  checked
                  label={<ScreenReaderContent>{I18n.t('Click to create a new user for %{address}',
                                                  {address: duplicateSet.address})}</ScreenReaderContent>}
                />
              </td>
              <td>
                <TextInput
                  required
                  name="name"
                  type="text"
                  placeholder={nameLabel}
                  label={<ScreenReaderContent>{nameLabel}</ScreenReaderContent>}
                  value={duplicateSet.newUserInfo.name}
                  onChange={this.onNewForDuplicateChange}
                />
              </td>
              <td>
                <TextInput
                  required
                  name="email"
                  type="email"
                  placeholder={emailLabel}
                  label={<ScreenReaderContent>{emailLabel}</ScreenReaderContent>}
                  value={duplicateSet.newUserInfo.email}
                  onChange={this.onNewForDuplicateChange}
                />
              </td>
              <td colSpan="3" />
            </tr>
          );
        } else {
          // render the row as a hint to the user
          rows.push(
            <tr key={duplicateSet.address + CREATE_NEW} className="create-new" >
              <td>
                <RadioInput
                  value={CREATE_NEW} name={duplicateSet.address} onChange={this.onSelectNewForDuplicate} checked={false}
                  label={<ScreenReaderContent>{I18n.t('Click to create a new user for %{login}',
                                                    {login: duplicateSet.address})}</ScreenReaderContent>}
                />
              </td>
              <td colSpan="5" >
                <Link
                  onClick={this.onSelectNewForDuplicate}
                >
                  {I18n.t('Create a new user for "%{address}"', {address: duplicateSet.address})}
                </Link>
              </td>
            </tr>
          );
        }
      }
      // finally, the skip this user row
      rows.push(
        <tr key={duplicateSet.address + SKIP} className="skip-addr">
          <td>
            <RadioInput
              value={SKIP} name={duplicateSet.address} onChange={this.onSkipDuplicate} checked={duplicateSet.skip}
              label={<ScreenReaderContent>{I18n.t('Click to skip %{address}', {address: duplicateSet.address})}</ScreenReaderContent>}
            />
          </td>
          <td colSpan="5" >
            <Link onClick={this.onSkipDuplicate}>{I18n.t('Don’t add this user for now.')}</Link>
          </td>
        </tr>

      );
      return rows;
    }

    render () {
      return (
        <div className="addpeople__duplicates namelist" key={`dupe_${this.props.duplicates.address}`}>
          <Table
            caption={
              <Typography>
                {I18n.t('Possible matches for "%{address}". Select the correct one below or create a new user.',
                      {address: this.props.duplicates.address})}
              </Typography>
            }
          >
            <thead>
              <tr>
                <th scope="col"><ScreenReaderContent>{I18n.t('User Selection')}</ScreenReaderContent></th>
                <th scope="col">{I18n.t('Name')}</th>
                <th scope="col">{I18n.t('Email Address')}</th>
                <th scope="col">{I18n.t('Login ID')}</th>
                <th scope="col">{I18n.t('SIS ID')}</th>
                <th scope="col">{I18n.t('Institution')}</th>
              </tr>
            </thead>
            <tbody>
              {this.renderDupeList()}
            </tbody>
          </Table>
        </div>
      );
    }
  }
  return DuplicateSection;
});
