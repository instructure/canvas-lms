External Tools Introduction
==============

Canvas, like many LMSs, supports loading external resources inline using the
<a href="http://www.imsglobal.org/lti/" target="_blank">IMS LTI standard</a>.
These tools can be deployed on a course or account level. Once configured, tools
can be surfaced <a href="file.link_selection_placement.html" target="_blank">as links in
course modules</a> or used to <a href="file.assignment_selection_placement.html"
target="_blank">deliver custom assignment experiences</a>. Canvas supports some
additional integration points using LTI (see the "Placements" dropdown in the
left hand navigation here) to offer a more integrated experience and to allow
for more customization of the Canvas product. This is accomplished by <a
href="file.lti_dev_key_config.html" target="_blank">configuring additional settings</a>
on external tools used inside of Canvas and by leveraging <a
href="https://www.imsglobal.org/lti-advantage-overview" target="_blank">LTI
Advantage services</a>.

Because tools can be deployed at any level in the system hierarchy, they can be
as general or specific as needed. The Chemistry Department can add chemistry-specific
tools without those tools cluttering everyone else's interfaces. Or, a single teacher
who is trying out some new web service can do so without needing the tool to be
set up at the account level.

## Types of Tool Integrations

Canvas currently supports the following types of tool placements:

External tool <a href="file.assignment_tools.html" target="_blank">assignments integrations</a>:

  This type of integration is part of the
  <a href="http://www.imsglobal.org/LTI/v1p1/ltiIMGv1p1.html" target=_"blank">LTI 1.1
  Outcomes Service</a> or <a href="http://www.imsglobal.org/spec/lti-ags/v2p0/"
  target="_blank">LTI 1.3 Assignment and Grade Services</a> and allows external services to
  synchronize grades, and other assignment details.

   Example use cases might include:

  - Administering a timed, auto-graded coding project
  - Evaluating a student's ability to correctly draw notes at different musical intervals
  - Giving students credit for participating in an interactive lesson on the Civil War

Adding a link/tab to the <a href="file.navigation_tools.html#course_navigation"
target="_blank">course navigation</a>:

  Example use cases might include:

  - Building a specialized attendance/seating chart tool
  - Adding an "ebooks" link with course required reading
  - Connecting to study room scheduling tool
  - Linking to campus communication hub
  - Displaying a course-level dashboard (ex: analytics, student engagement, risk assessment, etc.)

Adding a link/tab to the <a href="file.navigation_tools.html#account_navigation"
target="_blank">account navigation</a>:

  Example use cases might include:

  - Including outside reports in the Canvas UI
  - Building helper libraries for campus-specific customizations
  - Leveraging single sign-on for access to other systems, like SIS

Adding a link/tab to the <a href="file.navigation_tools.html#user_navigation"
target="_blank">
user profile navigation</a>:

  Example use cases might include:

  - Leveraging single sign-on to student portal from within Canvas
  - Linking to an external user profile

Selecting content to add to a variety of locations as <a
href="file.content_item.html" target="_blank">LTI deep links</a>:

  Example use cases might include:

  - adding a button to  <a href="file.editor_button_placement.html"
    target="_blank">embed content to the Rich Content Editor</a>:

   * Embedding resources from campus video/image repository
   * Inserting custom-designed chemistry diagrams into quiz question text
   * Building integrations with new or subject-area-specialized web authoring
     services

  - <a href="file.link_selection_placement.html" target="_blank">selecting links
   for modules</a>

   * Building and then linking to a remixed version of an online Physics textbook
   * Selecting from a list of pre-built, interactive quizzes on blood vessels
   * Choosing a specific chapter from an e-textbook to add to a module

  - <a href="file.assignment_tools.html" target="_blank">creating custom assignments for Canvas</a>

   * Creating a Canvas assignment that launches the student to a custom assessment
  that can be automatically graded by the tool and synced with the Canvas Gradebook
   * Launching the student to an assessment with interactive videos. Once complete,
  the tool returns an LTI launch url that allows the teacher to see the submission
  without leaving Canvas.

  - <a href="file.homework_submission_placement.html" target="_blank">allowing a
    student to submit attachments to assignments</a>

   * A student launches a custom video recording tool and submits the recording to Canvas
   * A student chooses an item from a portfolio tool and submits the item to Canvas



