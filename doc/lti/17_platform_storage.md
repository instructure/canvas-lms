# Platform Storage

This is an LTI 1.3 specification that does a few things:

- defines how tools can send Javascript `postMessage`s to platforms
- defines Platform Storage, which allows tools to store arbitrary cookie-like data with a platform
- outlines how to use Platform Storage to support "cookie-less launches" in browsers that block 3rd party cookies in iframes.

## Motivation

In 2020, Safari announced that it would start blocking cookies in iframes that were for a cross-origin site,
commonly called "3rd-party" or "tracking" cookies, in an effort to cut down on advertising and tracking. This
affects LTI tools, which by definition are "cross-origin sites in an iframe". This spec was developed so that
tools could set the cookies they still needed (commonly a session token), but more crucially to secure the
LTI 1.3 launch process.

Since the LTI 1.3 launch process is built on OIDC, it makes a request to the tool two separate times - first,
to notify the tool that it's beginning the launch and for the tool to pass back data it needs for the launch.
Second, once authentication is complete, the actual "target link URI" or launch URL is requested. OIDC requires
a `state` variable to be passed back and forth and stored as a cookie on the tool side, to prevent a MITM attack
where a malicious user Mal starts the request flow, completes the first request, and then captures the second
request URL and sends it to another user Alice. Alice clicks on the URL and unknowingly launches the tool
as Mal.

With keeping track of the `state` via cookie out of the picture, the idea Platform Storage spec was born. The tool
would tell the platform "store this value in your localStorage for me" and then ask for it back when needed.

## Specification Documents

1. [Client-side PostMessages](https://www.imsglobal.org/spec/lti-cs-pm/v0p1)

> "This document describes the functionality of sending and receiving window postMessages used within the LTI specifications. Any messages send or received by a tool or platform should follow these rules to maintain interoperability and security whilst communicating.

> LTI applications are often embedded within IFrame within the Learning Platform's main window. In order to offer a more integrated experience, it is desired to establish an in-browser communication between the IFrame and its host. This can range from purely UI experience like resizing of the frame to match the actual content, to storing state outside of the frame to offer an alternative to limitations imposed by browsers on 3rd party cookies. The messaging between cross domains documents is accomplished using windows postMessage API."

2. [LTI postMessage Storage](https://www.imsglobal.org/spec/lti-pm-s/v0p1)

> "This specification defines browser messages between an LTI Tool and an LTI Platform that allow an LTI Tool to store temporary values inside the window frame of an LTI Platform. There are many potential applications for this pattern, the current primary purpose is to enable a workaround for situations where an LTI Tool us unable to set a cookie with an iFrame.

> This specification defines a new postMessage type for the LTI Client Side postMessages specification."

3. [LTI OIDC Login with LTI Client Side postMessages](https://www.imsglobal.org/spec/lti-cs-oidc/v0p1)

> "The OIDC specification relies on browser cookies to validate the user agent starting the authorization workflow is the same one that finishes it. However, since an LTI integration is most often inside an iFrame there can be many issues involved with setting a state cookie for this purpose. This implementation guide explains how to use LTI Client Side postMessages with LTI postMessage Storage to replace the function of cookies in validating the state between stages of an OIDC launch."

## External Canvas Docs

1. See "Launching without Cookies" in [this API doc page](https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html)
   for a brief overview of the OIDC login process, similar to spec doc #3 above.

2. See "lti.put_data" and "lti.get_data" in [Using window.postMessage in LTI Tools](https://canvas.instructure.com/doc/api/file.lti_window_post_message.html)
   for a description of the postMessage API Canvas supports, similar to spec doc #2 above.

## Canvas Implementation

> tl;dr search for "platform_storage" or "post_message_forwarding" to find most of the code.

### JS postMessage Listening

`ui/shared/lti/jquery/messages.ts` has been around in Canvas for a while and handles many different
types of postMessages. It exposes `monitorLtiMessages`, which is called on various pages in Canvas.
Evidently it's also called by the tool launch page, in the `external_tools_show` JS. It's possible
that only calling it once on every page would be more foolproof in the future.

### Platform Storage Messages

`ui/shared/lti/jquery/subjects/lti.put_data.ts`
`ui/shared/lti/jquery/subjects/lti.get_data.ts`
`ui/shared/lti/jquery/subjects/lti.capabilities.ts`

### Storing in LocalStorage

`ui/shared/lti/jquery/platform_storage.ts`

### Signalling Support

To signal support of LTI Platform Storage, an `lti_storage_target` is included in both the
OIDC login and LTI launch requests. This parameter defaults to `_parent`, which tells the
tool to address messages to the parent Canvas window.

However, per the Platform Storage spec, tools are required to target their postMessages to the platform's
OIDC Auth domain so that the tool can be confident that the message is only sent to the platform.
For Canvas, this means that the base postMessage listening isn't enough for Platform Storage, since
messages sent to the parent Canvas window either need to be targeted to the `*` wildcard, or
the current Canvas domain. The spec allows for this by sending the name of an iframe that is a sibling
to the tool launch iframe in the `lti_storage_target` parameter. Canvas sends the value
`post_message_forwarding` in this parameter.

Canvas only sends this parameter in the web app, since the mobile apps don't support or need this spec.
For the most part, the mobile apps all use 1st-party WebViews instead of 3rd-party iframes to render
tools, and so can continue to set cookies. Plus, the postMessage listeners are in the Canvas web
front-end, and so would need to be reimplemented for each mobile app.

- defined: `lib/lti/platform_storage.rb#lti_storage_target`
- added to OIDC login request: `app/models/lti/lti_advantage_adapter.rb#login_request`
- included in launch request: `app/controllers/lti/ims/authentication_controller.rb#lti_storage_target`
- not included in mobile launch requests, global search for `include_storage_target`

### postMessage Forwarding

Canvas renders an iframe on every page that listens for postMessages and forwards them from
the tool to Canvas, and from Canvas back to the tool. As mentioned above, this frame's domain
is required by spec to match the OIDC Auth endpoint, which for INST-hosted production Canvas
is `sso.canvaslms.com`.

- frame added to every page: `app/views/lti/platform_storage/_forwarding_frame.html.erb`
- controller that responds to this endpoint: `app/controllers/lti/platform_storage_controller.rb`
- HTML page for this endpoint: `app/views/lti/platform_storage/post_message_forwarding.html.erb`
- Javascript forwarder: `public/javascripts/lti_post_message_forwarding.js`

#### non-Platform Storage Forwarding from the RCE

Tool launches from the RCE (Rich Content Editor) are a bit of a special case, since the RCE
(backed by TinyMCE) uses an iframe to wrap all of the rich content being edited. In that situation,
tools that launch from an iframe can't send postMessages to Canvas out of the box, since the
parent window is now the RCE and not Canvas.

To circumvent this, tool launches in the RCE use the `in_rce` display type, which renders the tool
launch iframe alongside a sibling forwarder frame, and also forwards any postMessages received to
the parent Canvas window. This uses the same forwarding code as the Platform Storage forwarder frame,
with slightly different parameters.

- in_rce HTML page: `app/views/lti/in_rce_launch.html.erb`
