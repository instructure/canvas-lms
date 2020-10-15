import React from 'react'
import ReactCSSTransitionGroup from 'react-addons-css-transition-group'
import styled from 'styled-components'
import axios from 'axios'
import parseLinkHeader from 'jsx/shared/helpers/parseLinkHeader'
import IcInput from 'jsx/account_course_user_search/IcInput'
import $ from 'jquery'
import I18n from 'i18n!profile'
import IconUserSolid from 'instructure-icons/lib/Solid/IconUserSolid'
import IconGroupSolid from 'instructure-icons/lib/Solid/IconGroupSolid'
import IconCheckSolid from 'instructure-icons/lib/Solid/IconCheckSolid'
import IconEndSolid from 'instructure-icons/lib/Solid/IconEndSolid'
import IconArrowOpenLeftSolid from 'instructure-icons/lib/Solid/IconArrowOpenLeftSolid'
import IconArrowOpenRightSolid from 'instructure-icons/lib/Solid/IconArrowOpenRightSolid'
import IconDocumentSolid from 'instructure-icons/lib/Solid/IconDocumentSolid'
import IconWarningSolid from 'instructure-icons/lib/Solid/IconWarningSolid'

const Card = styled.div`
  border: 1px solid #D7D7D7;
  border-radius: 4px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.3);
  text-align: center;
  height: 100%;
  width: 100%;
  max-width: 920px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  position: relative;

  h3 {
    font-family: 'Open Sans', sans-serif;
    font-weight: 600;
    letter-spacing: 0.2px;
  }

  label {
    font-family: 'Open Sans', sans-serif;
    font-size: 12px;
    margin-right: 10px;
  }

  .card-content {
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 2rem;
    width: 100%;
  }

  .descriptive-text {
    color: #5e5e5e;
    font-size: 12px;
    font-style: italic;
    font-family: 'Open Sans', sans-serif;
    margin-top: 0;
  }

  .font-bold {
    font-weight: bold;
  }

  .review-users {
    border-color: #5e5e5e;
    color: #5e5e5e;
    font-weight: bold;
  }

  .clear-all {
    background-color: #ae0734;
    border-color: #ae0734;
    color: #ffffff;
    transition: all 0.2s;

    &:hover {
      background-color: #C8254F;
      border-color: #C8254F;
    }
  }

  .full-width {
    width: 100%;
  }

  .button-container {
    .submit-button {
      margin-right: 1rem;
    }
  }

  // transitions
  .warning-enter {
    opacity: 0.01;
    height: 0;
  }
  
  .warning-enter.warning-enter-active {
    opacity: 1;
    transition: opacity 500ms ease-in;
    height: auto;
  }
  
  .warning-leave {
    opacity: 1;
  }
  
  .warning-leave.warning-leave-active {
    opacity: 0.01;
    transition: opacity 300ms ease-in;
  }
`

const Step = styled.div`
  display: flex;
  align-items: center;
  justify-content: center;
  height: 32px;
  width: 32px;
  background: #5CA0C6;
  border-radius: 100%;

  &.active-step {
    background: #006ba6;
  }

  > * {
    color: #ffffff;
    font-size: 16px;
  }
`

const Icon = styled.div`
  display: flex;
  align-items: center;
  justify-content: center;
  height: 48px;
  width: 48px;
  background: #006ba6;
  border-radius: 100%;
  margin-bottom: 0.5rem;

  > * {
    color: #ffffff;
    font-size: 24px;
  }
`

const PillContainer = styled.div`
  display: flex;
  flex-flow: row wrap;
  justify-content: center;

  > * {
    margin: 0.2rem;
  }
`

const Pill = styled.div`
  background: #006ba6;
  display: flex;
  align-items: center;
  padding: 0 0.5rem;
  border-radius: 25px;

  &.observees-to-remove {
    background: transparent;
    border: 2px solid #006ba6;

    > * {
      color: #006ba6;
      display: flex;
      align-items: center;
      cursor: pointer;

      &:hover {
        text-decoration: none;
      }
    }

    &.selected {
      background: #006ba6;

      > * {
        color: #ffffff;
      }
    }
  }

  > * {
    color: #ffffff;
  }
  
  p {
    font-family: 'Open Sans', sans-serif;
    font-size: 10px;
    font-weight: 600;
    margin-top: 0;
    margin-bottom: 0;
  }

  svg {
    margin-left: 10px;
    font-size: 9px;
  }
`

