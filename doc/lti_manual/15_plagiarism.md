# Plagiarism

In its history, Canvas has had 3 options for plagiarism detection.

## Canvas Plugin
Created initially for TurnItIn and then VeriCite was added at a later point.
In this version, when a student submitted to an assignment that had plagiarism data associated with it, Canvas would create a delayed job with to contact the plagiarism vendor and request the plagiarism report.  This version was problematic because the job would finish somewhere around 20 hours after the submission was created and if the vendor hadn't created the report for some reason (they were delayed or their settings required waiting to an arranged time to create the report), the report would never show up.
Plagiarism report data is saved on the student's submission record.
Theoretically this should be out of use, but we seem to keep running into it occasionally.


## LTI 1.0
In this version the assignment would be an LTI assignment and the student would submit their assignment directly to the plagiarism vendor.  The plagiarism vendor would then pass that assignment to Canvas (or possibly not and require the teacher to view and grade inside of the plagiarism vendor's LTI frame).  This version was not widely adopted as it meant Canvas wasn't the system of record for the student's assignment submissions, which could be confusing.
Plagiarism report data is saved on the student's submission record.
This was never widely adopted, but there are still clients using it.

There is a known issue with this version of the tool if a teacher selects "only provide plagiarism scores after due date" is selected.  When we receive notice from the vendor that the submission was created, we start a delayed job to request the originality report, since the vendor does not tell us when the plagiarism report is complete.  We check back on the plagiarism report for about 20 hours (similar to the plugin version) before we stop trying, and if the setting is set to not give any data until the due date, we will not receive anything until after the due date is passed.  Since we cannot see the setting inside Canvas, there is no way for us to know that we need to wait.  And the due date might be different inside of the plagiarism LTI than it is in Canvas.


## LTI 2.0/Plagiarism Platform (also called CPF by vendors)
This is currently the most widely used, despite LTI 2.0 having been end of lifed some time ago.
In this version, the student submits their assignment to an assignment that has the LTI 2.0 plagiarism placement set to a plagiarism vendor.  When the student submits, a live event is sent to the location registered by the LTI 2.0 tool installation.  Then once the LTI 2.0 tool has created the plagiarism report, they send it to Canvas using the LTI 2.0 plagiarism API endpoints.
Plagiarism report data is saved to the OriginalityReport table and associated to the submission by use of submission times or attachment ids.
This version is problematic as the live event system used by this platform is not part of the LTI spec, and is not available to open source users.

Specifics of the endpoints and flow for Plagiarism vendors can be found in the (Canvas API)[https://canvas.instructure.com/doc/api/file.plagiarism_platform.html]

LTI 2.0's data model is complex and messy in Canvas.  This is part of why LTI 2.0 failed as a standard.  For reference, you can view the old (LTI 2.0 spec)[http://www.imsglobal.org/specs/ltiv2p0/implementation-guide].  Also see (Tool Installation)[./02_tool_installation.md] section ## LTI 2.0

Plagiarism Platform requires an Lti::ToolConsumerProfile to be set up with extra LTI capabilities that allow Canvas.placements.similarityDetection and vnd.Canvas.OriginalityReport.url.  Those have been created by engineers directly and the UUID for the profile is given to the tool developer.

Assignments associated with the plagiarism platform have an AssignmentConfigurationToolLookup associated to them that contains a vendor code, a product code and a resource type code.  These are used to search for an associated Lti::ToolProxy that is installed.  (Thus allowing a school/vendor to reinstall a new version of the tool and have the links still work).  See `Lti::ToolProxy.proxies_in_order_by_codes`(app/models/lti/tool_proxy.rb) for the logic about how these are queried.

When the Lti::ToolProxy is created, we create a webhook subscription for that tool.  Since Lti::ToolProxies are mostly installed at the root account and not all assignments use the Plagiarism Platform, the Lti::ToolProxy has an associated_tool_id added on creation.  We add this associated_integration_id to the live event subscription, and then when an event is received in the live events publisher from Canvas, any subscriptions that have an associated_integration_id will not receive any event without a matching associated_integration_id.  To add the appropriate associated_integration_id when an event is created, we have to look up the closest currently installed tool to the assignment using the assignment configuration tool and the tool proxy lookup code.


## Resubmission
There is an API endpoint (and a button in the UI) that will allow support or admins to resubmit the plagiarism data to the vendor if there is an issue and the data has not arrived.  The endpoint sends a new live event (of type plagiarism_resubmit) for the submission and restarts the delayed job process for either the LTI tool configuration or the plugin configuration (if either are set up).
