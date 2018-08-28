Assignment External Tools
=================

External tools can be configured to appear embedded in assignment content.  When “assignment_edit” or "assignment_view" is configured as the tool placement, the tool will be embedded at the bottom of assignment edit pages.  If the tool is configured on an account, any assignment in a course in that account or any of its sub-accounts will feature the external tool.  If the tool is configured on a course, then the external tool will only appear in assignments for that course.  Unless otherwise specified, all assignment placements will appear on assignment, discussion, and quiz pages.

There are some settings common to all assignment LTI placements.

### Settings

All of these settings are contained under an assignment placement type LTI (i.e. “assignment_edit” or "assignment_view")

-   url: &lt;url&gt; (optional)

    This is the URL that will be POSTed to when the LTI is launched.  It can be the same as the tool’s URL, or something different.  In order to prevent security warnings for users, it is recommended that this URL be over SSL (https).  This is required if a url is not set on the main tool configuration.

-   launch_height:  &lt;int&gt; (optional)

    The height of the iframe that will host the application.  Should be an integer value without any trailing unit (i.e. do not include “px”).  If not specified, the iframe height will arbitrarily be determined by Canvas.

-   launch_width:  &lt;int&gt; (optional)

    The width of the iframe that will host the application.  Should be an integer value without any trailing unit (i.e. do not include “px”).  If not specified, the iframe width will be 100% of the available space.  The max width of the iframe is the width of the hosting container.  Any width larger than this will be capped at the max width.


<a name="assignment_edit"></a>
## Assignment Edit Placements

When the “assignment_edit” placement is utilized, the external tool will appear in the following locations:
-   The bottom of the assignment edit page (just above the row to save changes)
-   The bottom of the “Details” tab on the quiz edit page (just above the row to save changes)
-   The bottom of course discussion edit pages (just above the row to save changes)


<a name="assignment_view"></a>
## Assignment View Placements

When the “assignment_view” placement is utilized, the external tool will appear in the following locations:
-   The bottom of the assignment view page
-   The bottom of the quiz view page
-   The bottom of the discussion topic view page

The assignment_view placement does not appear on Quizzes.next view pages.

### Settings

All of these settings are specific to the “assignment_view”

-   visibility: 'public', 'members', 'admins' (optional, 'public' by default)

    This specifies what types of users will see the LTI content on the assignment page. "public" means anyone accessing the course, "members" means only users enrolled in the course, and "admins" means only Teachers, TAs, Designers and account admins will see the content.