const Observer = styled.p`
  color: #5e5e5e;
  font-family: 'Open Sans', sans-serif;
  font-size: 12px;
  margin-top: 0;
`

const UserSearchResults = styled.div`
  background: #ffffff;
  border: 1px solid #ccc;
  border-top: 0;
  border-bottom-left-radius: 4px;
  border-bottom-right-radius: 4px;
  box-sizing: border-box;
  position: absolute;
  z-index: 3;
  width: 100%;

  footer {
    display: flex;
    justify-content: space-between;
  }

  &.hidden {
    display: none;
  }
`

const UserSearch = styled.div`
  width: 70%;
  margin-top: 2rem;
  position: relative;

  .ic-Form-control {
    margin-bottom: 0;

    input {
      font-family: 'Open Sans', sans-serif;
    }

    label {
      text-align: left;
    }
  }
`

const UserList = styled.ul`
  font-size: 12px;
  list-style-type: none;
  margin-left: 0;

  li {
    padding: 0.2rem;
    transition: all 0.2s ease-in-out;

    &:hover, &.active {
      background: #006ba6;
      cursor: pointer;
      color: #ffffff;
    }
  }
`

const ClearSearch = styled.div`
  position: absolute;
  bottom: 0;
  right: 0;
  z-index: 3;
  
  svg {
    color: #5e5e5e;
    font-size: 12px;
    padding: 0.5rem;

    &:hover {
      cursor: pointer;
    }
  }
`

const Previous = styled.a`
  color: #006ba6;
  display: inline-block;
  font-family: 'Open Sans', sans-serif;
  font-size: 11px;
  font-weight: bold;
  padding: 0.25rem;

  &:hover:not(.disabled) {
    cursor: pointer;
  }

  &.disabled {
    color: #7e7e7e;

    &:hover {
      text-decoration: none;
    }
  }
`

const Next = styled.a`
  color: #006ba6;
  display: inline-block;
  font-family: 'Open Sans', sans-serif;
  font-size: 11px;
  font-weight: bold;
  padding: 0.25rem;

  &:hover:not(.disabled) {
    cursor: pointer;
  }

  &.disabled {
    color: #7e7e7e;

    &:hover {
      text-decoration: none;
    }
  }
`

const Button = styled.button`
  &:not(.traverse) {
    margin-top: 2rem;
  }

  &.invisible {
    visibility: hidden;
  }
`

const Zero = styled.div`
  padding: 2rem;
  margin: 0 auto;

  object {
      max-width: 13rem;
  }

  ${PillContainer} {
    margin-bottom: 2rem;
  }
`
const ObserveeWarning = styled.div`
  background: #eaeaea;
  padding: 1rem;

  > * {
    display: flex;
    align-items: center;
    justify-content: center;

    &:first-child {
      margin-bottom: 15px;
    }
  }

  p {
    color: #AE0734;
    font-family: 'Open Sans', sans-serif;
    font-size: 12px;
    margin: 0;
  }

  svg {
    color: #AE0734;
    margin-right: 10px;
  }

  button:not(:last-of-type) {
    margin-right: 10px;
  }
`

class AssignObservers extends React.Component {
  constructor(props) {
    super(props);

    let collection = this.props.users;

    this.state = {
      users: [],
      first: collection.urls.first,
      last: collection.urls.last,
      previous: collection.urls.prev,
      next: collection.urls.next,
      current: collection.urls.current,
      observer: {},
      observeesToAdd: [],
      observeesToRemove: [],
      currentObserversObservees: [],
      step: 1,
      searchTerm: '',
      addDisabled: false,
      removeDisabled: false,
      removeAllDisabled: false,
    }
  }
  
  static defaultProps = {
    users: [],
  };

  restart() {
    this.setState({
      observer: {},
      observeesToAdd: [],
      observeesToRemove: [],
      currentObserversObservees: [],
      step: 1,
      searchTerm: '',
      addDisabled: false,
      removeDisabled: false,
      removeAllDisabled: false,
    })
  }

  clickPrevious() {
    if (this.state.previous) {
      axios.get(this.state.previous).then(response => {
        this.parseResponseLinks(response);
      })
    }
  }

  clickNext() {
    if (this.state.next) {
      axios.get(this.state.next).then(response => {
        this.parseResponseLinks(response);
      })
    }
  }

  parseResponseLinks(response) {
    let links = parseLinkHeader(response)

    this.setState({
      users: response.data,
      previous: links.prev,
      next: links.next,
      current: links.current,
      first: links.first,
      last: links.last
    })
  }

