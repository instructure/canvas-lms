Using window.postMessage in LTI Tools
=====================================

Canvas listens for events sent through the `window.postMessage` Javascript
API (docs <a href="https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage" target="_blank">here</a>)
from LTI tools and other children rendered in iframes or opened in new tabs/windows. Tools
can send various types of events to resize windows, launch in new windows, or other
functionality. Note that this is not part of the LTI specification, and is Canvas-specific.

The data sent to `window.postMessage` can be of any type, and each message type looks for different
data. Most data is sent as an object with a `subject` property.

Some of these message handlers require the presence of a `token`, which identifies the tool launch.
This token is present in the launch as a custom variable, `$com.instructure.PostMessageToken`, and
should be passed in postMessage calls if it's present.

If the LTI tool is launched in a iframe, as is most common, then postMessages should be sent to
`window.parent`. However, if the tool is launched in a new tab, window, or popup, then postMessages
should be directed to `window.opener`. The examples will use `window.parent`.

# Message Types

## requestFullWindowLaunch

Launches the tool that sent the event in a full-window context (ie not inside a Canvas iframe).
Mainly used for Safari launches, since Safari disables setting cookies inside iframes.

**Required properties:**
- subject: "requestFullWindowLaunch"
- data: either a string or an object
  - if a string, a url for relaunching the tool
  - if an object, has required sub-properties
- data.url: a url for relaunching the tool
- data.placement: the Canvas placement that the tool was launched in. Provided in the 1.3 id token
  under the custom claim section (`https://www.instructure.com/placement`).

**Optional properties:**
- data.launchType: defaults to "same_window"
  - "same_window": launches the tool in the same window, replacing Canvas entirely
  - "new_window": launches the tool in a new tab/window, which depends on user preference
  - "popup": launches the tool in a popup window
- data.launchOptions.width: for launchType: popup, defines the popup window's width. Defaults to 800.
- data.launchOptions.height: for launchType: popup, defines the popup window's height. Defaults to 600.

```js
window.parent.postMessage(
  {
    subject: "requestFullWindowLaunch",
    data: {
      url: "https://example-tool.com/launch",
      placement: "course_navigation",
      launchType: "new_window",
      launchOptions: {
        width: 1000,
        height: 800
      }
    }
  },
  "*"
)
```

## toggleCourseNavigationMenu

Opens and closes the course navigation sidebar, giving more space for the tool to display.

**Required properties:**
- subject: "toggleCourseNavigationMenu"

```js
window.parent.postMessage({ subject: "toggleCourseNavigationMenu" }, "*")
```

## lti.resourceImported

Notifies the Canvas page holding the tool that a resource has finished importing.
Canvas will respond by reloading the page, if the tool was present in the external
apps tray. Used on wiki pages.

**Required properties:**
- subject: "lti.resourceImported"

```js
window.parent.postMessage({ subject: "lti.resourceImported" }, "*")
```

## lti.hideRightSideWrapper

Tells Canvas to remove the right side nav in the assignments view.

**Required properties:**
- subject: "lti.hideRightSideWrapper"

```js
window.parent.postMessage(
  {
    subject: "lti.hideRightSideWrapper",
  },
  "*"
)
```

## lti.frameResize

Tells Canvas to change the height of the iframe containing the tool.

**Required properties:**
- subject: "lti.frameResize"
- height: integer, in px

**Optional properties:**
- token: postMessage token, discussed above.

```js
window.parent.postMessage(
  {
    subject: "lti.frameResize",
    height: 400
  },
  "*"
)
```

## lti.fetchWindowSize

Sends a postMessage event back to the tool with details about the window size of
the tool's containing iframe.

**Required properties:**
- subject: "lti.fetchWindowSize"

Returning postMessage includes the following properties:
- subject: "lti.fetchWindowSize.response"
- height: height of the iframe
- width: width of the iframe
- footer: height of the "#fixed_bottom" HTML element or 0 if not found
- offset: [jquery.offset()](https://api.jquery.com/offset/) of the iframe's wrapper
- scrollY: the number of px that the iframe is scrolled vertically

```js
window.parent.postMessage({ subject: "lti.fetchWindowSize" }, "*")
```

## lti.showModuleNavigation

Toggles the module navigation footer based on the message's content.

**Required properties:**
- subject: "lti.showModuleNavigation"
- show: Boolean, whether to show or hide the footer

```js
window.parent.postMessage(
  {
    subject: "lti.frameResize",
    show: true
  },
  "*"
)
```

## lti.scrollToTop

Scrolls the iframe all the way to the top of its container.

**Required properties:**
- subject: "lti.scrollToTop"

```js
window.parent.postMessage({ subject: "lti.scrollToTop" }, "*")
```

## lti.setUnloadMessage

Sets a message to be shown in a browser dialog before page closes (ie
"Do you really want to leave this page?")

**Required properties:**
- subject: "lti.setUnloadMessage"
- message: The message to be shown in the dialog

```js
window.parent.postMessage(
  {
    subject: "lti.setUnloadMessage",
    message: "Are you sure you want to leave this app?"
  },
  "*"
)
```

## lti.removeUnloadMessage

Clears any set message to be shown on page close.

Required properties
- subject: "lti.removeUnloadMessage"

```js
window.parent.postMessage({ subject: "lti.removeUnloadMessage" }, "*")
```

## lti.screenReaderAlert

Shows an alert for screen readers.

**Required properties:**
- subject: "lti.screenReaderAlert"
- body: The contents of the alert.

```js
window.parent.postMessage(
  {
    subject: "lti.screenReaderAlert",
    body: "An alert just for screen readers"
  },
  "*"
)
```

## lti.showAlert

Shows an alert using Canvas's alert system, and includes the name of the LTI
tool that sent the message.

**Required properties:**
- subject: "lti.showAlert"
- body: The contents of the alert - can either be a string, or JSON string.

**Optional properties:**
- alertType: "success", "warning", or "error". Defaults to "success".
- title: A display name for the tool. If not provided, Canvas will attempt to
  supply the tool name or default to "External Tool".

```js
window.parent.postMessage(
  {
    subject: "lti.showAlert",
    alertType: "warning",
    body: "An warning to be shown",
    title: "Tool Name"
  },
  "*"
)
```

## lti.enableScrollEvents

Sends a debounced postMessage event to the tool every time its containing
iframe is scrolled.

**Required properties:**
- subject: "lti.enableScrollEvents"

Returning postMessage includes the following properties:
- subject: "lti.scroll"
- scrollY: the number of px that the iframe is scrolled vertically

```js
window.parent.postMessage({ subject: "lti.enableScrollEvents" }, "*")
```
