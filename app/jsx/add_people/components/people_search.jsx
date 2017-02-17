define([
  'i18n!roster',
  'react',
  'instructure-ui',
  './shapes'
], (I18n, React, {Button, Typography, RadioInputGroup,
    RadioInput, Select, TextArea, ScreenReaderContent,
    Checkbox, Alert}, {courseParamsShape, inputParamsShape}) => {
  class PeopleSearch extends React.Component {
    static propTypes = Object.assign({}, inputParamsShape, courseParamsShape);

    static defaultProps = {
      searchType: 'cc_path',
      nameList: []
    };

    constructor (props) {
      super(props);

      this.namelistta = null;
    }
    shouldComponentUpdate (nextProps /* , nextState */) {
      return nextProps.searchType !== this.props.searchType
          || nextProps.nameList.join(',') !== this.props.nameList.join(',')
          || nextProps.role !== this.props.role
          || nextProps.section !== this.props.section
          || nextProps.limitPrivilege !== this.props.limitPrivilege;
    }


    // event handlers ------------------------------------
    // inst-ui form elements are currently inconsistent in what args they send
    // to their onChange handler. Some send the event, others just the new value.
    // When they all send the event, we can coallesce these onChange handlers
    // into one and use the name attribute to set the proper state
    onChangeSearchType = (newValue) => {
      this.props.onChange({searchType: newValue});
    }
    onChangeNameList = (newValue) => {
      let nameList = newValue.trim();
      // split the user enteredd name list on commas,
      // then trim each result
      nameList = nameList.length ? nameList.split(/\s*,\s*/).map(n => n.trim()) : [];
      this.props.onChange({nameList});
    }
    onChangeSection = (event) => {
      this.props.onChange({section: event.target.value});
    }
    onChangeRole = (event) => {
      this.props.onChange({role: event.target.value});
    }
    onChangePrivilege = (event) => {
      this.props.onChange({limitPrivilege: event.target.checked});
    }

    // rendering ------------------------------------
    render () {
      let exampleText = '';
      let labelText = '';
      switch (this.props.searchType) {
        case 'sis_user_id':
          exampleText = 'student_2708, student_3693';
          labelText = I18n.t('Enter the SIS IDs of the users you would like to add, separated by commas');
          break;
        case 'unique_id':
          exampleText = 'lsmith, mfoster';
          labelText = I18n.t('Enter the login IDs of the users you would like to add, separated by commas');
          break;
        case 'cc_path':
        default:
          exampleText = 'lsmith@myschool.edu, mfoster@myschool.edu';
          labelText = I18n.t('Enter the Email addresses of the users you would like to add, separated by commas');
      }

      return (
        <div className="addpeople__peoplesearch">
          <RadioInputGroup
            name="search_type"
            defaultValue={this.props.searchType}
            description={I18n.t('Add user(s) by')}
            onChange={this.onChangeSearchType}
          >
            <RadioInput
              id="peoplesearch_radio_cc_path"
              isBlock={false}
              key="cc_path"
              value="cc_path"
              label={I18n.t('Email Address')}
            />
            <RadioInput
              id="peoplesearch_radio_unique_id"
              isBlock={false}
              key="unique_id"
              value="unique_id"
              label={I18n.t('Login ID')}
            />
            {this.props.canReadSIS
              ? <RadioInput
                id="peoplesearch_radio_sis_user_id"
                isBlock={false}
                key="sis_user_id"
                value="sis_user_id"
                label={I18n.t('SIS ID')}
              />
              : null}
          </RadioInputGroup>
          <fieldset>
            <div style={{marginBottom: '.5em'}}>{I18n.t('Example:')} {exampleText}</div>
            <TextArea
              label={<ScreenReaderContent>{labelText}</ScreenReaderContent>}
              autoGrow={false} resize="vertical" height="9em"
              value={this.props.nameList.join(',')} textareaRef={(ta) => { this.namelistta = ta; }}
              onChange={this.onChangeNameList}
            />
          </fieldset>
          <fieldset className="peoplesearch__selections">
            <div>
              <div className="peoplesearch__selection">
                <Select
                  id="peoplesearch_select_role"
                  label={I18n.t('Role')} isBlock
                  value={this.props.role}
                  onChange={this.onChangeRole}
                >
                  {
                    this.props.roles.map(r => <option key={`r_${r.name}`} value={r.id}>{r.label}</option>)
                  }
                </Select>
              </div>
              <div className="peoplesearch__selection">
                <Select
                  id="peoplesearch_select_section"
                  label={I18n.t('Section')}
                  isBlock
                  value={this.props.section}
                  onChange={this.onChangeSection}
                >
                  {
                    this.props.sections.map(s => <option key={`s_${s.id}`} value={s.id}>{s.name}</option>)
                  }
                </Select>
              </div>
            </div>
            <div style={{marginTop: '1em'}}>
              <Checkbox
                key="limit_privileges_to_course_section"
                id="limit_privileges_to_course_section"
                label={I18n.t('Can interact with users in their section only')}
                isBlock value={0}
                checked={this.props.limitPrivilege}
                onChange={this.onChangePrivilege}
              />
            </div>
          </fieldset>
          <div className="peoplesearch__instructions">
            <i className="icon-user" />
            <Typography size="medium">
              {I18n.t('Add user by Email Address, Login ID, or SIS ID.')}<br />
              {I18n.t('Use "," between for adding multiple users.')}
            </Typography>
          </div>
        </div>
      );
    }
  }

  return PeopleSearch;
});
