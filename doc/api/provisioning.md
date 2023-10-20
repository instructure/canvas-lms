User Provisioning
==============

Many external tools will need to know which users are enrolled in a course and their roles. The approaches to this are varied depending on the version of LTI used and sometimes a single approach is not sufficient for all the use cases a tool might be interested in. Here, we outline several different approaches:

- [LTI Advantage: Assignment and Grading Services](#lti-advantage)
- [Provisioning During Launch](#on-launch)
- [Supplemental Provisioning via API](#supplemental-provisioning)



<a name="lti-advantage"></a>
LTI Advantage: Names and Role Provisioning Service
==============

The IMS <a href="https://www.imsglobal.org/spec/lti-nrps/v2p0" target="_blank"> Names and Role Provisioning Service (NRPS)</a> provides an efficient API for synchronizing course rosters. This capability is only available to LTI 1.3 tools. We will not discuss details of the specification here, but instead focus on configuring and using NRPS within the Canvas platform.

### Configuring

Before NRPS can be used, an <a href="https://community.canvaslms.com/t5/Admin-Guide/How-do-I-configure-an-LTI-key-for-an-account/ta-p/140" target="_blank">LTI Developer Key must be created</a> and enabled with the https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly scope. Next, the <a href="https://community.canvaslms.com/t5/Admin-Guide/How-do-I-configure-an-external-app-for-an-account-using-a-client/ta-p/202" target="_blank"> external tool must be installed</a> in, or above, the context of the course that needs to be provisioned.

### Authenticating

As with the other LTI Advantage service, tools must complete a specific <a href="file.oauth.html#accessing-lti-advantage-services" target="_blank">OAuth2 client credentials</a> grant in order to obtain an access token. This access token works for any course that the tool is available in. A single token can be used for multiple courses and services.

### Using NRPS

Once an access token is obtained, tools may begin to <a href="names_and_role.html" target="_blank">synchronize data using NRPS</a>. Using endpoint require knowledge of the context_memberships_url, which can either be obtained during the LTI launch in the <a href=https://www.imsglobal.org/spec/lti-nrps/v2p0#lti-1-3-integration target="_blank">Names and Role Service claim</a>, or by substituting the desired course_id/group_id in the <a href="names_and_role.html" target="_blank">Names and Role API</a>.

### Advantages
- Canvas REST API access is not required (i.e. no additional authorization UI)
- Interoperable
- Can provision all users in an entire course/group as long as the tool knows the context_memberships_url. This is easily obtained in the LTI payload.
- Can easily deterine if users have been removed from a course

### Limitations/Challenges
- Must have knowledge of the Canvas course_id/group_id or context_memberships_url
- Unidirectional: cannot push new enrollments to Canvas

### Workflow
- Step 1: Configure a tool that support NRPS in Canvas
- Step 2: Launch the tool
- Step 3: Tool consumes the Names and Role service claim as described in the<a href="https://www.imsglobal.org/spec/lti-nrps/v2p0#lti-1-3-integration" target="blank">NRPS specification</a>, or by substituting the desired course_id/group_id in the <a href="names_and_role.html" target="_blank">Names and Role API</a>.
- Step 4: Tool obtains <a href="file.oauth.html#accessing-lti-advantage-services" target="_blank">a client_credentials access token</a> (this can actually happen any time before the next step)
- Step 5: Tool runs requests against the <a "names_and_role.html" target="_blank">Names and Role API</a>.

*Note:* Once a single launch has happened from a course, the tool has enough information to use NRPS at any time and get info about all the users.

<a name="on-launch"></a>
Provisioning during launch
==============

### Configuring
This approach requires an LTI integration (any version) to be configured and visible somewhere within a Canvas course. Ideally, this LTI connection will already have an LTI SSO mechanism. If username, login ID, email, and/or SIS ID is required, make sure the privacy level is set to Public in the tool configuration. Otherwise, Canvas will only send an opaque LTI user id (as the user_id parameter) and a Canvas ID (as the custom_canvas_user_id).

### Advantages
- Canvas REST API access not required
- Interoperable
- Can provision users on-the-fly as they launch the tool

### Limitations/Challenges
- The tool is only aware of users who've launched their tool at least once
- Unidirectional: cannot push new enrollments to Canvas
- Cannot determine if users drop courses or are deleted from Canvas

### Instructor/Admin/Student Workflow
- Step 1: Configure an LTI tool in Canvas
- Step 2: Launch the tool
- Step 3: Tool consumes user information (name, email, ID's, roles, contextual information etc...) and attempts to match on an ID. Best practice is to match on the user_id from the launch and then fall back to some other ID if a match is not found
- Step 4: If a match is confirmed (and the signature matches), let the user access their information in your application
- Step 5: If no match is found, either or send them through a user-creation flow within the iframe, or auto-create a user for them based on the information in Canvas (you may want to let them set a password at this point, or email them a registration URL).

<a name="supplemental-provisioning"></a>
Supplemental Provisioning via API
==============

In the event that the LTI standard alone is not enough to satisfy your tool's provisioning needs, Canvas has an open REST API and a data service (<a href="https://community.canvaslms.com/t5/Admin-Guide/What-is-Canvas-Data-Services/ta-p/142" target="blank"> Canvas Data</a>). Using the API or Canvas Data can help overcome some of the limitations of LTI-only integrations, but they have their own challenges. Where possible, tools should try to avoid using services that are not part of the LTI standards unless it is absolutely necessary.

### Configuring
Accessing Canvas API's requires an institution to issue a <a href="file.developer_keys.html" target="_blank">Developer Key</a>. Once issued, tools can begin using <a href="file.oauth.html#accessing-canvas-api" target="_blank">OAuth2</a> to request access tokens from individual users. The access token issued to access LTI advantage services **will not work** to access REST APIs.

Accessing Canvas Data also has its own authentication system that is <a href="https://community.canvaslms.com/t5/Admin-Guide/What-is-Canvas-Data-Services/ta-p/142" target="blank">discussed elsewhere</a>.

### Advantages
- bi-directional enrollment synchronization via the <a href="enrollments.html" target="blank">enrollments API</a>
- more efficiently pre-provision an entire account by <a href="account_reports.html" target="_blank"> exporting provisioning reports</a> or using Canvas Data.
- Obtaining course_id's/group_id's required to sync courses via NRPS without a launch occurring from that course.

### Limitations/Challenges
- Requires implementation of additional authentication systems.
- Results in non-interoperable integrations.
- If using Canvas APIs to sync entire accounts, can be slow for large accounts due to <a href="file.throttling.html" target="_blank">API throttling</a> and the sheer volume of requests being made
- Reports can take hours to generate for large accounts; breaking into many smaller reports broken by term or object is recommended.
- Canvas Data is not updated in real-time.


Other options include connecting directly to that same SIS that the client may be using, or leveraging <a href="https://community.canvaslms.com/t5/Admin-Guide/What-is-Canvas-Data-Services/ta-p/142" target="_blank"> Canvas Data</a> to pull flat files for courses and enrollments.