  filterUsers() {
    let observer_id = this.state.observer.id
    if (this.state.step === 1 || !observer_id) { return this.state.users }
    return this.state.users.filter(user => {
      return user.id !== observer_id && !this.state.currentObserversObservees.some(obs => obs.id === user.id)
    })
  }

  clearSearch() {
    this.setState({ searchTerm: '' })
  }

  assign(user) {
    if (this.state.step === 2) {
      this.setState({observeesToAdd: this.state.observeesToAdd.concat(user)})
    } else {
      this.setState({
        observer: user,
        observeesToAdd: this.state.observeesToAdd.filter(obs => obs.id !== user.id),
        searchTerm: ''
      }, () => {
        this.getCurrentObservees()
      })
    }
  }

  remove(user) {
    this.setState({observeesToAdd: this.state.observeesToAdd.filter(obs =>  obs.id !== user.id)});
  }

  isActive(user) {
    if (this.state.step === 1) {
      return user.id === this.state.observer.id 
    } else if (this.state.step === 2) {
      return this.state.observeesToAdd.some(obs => obs.id === user.id)
    }
  }
  
  renderUsers() {
    return this.filterUsers().map(user => {
      let clsname = this.isActive(user) ? "active" : ""
      return (
        <li className={clsname} onClick={(() => clsname ? undefined : this.assign(user))}>{user.name}</li>
      )
    });
  }

  paginationDisabledCheck(direction) {
    if (direction === "previous" && this.state.first === this.state.current) {
      return "disabled"
    } else if (direction === "next" && this.state.last === this.state.current) {
      return "disabled"
    } else {
      return ""
    }
  }
  
  searchInput() {
    return (
      <fieldset>
          <IcInput type="search" placeholder="Search" value={this.state.searchTerm}
            ref="userSearch" label="Find a user:" onInput={e => this.debouncedFilterBySearch(e.target.value)}></IcInput>
          {this.state.searchTerm !== '' &&
            <ClearSearch onClick={() => this.clearSearch()}>
              <IconEndSolid/>
            </ClearSearch>
          }
          {this.state.users.length > 0 &&
            <UserSearchResults className={this.state.searchTerm === '' ? 'hidden' : ''}>
              <UserList>
                {this.renderUsers()}
              </UserList>
              <footer>
                <Previous className={this.paginationDisabledCheck("previous")} onClick={this.clickPrevious.bind(this)}>Previous</Previous>
                <Next className={this.paginationDisabledCheck("next")} onClick={this.clickNext.bind(this)}>Next</Next>
              </footer>
            </UserSearchResults>
          }
      </fieldset>
    )
  }

  incrementStep() {
    if (this.state.step === 1 && this.state.observer.id) {
      this.getCurrentObservees().then(() => {
        this.setState({step: this.state.step + 1})
      })
    } else {
      this.setState({step: this.state.step + 1})
    }
  }

  decrementStep() {
    // need to go back to step 1 if on review removals step
    this.setState({step: this.state.step === 5 ? 1 : this.state.step - 1})
  }

  chooseStep() {
    switch (this.state.step) {
      case 1:
        return this.stepOne()
      case 2:
        return this.stepTwo()
      case 3:
        return this.stepThree()
      case 4:
        return this.stepFour()
      case 5:
        return this.bulkRemove()
      case 6:
        return this.bulkRemoveSuccess()
      default:
        return this.stepOne()
    }
  }
  
  stepOne() {
    return (
      <div className="card-content">
        <Icon role="presentation">
          <IconUserSolid/>
        </Icon>
        <h3>Choose an Observer</h3>
        <p className="descriptive-text">This is the person that will be observing multiple students at one time.</p>

        <ReactCSSTransitionGroup
          component="div"
          className="full-width"
          transitionName="warning"
          transitionEnterTimeout={500}
          transitionLeaveTimeout={300}>
          {this.state.observer.name &&
            <Observer>Selected: <span className="font-bold">{this.state.observer.name}</span></Observer>
          }
        </ReactCSSTransitionGroup>

        <ReactCSSTransitionGroup
          component="div"
          className="full-width"
          transitionName="warning"
          transitionEnterTimeout={500}
          transitionLeaveTimeout={300}>
          {this.state.currentObserversObservees.length > 0 && 
            <ObserveeWarning>
              <div>
                <IconWarningSolid />
                <p>
                  <span className="font-bold">{this.state.observer.name}</span> is already observing <span className="font-bold">{this.state.currentObserversObservees.length} users</span>
                </p>
              </div>
              <div>
                <button className="btn btn-small review-users" 
                  onClick={() => this.setState({step: 5})}
                  disabled={this.state.removeAllDisabled}>Review Users</button>
                <button className="btn btn-small clear-all font-bold"
                 onClick={() => { this.setState({removeAllDisabled: true}, this.deleteAllObservees) }} 
                 disabled={this.state.removeAllDisabled}>Clear All</button>
              </div>
            </ObserveeWarning>
          }
        </ReactCSSTransitionGroup>
        <UserSearch>
          {this.searchInput()}
        </UserSearch>
      </div>
    )
  }

