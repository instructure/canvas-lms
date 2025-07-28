# Tool Installation

The first step in using an LTI tool of any version is to install it, and that process differs by version. This file will walk you through how to install a tool of any version, and the relevant parts of the Canvas code for each step. Installing a tool requires a Tool Configuration, commonly represented by XML or JSON, that describes the name and domain of the tool, as well as where it should appear in Canvas. This Tool Configuration varies by LTI version, and is left up to the implementing Platforms to describe and store.

Canvas's implementation of tool configuration allows tools to be configured once and deployed or installed multiple times where possible, especially for LTI 1.3 and 2 tools. One of the main reasons for this configuration is to tell Canvas where to show links to this tool, referred to as Placements. A mostly-comprehensive list of placements is found in [`Lti::ResourcePlacement::PLACEMENTS`](/app/models/lti/resource_placement.rb). Once created, a Tool is represented in Canvas using the [`ContextExternalTool`](/app/models/context_external_tool.rb) Rails model.

## LTI 1.1

LTI 1.1 tool installation is much more simple than 1.3 or 2, since tools are directly installed in the context they are available in, and LTI 1.1's use of OAuth 1 means the only configuration information needed is a name, key and secret, and placements. The LTI 1.1 spec doesn't really define a format for configuring tools directly, but it does provide a format for importing external tools using Common Cartridge ([see spec, section 5](https://www.imsglobal.org/specs/ltiv1p1/implementation-guide)). Canvas and other Tool Consumers use this format to allow users to configure external tools, and we provide some Canvas-specific extensions to the format, including placements, and domain. This format is documented in the Canvas API docs [here](https://canvas.instructure.com/doc/api/file.tools_xml.html).

1. Go to the context in which you wish to install the tool. This can be a Course or Account.
2. Go to the Settings page in the left hand nav.
3. Go to the Apps tab, and click View App Configurations -> +App.
4. For LTI 1.1 tools, you can choose Manual Entry, By URL, or Paste XML. They all do effectively the same thing.
5. Provide the tool name, key, and secret, and other information needed, and click Submit.
6. The tool is now installed!

### Relevant Code

- The UI code for the Apps tab is under `app/jsx/external_apps`. It is a standalone React app that gets initialized when that tab is loaded.
- The [`ExternalToolsController`](/app/controllers/external_tools_controller.rb)is in charge of creating `ContextExternalTool`s
- Parsing the XML config passed in, whether pasted or from a URL, is done in `ContextExternalTool#process_extended_configuration`, which uses the Common Cartridge gem to parse the XML and then uses the content migration importer to create the tool with the correct configuration
- [`Importers::ContextExternalToolImporter`](/app/models/importers/context_external_tool_importer.rb) is used both by tool installation and also for its original purpose of importing an external tool using Common Cartridge.

## LTI 1.3

LTI 1.3 tool installation is very different from LTI 1.1 installation, since there is no format for configuration in the spec. However, the spec does talk about [tool deployment](http://www.imsglobal.org/spec/lti/v1p3/#tool-deployment), and during implementation we decided to mostly follow the "multi-tenant" format of deployment, where a tool is registered once (and has one `client_id` and one public key) and deployed one or many times (with many `deployment_id`s) in different contexts. 

Tool registration is likewise not explicitly defined in the 1.3 spec, but the IMS Security Framework provides some helpful guidance in the section describing [OpenID Connect Launch Flow](https://www.imsglobal.org/spec/security/v1p0/#openid_connect_launch_flow). In the OpenID Connect model (which is built on top of OAuth 2), Platform and Tool must be aware of each other before a successful launch can happen. The Tool must be given an OAuth 2 `client_id` and also a public key by the Platform, and the Platform must know what launch URLs to associate with that `client_id`, and also have the private key that matches the public key. In addition, the Tool must give the Platform a login endpoint that will start the OAuth 2 flow, one or many `redirect_uri`s that are valid end points for the Tool launch, and the Platform must give the Tool the Oauth2 authorization endpoint to connect the whole launch together.

To facilitate this sharing of information and to keep all tool configuration options in one place regardless of deployment location, an existing Canvas model was co-opted. The [`DeveloperKey`](/app/models/developer_key.rb) grants API access tokens to users and is in charge of access level, and was easily extended in the form of an "LTI Developer Key". The OAuth 2 `client_id` is just the global ID of the `DeveloperKey` associated with the tool, and that `DeveloperKey` also stores the tool's redirect URLs, its public JWK (JSON Web Key), and the scopes (or actions that the tool can perform against LTI Services). For a comprehensive list of scopes, both IMS-defined and Canvas extensions, see [`TokenScopes`](/lib/token_scopes.rb). This allows the tool to get an LTI access token for LTI Advantage services.

The actual tool configuration for LTI 1.3 is a custom JSON specification, detailed [here](https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html#anatomy-of-a-json-configuration). This specification is pretty Canvas-specific, but includes ideas from the [OpenID Connect Registration flow ](https://connect2id.com/products/server/docs/guides/client-registration) as well as the [section of the LTI spec](http://www.imsglobal.org/spec/lti/v1p3/#cclinks) that deals with importing in the Common Cartridge format. The Canvas API docs do a pretty good job of explaining each field, but the `extensions` field is worth highlighting for this important lesson: The LTI spec includes `extensions` fields in many schemas, to allow Platforms and Tools to do custom things and allow for domain-specific behavior. In Canvas's case, the `extensions` field is where the bulk of the configuration lives, as that field contains a list of placements and the details of how to display the tool at each placement. It's recommended for tools to provide this JSON via an easily-accessible URL, which is provided during creation of the `DeveloperKey`. This configuration is stored in an `Lti::ToolConfiguration` record linked to the tool's `Developer Key`, and is retrieved whenever the tool is installed into a new context.

1. Go to the account in which you wish to install the tool - for a globally-available tool, this should be Site Admin. Otherwise, it can be a root account.
2. Go to the Developer Keys page in the left hand nav.
3. Click +Developer Key -> +LTI Key to add a new developer key.
4. Provide the tool name. In the Redirect URIs box, enter the `target_link_uri` from the JSON configuration.
5. Choose Manual Entry, Paste JSON, or Enter JSON URL and complete the form. Click Submit.
6. Take note of the ID of your `DeveloperKey`, since your tool will need to compare that `client_id` against the ID Token's `aud` claim (spec [here](https://www.imsglobal.org/spec/security/v1p0/#id-token)), and you will need it to install the tool in the context(s) of your choice.
7. Go to the context in which you wish to install the tool (Course or Account).
8. Go to the Settings page in the left hand nav.
9. Go to the Apps tab and click View App Configurations -> +App.
10. Choose By Client ID , and paste the ID of the `DeveloperKey` you just created.
11. The tool is now installed!

### Relevant Code

- [`DeveloperKey`](/app/models/developer_key.rb)
- The UI code for the Developer Keys page is under `app/jsx/developer_keys` and is a standalone React app initialized on page load
- The UI code for the Apps tab is under `app/jsx/external_apps`. It is a standalone React app that gets initialized when that tab is loaded.
- The [`ExternalToolsController`](/app/controllers/external_tools_controller.rb)is in charge of creating `ContextExternalTool`s
- [`Lti::ToolConfiguration`](/app/models/lti/tool_configuration.rb) is in charge of creating a `ContextExternalTool` from the configuration it has stored, and uses the same importer as LTI 1.1 to construct the tool
- [`Importers::ContextExternalToolImporter`](/app/models/importers/context_external_tool_importer.rb) is used both by tool installation and also for its original purpose of importing an external tool using Common Cartridge.


## LTI 2.0

One of the defining features of the LTI 2 spec was automatic tool registration, meaning no more fussing around with XML configuration! Instead, the installation process (mostly) boils down to giving Canvas a registration URL and letting it and the tool figure things out. There are a couple of prerequisites, though.

Like LTI 1.3, the root model for tool configuration is a [`DeveloperKey`](/app/models/developer_key.rb). This allows all configuration options for the tool to be linked back to a single place, and to grant the tool an access token for grade passback services. However, this `DeveloperKey` is a normal API key, and not a special LTI key like 1.3. This key is used by the tool on installation to do all the work on the tool side instead of the Canvas side.

One of the main use cases for LTI 2 tools in Canvas is the Plagiarism Platform, which allows tools like TurnItIn to take submissions, grade them for originality, and pass them back to Canvas. This is actually the only use case that is still active, and the only reason we haven't ripped out LTI 2 support. For a tool to properly use this platform, it requires access to the "restricted" service and capabilities defined in [`Lti::ToolConsumerProfile`](/app/models/lti/tool_consumer_profile.rb), and a `ToolConsumerProfile` must be created and associated to the tool. It's not required, and all LTI 2 tools have access to the "default" services and capabilities also defined in that model.

1. Go to the account in which you wish to install the tool - for a globally-available tool, this should be Site Admin. Otherwise, it can be a root account.
2. Go to the Developer Keys page in the left hand nav.
3. Click +Developer Key -> +API Key to add a new developer key.
4. Provide the tool name and a Vendor Code, which should be a domain name registered to the vendor, eg `Instructure.com`, and click Save.
5. Take note of the ID and secret of your `DeveloperKey`, since your tool will need to use those to access Canvas APIs.
6. (Optional) Launch a Rails console to create a `ToolConsumerProfile`:
```
key = DeveloperKey.find(<your developer key id>)
Lti::ToolConsumerProfile.create!(
    services: Lti::ToolConsumerProfile::RESTRICTED_SERVICES,
    capabilities: Lti::ToolConsumerProfile::RESTRICTED_CAPABILITIES,
    developer_key: key
)
```
6. Go to the context in which you wish to install the tool (Course or Account).
7. Go to the Settings page in the left hand nav.
8. Go to the Apps tab and click View App Configurations -> +App.
9. Choose By LTI 2 Registration Url, and paste the registration url of the tool.
10. The tool is now installed!

### Relevant Code

- [`DeveloperKey`](/app/models/developer_key.rb)
- [`Lti::ToolConsumerProfile`](/app/models/lti/tool_consumer_profile.rb)
- [`Lti::ToolConfiguration`](/app/models/lti/tool_configuration.rb) is in charge of creating a `ContextExternalTool` from the configuration it has stored, and uses the same `Importers::ContextExternalToolImporter` to construct the tool