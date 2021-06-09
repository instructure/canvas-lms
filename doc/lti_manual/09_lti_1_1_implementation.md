# Lti 1.1 Implementation

Canvas LTI 1.1 Implementation can be divided into three sections: tool installation, tool launches, and content item.

## Tool Installation
Tools are created via post requests to the `ExternalToolsController#create` action. Sometimes this is done by partners or customers making API requests directly. Sometimes this is done by using the UI Canvas provides.

The [Instructure API documentation](https://canvas.instructure.com/doc/api/external_tools.html) is a helpful resource to see what parameters may be used when creating a tool.

Tools are modeled using the ContextExternalTool class (context_external_tools table). This table has several columns to help keep track of the tool's context (account or course), privacy level (See [LTI 1.1 Launches](./05_lti_1_1_launches.md)), and configuration.

The `settings` column of the `context_external_tools` table is one of the most important data points. It contains a serialized representation of the tool's configuration.

Example `settings` column contents:
```ruby
{
  "url" => "https://wkd-lti-test.herokuapp.com/messages/blti"
  "selection_height" => 500,
  "selection_width" => 500,
  "text" => "Extension text",

  # Placement specific configuration
  "course_navigation" => {
        "canvas_icon_class" => "icon-lti",
                 "icon_url" => "https://wkd-lti-test.herokuapp.com/selector.png?course_navigation",
                     "text" => "course_navigation Text",
                      "url" => "https://wkd-lti-test.herokuapp.com/messages/blti"
    },
    "user_navigation" => {
        "canvas_icon_class" => "icon-lti",
                 "icon_url" => "https://wkd-lti-test.herokuapp.com/selector.png?user_navigation",
                     "text" => "user_navigation Text",
                      "url" => "https://wkd-lti-test.herokuapp.com/messages/blti"
    }
}
```

Data in the setting column is one of two types: top-level configuration or placement-level configuration.

In this example, the first key (`url`) is an example of a top-level configuration. Top-level configuration can usually be overridden by placement-specific configuration.

Placement-specific configuration is nested in a sub-hash with the placement name as the key. In the above configuration, the sub-hash identified by the `course_navigation` key is placement-specific. When Canvas launches an LTI tool, placement-specific configuration always trumps top-level configuration.

See the [LTI Overview](./01_lti_overview.md) for more information on placements.

The [External Tools Create API documentation](https://canvas.instructure.com/doc/api/external_tools.html#method.external_tools.create) does a good job enumerating possible keys and values the settings hash may contain.

Once a tool has been added to Canvas in the form of a `ContextExternalTool` record it can be launched.

## Tool Launches
For a conceptual overview of LTI 1.1 launches, see [LTI 1.1 Launches](doc/lti_manual/05_lti_1_1_launches.md)

LTI 1.1 launches use have five primary components in play:
- The user's browser
- Rails Controllers Actions
- LTI Outbound Adapter / Related Factories
- LTI Outbound Gem
- IMS LTI Gem

Here is a very high-level overview showing the lifecycle of a launch and what components are used:
![LTI Launch Component Overview](assets/lti_launch_overview.png)

Next, we will go through each component that makes the LTI launch work in greater detail.

### 1. The User's Browser
LTI launches begin when a user clicks a link to some LTI tool in their browser. Their browser makes a GET request to one of the LTI launch controller actions.

### 2. Rails Controller Actions
A rails controller action handles the request made by the user's browser. For LTI 1.1, there are five controller actions used to trigger LTI launches:

**UsersController#external_tool**(`/app/controllers/users_controller.rb#external_tool`)

This action is only used for handling LTI launches that use the `user_navigation` placement.


**ApplicationController#content_tag_redirect**(`app/controllers/application_controller.rb#content_tag_redirect`)

This action is used to trigger LTI launches for two primary cases: "external tool" Assignment launches, and module item launches.

Both of these launches have one thing in common: a ContentTag record exists in Canvas that maps the assignment or module item to an external tool.

This action knows how to take a ContentTag pointing to an external tool and launch it.


**ExternalToolsController#show**(`app/controllers/external_tools_controller.rb#show`)

This is one of the most common actions that handle LTI launches. If the ID of the `ContextExternalTool` is known, this action will launch that tool.

This endpoint is used by any placement where the tool ID is known (`course_navigation`, `account_navigation`, etc.)


**ExternalToolsController#retrieve**(`app/controllers/external_tools_controller.rb#retrieve`)

This action is used when the exact `ContextExternalTool` ID is not known, but the launch URL to be used in the LTI launch is.

This scenario can occur when an LTI link is embedded in the RCE, for example.


**ExternalToolsController#generate_sessionless_launch**(`app/controllers/external_tools_controller.rb#generate_sessionless_launch`)

This particular action enables LTI launches in contexts that do not have an active Canvas web session. This is primarily used by the Canvas mobile apps.

To use an LTI 1.1 sessionless launch, a client first makes a request to the `generate_sessionless_launch` endpoint. This creates an LTI 1.1 launch in much the same way as the other actions (more details below).

Rather than rendering the LTI launch, however, this endpoint caches the LTI launch as a serialized Hash and returns a random "verifier" string to the client.

The client can then make a follow-up request to the `sessionless_launch` endpoint and provide that verifier, which will render the LTI launch.

**Action Summary**

While these actions differ in a few ways, they each perform similar steps do launch the LTI tool. Each of the above actions to the following:

**I. Lookup the correct ContextExternalTool record**.

In the `ExternalToolsController#show` action, this is as easy as `@context.context_external_tools.active.find(params[:external_tool_id])`.

Other actions, however, lookup the tool in different ways. The `ExternalToolsController#retrieve`action looks up the tool by URL and the `ApplicationController#content_tag_redirect` action looks up the tool by ContentTag.

**II. Construct an Lti::Launch instance**

Next, the action constructs an object that is used to model the LTI launch data. This model is not an active record model, it's just used to provide a common interface that describes an LTI launch.

The Launch model class is located at `app/models/lti/launch.rb`

This Launch model contains several important attributes like `params` (a hash of all parameters) and `launch_type`.

in the `ExternalToolsController#show` action, this model is initialized like this:
```ruby
# ExternalToolsController#basic_lti_launch_request
lti_launch = tool.settings['post_only'] ? Lti::Launch.new(post_only: true) : Lti::Launch.new
```
The model is now initialized but does not have much useful data in the `params` attribute. Next, the action will work to populate those parameters.

**III. Construct an Lti::VariableExpander instance**

LTI launches may include _custom variable expansions_ in the launch as parameters (See [Custom Parameters](./08_custom_parameters.md)).

To expand these custom variables, LTI controller actions use the `Lti::VariableExpander` (lib/lti/variable_expander.rb).

This class can take a hash of key/values and expand all the expandable values. Expandable values being with a `$`. For example, the variable expander could transform a hash like this: `{ course_id: '$Canvas.course.id' }` into `{ course_id: 23 }`.

The action constructs an instance of this variable expander class in order to expand custom variables. In the `ExternalToolsController#show` action, this happens like so:
```ruby
# ExternalToolsController#basic_lti_launch_request
expander = variable_expander(assignment: assignment,
      tool: tool, launch: lti_launch,
      post_message_token: opts[:launch_token],
      secure_params: params[:secure_params])
...

private

def variable_expander(opts = {})
  default_opts = {
    current_user: @current_user,
    current_pseudonym: @current_pseudonym,
    tool: @tool }
  Lti::VariableExpander.new(@domain_root_account, @context, self, default_opts.merge(opts))
end
```

As you can see from the above code, the variable expander's initializer requires contextual information to expand all possible variables.

**IV. Construct an Lti::LtiOutboundAdapter instance**

The action is getting closer to populating the `Lti::Launch` model's `params` attribute, but we need one more thing first.

Ultimately, the `lti_outbound` Ruby gem (located in `gems/lti_outbound`) is responsible for creating the hash we will use for the `params` attribute.

This Ruby gem's original intent was to create a reusable library that other tool consumers (besides Canvas) could use to easily do LTI launches. This intent was never fully realized, but it still provides a nice separation of concerns.

The `lti_outbound` gem models resources that are important to an LTI launch, then uses those models to generate a Hash representing the LTI launch parameters. This means we need some way to translate Canvas models (like User, Course, etc.) into `lti_outbound` models (like LtiUser, LtiContext, etc.).

The LTI controller actions use a class that serves as a translation layer between the Canvas models and the `lti_outbound` models: an _adapter_.

The LTI controller action constructs an instance of an Lti::LtiOutboundAdapter as the next step of getting the `Lti::Launch.params` populated.

In the `ExternalToolsController#show` action, this happens like so:
```ruby
adapter = Lti::LtiOutboundAdapter.new(tool, @current_user, @context).prepare_tool_launch(
  @return_url,
  expander,
  opts
)
```

We'll talk more about the `prepare_tool_launch` method getting called there later, but for now, just know it's constructing the `lti_outbound` models.

Next, the controller action uses some public methods from the adapter to construct the parameters. Let's see what the adapter is doing under the hood:

### 3. LTI Outbound Adapter & Related Factories
TODO

### 4. LTI Outbound Gem
TODO

### 5.IMS LTI Gem
TODO

### 6. Self-submitting HTML form