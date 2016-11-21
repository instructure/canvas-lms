External Tools Introduction
==============

Canvas, like many LMSs, supports loading external resources inline using the
<a href="http://www.imsglobal.org/lti/">IMS LTI standard</a>.
These tools can be configured on a course or account level, and
can be added to course modules or used to create custom assignments (see the
LTI Outcomes service for more information on that). Canvas supports some additional
integration points using LTI to offer a more integrated experience and to allow for
more customization of the Canvas product, even in a cloud environment. This is
accomplished by configuring additional settings on external tools used inside of
Canvas.

Because tools can be configured at any level in the system heirarchy, they can be
as general or specific as needed. The Chemistry Department can add chemistry-specific
tools without those tools cluttering everyone else's interfaces. Or, a single teacher
who is trying out some new web service can do so without needing the tool to be
set up at the account level.

### Types of Tool Integrations

Canvas currently supports the following types of tool extensions:

[External tool assignments, with grades passed back from the tool to Canvas](assignment_tools.html):

  This type of integration is part of the
  [LTI 1.1 specification](http://www.imsglobal.org/LTI/v1p1/ltiIMGv1p1.html),
  and is important in that it allows external services to take care of things
  that can be graded automatically, or outside the LMS scope.

   Example use cases might include:

  - Administering a timed, auto-graded coding project
  - Evaluating a student's ability to correctly draw notes at different musical intervals
  - Giving students credit for participating in an interactive lesson on the Civil War

[Adding a link/tab to the course navigation](navigation_tools.html#course_navigation):

  Example use cases might include:

  - Building a specialized attendance/seating chart tool
  - Adding an "ebooks" link with course required reading
  - Connecting to study room scheduling tool
  - Linking to campus communication hub

[Adding a link/tab to the account navigation](navigation_tools.html#account_navigation):

  Example use cases might include:

  - Including outside reports in the Canvas UI
  - Building helper libraries for campus-specific customizations
  - Leveraging single sign-on for access to other systems, like SIS

[Adding a link/tab to the user profile navigation](navigation_tools.html#user_navigation):

  Example use cases might include:

  - Leveraging single sign-on to student portal from within Canvas
  - Linking to an external user profile

[Selecting content to add to a variety of locations](content_item.html):

  Example use cases might include:

  - adding a button to embed content to the Rich Content Editor:

   * Embedding resources from campus video/image repository
   * Inserting custom-designed chemistry diagrams into quiz question text
   * Building integrations with new or subject-area-specialized web authoring services

  - selecting links for modules or external tools

   * Building and then linking to a remixed version of an online Physics textbook
   * Selecting from a list of pre-built, interactive quizzes on blood vessels
   * Choosing a specific chapter from an e-textbook to add to a module

  - creating custom assignments for Canvas

   * Creating a Canvas assignment that launches the student to a custom assessment
  that can be automatically graded by the tool and synced with the Canvas Gradebook
   * Launching the student to an assessment with interactive videos. Once complete,
  the tool returns an LTI launch url that allows the teacher to see the submission
  without leaving Canvas.

  - allowing a student to submit attachments to assignments

   * A student launches a custom video recording tool and submits the recording to Canvas
   * A student chooses an item from a portfolio tool and submits the item to Canvas



### How to Configure/Import Integrated Tools

Tools extensions can be configured using LTI configuration XML as specified in the IMS
Common Cartridge specification, or using the <a href="external_tools.html">external tools
API</a>. Configuration XML contains all non-account-specific
settings (everything except the consumer key and shared secret, which must always be
entered manually). The user can retrieve the info from a standard URL that you provide
(recommended), or paste in the XML that you provide. For more information on this
configuration, see the "Examples" link.

For information on how to programmatically configured external tools, so users
don't have to copy and paste URLs or XML, please see the Canvas
<a href="external_tools.html">external tools API</a>.
