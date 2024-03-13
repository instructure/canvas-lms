Editor Button Placement
==============

External tools can be configured to appear as buttons in the rich content editor.
The **editor_button** placement allows many users to use the <a
href="file.content_item.html" target="_blank">LTI Deep Linking</a>
flow to select resources from an external tool and embed them in the
<a href="https://community.canvaslms.com/t5/Canvas-Basics-Guide/What-is-the-New-Rich-Content-Editor/ta-p/12"
target="_blank">Canvas Rich Content Editor</a> (RCE).

### Configuring
For configuration examples and links to the specification, please refer to the <a
href="file.content_item.html" target="_blank">LTI
Deep Linking documentation</a>. Simply replace the **assignment_selection** text
with **editor_button** in the XML (LTI 1.0, 1.1, and 1.2) or JSON (LTI 1.3) examples.

### Advantages
- Tools can embed different content types (images, text/html, LTI Launch URLs,
basic URLs).
- Tools can determine the presentation style and size of the content.
- Tools can return an array of different content types in a single message.
- Many different types of users can access the RCE from many different locations
such as assignment descriptions, discussions posts, and wiki pages.


### Limitations/Challenges
- Grades cannot be applied to editor content; use the
<a href="file.assignment_selection_placement.html" target="_blank">assignment_selection
placement</a> if grades are desired.
- Requires UI interactions to generate content. To generate content server-to-server,
use of <a href="file.oauth.html#accessing-canvas-api" target="_blank">Canvas API</a> is required.


### Workflow
1. A user loads a page that has the RCE available (discussion posts, quiz
questions, etc.).
2. Once loaded, tools that use the **editor_button** placement
will appear in the tool bar of the RCE.
3. When the tool bar button is clicked, Canvas initiates an LTI launch to the
tool and indicates that a deep linking selection request is happening.
4. The tool can then present the user with a UI to select and/or create content and return
items of different types to Canvas.
5. Canvas then consumes the request and converts the payload to HTML in the RCE.
6. Once published, the audience can then view the content returned by the tool.

The end result is users can search for embeddable content from a tool provider
and submit it back to the RCE without having to leave Canvas or paste embed code!

**Pro-tip:** Use the com.instructure.Editor.contents and/or com.instructure.Editor.selection
<a href="file.tools_variable_substitutions.html"
target="_blank">variable substitutions</a> to include the full RCE contents and/or
highlighted selection, respectively, in the launch request.

### Settings
All of these settings are contained for the **editor_button** placement:

-   url: &lt;url&gt; (required if not set on main tool configuration)

    This is the URL that will be POSTed to when users click the left tab. It can
     be the same as the tool's URL, or something different. Domain and URL
     matching are not enforced for editor_button launches; however, if LTI links
     are returned, Domain and URL matching is enforced. In order to prevent
     security warnings for users, it is recommended that URLs be over SSL (https).
     This setting is required if a url is not set on the main tool configuration.

-   text: &lt;text&gt; (required if not set on main tool configuration)

    This is the default text that will be shown on the hover-over tip for the RCE
    button. This can be overridden by language-specific settings if desired by
    using the labels setting. This is required if a text value is not set on the main tool configuration.

-   icon_url &lt;url&gt; (optional)

    The URL for an icon that identifies your tool in the RCE toolbar. The icon
    will be shown at 16x16 pixels in the editor toolbar, and at 28x28 pixels in
    the editor's listing of all tools. It is recommended that this icon be in
    PNG or SVG format. The url must be an https (SSL) URL.

    After April 2024, if a tool does not provide an icon_url on the
    editor_button placement or the main tool configuration, a default icon
    based on the first letter of the tool's name will be used. Before this
    change, if a tool does not provide an icon_url, the editor_button placement
    will be removed from the tool's install configuration, and the tool will not
    be shown in the editor_button placement.

-   labels: &lt;set of locale-label pairs&gt; (optional)

    This can be used to specify different label names for different locales.
    For example, if an institution supports both English and Spanish interfaces,
    the text for the hover-over tip should change depending on the language
    being displayed. This option lets you support multiple languages for a single tool.

-   enabled: &lt;boolean&gt; (optional)

    Whether to enable this selection feature; this setting defaults to enabled if omitted.

-   message_type: &lt;an IMS LTI message type&gt; (optional)

    Sets the message_type to be sent during the LTI launch. It is expected that
    the tool use this to determine if a Deep Linking flow is being requested by
    Canvas and present an appropriate UI. A Deep Linking flow is highly recommended
    for this placement, but is not required. See the
    <a href="file.content_item.html" target=_"blank">Deep Linking
    documentation</a> for more information, including accepted values.

-   selection_width: &lt;pixels&gt; (optional)

    This sets the width (px) of the selection launch modal. Canvas may set a
    maximum or minimum width that overrides this option.

-   selection_height: &lt;pixels&gt; (optional)

    This sets the height (px) of the selection launch modal. Canvas may set a
    maximum or minimum height that overrides this option.

-   visibility: 'public', 'members', 'admins' (optional, 'public' by default)

    This specifies what types of users will see the link in the editor. "public" means anyone accessing the course, "members" means only users enrolled in the course, and "admins" means only Teachers, TAs, Designers and account admins will see the link.
