# Contributing

One of the best ways to contribute to this plugin is by writing rules to check
for additional accessibility concerns.  We see this as the primary source of contributions
thus this guide will focus on that scenario.

## Starting the Demo

You'll probably want to be able to work in a demo environment for trying things out and doing development.  You can
get to such an environment by running the following:

```

npm start

```

## Contribution Standards

We strive to maintain a high level of quality for our code.  We also expect the same from our contributions.  You should
adhere to the following guidelines:

  - Test the code
    - We use [Jest](https://facebook.github.io/jest/) for our unit tests (`npm test`)
    - We use [Cypress](http://cypress.io/) for integration/e2e tests (`npm run cypress:run`)
    - Unit tests should be colocated with the code in a `__tests__` directory.  Integration tests should be in
      `cypress/integration`.
    - We expect a certain level of unit test coverage, if your commit lowers it beneath this threshold, it will fail the build.
  - Format the code
    - We use prettier to format our code (`npm run fmt`)
    - If you don't format the code, it will fail our build.
  - Internationalize the code
    - All strings in the source should be in English and wrapped with the `formatMessage` helper.  This will ensure that
      everything gets translated.

Additionally, our `master` branch is protected and commits cannot be merged to it without being reviewed and passing our build.

## Important Directories

```
.
├── src/
|   ├── components/   <-- Main components that make the plugin
|   └── rules/        <-- All the rules that the are checked
└── cypress/
    └── integration/  <-- The integration test suite


```

## What is a rule?

A basic rule is an object that looks like this:

```js
export default {
  /**
   * The `test` method should take an element of the TinyMCE content as a parameter.
   * It should test that element against the rule and return true if the rule
   * passes.  It should also return true if an element the rule doesn't pertain
   * to is passed in.  It should return false if the rule does not pass.
   *
   * Additionally, it can return a Promise that will eventually resolve to
   * either true or false.  This is handy for rules that need to handle
   * some sort of async action.
   */
  test: elem => {
      if (elem.tagName !== "IMG") {
        return true // return true since this rule only applies to images.
      }

      // Images less than 100px wide are not good (in this example anyway)
      return elem.naturalWidth < 100;
  },

  /**
   * The `data` method should optionally take an element to describe the state
   * the form for the rule should be in when it is displayed (if the rule failed).
   * It should return an object containing a key for each form item that appears
   * in the `form` method.
   */
  data: elem => {
    return {
      width: elem.naturalWidth
    };
  },

  /**
   * The `form` method should return an array of objects that represent the
   * form fields that should display when the rule fails.
   *
   * The objects can contain the following:
   *   - label - A label to show on the form field [string] (Required)
   *   - dataKey - A key used to represent the field in code [string] (Required)
   *   - disabledIf - a method that will conditionally disable the form control.  
   *                  It receives the current form state as a parameter. [function]
   *   - checkbox - indicates the field should show as a checkbox [boolean]
   *   - color - indicates the field should show as a color picker [boolean]
   *   - textarea - indicates the field should show as a text area for longer text entry [boolean]
   *   - options - indicates the field should be a dropdown. Each entry should be
   *               an array with a value/label mapping such as `["none", formatMessage("None")]` [array]
   */
  form: () => [
    {
      label: formatMessage("Width"),
      dataKey: "width",
      disabledIf: (data) => data.width === 99 // Too bad if the width is 99, you can't change it
      checkbox: false
    }
  ],

  /**
   * The `update` method is called whenever changes are made in the form.  It receives two
   * arguments, `elem` and `data`.  `elem` is the element that is being updated and `data` is the
   * current state of the form.
   *
   * It may be helpful in some circumstances to traverse up the DOM tree by accessing the element's parentNode.
   * This is completely acceptable as `update` has the ability to operate within
   * the entire TinyMCE content space.
   * 
   * It should return the element that has been modified, replaced, or otherwise updated.
   * If the element no longer exists then it should return the equivalent new element that replaces it.
   */
  update: (elem, data) => {
    elem.setAttribute('width', data.width)
    return elem;
  },

  /**
   * The `message` method should return a string succinctly explaining the rule.  Note: formatMessage is used
   * for internationalization.
   */
  message: () =>
    formatMessage(
      "Images should be wider than 100px."
    ),

  /**
   * The `why` method should return a string giving additional information on why the rule needs
   * to be in place. Note: formatMessage is used for internationalization.
   */
  why: () =>
    formatMessage(
      "Small images just aren't as cool as larger images.  Some users might not be able to see small images."
    ),

  /**
   * `link` is a text property that should have a link to supporting documentation for the rule.  If there is
   * no supporting documentation then this property should not be included.  A fake url is provided here for
   * illustration of the technique only.  The rule we've used here is made up and should have no link.
   */
  link: "https://www.w3.org/TR/WCAG20-TECHS/H37.html"
}

```

