# Testing

There are a few common scenarios for testing LTI tools that will be detailed here, so that test plans on commits can just reference the pertinent section of this document instead of typing out the installation/setup/reproduction instructions.

## 1.1 Basic Outcomes (Grade Passback)

LTI 1.1 tools can pass grades back to Canvas, only after the student has launched the tool from the associated assignment. Using the [Outcome Service Example](./10_example_tools.md#Outcome-Service-Example) tool, it's possible to locally perform this action.

1. Install the above tool locally, following the instructions in the README.
2. Install the tool in Canvas, following the instructions in the README.
3. In a course with at least one student, create an assignment that launches this tool.
4. Masquerade as the student and launch the tool - the `?become_student` and `?become_user_id=:id` helpers may be useful here. While on the assignment page with url `http://canvas.docker/courses/1/assignments/`, add either of those parameters on to the end of the url to automatically masquerade as the student.
5. The tool should launch and allow you to post a score back to Canvas.
6. To manipulate the grade passback request (to add submission text, a url, a timestamp, etc), open the tool repository and change the XML in `lti_example.rb:100`. Documentation for this XML is located in the [Canvas API docs](https://canvas.instructure.com/doc/api/file.assignment_tools.html#outcomes_service).

## 1.3 AGS (Grade Passback)

The Assignments and Grades Service, which is part of LTI Advantage, allows 1.3 tools to pass grades back to Canvas with much more flexibility than the 1.1 Basic Outcomes methods. There are a couple of ways to make these kinds of requests locally.

### Getting an LTI Access Token

LTI access tokens are different than normal API access tokens, in that they aren't directly tied to a User or a DeveloperKey, and that they are a JWT instead of a traditional encoded string. This JWT contains useful information about the tool that requested the token, the scopes that the key
is allowed to access, and the expiration of the token.

Historically, generating an LTI access token requires an installed tool to create another JWT and send it to Canvas, and the best tool to do that with is the 1.3 test tool. Unfortunately, that tool is difficult to install in a production environment without using ngrok.

It's now possible to, as a Site Admin user, directly ask Canvas for an LTI access token for any 1.3 tool. This will make local development and troubleshooting much easier.

1. Sign in to Canvas as a Site Admin user (this can be local Canvas, or production).
2. Find the host/school/local canvas url, and a ContextExternalTool id or DeveloperKey id related to the tool for which you need a token.
3. Navigate to `<host>/api/lti/advantage_token`, and pass one of these two parameters: `tool_id=<tool id>` or `client_id=<client id>`. Example: `http://canvas.docker/api/lti/token?tool_id=6` or `office365.instructure.com/api/lti/token?client_id=170000000000401`

### With the 1.3 Test Tool

The test tool provides a nice UI for making all types of AGS requests, which can be nice for testing established features.

1. Install and configure the [1.3 test tool](./10_example_tools.md#LTI-1.3-Test-Tool) following the instructions in the README.
2. In a course with at least one student, create an assignment that launches this tool.
3. Go to `http://lti13testtool.docker/ags/new` and populate the information needed for the call you want to make. Submit the form to make the request.
4. To further manipulate the request body, edit the [`ags_service.rb`](https://gerrit.instructure.com/plugins/gitiles/lti-1.3-test-tool/+/refs/heads/master/app/services/ags_service.rb#98) file in the test tool repository.

### From an HTTP CLient

For testing new features that may not have been added to the test tool, or for maximum flexibility, you can make requests to the AGS endpoints using any HTTP client you like (curl, Postman, Insomnia, etc). You will need to acquire an LTI access token, which is different than an API access token. In addition to the site admin token endpoint described above, the test tool also allows for this.

1. Install and configure the [1.3 test tool](./10_example_tools.md#LTI-1.3-Test-Tool) following the instructions in the README.
2. In a course with at least one student, create an assignment that launches this tool.
3. In a shell in the test tool repository, run this command: (note that both ids are integers)
  ```
  docker-compose run --rm web jwt:access_token CLIENT_ID=<global DeveloperKey id>
  ```
4. This command returns a blob of JSON that includes an access token, which is a JWT. Include that token on all requests you make in an `Authentication: Bearer <jwt>` header.
5. Include a request body, which could look like something like this:
  - [Line Item API docs](https://canvas.instructure.com/doc/api/line_items.html)
  - [Score API docs](https://canvas.instructure.com/doc/api/score.html)
  - [Result API docs](https://canvas.instructure.com/doc/api/result.html)