  stepTwo() {
    return (
      <div className="card-content">
        <Icon role="presentation">
          <IconGroupSolid/>
        </Icon>
        <h3>Choose Observees</h3>
        <p className="descriptive-text">These are the users that will be observed.  You may select multiple users.</p>
        {this.state.observer.name &&
          <Observer>Observer: <span className="font-bold">{this.state.observer.name}</span></Observer>
        }
        <PillContainer>
          {this.state.observeesToAdd.map(obs => {
            return (
                <Pill>
                  <p>{obs.name}</p>
                  <a alt={"Remove " + obs.name} onClick={(() => this.remove(obs))}>
                    <IconEndSolid/>
                  </a>
                </Pill>
            )
          })}
        </PillContainer>
        <UserSearch>
          {this.searchInput()}
        </UserSearch>
      </div>
    )
  }

  stepThree() {
    return (
      <div className="card-content">
        <Icon role="presentation">
          <IconCheckSolid/>
        </Icon>
        <div>
          <h3>Confirm and Submit</h3>
          <Observer><span className="font-bold">{this.state.observer.name}</span> will be observing the following users:</Observer>
        </div>
        <PillContainer>
          {this.state.observeesToAdd.map(obs => {
            return (
                <Pill>
                  <p>{obs.name}</p>
                  <a alt={"Remove " + obs.name} onClick={(() => this.remove(obs))}>
                    <IconEndSolid/>
                  </a>
                </Pill>
            )
          })}
        </PillContainer>
        <Button className="btn btn-primary submit-button" 
          onClick={() => { this.setState({addDisabled: true}, this.submitObserver) }} 
          disabled={this.state.addDisabled || this.state.observeesToAdd.length === 0}>Submit</Button>
      </div>
    )
  }

  stepFour() {
    return (
      <Zero>
        <object type="image/svg+xml" data="../../images/svg_illustrations/sunny.svg"></object>
        <h3>Assignments Complete!</h3>
        <p className="descriptive-text">
          A total of <span className="font-bold">{this.state.observeesToAdd.length}</span> observees were successfully assigned to <span className="font-bold">{this.state.observer.name}:</span>
        </p>
        <PillContainer>
          {this.state.observeesToAdd.map(obs => {
            return(
              <Pill>
                <p>{obs.name}</p>
              </Pill>
            )
          })}
        </PillContainer>
        <Button className="btn start-over-button btn-primary" onClick={this.restart.bind(this)}>Start over</Button>
      </Zero>
    )
  }

  bulkRemove() {
    return (
      <div className="card-content">
        <Icon role="presentation">
          <IconDocumentSolid/>
        </Icon>
        <div>
          <h3>Review Observees</h3>
          <p className="descriptive-text">
            These are the users that are currently being observed.
          </p>
          <Observer>Observer: <span className="font-bold">{this.state.observer.name}</span></Observer>
        </div>
        <PillContainer>
          {this.state.currentObserversObservees.map(obs => {
            return (
              <Pill className={`observees-to-remove ${this.observeeAlreadyBeingRemoved(obs) ? 'selected' : ''}`}>
                <a alt={"Remove " + obs.name}
                   onClick={() => this.addToRemoveIfNecessary(obs)}>
                  <p>{obs.name}</p>
                  <IconCheckSolid/>
                </a>
              </Pill>
            )
          })}
        </PillContainer>
        <div className="button-container">
          <Button className="btn btn-primary submit-button"
            onClick={() => { this.setState({removeDisabled: true}, this.deleteObservees) }} 
            disabled={this.state.removeDisabled || this.state.removeAllDisabled || this.state.observeesToRemove.length === 0}
          >Remove Selected</Button>
          <Button className="btn clear-all"
            onClick={() => { this.setState({removeAllDisabled: true}, this.deleteAllObservees) }} 
            disabled={this.state.removeAllDisabled}>Clear All</Button>
        </div>
      </div>
    )
  }

