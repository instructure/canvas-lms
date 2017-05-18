/*
 * Copyright (C) 2016 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import I18n from 'i18n!roster'
import React from 'react'
import PropTypes from 'prop-types'
import Modal, {ModalHeader, ModalBody, ModalFooter} from 'instructure-ui/lib/components/Modal'
import Heading from 'instructure-ui/lib/components/Heading'
import Button from 'instructure-ui/lib/components/Button'
import Spinner from 'instructure-ui/lib/components/Spinner'
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent'
import {courseParamsShape, apiStateShape, inputParamsShape, validateResultShape, personReadyToEnrollShape} from './shapes'
import PeopleSearch from './people_search'
import PeopleReadyList from './people_ready_list'
import PeopleValidationIssues from './people_validation_issues'
import APIError from './api_error'

  const PEOPLESEARCH = 'peoplesearch';
  const PEOPLEREADYLIST = 'peoplereadylist';
  const PEOPLEVALIDATIONISSUES = 'peoplevalidationissues';
  const RESULTPENDING = 'resultpending';
  const APIERROR = 'apierror';

  // @param props: the component's properties to consider
  // @returns true if our user has dealt with all the duplicates and missing
  //          search results
  function arePeopleValidationIssuesResolved (props) {
    function isReadyToCreate (candidate) {
      return !!(candidate.createNew && candidate.newUserInfo
        && candidate.newUserInfo.email);    // newUserInfo.name is now optional
    }

    let found = Object.keys(props.userValidationResult.duplicates).find((address) => {
      const dupe = props.userValidationResult.duplicates[address];
      return !(dupe.selectedUserId >= 0 || dupe.skip || isReadyToCreate(dupe))
    })
    if (found) return false

    found = Object.keys(props.userValidationResult.missing).find((address) => {
      const miss = props.userValidationResult.missing[address];
      return miss.createNew && !isReadyToCreate(miss);
    });
    if (found) return false;

    return true;
  }

  class AddPeople extends React.Component {
    // TODO: deal with defaut props after the warmfix to keep this change small
    /* eslint-disable react/require-default-props */
    static propTypes = {
      isOpen: PropTypes.bool,
      validateUsers: PropTypes.func.isRequired,
      enrollUsers: PropTypes.func.isRequired,
      onClose: PropTypes.func,
      // these props are generated from store state
      courseParams: PropTypes.shape(courseParamsShape),
      apiState: PropTypes.shape(apiStateShape),
      inputParams: PropTypes.shape(inputParamsShape),
      userValidationResult: PropTypes.shape(validateResultShape),
      usersToBeEnrolled: PropTypes.arrayOf(PropTypes.shape(personReadyToEnrollShape)),
      // these are props generated from actions
      setInputParams: PropTypes.func,
      chooseDuplicate: PropTypes.func,
      enqueueNewForDuplicate: PropTypes.func,
      skipDuplicate: PropTypes.func,
      enqueueNewForMissing: PropTypes.func,
      resolveValidationIssues: PropTypes.func,
      reset: PropTypes.func,
      usersEnrolled: PropTypes.bool // eslint-disable-line react/no-unused-prop-types
                                          // it IS used in componentWillReceiveProps.
    };
    /* eslint-enable */

    constructor (props) {
      super(props);

      this.state = {
        currentPage: PEOPLESEARCH, // the page to render
        focusToTop: false          // move focus to the top of the panel
      };
      this.content = null;
    }
    componentDidMount () {
      this.manageFocus();
    }
    componentWillReceiveProps (nextProps) {
      if (nextProps.usersEnrolled) {
        this.close();
      }
    }
    componentDidUpdate () {
      this.manageFocus();
    }


    // event handlers  ---------------------
    // search input changes
    onChangeSearchInput = (newValue) => {
      const inputParams = Object.assign({}, this.props.inputParams, newValue);
      this.props.setInputParams(inputParams);
    }
    // dispensation of duplicate results change
    onChangeDuplicate = (newValues) => {
      if ('selectedUserId' in newValues) {
        // our user chose one of the duplicates
        this.props.chooseDuplicate({
          address: newValues.address,
          user_id: newValues.selectedUserId
        });
      } else if ('newUserInfo' in newValues) {
        // our chose to create a new user instead of chosing a duplicate
        this.props.enqueueNewForDuplicate({
          address: newValues.address,
          newUserInfo: newValues.newUserInfo
        });
      } else if (newValues.skip) {
        // our user chose to skip these duplicates
        this.props.skipDuplicate(newValues.address);
      }
    }
    // our user is updating the new user data for a missing result
    onChangeMissing = ({address, newUserInfo}) => {
      this.props.enqueueNewForMissing({address, newUserInfo});
    }
    // for a11y, whenever the user changes panels, move focus to the top of the content
    manageFocus () {
      if (this.state.focusToTop) {
        if (this.content) {
          this.content.focus();
        }
        this.setState({focusToTop: false});
      }
    }


    // modal next and back handlers ---------------------
    // on next callback from PeopleSearch page
    searchNext = () => {
      this.setState({currentPage: PEOPLEVALIDATIONISSUES, focusToTop: true});
      this.props.validateUsers();
    }
    // on next callback from PeopleValidationIssues page
    validationIssuesNext = () => {
      this.setState({currentPage: PEOPLEREADYLIST, focusToTop: true});
      this.props.resolveValidationIssues();
    }
    // on next callback from the ready list of users
    enrollUsers = () => {
      this.props.enrollUsers();
    }

    // we're finished. close up shop.
    close = () => {
      this.setState({
        currentPage: PEOPLESEARCH,
        focusToTop: true
      });
      if (typeof this.props.onClose === 'function') {
        this.props.onClose();
      }
      this.props.reset();
    }

    // go back to a previous panel in the modal
    // @param pagename: name of the panel to return to
    // @param stateResets: arrayOf(string): which of the state sub-sections
    //                      should get reset to default values.
    //                      undefined implies all
    goBack (pagename, stateResets) {
      this.props.reset(stateResets);
      this.setState({currentPage: pagename, focusToTop: true});
    }
    // different panels go back slightly differently
    apiErrorOnBack = () => {
      this.goBack(PEOPLESEARCH, []);
    }
    peopleReadyOnBack = () => {
      this.goBack(PEOPLESEARCH, undefined);
    }
    peopleValidationIssuesOnBack = () => {
      this.goBack(PEOPLESEARCH, ['userValidationResult']);
    }

    // rendering -------------------------------------
    render () {
      // this.state.currentPage is the requested page,
      // but it may get overridden
      let currentPage = this.state.currentPage;
      if (this.props.apiState.pendingCount) {
        // api call is in-flight
        currentPage = RESULTPENDING;
      } else if (this.props.apiState.error) {
        // api call returned an error
        currentPage = APIERROR;
      } else if (PEOPLEVALIDATIONISSUES === currentPage
          && Object.keys(this.props.userValidationResult.missing).length === 0
          && Object.keys(this.props.userValidationResult.duplicates).length === 0) {
        // user initiated the search, so we plan on going to the validation page,
        // but if the search returned nothing but unique and valid users, then
        // we can skip ahead
        currentPage = PEOPLEREADYLIST;
      }

      let currentPanel = null;          // component in the modal's body
      let onNext = null;                // callback on Next button
      let nextLabel = I18n.t('Next');  // label on Next button
      let readyForNext = false;         // is the Next button enabled?
      let onBack = null;                // callback on the back button
      let backLabel = I18n.t('Back');  // label on eh Back button
      const cancelLabel = I18n.t('Cancel');  // label on the cancel button
      let panelLabel = '';              // tell SR user what this panel is for
      let panelDescription = '';        // tell SR user more info

      switch (currentPage) {
        case RESULTPENDING:
          currentPanel = <Spinner size="medium" title={I18n.t('Loading')} />;
          panelLabel = I18n.t('loading');
          break;
        case APIERROR:
          currentPanel = <APIError error={this.props.apiState.error} />
          onBack = this.apiErrorOnBack;
          panelLabel = I18n.t('error')
          break;
        case PEOPLESEARCH:
        default:
          currentPanel = (
            <PeopleSearch
              {...this.props.inputParams}
              {...this.props.courseParams}
              onChange={this.onChangeSearchInput}
            />
          );
          onNext = this.searchNext;
          readyForNext = this.props.inputParams.nameList.length > 0;
          panelLabel = I18n.t('User search panel');
          panelDescription = I18n.t('Use this panel to search for people you wish to add to this course.');
          break;
        case PEOPLEVALIDATIONISSUES:
          currentPanel = (
            <PeopleValidationIssues
              {...this.props.userValidationResult}
              searchType={this.props.inputParams.searchType}
              inviteUsersURL={this.props.courseParams.inviteUsersURL}
              onChangeDuplicate={this.onChangeDuplicate}
              onChangeMissing={this.onChangeMissing}
            />
          );
          onNext = this.validationIssuesNext;
          onBack = this.peopleValidationIssuesOnBack;
          readyForNext = arePeopleValidationIssuesResolved(this.props);
          panelLabel = I18n.t('User vaildation issues panel');
          panelDescription = I18n.t('Use this panel to resolve duplicate results or people not found with your search.');
          break;
        case PEOPLEREADYLIST:
          currentPanel = (
            <PeopleReadyList
              nameList={this.props.usersToBeEnrolled}
              defaultInstitutionName={this.props.courseParams.defaultInstitutionName}
              canReadSIS={this.props.inputParams.canReadSIS}
            />
          );
          onNext = this.enrollUsers;
          onBack = this.peopleReadyOnBack;
          backLabel = I18n.t('Start Over');
          nextLabel = I18n.t('Add Users');
          readyForNext = this.props.usersToBeEnrolled.length > 0;
          panelLabel = I18n.t('Ready to enroll panel');
          panelDescription = I18n.t('This panel lists the users ready to be added to this course.');
          break;
      }

      return (
        <Modal
          closeButtonLabel={cancelLabel}
          id="add_people_modal"
          isOpen={this.props.isOpen}
          label={I18n.t('Modal Dialog: Add People')}
          onRequestClose={this.close}
          ref={(node) => { this.node = node; }}
          shouldCloseOnOverlayClick={false}
          size="medium"
          tabindex="-1"
        >
          <ModalHeader>
            <Heading tabIndex="-1">{I18n.t('Add People')}</Heading>
          </ModalHeader>
          <ModalBody>
            <div
              className="addpeople"
              tabIndex="-1"
              ref={(elem) => { this.content = elem }}
              aria-label={panelLabel}
              aria-describedby="addpeople_panelDescription"
            >
              <ScreenReaderContent id="addpeople_panelDescription">{panelDescription}</ScreenReaderContent>
              {currentPanel}
            </div>
          </ModalBody>
          <ModalFooter>
            <Button id="addpeople_cancel" onClick={this.close}>{cancelLabel}</Button>
            &nbsp;{onBack ? <Button id="addpeople_back" onClick={onBack}>{backLabel}</Button> : null}
            &nbsp;{onNext
              ? <Button id="addpeople_next" onClick={onNext} variant="primary" disabled={!readyForNext}>{nextLabel}</Button>
              : null}
          </ModalFooter>
        </Modal>
      );
    }
  }

export default AddPeople
