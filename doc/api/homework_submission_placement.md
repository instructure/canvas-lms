Homework Submission Placement
==============

The **homework_submission** placement allows students to use the <a
href="file.content_item.html" target="_blank">LTI
Deep Linking</a> flow to select a resource from an external tool for submission
to an <a href="https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-add-or-edit-details-in-an-assignment/ta-p/971"
target="_blank">"Online File Upload"</a> submission type assignment.

### Configuring
For configuration examples and links to the specification, please refer to the <a
href="file.content_item.html" target="_blank">LTI
Deep Linking documentation</a>. Simply replace the **assignment_selection** text
with **homework_submission** in the XML (LTI 1.0, 1.1, and 1.2) or JSON (LTI 1.3)
examples.

### Advantages
- Allows Canvas to have a full copy of the file, which may be of importance for
auditing or other administrative purposes.
- Allows students to choose whether or not they want to use the tool to submit.
- Files can be checked for plagiarism by tools that use the <a
href="file.plagiarism_platform.html"
target="_blank">Plagiarism Detection Platform</a>.
- Integrates into the native Canvas submission workflow that students are already familiar with.

### Limitations/Challenges
- Tools cannot use <a href="file.assignment_tools.html"
target="_blank">LTI grading services to sync grades</a>.
- If the tool wants to update/alter the submission, the student must resubmit
the new version.

### Workflow
Once an assignment is <a href="https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-add-or-edit-details-in-an-assignment/ta-p/971"
target="_blank">configured to accept file uploads</a>, any LTI tool that uses
the **homework_submission** placement will be exposed as a tab when the student
attempts to submit to the assignment. Students will be able to choose to either
upload a file directly from their system, or click on a tool's tab. When the
tab is clicked, Canvas initiates an LTI launch to the tool and indicates that
a deep linking selection request is happening. The tool can then present the
student with a UI to select and/or create content and return it to the LMS as a
file download url. Canvas then attempts to download the file and attach it to the
Canvas submission.

The end result is Instructors can ask students to submit a file to Canvas as the
submission. The student can then choose from multiple sources for that file
without having to go to the source in a separate window and download the file
locally to their machine.

### Settings
All of these settings are contained for the **homework_submission** placement:

-   url: &lt;url&gt; (optional)

    This is the URL that will be POSTed to when users click tab in the file
    upload UI. It can be the same as the tool's URL, or something different. Domain and URL
     matching are not enforced for homework_submission launches. In order to prevent
     security warnings for users, it is recommended that URLs be over SSL (https).
    This setting is required if a url is not set on the main tool configuration.

-   text: &lt;text&gt; (optional)

    This is the default text that will be shown on the tab in the file
    upload UI. This can be overridden by language-specific settings if desired by
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

-   icon_url &lt;url&gt; (optional)

    The URL for an icon that identifies your tool in the RCE toolbar. It is
    it is recommended that this icon be at least 16 x 16 px and png or svg format
    the url should be secured over SSL (https). This icon only appears if a tool
    is listed in the "More" tab (i.e. the 4th or greater installed tool that uses
    this placement).

-   selection_width: &lt;pixels&gt; (optional)

    This sets the width (px) of the selection launch iframe. Canvas may set a
    maximum or minimum width that overrides this option.

-   selection_height: &lt;pixels&gt; (optional)

    This sets the height (px) of the selection launch iframe. Canvas may set a
    maximum or minimum height that overrides this option.
