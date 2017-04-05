define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jquery',
  'underscore',
  'compiled/api/gradingPeriodSetsApi',
  'jsx/grading/NewGradingPeriodSetForm'
], (React, ReactDOM, {Simulate}, $, _, setsApi, NewSetForm) => {
  const wrapper = document.getElementById('fixtures');

  const assertDisabled = function(component) {
    let $el = ReactDOM.findDOMNode(component);
    equal($el.getAttribute('aria-disabled'), 'true');
  };

  const assertEnabled = function(component) {
    let $el = ReactDOM.findDOMNode(component);
    notEqual($el.getAttribute('aria-disabled'), 'true');
  };

  const exampleSet = {
    id: '81',
    title: 'Example Set!',
    weighted: false,
    displayTotalsForAllGradingPeriods: false,
    gradingPeriods: [],
    permissions: { read: true, update: true, delete: true, create: true },
    createdAt: '2013-06-03T02:57:42Z'
  };

  QUnit.module('NewGradingPeriodSetForm', {
    renderComponent(props={}) {
      const defaultProps = {
        enrollmentTerms: [],
        closeForm () {},
        addGradingPeriodSet () {},
        urls: {
          gradingPeriodSetsURL: "api/v1/accounts/1/grading_period_sets",
          enrollmentTermsURL: "api/v1/accounts/1/enrollment_terms"
        },
        readOnly: false
      };
      const element = React.createElement(NewSetForm, _.defaults(props, defaultProps));
      return ReactDOM.render(element, wrapper);
    },

    stubCreateSuccess(){
      const success = Promise.resolve(exampleSet);
      this.stub(setsApi, 'create').returns(success);
      return success;
    },

    stubCreateFailure(){
      const failure = Promise.reject(new Error('FAIL'));
      this.stub(setsApi, 'create').returns(failure);
      return failure;
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test('initially renders with the create button not disabled', function() {
    let form = this.renderComponent();
    assertEnabled(form.refs.createButton);
  });

  test('initially renders with the cancel button not disabled', function() {
    let form = this.renderComponent();
    assertEnabled(form.refs.cancelButton);
  });

  test('initially renders with the "Display totals for All Grading Periods option" checkbox unchecked', function () {
    const form = this.renderComponent();
    notOk(form.displayTotalsCheckbox._input.checked)
  });

  test('disables the create button when it is clicked', function() {
    const promise = this.stubCreateSuccess();
    let form = this.renderComponent();
    Simulate.change(form.refs.titleInput, { target: { value: 'Cash me ousside' } });
    Simulate.click(ReactDOM.findDOMNode(form.refs.createButton));
    return promise.then(() => { assertDisabled(form.refs.createButton); });
  });

  test('the "Display totals for All Grading Periods option" checkbox state is included when the set is created', function () {
    const promise = this.stubCreateSuccess();
    const addSetStub = this.stub();
    const form = this.renderComponent({ addGradingPeriodSet: addSetStub });
    Simulate.change(form.refs.titleInput, { target: { value: 'Howbow dah' } });
    Simulate.click(ReactDOM.findDOMNode(form.refs.createButton));
    return promise.then(() => {
      equal(addSetStub.callCount, 1, 'addGradingPeriodSet was called once');
      const { displayTotalsForAllGradingPeriods } = addSetStub.getCall(0).args[0];
      equal(displayTotalsForAllGradingPeriods, false, 'includes displayTotalsForAllGradingPeriods');
    });
  });

  test('disables the cancel button when the create button is clicked', function() {
    const promise = this.stubCreateSuccess();
    const form = this.renderComponent();
    Simulate.change(form.refs.titleInput, { target: { value: 'Watch me whip' } });
    this.stub(form, 'isValid').returns(true);
    Simulate.click(ReactDOM.findDOMNode(form.refs.createButton));
    return promise.then(() => { assertDisabled(form.refs.cancelButton); });
  });

  test('updates weighted state when checkbox is clicked', function() {
    const form = this.renderComponent();
    equal(form.state.weighted, false);
    form.weightedCheckbox.handleChange({ target: { checked: true } });
    equal(form.state.weighted, true);
  });

  test('re-enables the cancel button when the ajax call fails', function () {
    const fakePromise = {
      then () {
        return fakePromise;
      },
      catch (handler) {
        handler(new Error('FAIL'));
      }
    };
    this.stub(setsApi, 'create').returns(fakePromise);
    const form = this.renderComponent();
    Simulate.change(form.refs.titleInput, { target: { value: 'Watch me nay nay' } });
    Simulate.click(ReactDOM.findDOMNode(form.refs.cancelButton));
    assertEnabled(form.refs.cancelButton);
  });

  test('re-enables the create button when the ajax call fails', function () {
    const fakePromise = {
      then () {
        return fakePromise;
      },
      catch (handler) {
        handler(new Error('FAIL'));
      }
    };
    this.stub(setsApi, 'create').returns(fakePromise);
    const form = this.renderComponent();
    Simulate.change(form.refs.titleInput, { target: { value: ':D' } });
    Simulate.click(ReactDOM.findDOMNode(form.refs.createButton));
    assertEnabled(form.refs.createButton);
  });
});
