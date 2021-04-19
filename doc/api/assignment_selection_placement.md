Assignment Selection Placement
==============

External tools can be configured to be selectable as an assignment during
assignment creation or editing. The **assignment_selection** placement
alows course designers (Admins/Instructors) to use the <a
href="content_item.html" target="_blank">LTI
Deep Linking</a> flow to select an LTI resource from an external tool and
associate it with a Canvas assignment. Assigned students can then directly
access the tools assessment activity from Canvas. Tools can then leverage <a
href="assignment_tools.html" target="_blank">
LTI grading services</a> for a deeper assignment integration.

Note: This placement is enabled by default in Canvas for LTI 1.1. It can be
removed by using the `not_selectable` configuration option (see <a
href="external_tools.html" target="_blank">External Tools API</a>). For LTI
1.3, the placement will only be enabled if listed in the `placements` in the
JSON configuration.

### Configuring
For configuration examples and links to the specification, please refer to the <a
href="file.content_item.html" target="_blank">LTI
Deep Linking documentation</a>.

### Advantages
- Course designers can associate LTI resources with Canvas assignments.
- Students can complete LTI assignments without leaving Canvas.
- Tools can synchronize grades and submissions back to the course gradebook by
leveraging <a href="file.assignment_tools.html" target="_blank">
LTI grading services</a>.
- Using <a href="https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-add-requirements-to-a-module/ta-p/1131"
target="_blank">module requirements</a>, Course designers can require the students
to launch the tool, achieve a specific score, or submit to the item before
module progression is allowed.


### Limitations/Challenges
- Tools must support <a href="file.content_item.html" target="_blank"
>Deep Linking</a>.
- Tools must create a UI allowing the course designer to either select existing
LTI resources or create LTI resources on-the-fly.
- Only one LTI resource can be returned at a time.
- Only LTI links are allowed.


### Workflow
A user must be allowed to create Canvas Assignments and the tool must be
configured to use the **assignment_selection** placement. While tools *can*
be configured to use this placement without deep linking, the workflow
described here applies to tools that leverage deep linking *with* the placement.
If a tool does not leverage deep linking, Canvas uses the URL configured at the
tool-level or placement-level every time the tool is selected in step 2 below.

During <a href="https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-create-an-assignment/ta-p/740" 
target="_blank">assignment creation</a>:
1. the user can select "External Tool" from
the **Submission Type** dropdown.
2. They then choose "Find" and select the tool
they wish to select content from.
3. Canvas then performs a Deep Linking launch
request (if configured) to the tool and the user is presented with a tool-side UI
to select or create a single LTI resource.
4. The tool can return an LTI deep linking message back to Canvas with a URL for
the LTI resource. Usually this is a URL with resource identifiers in the url.
5. When students view the assignment, Canvas launches to the URL returned by the tool.
6. If a resource identifier was provided as part of the url, then the tool will see this in the
launch payload and be able to look up and render the correct resource.
7. After completing the tool-side assignment, tools may optionally return a grade
and/or submission. See the <a href="file.assignment_tools.html">Grading</a>
documentation for more details.

Now the instructors and students can view the grade/submission in the Canvas
gradebook if they were returned!

### Settings
All of these settings are contained for the **assignment_selection** placement:

-   url: &lt;url&gt; (optional)

    This is the URL that will be POSTed to when users click the **Find**
    button from the assignment create/edit view. It can be the same as the tool's
    URL, something different. Domain and URL matching are not enforced for
    assignment_selection launches; however, if LTI links are returned, Domain and
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

-   enabled: &lt;boolean&gt; (optional)

    Whether to enable this selection feature; this setting defaults to enabled if omitted.

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
