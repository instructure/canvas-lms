<!--
  DONT EDIT THIS FILE DIRECTLY
  Update:
    - doc/api/tools_variable_substitutions.head.md
    - lib/lti/variable_expander.rb

  then run `script/generate_lti_variable_substitution_markdown`
-->

LTI Variable Substitutions
==========================

Variable substitution (aka variable expansion) is where custom variables really start to
shine.  They provide a mechanism for tool providers to request that specific, contextual
information be sent across in the launch.  When the tool consumer processes the launch request,
it detects requested variable substitutions and sends the appropriate data where possible.
Adding variable substitutions is exactly the same as adding custom variables, except the values
are variables instead of constants.  This is denoted by prefixing the value with a $.  If the
tool consumer doesn't recognize, or can't substitute, the value it will just send the variable
as if it were are regular custom variable (i.e. the name of the substitution variable will be
sent rather than the value).

This allows Canvas to expose data as LTI launch parameters during the LTI launch rather than
requiring access to the Canvas API, which can be expensive for Canvas and the tool.  It allows
tool providers to be much more surgical when requesting user data, and it paves the way for us
to be more transparent to tool installers, by showing them exactly what data the LTI tool will
be given access to. Additionally, variable substitutions are generally simple to add to Canvas
relative to gaining API access.

There are currently over 80 substitutions available.  Many of the substitutions simply
give access to additional user and context information.  An LTI tool can request things
like SIS ids, names, an avatar image, and an email address.  Other variable substitutions
assist tools with accessibility (prefersHighContrast), course copy (previousCourseIds), and
masquerading users.  Additionally, when we don't provide enough information or customization
directly through LTI, tools can request everything they need to use the Canvas API for an even
richer experience.

Some substitutions may be used as 'enabled_capabilities' for LTI2 tools. These substitutions have a
'Launch Parameter' label indicating the parameter name that will be sent in the tool launch if enabled.

For more information on variable substitution, see the <a href="https://www.imsglobal.org/specs/ltiv1p1p1/implementation-guide#toc-9">IMS LTI specification</a>.

# Usage/Configuration
Variable substitutions can be configured for a tool in 3 ways:

## Via UI
Custom fields can be <a href="https://community.canvaslms.com/t5/Admin-Guide/How-do-I-configure-a-manual-entry-external-app-for-an-account/ta-p/219">configured via UI</a> by editing the tool configuration and adding the
desired variable to the Custom Fields text box.

The following would add the domain as a launch parameter called custom_arbitrary_name:

```
arbitrary_name=$Canvas.api.domain
```

## Via API
Custom fields can also be <a href="/doc/api/external_tools.html#method.external_tools.create">configured via API</a>.

This would install a course-level tool with domain as a custom field:
```
curl 'https://<domain>.instructure.com/api/v1/courses/<course_id>/external_tools' \
  -X POST \
  -H "Authorization: Bearer <token>;" \
  -F 'name=LTI Example' \
  -F 'consumer_key=some_key' \
  -F 'shared_secret=some_secret' \
  -F 'url=https://example.com/ims/lti' \
  -F 'privacy_level=name_only' \
  -F 'custom_fields[domain]=$Canvas.api.domain'
```

## Via JSON Configuration (LTI 1.3)
JSON can be used to <a href="https://community.canvaslms.com/t5/Admin-Guide/How-do-I-configure-an-LTI-key-for-an-account/ta-p/140" target="_blank">configure an LTI 1.3 Developer Key</a>.

The following JSON would create a developer key with the a placement specfic custom field and a tool-level custom field:

```
{  
   "title":"Variable Expansion Tool",
   "scopes":[  

   ],
   "extensions":[  
      {  
         "domain":"variableexpander.com",
         "tool_id":"variable-expansion-example",
         "platform":"canvas.instructure.com",
         "settings":{  
            "text":"Variation Expansion Tool Text",
            "icon_url":"https://some.icon.url",
            "placements":[  
               {  
                  "text":"User Navigation Placement",
                  "enabled":true,
                  "icon_url":"https://static.thenounproject.com/png/131630-200.png",
                  "placement":"user_navigation",
                  "message_type":"LtiResourceLinkRequest",
                  "target_link_uri":"https://lti-ri.imsglobal.org/lti/tools/281/launches",
                  "canvas_icon_class":"icon-lti",
                  "custom_fields":{  
                     "foo":"$Canvas.user.id"
                  }
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
   "description":"1.3 Test Tool",
   "custom_fields":{  
      "bar":"$Canvas.user.sisid"
   },
   "target_link_uri":"https://your.target_link_uri",
   "oidc_initiation_url":"https://your.oidc_initiation_url"
}
```

## Via XML Configuration (LTI 1.1)
Custom fields can also be <a href="/doc/api/file.tools_xml.html">configured via XML</a>.

This would create a tool in a course with custom fields, some of which are specific for a
particular placement:
```
<?xml version="1.0" encoding="UTF-8"?>
   <cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0"
       xmlns:blti = "http://www.imsglobal.org/xsd/imsbasiclti_v1p0"
       xmlns:lticm ="http://www.imsglobal.org/xsd/imslticm_v1p0"
       xmlns:lticp ="http://www.imsglobal.org/xsd/imslticp_v1p0"
       xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation = "http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd
       http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0.xsd
       http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd
       http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
     <blti:title>Wikipedia</blti:title>
     <blti:launch_url>https://www.wikipedia.org/</blti:launch_url>
     <blti:custom>
       <lticm:property name="user_sis_id">$Person.sourcedId</lticm:property>
     </blti:custom>
     <blti:extensions platform="canvas.instructure.com">
       <lticm:property name="domain">wikipedia.org</lticm:property>
       <lticm:options name="custom_fields">
           <lticm:property name="canvas_api_domain">$Canvas.api.domain</lticm:property>
           <lticm:property name="canvas_user_id">$Canvas.user.id</lticm:property>
       </lticm:options>
       <lticm:options name="course_navigation">
         <lticm:property name="url">https://en.wikipedia.org/wiki/Wikipedia:Unusual_articles#mediaviewer/File:Cow-on_pole,_with_antlers.jpeg</lticm:property>
         <lticm:property name="text">Cow With Antlers</lticm:property>
         <lticm:options name="custom_fields">
           <lticm:property name="concluded_roles">$Canvas.membership.concludedRoles</lticm:property>
         </lticm:options>
       </lticm:options>
     </blti:extensions>
   </cartridge_basiclti_link>
```
# Supported Substitutions
