Homework Submission Tools
=================================

An extension to standard LTI, external tools can be configured
to appear when a student is submitting content for an assignment.
When a tool is configured, users will see an additional tab during
assignment submission for assignments that accept online submissions.
If a user selects a homework submission tool, a popup will appear
where the external tool will be loaded. The tool should direct users
to select or build some piece of content, then submit that content to
the tool. The tool will then redirect the user to the LTI success URL
with some additional parameters. Canvas will take this information and
submit it for the current user as their submission to this assignment.

When tools are loaded as homework submission tools, Canvas uses the
LTI content extension to communicate what types of content are
accepted.  This extension adds the following parameters to the LTI
launch event:

-   <b>ext\_content\_intended\_use:</b> This describes what the content will be used
    for once it is returned to Canvas. For a homework submission tools the
    value will be "homework".

-   <b>ext\_content\_return\_types:</b> A comma separated list of the possible return
    types.  The possible values for homework submissions are "file" and "url".

-   <b>ext\_content\_return\_url:</b> The url that the external tool should redirect
    the user to with the selected content.

-   <b>ext\_content\_file\_extensions</b> (optional): A comma separated list of the file
    extensions that are allowed as valid submissions for this assignment.

When a tool receives these launch parameters, it means that Canvas is
expecting the tool to redirect the user to the ext_content_return_url
with some additional parameters. These additional parameters tell
Canvas what type of content to embed, as listed below. Remember to
URL encode parameter values such as url.

Remember, to prevent unexpected security warnings for users, it's recommended
that all URLs you return be over SSL (https instead of http).

## Possible Redirect Parameters
### to submit a file:
<table class="tool">
  <tr>
    <td>return_type=file</td>
    <td></td>
    <td>(required)</td>
  </tr><tr>
    <td>url=&lt;url&gt;</td>
    <td>this is a URL to the file that can be retrieved without requiring any additional authentication (no sessions, cookies, etc.)</td>
    <td>(required)</td>
  </tr><tr>
    <td>text=&lt;file name&gt;</td>
    <td>this is the filename</td>
    <td>(required)</td>
  </tr><tr>
    <td>content_type=&lt;mime/type&gt;</td>
    <td>content or MIME type of the file to be retrieved</td>
    <td>(optional)</td>
  </tr>
</table>

#### examples:
If the `launch_presentation_return_url` were
<code>http://www.example.com/done</code>, possible return URLs could include:

- http://www.example.com/done?return_type=file&url=https%3A%2F%2Fothersite.com%2Ffile.pdf&text=good+picture.pdf
- http://www.example.com/done?return_type=file&url=https%3A%2F%2Fothersite.com%2Fimage2.gif&text=great+picture.gif&content_type=image%2Fgif

### to submit a url:
<table class="tool">
  <tr>
    <td>return_type=url</td>
    <td></td>
    <td>(required)</td>
  </tr><tr>
    <td>url=&lt;url&gt;</td>
    <td>this is used as the 'href' attribute of the inserted link</td>
    <td>(required)</td>
  </tr>
</table>

#### examples:
If the `launch_presentation_return_url` were
<code>http://www.example.com/done</code>, possible return URLs could include:

- http://www.example.com/done?return_type=url&url=https%3A%2F%2Fothersite.com%2Flink

## Settings
All of these settings are contained under "homework_submission" in the tool configuration

-   url: &lt;url&gt; (optional)

    This is the URL that will be POSTed to when users click the button in any rich editor. It can be the same as the tool's URL, or something different. Domain and URL matching are not enforced for editor button links. In order to prevent security warnings for users, it is recommended that this URL be over SSL (https).
    This is required if a url is not set on the main tool configuration.
  
-   icon_url: &lt;url&gt; (optional)

    This is the URL of the icon that will be shown on the button in the rich editor. Icons should be 16x16 in size, and can be any standard web image format (png, gif, ico, etc.). It is recommended that this URL be over SSL (https).
    This is required if an icon_url is not set on the main tool configuration.
  
-   text: &lt;text&gt; (optional)

    This is the default text that will be shown if a user hovers over the editor button. This can be overridden by language-specific settings if desired by using the labels setting. This text will also be shown next to the icon if there are too many buttons and the tool is available in the "more tools" dropdown.
    This is required if a text value is not set on the main tool configuration.
  
-   labels: &lt;set of locale-label pairs&gt; (optional)

    This can be used to specify different label names for different locales. For example, if an institution supports both English and Spanish interfaces, the text in the link should change depending on the language being displayed. This option lets you support multiple languages for a single tool.
  
-   selection_width: &lt;number&gt; (required)

    This value is the explicit width of the dialog that is loaded when a user clicks the icon in the rich editor.
  
-   selection_height: &lt;number&gt; (required)

    This value is the explicit height of the dialog that is loaded when a user clicks the icon in the rich editor.

-   enabled: &lt;boolean&gt; (required)

    Whether to enable this selection feature.
