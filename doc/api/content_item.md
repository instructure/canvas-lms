Using Content Item to Select Resources
=================================
## Introduction

Content-Item is an extension to LTI that allows data to be passed back to the
Tool Consumer (i.e., Canvas) in context of an LTI Launch. A few common use cases
 are:

*   Providing a teacher the ability to select a customized LTI launch link from
the tool provider to be placed in the tool consumer.

*   Allowing a student to submit an attachment for an assignment that is
provided by a tool provider (i.e., the external tool).

*   Embedding custom content into a rich text editor from a tool provider.

To see the full spec for content item and other code examples see the
[IMS Documentation](https://www.imsglobal.org/specs/lticiv1p0)

## Content-Item Process

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


# Configuring Content-item


To use content-item, the tool provider must be configured correctly. The
following is an overview of how to configure the tool provider to use
content-item.

## LTI Tool XML Configuration

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


Content-item is not applicable to all placements in Canvas, but can be used with
 the following placements:

**editor_button**

**homework_submission**

**migration_selection**

**assignment_selection**

**link_selection**

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
