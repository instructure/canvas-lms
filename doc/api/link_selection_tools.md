External Tool Link Selector
============================

<a name="top"></a>
<div class="warning-message">The methods outlined here use resource selection, which is deprecated.
<p></p>
See the <a href="content_item.html">Content Item</a> documentation to design a tool that
can add content to the RCE in a way that conforms with the most up to date
<a href="http://www.imsglobal.org/lti/">IMS LTI standard</a>. </div>

An extension to standard LTI, external tools can be configured 
to allow selecting custom links to be 
added to modules or used for external tool assignments. When a tool is 
configured, if the user goes to add a link to a module or select a link 
for an external tool assignment, they'll see the tool with a special 
"find" icon on it. Clicking this tool will pop up a dialog and load 
the external tool inline. The tool should direct users to select or 
build a resource. The tool will then redirect the user to the LTI 
success URL with some additional parameters. Canvas will use these 
parameters to create custom URL that will be used as the link.

URLs returned in this manner will not circumvent the standard LTI 
URL/domain checking procedure, which is important to remember when 
returning URLs to add to the course. In general, it is best to make 
the these type of tools as domain-matching tool and only return URLs
whose domain matches the tool's specified domain.

When tools are loaded as link selectors, Canvas sends an additional 
parameter to notify the tool of the directive, `ext_content_return_types=select_link`.
When a tool receives this directive, it means Canvas is expecting the 
tool to redirect the user to the LTI success URL with some specific 
additional parameters. These additional parameters tell Canvas what 
URL to select, as listed below. Remember to URL encode parameter 
values such as url.

## Possible Redirect Parameters
### to embed an lti link:
<table class="tool">
  <tr>
    <td>return_type=lti_launch_url</td>
    <td></td>
    <td>(required)</td>
  </tr><tr>
    <td>url=&lt;url&gt;</td>
    <td>this is URL that will be used to load the external tool</td>
    <td>(required)</td>
      </tr><tr>
        <td>text=&lt;text&gt;</td>
        <td>this is the suggested text for the inserted link. Highlighted content will be overwritten by this value.</td>
        <td>(required)</td>
      </tr>
  </tr><tr>
    <td>title=&lt;text&gt;</td>
    <td>this is used as the 'title' attribute of the inserted external tool link</td>
    <td>(optional)</td>
</table>

#### examples:
If the `launch_presentation_return_url` were
<code>http://www.example.com/done</code>, possible return URLs could include:

- http://www.example.com/done?return_type=lti_launch_url&url=https%3A%2F%2Fothersite.com%2Flti_link&text=Link+Text
- http://www.example.com/done?return_type=lti_launch_url&url=https%3A%2F%2Fothersite.com%2Flti_link&title=link_title&text=Link+Text

## Settings
All of these settings are configurable for the "resource_selection" placement in the tool configuration

-   url: &lt;url&gt; (optional)
    
    This is the URL that will be POSTed to when users click the button in any rich editor. It can be the same as the tool's URL, or something different. Domain and URL matching are not enforced for editor button links. In order to prevent security warnings for users, it is recommended that this URL be over SSL (https).
    This is required if a url is not set on the main tool configuration.

-   icon_url: &lt;url&gt; (optional)

    This is the URL of the icon to be shown.

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