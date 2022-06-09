Using Deep Linking to Select Resources
=================================
## Introduction

Deep Linking (formerly named Content-Item) is an extension to LTI that allows
data to be passed back to the Tool Consumer (i.e., Canvas) in context of an LTI
Launch. A few common use cases are:

*   Providing a teacher the ability to select a customized LTI launch link from
the tool provider to be placed in the tool consumer.

*   Allowing a student to submit an attachment for an assignment that is
provided by a tool provider (i.e., the external tool).

*   Embedding custom content into a rich text editor from a tool provider.

*   Providing a teacher the ability to select a customized LTI launch link from
the tool and include grading information with it, which is used to create an assignment
directly from the tool.
> **This is a new feature currently being tested, and can be turned on for your**
> **partner sandbox account by partner support, or for your**
> **institution through your CSM.**

*   Using an external tool to create multiple pieces of content directly from,
the tool, whether ungraded (like module items), or graded (like assignments),
and return them to Canvas in bulk.
> **This is a new feature currently being tested, and can be turned on for your**
> **partner sandbox account by partner support, or for your**
> **institution through your CSM.**

Deep Linking is supported in the LTI 1.1 Outcomes Service and LTI Advantage
specifications. To see the full spec for content item and other code examples
see these documents:
* <a href="https://www.imsglobal.org/specs/lticiv1p0" target="_blank">IMS LTI
1.1 Deep Linking v1.0 Documentation</a>

* <a href="https://www.imsglobal.org/spec/lti-dl/v2p0" target="_blank">IMS LTI
Advantage Deep Linking v2.0 Documentation (For LTI Advantage)</a>

Deep Linking is not applicable to all placements in Canvas, but can be used with
 the following placements:

* <a href="file.editor_button_placement.html" target="_blank">editor_button</a>:
 Allows users that have access to the Canvas Rich Content
Editor to select a variety of content types from the tool and embed them
directly in the editor.

* <a href="file.homework_submission_placement.html" target="_blank">homework_submission</a>:
 Allows students to select a resource from the
external tool for assignments that are set up as File Upload submission types.

* <a href="file.migration_selection_placement.html" target="_blank">migration_selection</a>:
 Allows users that have permission to import course
content to launch to a tool to select a file (ex:
<a href="https://www.imsglobal.org/activity/common-cartridge" target="_blank">a
common cartridge file</a>) from a tool and have it imported into the course.

* <a href="file.assignment_selection_placement.html" target="_blank">assignment_selection</a>:
 Allows users that have permission to create
assignments to launch to a tool, select a deep link, and return it as an
External Tool submission type.

* <a href="file.link_selection_placement.html" target="_blank">link_selection</a>:
Allows users that have permission to create module items to
launch to a tool, select a deep link, and return it as a module item.

The following placements support deep linking with LTI 1.3/Advantage tools, but not
with LTI 1.1 tools:
> **These placements are part of a new feature currently being tested, and can be turned on for your**
> **partner sandbox account by partner support, or for your**
> **institution through your CSM.**

* course_assignments_menu:
Appears in the dropdown menu in the top right of the assignments page. Allows users that
have permission to create module items to launch to a tool, select one or many deep
links, and return them as module items or assignments.

* module_index_menu_modal:
Appears in the dropdown menu in the top right of the modules page. Allows users that
have permission to create module items to launch to a tool, select one or many deep
links, and return them as module items or assignments. Adds all returned deep links
to a newly created module.


This document will continue referring to this process as "Content-Item" for LTI
1.1 and Deep Linking for LTI Advantage.

# LTI Advantage Deep Linking Process

LTI Advantage tools can be configured in Canvas to send an LTI launch request
with a deep linking message type for certain placements. The specific details of
 a deep linking interaction are best presented in the <a
 href="https://www.imsglobal.org/spec/lti-dl/v2p0#lti-deep-linking-interaction"
 target="_blank">IMS LTI Deep Linking specification</a>.
 Instead this section will focus on tool configuration.


## Supported Content Item Types
The IMS LTI Deep Linking specification <a href="https://www.imsglobal.org/spec/lti-dl/v2p0#content-item-types">defines several content items types</a> that a tool may return to the platform via Deep linking. Canvas supports all of these
content item types and their respective required properties with additional support for the optional properties listed here:

### File
Full support for require properties.

Support for the following optional properties:
- text (should be filename)

### Link
Full support for required properties.

Support for the following optional properties:
- title
- text
- icon
- thumbnail
- iframe

### LTI Resource Link
Full support for required properties.

Support for the following optional properties:
- url
- title
- text
- icon
- thumbnail
- iframe
- custom (allows for setting link-specific LTI launch parameters. See documentation <a href="https://www.imsglobal.org/spec/lti-dl/v2p0#lti-resource-link">here</a>.)
- lineItem **(in testing)** (if present, requires `scoreMaximum`)
- available **(in testing)**
- submission **(in testing)** (except `startDateTime`)

