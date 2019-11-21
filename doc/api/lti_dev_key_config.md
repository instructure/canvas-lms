Configuring LTI Advantage Tools
=======================================
<a name="top"></a>
<div class="warning-message">For versions of LTI previous to LTI 1.3, please 
    refer to the <a href="file.tools_xml.html">older documentation</a></div>

For a successful launch to occur, LTI Advantage Tools require configuration
on both Canvas and inside the tool:

- [Overview of an LTI Launch](#launch-overview)
 - [Step 1: Login Initiation](#step-1)
 - [Step 2: Authentication Response](#step-2)
 - [Step 3: LTI Launch](#step-3)
 - [Step 4: Resource Display](#step-4)
- [Configuring Canvas Settings in the Tool](#config-in-tool)
- [Configuring the Tool in Canvas](#config-in-canvas)

But first, the importance of each configuration setting can only be understood 
with a basic understanding of how an LTI launch occurs.

<a name="launch-overview"></a>
Overview of an LTI Launch
=======================================
The <a href="http://www.imsglobal.org/spec/security/v1p0/" target="_blank">IMS Security Framework</a> uses an 
<a href="http://www.imsglobal.org/spec/security/v1p0/#openid_connect_launch_flow" target="_blank">Open ID Connect (OIDC)</a> third-party flow. You'll want to read these specifications in detail, but the following is a Canvas-specific summary:

<a name="step-1"></a>
###Step 1: Login Initiation
 Canvas <a href="http://www.imsglobal.org/spec/security/v1p0/#step-1-third-party-initiated-login" target="_blank">initiates a login request</a> to the `oidc_initiation_url` that is <a href="#config-in-canvas">configured on the LTI developer key</a>. This requests contains an issuer identifier (`iss`) to recognize Canvas is launching the tool. As the issuer, Instructure-hosted Canvas intances all use the following, regardless of the specific account domain(s) that the tool was launched from:

 - https://canvas.instructure.com (Production environment launches)
 - https://canvas.beta.instructure.com (Beta environment launches)
 - https://canvas.beta.instructure.com (Test environment launches)

 The request also includes a `login_hint` that is passed in the next step. Last, the request include the `target_link_uri` that has been configured on the Developer key; this is later used by the tool as a recommended final redirect.

<a name="step-2"></a>
###Step 2: Authentication Response
 To complete authentication, tools are expected to send back an <a href="http://www.imsglobal.org/spec/security/v1p0/#step-2-authentication-request" target="_blank">authentication response</a> to an "OIDC Authorization end-point".  This can be a GET or POST. For cloud-hosted Canvas, regardless of the domain used by the client, the endpoint is always:

 - `https://canvas.instructure.com/api/lti/authorization_redirect` (if launched from a **production** environment)
 - `https://canvas.beta.instructure.com/api/lti/authorization_redirect` (if launched from a **beta** environment)
 - `https://canvas.test.instructure.com/api/lti/authorization_redirect` (if launched from a **test** environment)
  
 Among the <a href="<a href="http://www.imsglobal.org/spec/security/v1p0/#step-2-authentication-request" target="_blank">required variables</a> the request should include:

 - a `redirect_uri`, which must match at least one configured on the developer key.
 - a `client_id` that matches the developer key. This must be <a href="#config-in-tool">registered in the tool</a> before the launch occurs.
 - the same `login_hint` that Canvas sent in Step 1.
 - a `state` parameter the tool will use to validate the request in Step 4.

<a name="step-3"></a>
###Step 3: LTI Launch
 Canvas will use the `client_id` to lookup which developer key to use and then check the `redirect_uri` that was sent in the previous step and ensure that there is a exact-matching `redirect_uri` on the developer key. Canvas then sends its <a href="http://www.imsglobal.org/spec/security/v1p0/#step-3-authentication-response" target="_blank">authentication response</a> to the `redirect_uri` that the tool provided in Step 2. The request will include an `id_token` which is a signed JWT containing the LTI payload (user identifiers, course contextual data, custom data, etc.). Tools must <a href="http://www.imsglobal.org/spec/security/v1p0/#authentication-response-validation" target="_blank">validate the request is actually coming from Canvas</a> using <a href="#config-in-tool" target="_blank">Canvas' public JWKs</a>.

<a name="step-4"></a>
###Step 4: Resource Display
 The tool then validates the `state` parameter matches the one sent in Step 2 and redirects the User Agent to the `target_link_uri` that was sent in Step 1 (or some other location of its choice) to <a href="http://www.imsglobal.org/spec/security/v1p0/#step-4-resource-is-displayed" target="_blank">display the final resource</a>. This redirect occurs in an iframe unless the tool is configured otherwise.

<a name="config-in-tool"></a>
Configuring Canvas in the Tool
=======================================
Tools will need to be aware of some Canvas-specific settings in order to accept a launch from Canvas and use the LTI Advantage Services:

- **Canvas Public JWKs**: When the tool recieves the authentication response ([Step 3](#step-3)), tools must <a href="http://www.imsglobal.org/spec/security/v1p0/#authentication-response-validation" target="_blank">validate that the request is actually coming from Canvas</a>. Canvas' public keys are environment-specific, but not domain-specific (the same key set can be used across all client accounts):

 - Production: `https://canvas.instructure.com/api/lti/security/jwks`
 - Beta: `https://canvas.beta.instructure.com/api/lti/security/jwks`
 - Test: `https://canvas.test.instructure.com/api/lti/security/jwks`

- **Authorization Redirect URL**: The values and use of this are described in [Step 2](#step-2). Since the URL is static, you will want to configure this in your tool.

- **Client ID**: The `client_id` of the Developer Key that's been configured in Canvas. Your tool will need to use this in the authentication response to Canvas ([Step 2](#step-2)) and it is also used during the <a href="" target="_blank">Client Credentials Grant</a> to access <a href="file.oauth.html#accessing-lti-advantage-services" target="_blank">LTI Advantage Services</a>.

- **Deployment ID**: The `deployment_id` can be optionally configured in the tool. A single developer key may have many deployments, so the deployment ID can be used to identify which deployment is being launched. For more, refer to the LTI 1.3 core specification, <a href="https://www.imsglobal.org/spec/lti/v1p3/#lti_deployment_id-login-parameter" target="_blank">section 4.1.2</a>. The `deployment_id` in Canvas is exposed after a tool has been <a href="https://community.canvaslms.com/docs/DOC-16730-42141110273" target="_blank">deployed using the `client_id`</a>.

<a name="config-in-canvas"></a>
Configuring the Tool in Canvas
=======================================
With LTI Advantage, Canvas moved to using Developer Keys to store tool 
configuration information. After a developer key is 
<a href="https://community.canvaslms.com/docs/DOC-16729-42141110178" target="_blank">created and enabled</a>,
tools can be deployed to 
<a href="https://community.canvaslms.com/docs/DOC-16730-42141110273" target="_blank">accounts/sub-accounts</a> 
or <a href="https://community.canvaslms.com/docs/DOC-16843-41521110311" target="_blank">courses</a>.

Developer Keys allow tools to set the required parameters to complete the
<a href="https://www.imsglobal.org/spec/security/v1p0#openid_connect_launch_flow"
target="_blank">OpenID Connect Launch Flow</a>, leverage 
<a href="https://canvas.instructure.com/doc/api/file.oauth.html#accessing-lti-advantage-services"
 target="_blank">LTI Advantage Services</a>, and configure other important settings.

With guidance from the tool developer, developer keys settings can be manually 
entered by Account Admins. Tools providers can also supply Account Admins with
a JSON configuration or configuration URL containing the settings the tool 
provider has verfied to work. 

In the manual case, since many of the extensions listed here require
more than a few lines of configuration, there is not currently an 
interface for *every* extension to be manually configured. Instead, we encourage
tool providers to expose a set of URL endpoints that return working
configuration options for their tool services. 

If providing a URL configuration endpoint is not an option, you can also
provide your users with raw JSON that they can paste in for configuration.

## Anatomy of a JSON configuration
In this section, an example JSON configuration is shown followed by a table describing the
relevance of each field.

**NOTE**: Certain placement-specific settings may not be described here.
Some examples of JSON configuration snippets and placement-specific settings are
also found in the placements sub-menu in the left-navigation of this documentation. 

```
{  
   "title":"The Best Tool",
   "description":"1.3 Test Tool used for documentation purposes.",
   "privacy_level":"public",
   "oidc_initiation_url":"https://your.oidc_initiation_url",
   "target_link_uri":"https://your.target_link_uri",
   "scopes":[
       "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem",
       "https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly"
    ],
   "extensions":[  
      {  
         "domain":"thebesttool.com",
         "tool_id":"the-best-tool",
         "platform":"canvas.instructure.com",
         "settings":{  
            "text":"Launch The Best Tool",
            "icon_url":"https://some.icon.url/tool-level.png",
            "selection_height": 800,
            "selection_width": 800,
            "placements":[  
               {  
                  "text":"User Navigation Placement",
                  "enabled":true,
                  "icon_url":"https://some.icon.url/my_dashboard.png",
                  "placement":"user_navigation",
                  "message_type":"LtiResourceLinkRequest",
                  "target_link_uri":"https://your.target_link_uri/my_dashboard",
                  "canvas_icon_class":"icon-lti",
                  "custom_fields":{  
                     "foo":"$Canvas.user.id"
                   }
               },
               {  
                  "text":"Editor Button Placement",
                  "enabled":true,
                  "icon_url":"https://some.icon.url/editor_tool.png",
                  "placement":"editor_button",
                  "message_type":"LtiDeepLinkingRequest",
                  "target_link_uri":"https://your.target_link_uri/content_selector",
                  "selection_height": 500,
                  "selection_width": 500
               }
            ]
         }
      }
   ],
   "public_jwk":{  
      "kty":"RSA",
      "alg":"RS256",
      "e":"AQAB",
      "kid":"8f796169-0ac4-48a3-a202-fa4f3d814fcd",
      "n":"nZD7QWmIwj-3N_RZ1qJjX6CdibU87y2l02yMay4KunambalP9g0fU9yZLwLX9WYJINcXZDUf6QeZ-SSbblET-h8Q4OvfSQ7iuu0WqcvBGy8M0qoZ7I-NiChw8dyybMJHgpiP_AyxpCQnp3bQ6829kb3fopbb4cAkOilwVRBYPhRLboXma0cwcllJHPLvMp1oGa7Ad8osmmJhXhM9qdFFASg_OCQdPnYVzp8gOFeOGwlXfSFEgt5vgeU25E-ycUOREcnP7BnMUk7wpwYqlE537LWGOV5z_1Dqcqc9LmN-z4HmNV7b23QZW4_mzKIOY4IqjmnUGgLU9ycFj5YGDCts7Q",
      "use":"sig"
   },
   "custom_fields":{  
      "bar":"$Canvas.user.sisid"
   }

}
```
<table class="request-params">
  <thead>
    <tr>
      <th class="param-name">Parameter</th>
      <th class="param-req"></th>
      <th class="param-type">Type</th>
      
      <th class="param-desc">Description</th>
    </tr>
  </thead>
  <tbody>
  
<!-- title -->  
    <tr class="request-param ">
      <td>title</td>
      <td>
        
        Required
        
      </td>
      <td>string</td>

      

      <td class="param-desc">
        
<p>The default name of the tool in the app index. This value is also displayed if no "text" field is provided within extension settings or placements.</p>

        
      </td>
    </tr>
   
<!-- description -->  
    <tr class="request-param ">
      <td>description</td>
      <td>

                Required

      </td>
      <td>string</td>

      

      <td class="param-desc">
        
<p>A description of the tool</p>

        
      </td>
    </tr>    

<!-- privacy_level -->  
    <tr class="request-param ">
      <td>privacy_level</td>
      <td>
        
        Required
        
      </td>
      <td>string</td>

      

      <td class="param-desc">
        
<p>What level of user information to send to the external tool.</p>

        
        <p class="param-values">
          <span class="allowed">Allowed values:</span> <code class="enum">anonymous</code>, <code class="enum">public</code>
        </p>
        
      </td>
    </tr>

<!-- oidc_initiation_url -->  
    <tr class="request-param ">
      <td>oidc_initiation_url</td>
      <td>
        
        Required
        
      </td>
      <td>string</td>

      

      <td class="param-desc">
        
<p>The <a href="https://www.imsglobal.org/spec/security/v1p0#step-1-third-party-initiated-login" target="_blank">login intiation url</a> that Canvas should redirect the User Agent to.

        
      </td>
    </tr> 
    
<!-- target_link_uri -->  
    <tr class="request-param ">
      <td>target_link_uri</td>
      <td>
        
        Required
        
      </td>
      <td>string</td>

      

      <td class="param-desc">
        
<p>The <a href="https://www.imsglobal.org/spec/security/v1p0#step-1-third-party-initiated-login" target="_blank">target_link_uri</a> that Canvas should pass in the to the login initiation endpoint. This allows tools to determine which redirect_uri to pass Canvas in the authorization redirect request and should be <a href="https://www.imsglobal.org/spec/lti/v1p3/impl#verify-the-target_link_uri" target="_blank">verfied during the final 
launch</a>. This can be set at the tool-level, or within the "placements" JSON 
object for placement-specific target_link_uri's</p>

        
      </td>
    </tr>

<!-- scopes -->      
    <tr class="request-param ">
      <td>scopes</td>
      <td>
        
      </td>
      <td>string array</td>

      

      <td class="param-desc">
        
<p>The comma separated list of scopes to be allowed when using the 
    <a href="file.oauth.html#accessing-lti-advantage-services">client_credentials
     grant to access LTI services</a>.

     <p class="param-values">
          <span class="allowed">Allowed values:</span> 
          <code class="enum">"https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"</code>,
          <code class="enum">"https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly"</code>,
          <code class="enum">"https://purl.imsglobal.org/spec/lti-ags/scope/score"</code>,
          <code class="enum">"https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly"</code>,
          <code class="enum">"https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly"</code>,
          <code class="enum">"https://canvas.instructure.com/lti/public_jwk/scope/update"</code>

     </p>
</p>

        
      </td>
    </tr>

<!-- extensions -->      
    <tr class="request-param ">
      <td>extensions</td>
      <td>
        
      </td>
      <td>JSON object</td>

      

      <td class="param-desc">
        
<p>The set of Canvas extensions, including placements, that the tool should use
</p>

        
      </td>
    </tr>

<!-- domain -->      
    <tr class="request-param ">
      <td>domain</td>
      <td>
        
      </td>
      <td>string</td>

      

      <td class="param-desc">
        
<p>The domain Canvas should use to match clicked LTI links against. This is recommended if <a href="file.content_item.html">deep linking</a> is used</p>.

        
      </td>
    </tr>

<!-- tool_id -->      
    <tr class="request-param ">
      <td>tool_id</td>
      <td>
        
      </td>
      <td>string</td>

      

      <td class="param-desc">
        
<p>Allows tools to set a unique identifier for the tool.</p>.

        
      </td>
    </tr>

<!-- platform -->      
    <tr class="request-param ">
      <td>platform</td>
      <td>
        
      </td>
      <td>string</td>

      

      <td class="param-desc">
        
<p>The LMS platform that the extensions belong to. This should always be set to "canvas.instructure.com" for cloud-hosted Canvas</p>

        
      </td>
    </tr>

<!-- settings -->      
    <tr class="request-param ">
      <td>settings</td>
      <td>
        
      </td>
      <td>JSON object</td>

      

      <td class="param-desc">
        
<p>The set of platform-specific settings to be used.</p>
        
      </td>
    </tr>

<!-- icon_url -->          
    <tr class="request-param ">
      <td>icon_url</td>
      <td>
        
      </td>
      <td>string</td>

      

      <td class="param-desc">
        
<p>The url of the icon to show for this tool. Can be set within the "settings" object for tool-level icons, or in the "placement" object for placement-specifc icons. NOTE: Not all placements display an icon.</p>

<!-- selection_height -->          
    <tr class="request-param ">
      <td>selection_height</td>
      <td>
        
      </td>
      <td>string</td>

      

      <td class="param-desc">
        
<p>The display height of the iframe. This may be ignored or overidden for some LTI placements due to other UI requirements set by Cavnas. Tools are advised to experiment with this setting to see what makes the most sense for their application.</p>

<!-- selection_width -->          
    <tr class="request-param ">
      <td>selection_width</td>
      <td>
        
      </td>
      <td>string</td>

      

      <td class="param-desc">
        
<p>The display width of the iframe. This may be ignored or overidden for some LTI placements due to other UI requirements set by Cavnas. Tools are advised to experiment with this setting to see what makes the most sense for their application.</p>

<!-- text -->          
      </td>
    </tr>
    
    <tr class="request-param ">
      <td>text</td>
      <td>
        
      </td>
      <td>string</td>

      

      <td class="param-desc">
        
<p>The default text to show for this tool. Can be set within "settings" for the tool-level display text, or within "placements" object for placement-specific display text.</p>

        
      </td>
    </tr>

<!-- enabled -->              
    <tr class="request-param ">
      <td>enabled</td>
      <td>
          required, see notes
      </td>
      <td>boolean</td>

      

      <td class="param-desc">
        
<p>Required for each placement. Set within the "placements" object to to determine if the placement is enabled.</p>

        
      </td>
    </tr>

<!-- message_type -->              
    <tr class="request-param ">
      <td>message_type</td>
      <td>
        
      </td>
      <td>string</td>

      

      <td class="param-desc">
        
        <p>The IMS message type to be sent in the launch. This is set at the placement level. Not all placements support both message_types.
          <p class="param-values">
           <span class="allowed">Allowed values:</span> 
           <code class="enum">"LtiResourceLinkRequest"</code>,
           <code class="enum">"LtiDeepLinkingRequest"</code>
          </p>
        </p>

        
      </td>
    </tr>

<!-- public_jwk -->          
    <tr class="request-param ">
      <td>public_jwk</td>
      <td>
          required, see notes
      </td>
      <td>JSON object</td>

      

      <td class="param-desc">
        
<p>Required if public_jwk_url is omitted. The tools <a href="https://www.imsglobal.org/spec/lti/v1p3/impl/#tool-s-jwk-set" target="_blank">public key</a> to be used during the client_credentials grant for <a href="file.oauth.html#accessing-lti-advantage-services" target="_blank">accessing LTI Advantage services</a>.</p>

        
      </td>
    </tr>

<!-- public_jwk_url -->          
    <tr class="request-param ">
      <td>public_jwk_url</td>
      <td>
          required, see notes
      </td>
      <td>string</td>

      

      <td class="param-desc">
        
<p>Required if public_jwk is omitted. The tools <a href="https://www.imsglobal.org/spec/lti/v1p3/impl/#tool-s-jwk-set" target="_blank">public key uri</a> to be used during the client_credentials grant for <a href="file.oauth.html#accessing-lti-advantage-services" target="_blank">accessing LTI Advantage services</a>.</p>

        
      </td>
    </tr>

<!-- custom_fields -->          
    <tr class="request-param ">
      <td>custom_fields</td>
      <td>
          
      </td>
      <td>JSON object</td>

      

      <td class="param-desc">
        
<p>Custom fields that will be sent to the tool consumer; can be set at the tool-level or within the "placement" JSON object for placement-specific custom fields.</p>

        
      </td>
    </tr>
    
  </tbody>
</table>

