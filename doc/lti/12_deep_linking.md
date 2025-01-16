# Deep Linking

The concept of deep links is not specific to LTI and is a simple one: providing a link to a part of a website/app/tool that is not the home page.

In the LTI world, this process involves a teacher launching a tool, selecting some content from the tool, and the tool passing a link to that content back to Canvas for further display. Once another user comes and launches this link, the tool directly displays it. A tool can also return arbitrary content that isn't a link to itself, including files, images, and HTML. These are referred to as Content Items.

This is used for many facets of LTI integration with Canvas, like:

- a teacher selecting content to be displayed in an assignment with external tool submission type
- a student selecting content to be submitted to an assignment
- a teacher selecting content to be displayed in a module item

A definitive list of integration spots in Canvas is listed below in the 1.3 section under "Supported Placements and Content".

## Deep Linking and LTI 1.1

[1.1 Content-Item Message Spec](http://www.imsglobal.org/specs/lticiv1p0/specification)

This version of deep linking is usually referred to as content-item messages, and the "deep linking" moniker is usually reserved for the 1.3 version. Despite that, the principle behind this is the same: a 1.1 tool is launched and returns some content for Canvas to launch later.

### Implementation Details

During an LTI 1.1 launch, if the placement that the tool launched from supports deep linking, the message type that is sent is `ContentItemSelectionRequest`, as opposed to the normal `BasicLtiLaunchRequest`. In addition, a `content_item_return_url` is provided, to which the tool should redirect once the user has selected content. This redirect contains another LTI message which has a type of `ContentItemRequest`.

At this point, the tool has launched in an iframe, content has been selected, and then - still within the iframe - the tool has redirected back to the Canvas return url.

Canvas exposes this return url, and can parse the content item request message and create the content. It then renders some Javascript that knows about the created content, and can communicate with the parent Canvas window. It sends a `window.postMessage` to main Canvas, which is in charge of interpreting that message and updating its UI to match.

When this process is complete, Canvas now knows about and is displaying the selected content from the tool without the need for a page reload, and without the tool needing to know Canvas specifics. The return url is almost always the same, and knows how to handle all content defined by the LTI spec.

If the return url has an id appended to it, Canvas interprets this as an "edit" request and will try to edit the content item with that id. This is only supported and used by the `collaborations` placement, and only by the 1.1 content item process.

### Adding Deep Linking to a New Placement

1. Add message type support for the placement. This should define what content types this placement accepts, if it accepts multiple content items, and other configuration. This is done in the `content_item_selection_request` module, and a good example method is `editor_button_params`.

2. Install a 1.1 tool that uses this placement, and defines the message type for that placement as `ContentItemSelectionRequest`. Customer tools that want to use content-item messages in this placement will need to update their tool configuration in the same way. Launch this tool from that placement and confirm that the form data sent in the launch contains the correct message type, and also the values that you specified in step 1 in the deep linking claim: `accept_presentation_document_targets`, `accept_media_types`, `auto_create`, `accept_multiple`. It's up to the tool to interpret these properly and make sure that the content passed back to Canvas conforms to these requirements.

3. If needed, add any backend work to parse the content items returned. This work is done in the `ExternalContentController#success` controller action, and may not need anything added, depending on the placement.

4. In the UI for this placement, listen for the `EXTERNAL_CONTENT_READY` (defined in `ui/shared/external-tools/messages.ts`) postMessage (using `handleExternalContentMessages` if it is convenient) and update the UI based on the content items returned.

### Relevant Code

[`Lti::ContentItemSelectionRequest`](/lib/lti/content_item_selection_request.rb) builds the parameters for the content item selection request, and houses per-placement configuration of those parameters.
[`ExternalContentController`](/app/controllers/external_content_controller.rb) exposes the content item return url and creates content items.
[`ExternalContentSuccess` (UI)](/ui/features/external_content_success/index.js) rendered by the above controller, sends postMessage containing content items to main Canvas window.

## Deep Linking and LTI 1.3

[1.3 Deep Linking Spec](https://www.imsglobal.org/spec/lti-dl/v2p0)

### Supported Placements and Content

The definitive list of LTI placements that support 1.3 Deep Linking is found in [`Lti::Messages::DeepLinkingRequest`](/lib/lti/messages/deep_linking_request.rb). This config also lists the types of LTI Content Items valid for each placement. How does this config translate to actions in Canvas? Where can I expect to find content items returned from deep linking?

- Module Items that launch LTI tools
- Assignments that launch LTI tools, whether created in Canvas or by an LTI tool
- Content in any RCE (Rich Content Editor) that can be an LTI launch link, a normal link, a file, arbitrary HTML, or an image
- Collaborations that launch LTI tools
- Homework Submissions that are either files or an LTI launch link
- Video Conference links in Calendar Events that can be a link or arbitrary HTML
- Content Migration files that can be used to import Course content

### Implementation Details

During an LTI launch, if the placement that the tool launched from supports deep linking, the LTI message that is sent has a type of `LtiDeepLinkingRequest`, as opposed to the normal `LtiResourceLinkRequest`. In addition, a deep linking return url is provided, to which the tool should redirect once the user has selected content. The redirect to this return url contains another LTI message (also in the form of a JWT), which has a type of `LtiDeepLinkingResponse`.

At this point, the tool has launched in an iframe, content has been selected, and then - still within the iframe - the tool has redirected back to the Canvas return url.

Canvas exposes this return url and knows how to read the deep linking response message and create links, files, images, assignments, and other content based on the content of this message. This takes care of the backend response to the deep linking request.

Then, the return url endpoint renders some Javascript that knows about the content that has been created, and can communicate with the parent iframe that contains Canvas. It sends a `window.postMessage` to the main Canvas window, and the main Canvas window is in charge of interpreting that message and updating its UI to match.

When this process is complete, Canvas now knows about and is displaying the selected content from the tool without the need for a page reload, and without the tool needing to know Canvas specifics. The return url is always the same, and knows how to handle all content defined by the LTI spec.

### Adding Deep Linking to a New Placement

1. Add message type support for the placement. This should define what content types this placement accepts, if it accepts multiple content items, and other configuration.
   [example commit](https://gerrit.instructure.com/c/canvas-lms/+/256204)

2. Install a tool that uses this placement, and defines the message type for that placement as `LtiDeepLinkingRequest`. Customer tools that want to use deep linking in this placement will need to update their tool configuration in the same way. Launch this tool from that placement and confirm that the `id_token` sent in the launch contains the correct message type, and also the values that you specified in step 1 in the deep linking claim: `accept_types`, `accept_presentation_document_targets`, `accept_media_types`, `auto_create`, `accept_multiple`. It's up to the tool to interpret these properly and make sure that the content passed back to Canvas conforms to these requirements.

3. In the UI for this placement, listen for the deep linking return message, and update the UI based on the content items returned.
   [example: adding support to homework_submission](https://gerrit.instructure.com/c/canvas-lms/+/190167)
   [example: adding support to collaborations](https://gerrit.instructure.com/c/canvas-lms/+/256594)

4. Add this placement to the Developer Key UI's [list of placements](/ui/features/developer_keys_v2/react/ManualConfigurationForm/Placement.js) that can handle deep linking, so that users manually configuring a tool can choose to configure this placement with deep linking. Some placements _only_ accept deep linking messages, and there is a relevant list for that as well.

5. If needed, add the backend work to create database objects to the deep linking controller. This is already done for module items and all resource links (links to tool content), and possibly could be helpful for the placement and records you are adding.

### Relevant Code

[`Lti::Messages::DeepLinkingRequest`](/lib/lti/messages/deep_linking_request.rb) builds the LTI message that gets sent during a deep linking request, and also houses the per-placement configuration for allowing deep linking.
[`Placement` (UI)](/ui/features/developer_keys_v2/react/ManualConfigurationForm/Placement.js) contains a list of placements that can handle deep linking.
[Deep Linking Shared Code (UI)](/ui/shared/deep-linking/) contains a few shared modules for interpreting deep linking postMessages in the UI. These are mostly used piecemeal by pages and placements that support deep linking.
[`Lti::IMS::DeepLinkingController`](/app/controllers/lti/ims/deep_linking_controller.rb) controller for deep linking return url that creates Canvas records based on the content items from the deep linking response message.
[`Lti::IMS::Concerns::DeepLinkingServices`](/app/controllers/lti/ims/concerns/deep_linking_services.rb) verifies JWT from deep linking response message, handles support functionality for the controller above.
[`Lti::IMS::Concerns::DeepLinkingModules`](/app/controllers/lti/ims/concerns/deep_linking_modules.rb) specific logic for creating module items from the deep linking response message.
[`DeepLinkingResponse` (UI)](/ui/features/deep_linking_response/react/DeepLinkingResponse.js) UI rendered by the controller above that sends the content items in a postMessage to the main Canvas frame.
