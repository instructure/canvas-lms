Link Selection Placement
==============

External tools can be configured to be selectable as an LTI resource link during 
**module item** creation. The **link_selection** placement 
allows course designers (Admins/Instructors) to use the <a 
href="file.content_item.html" target="_blank">LTI 
Deep Linking</a> flow to select an LTI resource from an external tool and 
associate it with a Canvas module item.


### Configuring
For configuration examples and links to the specification, please refer to the <a 
href="file.content_item.html" target="_blank">LTI Deep Linking documentation</a>.
Simply replace the **assignment_selection** text
with **link_selection** in the XML (LTI 1.0, 1.1, and 1.2) or JSON (LTI 1.3) examples.

### Advantages
- Course designers can create non-graded LTI resources as organized links in 
Canvas modules.
- Students can view non-graded LTI resources without leaving Canvas.
- Using <a href="https://community.canvaslms.com/docs/DOC-13134-415261967" 
target="_blank">module requirements</a>, Course designers can require the students 
to launch the tool before module progression is allowed.


### Limitations/Challenges
- Tools must support <a href="file.content_item.html" target="_blank">Deep Linking</a>.
- Tools must create a UI allowing the course designer to either select existing 
LTI resources or create them on-the-fly.
- Only one LTI resource can be returned at a time.
- Tools **cannot synchronize grades and submissions** back to the course gradebook
by leveraging <a href="file.assignment_tools.html" target="_blank">
LTI grading services</a>. Tools that want this capability should use the 
<a href="file.assignment_selection_placement.html" target="_blank">
assignment_selection placement</a> instead.


### Workflow
A user must be allowed to create Canvas module items and the tool must be
configured to use the link_selection placement. While tools *can* 
be configured to use link_selection without deep linking, the workflow
described here applies to tools that leverage deep linking *with* the 
link_selection placement. If a tool does not leverage deep linking, 
Canvas uses the URL configured at the tool-level or placement-level every
time the tool is selected in step 2 below.

During <a href="https://community.canvaslms.com/docs/DOC-10301-415270926" 
target="_blank">module item creation</a>:
1. the user can select "External Tool" from
the **Add** dropdown. 
2. They then choose the tool they want to select content from. 
3. Canvas then performs a Deep Linking launch request (if configured) to the 
tool and the user is presented with a tool-side UI to select or create a
single LTI resource.
4. The tool then returns the LTI deep linking message back to Canvas with a URL for
the LTI resource. Usually this message contains a URL with resource identifiers in the url.
5. When students view the module item, Canvas launches to the URL returned by the tool.
6. If a resource identifier was provided in Step 4, then the tool will receive this in the
launch and be able to render the correct resource.

### Settings
All of these settings are contained for the **link_selection** placement:

-   url: &lt;url&gt; (optional)

    This is the URL that will be POSTed to when users click selects the tool from
    the module item creation view. It can be the same as the tool's 
    URL, something different. Domain and URL matching are not enforced for 
    link_selection launches; however, if LTI links are returned, Domain and
    URL matching is enforced. In order to prevent security warnings for users, it
    is recommended that URLs be over SSL (https). This setting is required if a 
    url is not set on the main tool configuration.

-   text: &lt;text&gt; (optional)

    This is the default text that will be shown on in the tool selection menu.
    This can be overridden by language-specific settings if desired by 
    using the labels setting. This is required if a text value is not set on the
    main tool configuration.

-   labels: &lt;set of locale-label pairs&gt; (optional)

    This can be used to specify different label names for different locales. 
    For example, if an institution supports both English and Spanish interfaces,
    the text for the hover-over tip should change depending on the language 
    being displayed. This option lets you support multiple languages for a single tool.

-   enabled: &lt;boolean&gt; (required)

    Whether to enable this selection feature.

-   message_type: &lt;an IMS LTI message type&gt; (optional)

    Sets the message_type to be sent during the LTI launch. It is expected that 
    the tool use this to determine if a Deep Linking flow is being requested by
    Canvas and present an appropriate UI. A Deep Linking flow is highly recommended
    for this placement, but is not required. See the 
    <a href="file.content_item.html" target=_"blank">Deep Linking 
    documentation</a> for more information, including accepted values.

-   selection_width: &lt;pixels&gt; (optional)

    This sets the width (px) of the selection launch modal. Canvas may set a 
    maximum or minimum width that overrides this option.

-   selection_height: &lt;pixels&gt; (optional)

    This sets the height (px) of the selection launch modal. Canvas may set a 
    maximum or minimum height that overrides this option.


