Grade Passback Tools
====================

Graded external tools are configured just like regular external tools. The
difference is that rather than adding the tool to a course as a link in a
module, a navigation item, etc. the tool gets added as an assignment.
Instructors will see a new assignment type called "External Tool" where 
they can select a tool configuration to use for the assignment. When students
go to view the assignment instead of seeing a standard Canvas description
they'll see the tool loaded in an iframe on the page. The tool can then 
send grading information back to Canvas.

Tools can know that they have been launched in a graded context because
an additional parameter is sent across, <code>lis_outcome_service_url</code>, 
as specified in the LTI 1.1 specification. Grades are passed back to Canvas 
from the tool's servers using the 
<a href="http://www.imsglobal.org/lti/v1p1pd/ltiIMGv1p1pd.html#_Toc309649691">outcomes component of LTI 1.1</a>. 