## How to Configure/Import Integrated Tools

### LTI 1.1
Tool's placements can be configured using
<a href="file.tools_xml.html">LTI configuration XML</a>
as specified in the IMS Common Cartridge specification, or using the <a
href="external_tools.html">external tools API</a>. Configuration XML contains all
non-account-specific settings (except the consumer key and shared secret, which must always be
entered manually). The user can <a href="https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-configure-an-external-app-for-a-course-using-a-URL/ta-p/884"
target="_blank">configure the tool by a tool-provided URL</a>
(recommended), or <a href="https://community.canvaslms.com/t5/Admin-Guide/How-do-I-configure-an-external-app-for-an-account-using-XML/ta-p/221"
target="_blank">paste in the XML</a> that the tool provides.

For information on how to programmatically configured external tools, so users
don't have to copy and paste URLs or XML, please see the Canvas
<a href="external_tools.html">external tools API</a>.

### LTI 1.3
Similar to LTI 1.1, tools built on the <a href="https://www.imsglobal.org/spec/lti/v1p3/"
target="_blank">LTI 1.3 specification</a> can be configured by either supplying clients with a
JSON block or URL that hosts the JSON. This JSON is used to determine the behavior of the tool
within Canvas by <a href="https://community.canvaslms.com/t5/Admin-Guide/How-do-I-configure-an-LTI-key-for-an-account/ta-p/140"
target="_blank">configuring and LTI Developer Key</a>. Once the developer key is created and
turned on, users with sufficient permissions can
<a href=https://community.canvaslms.com/t5/Admin-Guide/How-do-I-configure-an-external-app-for-an-account-using-a-client/ta-p/202 target="_blank">install the
tool using the developer key's client ID</a>.

#### LTI Advantage Services permissions

When setting up Developer Keys, the section “LTI Advantage Services” allows you to enable or disable permissions for 
access via that developer key. Below is the list of permissions available:

| Permission name                                                                       | What it does                                                                                                                                                | IMS / Canvas scope                                                        |
|---------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------|
| **Can create and view assignment data in the gradebook associated with the tool**     | Allows use of all functionality of the <a href="/doc/api/line_items.html" target="_blank">LTI LineItems API</a>                                             | https://purl.imsglobal.org/spec/lti-ags/scope/lineitem                    |
| **Can view assignment data in the gradebook associated with the tool**                | Allows use of the “show” and “list” endpoints of the <a href="/doc/api/line_items.html" target="_blank">LTI LineItems API</a>                               | https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly           |
| **Can view submission data for assignments associated with the tool.**                | Allows use of the <a href="/doc/api/result.html" target="_blank">LTI Advantage Result API</a>                                                               | https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly             |
| **Can create and update submission results for assignments associated with the tool** | Allows use of the <a href="/doc/api/score.html" target="_blank">LTI Advantage Score API</a>                                                                 | https://purl.imsglobal.org/spec/lti-ags/scope/score                       |
| **Can view Progress records associated with the context the tool is installed in**    | Allows use of the <a href="/doc/api/progress.html" target="_blank">Canvas LTI Progress API</a>, which is used during Score creation with an associated file | https://canvas.instructure.com/lti-ags/progress/scope/show                |
| **Can retrieve user data associated with the context the tool is installed in**       | Allows use of the <a href="/doc/api/names_and_role.html" target="_blank">LTI Advantage Names and Roles Provisioning Service</a>                             | https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly |
| **Can update public jwk for LTI services**                                            | Allows to update the public JWT                                                                                                                             | https://canvas.instructure.com/lti/public_jwk/scope/update                |
| **Can lookup Account information**                                                    | Allows use of the <a href="/doc/api/accounts_(lti).html" target="_blank">Canvas LTI Account API</a> (read only)                                             | https://canvas.instructure.com/lti/account_lookup/scope/show              |

NOTE: scopes with "https://canvas.instructure.com" are Canvas specific while others are LTI specifications
