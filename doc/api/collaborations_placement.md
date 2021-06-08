Collaboration Placement
==============

External tools can be configured to appear as a collaboration provider.

 **collaboration** placement allows users to launch a tool to select a collaboration resource.

 For an overview of Canvas collaborations, refer to the <a href="https://community.canvaslms.com/t5/Canvas-Basics-Guide/What-are-Collaborations/ta-p/61">Canvas Community article.</a>

### Configuring
For configuration examples and links to the specification, please refer to the <a
href="file.content_item.html" target="_blank">LTI
Deep Linking documentation</a>. Simply replace the **assignment_selection** text
with **collaboration** in the XML (LTI 1.0, 1.1, and 1.2) or JSON (LTI 1.3) examples.

### Supported Content Item Types
For Deep Linking, the collaboration placement supports the <a href="https://www.imsglobal.org/spec/lti-dl/v2p0#lti-resource-link">LTI Resource Link type</a>.

Canvas also includes an optional extension to the LTI Resource link type at this placement. The extension allows specifying the users and/or groups that should be
included as collaborators on the collaboration created for the returned resource.

Example deep linking response (decoded JWT):

```
{
  "type": "ltiResourceLink",
  "url": "http://www.test-tool.com/launch?deep_linking=true",
  "title": "Lti 1.3 Tool Title",
  "text": "Lti 1.3 Tool Text",
  "icon": "https://img.icons8.com/metro/1600/unicorn.png",
  "thumbnail": "https://via.placeholder.com/150?text=thumbnail",
  "https://canvas.instructure.com/lti/collaboration": {
    "users": ['02fb7032-1144-4d69-aab1-83c67bdecd2e'],
    "groups": ['e8d625b7-7f27-4a81-9b86-5dcb110e1943']
  }
}
```

This example would create a collaboration associated with the launch `url` and include all users included in the `users` property of the extension. Additionally it would include all users in the group identified by the `groups` property of the extension.

The IDs in the `users` array are the same IDs available in the <a href="https://canvas.instructure.com/doc/api/names_and_role.html">Names & Roles Provisioning Service</a>. These IDs are also the value of the `sub` claim in an LTI 1.3 launch.
