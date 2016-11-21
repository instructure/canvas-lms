Rich Content Editor Button Tools
=================================

<a name="top"></a>
<div class="warning-message">The methods outlined here use resource selection, which is deprecated.
<p></p>
See the <a href="content_item.html">Content Item</a> documentation to design a tool that
can add content to the RCE in a way that conforms with the most up to date
<a href="http://www.imsglobal.org/lti/">IMS LTI standard</a>. </div>

An extension to standard LTI, external tools can be 
configured to appear as buttons in the rich content 
editor. When a tool is configured, users will see it appear in the rich 
content editor for any pages inside the appropriate course/account. If a 
user clicks the button, a popup will appear where the external tool will 
be loaded. The tool should direct users to select or build some piece of 
content, then submit that content to the tool. The tool will then redirect 
the user to the LTI success URL with some additional parameters. Canvas 
will take this information and use it to embed rich content into the 
appropriate editor window.

If there are many editor buttons configured for a course, Canvas will show 
the first 3 as icons, and add a "more tools" icon that will show the rest 
of the configured tools in a dropdown.

When tools are loaded as rich editor buttons, Canvas sends an additional 
parameter to notify the tool of the directive, 
`ext_content_return_types=embed_content`. When a tool receives this directive,
it means Canvas is expecting the tool to redirect the user to the LTI 
success URL with some additional parameters. These additional parameters 
tell Canvas what type of content to embed, as listed below. Remember to 
URL encode parameter values such as url.

Remember, to prevent unexpected security warnings for users, it's recommended
that all URLs you return be over SSL (https instead of http).

## Possible Redirect Parameters
### to embed an image:
<table class="tool">
  <tr>
    <td>return_type=image_url</td>
    <td></td>
    <td>(required)</td>
  </tr><tr>
    <td>url=&lt;url&gt;</td>
    <td>this is used as the 'src' attribute of the embedded image tag</td>
    <td>(required)</td>
  </tr><tr>
    <td>alt=&lt;text&gt;</td>
    <td>this is used as the 'alt' attribute of the embedded image tag</td>
    <td>(required, can be empty string)</td>
  </tr><tr>
    <td>width=&lt;number&gt;</td>
    <td>this is used as the 'width' style of the embedded image tag</td>
    <td>(required)</td>
  </tr><tr>
    <td>height=&lt;number&gt;</td>
    <td>this is used as the 'height' style of the embedded image tag</td>
    <td>(required)</td>
  </tr>
</table>

#### examples:
If the `launch_presentation_return_ur`l</code> were
<code>http://www.example.com/done</code>, possible return URLs could include:

- http://www.example.com/done?return_type=image_url&url=https%3A%2F%2Fothersite.com%2Fimage.gif&alt=good+picture&width=30&height=50
- http://www.example.com/done?return_type=image_url&url=https%3A%2F%2Fothersite.com%2Fimage2.gif&alt=&width=300&height=500

### to embed an iframe:
<table class="tool">
  <tr>
    <td>return_type=iframe</td>
    <td></td>
    <td>(required)</td>
  </tr><tr>
    <td>url=&lt;url&gt;</td>
    <td>this is used as the 'src' attribute of the embedded iframe</td>
    <td>(required)</td>
  </tr><tr>
    <td>title=&lt;text&gt;</td>
    <td>this is used as the 'title' attribute of the embedded iframe</td>
    <td>(optional)</td>
  </tr><tr>
    <td>width=&lt;number&gt;</td>
    <td>this is used as the 'width' style of the embedded iframe</td>
    <td>(required)</td>
  </tr><tr>
    <td>height=&lt;number&gt;</td>
    <td>this is used as the 'height' style of the embedded iframe</td>
    <td>(required)</td>
  </tr>
</table>

#### examples:
If the `launch_presentation_return_url`</code> were
<code>http://www.example.com/done</code>, possible return URLs could include:

- http://www.example.com/done?return_type=iframe&url=https%3A%2F%2Fothersite.com%2Fiframe&width=30&height=50
- http://www.example.com/done?return_type=iframe&url=https%3A%2F%2Fothersite.com%2Fiframe2&text=good+iframe&width=300&height=500