#### Line Items

> **This is a new feature currently being tested, and can be turned on for your**
> **partner sandbox account by partner support, or for your**
> **institution through your CSM.**

If a returned content item has the `lineItem` property, then it is used to create
a new assignment, instead of a normal LTI link. The `available` and `submission`
properties are also used for the assignment unlock, lock, and due dates. Note that
since Canvas has no notion of a start date for submissions, it ignores the
`submission.startDateTime` sub-property.

There are only 3 places that support assigment creation using Line Items, and each of
them respond differently:

- assignment_selection: creates an assignment using the given data and presents it to
the user for further editing.

- course_assignments_menu: creates one or many assignments from the given Line Items.
If any given content items do not have the `lineItem` property, a new module is created
and they are added to it as new module items.

- module_index_menu_modal: creates a new module and adds all given content items to it
as either module items or assignments, based on the presence or absence of the `lineItem`
property.

### HTML fragment
Full support for required properties.

Full support for all optional properties.

### Image
Full support for required properties.

Support for the following optional properties:
- title
- text
- thumbnail
- width
- height


## Configuring Deep Linking
Deep linking is configured by <a
href="https://community.canvaslms.com/t5/Admin-Guide/How-do-I-configure-an-LTI-key-for-an-account/ta-p/140"
target="_blank">creating a Canvas LTI Developer Key</a> with a
`LtiDeepLinkingRequest` message type set on a supported placement. This can be
done via the UI, or by supplying Canvas with JSON.

For example, the following JSON would allow an LTI Advantage tool to be
installed that uses deep linking return items back to Canvas as an assignment or
within the canvas Rich Content Editor:

```
{  
   "title":"Cool Deep Linking Tool ",
   "scopes":[],
   "extensions":[  
      {  
         "domain":"deeplinkexample.com",
         "tool_id":"deep-linky",
         "platform":"canvas.instructure.com",
         "settings":{  
            "text":"Cool Deep Linking Text",
            "icon_url":"https://some.icon.url",
            "placements":[                 
               {  
                  "text":"Embed Tool Content in Canvas RCE",
                  "enabled":true,
                  "icon_url":"https://some.icon.url",
                  "placement":"editor_button",
                  "message_type":"LtiDeepLinkingRequest",
                  "target_link_uri":"https://your.target_link_uri/deeplinkexample"
               },
               {  
                  "text":"Embed Tool Content as a Canvas Assignment",
                  "enabled":true,
                  "icon_url":"https://some.icon.url",
                  "placement":"assignment_selection",
                  "message_type":"LtiDeepLinkingRequest",
                  "target_link_uri":"https://your.target_link_uri/deeplinkexample"
               }
            ]
         }
      }
   ],
   "public_jwk":{  
      "kty":"RSA",
      "alg":"RS256",
      "e":"AQAB",
      "kid":"8f796169-0ac4-48a3-a202-fa4f3d814fcd",
      "n":"nZD7QWmIwj-3N_RZ1qJjX6CdibU87y2l02yMay4KunambalP9g0fU9yZLwLX9WYJINcXZDUf6QeZ-SSbblET-h8Q4OvfSQ7iuu0WqcvBGy8M0qoZ7I-NiChw8dyybMJHgpiP_AyxpCQnp3bQ6829kb3fopbb4cAkOilwVRBYPhRLboXma0cwcllJHPLvMp1oGa7Ad8osmmJhXhM9qdFFASg_OCQdPnYVzp8gOFeOGwlXfSFEgt5vgeU25E-ycUOREcnP7BnMUk7wpwYqlE537LWGOV5z_1Dqcqc9LmN-z4HmNV7b23QZW4_mzKIOY4IqjmnUGgLU9ycFj5YGDCts7Q",
      "use":"sig"
   },
   "description":"1.3 Test Tool",
   "target_link_uri":"https://your.target_link_uri",
   "oidc_initiation_url":"https://your.oidc_initiation_url"
}
```

Once the developer key is configured, it can then be used to
<a href="https://community.canvaslms.com/t5/Admin-Guide/How-do-I-configure-an-external-app-for-an-account-using-a-client/ta-p/202"
target="_blank">install the LTI tool</a>. Links will then be exposed in the
Canvas Rich Content Editor toolbar and Assignment edit view. Clicking the links
will then initiate a deep linking LTI workflow to allow the user to select a
resource from the tool and have them embedded in Canvas.

# LTI 1.1 Content-Item Process

The first step in the content-item process is the sending of the
`ContentItemSelectionRequest` message from the Tool Consumer to
the Tool Provider. An example message is included
below:

### ContentItemRequest: Tool Consumer -> Tool Provider

```

    lti_message_type: ContentItemSelectionRequest
    lti_version: LTI-1p0
    accept_media_types: application/vnd.ims.lti.v1.ltilink
    accept_presentation_document_targets: frame,window
    content_item_return_url:
    http://lms.example/courses/5/external_content/success/external_tool_dialog

```

