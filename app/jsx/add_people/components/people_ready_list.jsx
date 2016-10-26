define([
  'i18n!roster',
  'react',
  './shapes',
  'instructure-ui/Alert',
  'instructure-ui/Table',
  'instructure-ui/ScreenReaderContent'
], (I18n, React, {personReadyToEnrollShape},
   {default: Alert}, {default: Table}, {default: ScreenReaderContent}) => {
  function PeopleReadyList (props) {
    return (
      <div className="addpeople__peoplereadylist">
        <div className="peoplereadylist__pad-box">
          <Alert variant="success" isDismissable={false}>{I18n.t('The following users are ready to be added to the course.')}</Alert>
        </div>
        <Table caption={<ScreenReaderContent>{I18n.t('User list')}</ScreenReaderContent>}>
          <thead>
            <tr>
              <th>{I18n.t('Name')}</th>
              <th>{I18n.t('Email Address')}</th>
              <th>{I18n.t('Login ID')}</th>
              <th>{I18n.t('SIS ID')}</th>
              <th>{I18n.t('Institution')}</th>
            </tr>
          </thead>
          <tbody>
            {props.nameList.map((n, i) => (
              <tr key={`${n.address}_${i}`}>
                <td>{n.user_name}</td>
                <td>{n.email}</td>
                <td>{n.login_id || ''}</td>
                <td>{n.sis_user_id || ''}</td>
                <td>{n.account_name || props.defaultInstitutionName}</td>
              </tr>
            ))}
          </tbody>
        </Table>
      </div>
    );
  }

  PeopleReadyList.propTypes = {
    nameList: React.PropTypes.arrayOf(React.PropTypes.shape(personReadyToEnrollShape)),
    defaultInstitutionName: React.PropTypes.string
  }
  PeopleReadyList.defaultProps = {
    nameList: [],
    defaultInstitutionName: ''
  }

  return PeopleReadyList;
});
