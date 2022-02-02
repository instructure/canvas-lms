# Basic Outcomes

Also known as Grade Passback, this is the the IMS-blessed method of grading for 1.1 tools.

A great overview can be found in the [Canvas API Docs](https://canvas.instructure.com/doc/api/file.assignment_tools.html#outcomes_service),
and in the [LTI 1.1 Spec](http://www.imsglobal.org/specs/ltiv1p1/implementation-guide#toc-6).

This document is meant to provide an overview of the Canvas-specific implementation of this service.

## Initiating Launches

During launches relating to an assignment (ie, `generate_post_payload_for_assignment` is called, see [LTI 1.1 Implementation](./09_lti_1_1_implementation.md) for details),
a SourcedId is generated and added to the launch. This signifies that a grade passback request can be performed by the tool.
The SourcedId is a canvas-signed JWT that contains the ids of the tool, assignment, course, and user for that specific launch,
and is used to verify that the grade passback request is from the right tool and for the right request.

This SourcedId is added to the launch data by the `Lti::LtiOutboundAdapter` (app/models/lti/lti_outbound_adapter.rb),
in the `encode_source_id` method.

Note that `source id` and `sourced id` are used interchangeably throughout the codebase. If you have a bone to pick with the
naming, take it up with IMS.

## Grade Passback Requests

Requests to the `/api/lti/v1/tools/:id/grade_passback` endpoint are handled by the `LtiApiController`
(app/controllers/lti_api_controller.rb#grade_passback). The controller action parses inbound XML
from the request and delegates all further response to `BasicLTI::BasicOutcomes`
(lib/basic_lti/basic_outcomes.rb#process_request), which is a self-contained module that has the rest
of the basic outcomes code.

All errors that are returned from this process_request are transformed in the controller (#check_outcome)
into a Canvas ErrorReport, and logged to the database and to Sentry here. Information about the error and the
corresponding XML response are included, and then the ID of the ErrorReport is inserted back into the
XML before the HTTP response is sent, with a status of 422. To differentiate between the errors that
may occur, an `ext_canvas_error_code` XML attribute is included in the response XML headers along
with the IMS-specified status and description, which allows consumers like Quizzes to bucket any
errors received by the type.

The `BasicOutcomes` class's major responsibility is to decode the sourcedId using `BasicLTI::Sourcedid`
(lib/basic_lti/sourcedid.rb), and then pick a child class to handle the XML response and manipulate
actual Canvas data objects.

There are 3 child classes that inherit from each other to parse the request XML, perform Canvas
database operations, and construct a response.

1. `BasicLTI::BasicOutcomes::LtiResponse`: the base class, and the main workflow. Defines the base
response XML in `envelope` and populates it based on data from `handle_request`, the main entrypoint.
There are 3 operations that can be performed: read, delete, and replace. The first two are not used
very often and have very simple implementations. The last, on the other hand, has the bulk of the logic
used to calculate scores for a submission. There are two main destinations for a replace operation:
creating a new submission for a user, using the Assignment methods `submit_homework` and `grade_student`,
and creating a delayed job to fetch an attachment from a url and then creating a submission.

2. `BasicLTI::BasicOutcomes::LtiResponse::Legacy`: a child class, used only for some "legacy" (and keep
in mind this was considered legacy in 2011) requests that use an earlier version of the basic LTI spec
that had drastically different request/response formatting. One major partner (TurnItIn's 1.1 tool)
evidently still uses this format. Sad!

3. `BasicLti::QuizzesNextLtiResponse`: a child class (yet currently in a different level of class
hierarchy, joy), and the workflow dedicated specifically for the New Quizzes 1.1 tool. This only
overrides handle_replace_result, and has some quizzes-specific differences in how submissions
are graded and how previous versions of a submission can be referenced.