Some of the important parameters are: **accept_media_types**,
**accept_presentation_document_targets**, and **content_item_return_url**.

**accept_media_types** is a comma separated list of MIME types the Tool Consumer
 supports.

**accept_presentation_document_targets** is a comma separated list of
presentation formats the Tool Consumer supports.

**content_item_return_url** is where the tool provider should redirect to at the
 end of the content-item process.

After the Tool Provider receives the `ContentItemSelectionRequest` message it
will need to send back a `ContentItemSelection` message that includes the
`content-items` they wish to send back. An example of this message is shown
below:

### ContentItemSelection: Tool Consumer <- Tool Provider

```

    lti_message_type: ContentItemSelection
    lti_version: LTI-1p0
    content_items: {
                     "@context": "http://purl.imsglobal.org/ctx/lti/v1/ContentItem",
                     "@graph": [
                       {
                         "@type": "LtiLinkItem",
                         "@id": "http://example.com/messages/launch",
                         "url": "http://example.com/messages/launch",
                         "title": "test",
                         "text": "text",
                         "mediaType": "application/vnd.ims.lti.v1.ltilink",
                         "placementAdvice": {
                           "presentationDocumentTarget": "frame"
                         }
                       }
                     ]
                   }

```

The main points of interest here is the `content_items` parameter. It contains a
 JSON object that includes an array of content-item objects. Inside the JSON
 object, the `@graph` object contains an array that holds all of the
 content-item objects.

The content-item object in this example is sending back a single LTI link that
is to be launched in the current frame. the `url` specifies the lti launch point
, and the `mediaType` specifies that it is an lti launch.


## Configuring Content-item


To use content-item, the tool provider must be configured correctly. The
following is an overview of how to configure the tool provider to use
content-item.

### LTI Tool XML Configuration

Below is an example of a bare-bones tool provider LTI configuration that
_does not_ use content-item:
```
    <?xml version="1.0" encoding="UTF-8"?><cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0" xmlns:blti="http://www.imsglobal.org/xsd/imsbasiclti_v1p0" xmlns:lticm="http://www.imsglobal.org/xsd/imslticm_v1p0" xmlns:lticp="http://www.imsglobal.org/xsd/imslticp_v1p0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0p1.xsd http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
      <blti:title>Example Tool Provider</blti:title>
      <blti:description>This is a Sample Tool Provider.</blti:description>
      <blti:launch_url>http://localhost:4040/messages/blti</blti:launch_url>
      <blti:extensions platform="canvas.instructure.com">
        <lticm:property name="selection_height">500</lticm:property>
        <lticm:property name="selection_width">500</lticm:property>
      </blti:extensions>
    </cartridge_basiclti_link>

```

**Note:** for more on the basics of LTI tool configuration see
[external tools documentation](https://canvas.instructure.com/doc/api/file.tools_xml.html).

To begin using content-item we need to specify at least one valid placement for
Canvas to use. Placements are used to help the tool consumer (Canvas in this
case) know where the tool should be placed within the LMS. For example, adding
the following node as a child of the **blti:extensions** element in the above
XML would tell Canvas to add a link in the course navigation to the LTI tool:



```
    <lticm:options name="course_navigation">
      <lticm:property name="url">http://localhost:4040/messages/blti</lticm:property>
    </lticm:options>
```

For our example we will use **assignment_selection**.

To enable content-item with the **assignment_selection** placement, we add lines
 6-9 to the example from above:



```
     1 <?xml version="1.0" encoding="UTF-8"?><cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0" xmlns:blti="http://www.imsglobal.org/xsd/imsbasiclti_v1p0" xmlns:lticm="http://www.imsglobal.org/xsd/imslticm_v1p0" xmlns:lticp="http://www.imsglobal.org/xsd/imslticp_v1p0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0p1.xsd http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
     2   <blti:title>Example Tool Provider</blti:title>
     3   <blti:description>This is a Sample Tool Provider.</blti:description>
     4   <blti:launch_url>http://localhost:4040/messages/blti</blti:launch_url>
     5   <blti:extensions platform="canvas.instructure.com">
     6     <lticm:options name="assignment_selection">
     7       <lticm:property name="message_type">ContentItemSelectionRequest</lticm:property>
     8       <lticm:property name="url">http://localhost:4040/messages/blti</lticm:property>
     9     </lticm:options>
    10     <lticm:property name="icon_url">http://localhost:4040/selector.png</lticm:property>
    11     <lticm:property name="selection_height">500</lticm:property>
    12     <lticm:property name="selection_width">500</lticm:property>
    13   </blti:extensions>
    14 </cartridge_basiclti_link>
```


Adding the element on line 6 lets Canvas know the tool should be placed in the
assignments menu. Line 7 tells Canvas the tool is using content-item, and line 8
 provides Canvas the launch URL.