  // Helpers for bulkremove
  observeeAlreadyBeingRemoved(obs) {
    return this.state.observeesToRemove.some(obj => obj.id === obs.id)
  }

  // Helpers for bulkremove
  addToRemoveIfNecessary(obs) {
    if (!this.observeeAlreadyBeingRemoved(obs)) {
      this.setState({observeesToRemove: this.state.observeesToRemove.concat(obs)})
    }
  }

  bulkRemoveSuccess() {
    return (
      <Zero>
        <object type="image/svg+xml" data="../../images/svg_illustrations/sunny.svg"></object>
        <h3>Success!</h3>
        <p className="descriptive-text">
          A total of <span className="font-bold">{this.state.observeesToRemove.length}</span> observees were removed from <span className="font-bold">{this.state.observer.name}:</span>
        </p>
        <PillContainer>
          {this.state.observeesToRemove.map(obs => {
            return(
              <Pill>
                <p>{obs.name}</p>
              </Pill>
            )
          })}
        </PillContainer>
        <Button className="btn start-over-button btn-primary" onClick={this.restart.bind(this)}>Back</Button>
      </Zero>
    )
  }

  setPreviousStepButton() {
    if (this.state.step === 4 || this.state.removeAllDisabled) {
      return
    } else {
      return (
        <Button className={`btn btn-secondary traverse ${this.state.step === 6 ? 'invisible' : ''}`} alt="Previous Step" onClick={this.decrementStep.bind(this)} disabled={this.state.step === 1}>
          <IconArrowOpenLeftSolid/>
        </Button>
      )
    }
  }
  
  setNextStepButton() {
    if (this.state.step === 4 || this.state.removeAllDisabled) {
      return
    } else {
      return (
        <Button className={`btn btn-primary traverse ${[3, 5, 6].includes(this.state.step) ? 'invisible' : ''}`} alt="Next Step" onClick={this.incrementStep.bind(this)} disabled={!this.state.observer.id}>
          <IconArrowOpenRightSolid/>
        </Button>
      )
    }
  }

  filterBySearch() {
    let queryParams = `&search_term=${this.state.searchTerm}&assign_observers=true`;
    let path = this.state.first.replaceAll('&no_students=true', '').replaceAll(queryParams, '');

    if (this.state.step === 1) {
      queryParams = queryParams + '&no_students=true'
    }

    return axios.get(path + queryParams).then(response => {
      this.parseResponseLinks(response)
    })
  }

  debounce(func, wait, immediate) {
    var timeout;
    return function() {
      var context = this, args = arguments;
      var later = function() {
        timeout = null;
        if (!immediate) func.apply(context, args);
      };
      var callNow = immediate && !timeout;
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
      if (callNow) func.apply(context, args);
    };
  }

  debouncedFilterBySearch(search_term) {
    this.setState({searchTerm: search_term});
    let debouncedFilter = this.debounce(this.filterBySearch, 250).bind(this);
    return debouncedFilter();
  }
  
  getCurrentObservees() {
    return axios.get(`${ENV.BASE_URL}/api/v1/users/${this.state.observer.id}/observees`).then(response => {
      this.setState({currentObserversObservees: response.data})
    })
  }
  
  submitObserver() {
    let observer_id = this.state.observer.id
    if (!observer_id) { return false }
    axios.post(
      `${ENV.BASE_URL}/api/v1/users/${observer_id}/bulk_create_observees`,
      { observee_ids: this.state.observeesToAdd.map(obs => obs.id) }
    ).then(response => {
      this.setState({step: 4})
    }).catch(error => {
      $.flashError(I18n.t('failed_to_assign_observers', 'There was a problem adding these users.  Please try again.'))
    })
  }

  deleteObservees() {
    let observer_id = this.state.observer.id
    if (!observer_id) { return false }
    axios.post(
      `${ENV.BASE_URL}/api/v1/users/${observer_id}/bulk_destroy_observees`,
      { observee_ids: this.state.observeesToRemove.map(obs => obs.id) }
    ).then(response => {
      this.setState({step: 6})
    }).catch(error => {
      $.flashError(I18n.t('failed_to_remove_observers', 'There was a problem removing these users.  Please try again.'))
    })
  }

  deleteAllObservees() {
    this.setState({observeesToRemove: this.state.currentObserversObservees}, this.deleteObservees)
  }
  
  render() {
    return (
      <Card>
        {this.setPreviousStepButton()}
        {this.chooseStep()}
        {this.setNextStepButton()}
      </Card>
    )
  }
}

export default AssignObservers