### to embed a link:
<table class="tool">
  <tr>
    <td>return_type=url</td>
    <td></td>
    <td>(required)</td>
  </tr><tr>
    <td>url=&lt;url&gt;</td>
    <td>this is used as the 'href' attribute of the inserted link</td>
    <td>(required)</td>
  </tr><tr>
    <td>title=&lt;text&gt;</td>
    <td>this is used as the 'title' attribute of the inserted link</td>
    <td>(optional)</td>
  </tr><tr>
    <td>text=&lt;text&gt;</td>
    <td>this is the suggested text for the inserted link. If the user has already selected some content before opening this dialog, the link will wrap that content and this value will be ignored</td>
    <td>(optional, defaults to 'link')</td>
  </tr><tr>
    <td>target=&lt;text&gt;</td>
    <td>this is used as the 'target' attribute of the inserted link</td>
    <td>(optional, only '_blank' is allowed as a value)</td>
  </tr>
</table>

#### examples:
If the `launch_presentation_return_url` were
<code>http://www.example.com/done</code>, possible return URLs could include:

- http://www.example.com/done?return_type=url&url=https%3A%2F%2Fothersite.com%2Flink
- http://www.example.com/done?return_type=url&url=https%3A%2F%2Fothersite.com%2Flink&text=other+site+link
- http://www.example.com/done?return_type=url&url=https%3A%2F%2Fothersite.com%2Flink&title=link&target=_blank

### to embed an external tool link:
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
    <td>title=&lt;text&gt;</td>
    <td>this is used as the 'title' attribute of the inserted external tool link</td>
    <td>(optional)</td>
  </tr><tr>
    <td>text=&lt;text&gt;</td>
    <td>this is the suggested text for the inserted link. If the user has already selected some content before opening this dialog, the link will wrap that content and this value will be ignored.</td>
    <td>(optional, defaults to 'link')</td>
  </tr>
</table>

#### examples:
If the `launch_presentation_return_url` were
<code>http://www.example.com/done</code>, possible return URLs could include:

- http://www.example.com/done?return_type=lti_launch_url&url=https%3A%2F%2Fothersite.com%2Flti_link
- http://www.example.com/done?return_type=lti_launch_url&url=https%3A%2F%2Fothersite.com%2Flti_link&text=other+site+link
- http://www.example.com/done?return_type=lti_launch_url&url=https%3A%2F%2Fothersite.com%2Flti_link&title=link

Remember that these links would only work if the current tool or some other tool was set to
match on either the exact URL returned or the domain (in this case othersite.com)

### to embed any other rich content:
For other types of rich content (such as a video tag, a large block of text, etc.) we also support the oEmbed standard. oEmbed works by giving Canvas an additional URL that can be queried to retrieve the block of content to be embedded. See http://oembed.com for more details about how oEmbed works
<table class="tool">
  <tr>
    <td>return_type=oembed</td>
    <td></td>
    <td>(required)</td>
  </tr><tr>
    <td>url=&lt;url&gt;</td>
    <td>this is the oEmbed resource URL</td>
    <td>(required)</td>
  </tr><tr>
    <td>endpoint=&lt;url&gt;</td>
    <td>this is the oEmbed API endpoint URL</td>
    <td>(required)</td>
  </tr>
</table>

#### examples:
If the `launch_presentation_return_url` were
<code>http://www.example.com/done</code>, possible return URLs could include:

- http://www.example.com/done?return_type=oembed&endpoint=https%3A%2F%2Fothersite.com%2Foembed&url=https%3A%2F%2Fothersite.com%2Fresources%2Fimage1
- http://www.example.com/done?return_type=oembed&endpoint=http%3A%2F%2Fwww.flickr.com%2Fservices%2Foembed%2F&url=http%3A%2F%2Fwww.flickr.com%2Fphotos%2Fbees%2F2341623661%2F

## Settings
All of these settings are contained under "editor_button" in the tool configuration

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
