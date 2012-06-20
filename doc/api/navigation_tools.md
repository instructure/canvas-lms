Navigation Tools
=================

<a name="course_navigation"></a>
## Course navigation links

External tools can be configured to appear as links in course-level 
navigation. If the tool is configured on an account, any course in 
that account or any of its sub-accounts will have the link added to 
the course navigation. If the tool is configured on a course, then 
the navigation will only appear in that course.


There are some additional parameters that can be set on course 
navigation tools to define default behavior. These settings allow 
the tool to be disabled by default or visible only to some types 
of users.


### Settings
All of these settings are contained under "course_navigation"

-   url: &lt;url&gt; (optional)
    
    This is the URL that will be POSTed to when users click the left tab. It can be the same as the tool's URL, or something different. Domain and URL matching are not enforced for course navigation links. In order to prevent security warnings for users, it is recommended that this URL be over SSL (https).
    This is required if a url is not set on the main tool configuration.

-   default: ['enabled', 'disabled'] (optional, 'enabled' by default)
    
    This specifies whether the link is turned on or off by default for courses. Course administrators will see the link appear in Settings just like any other link, and can explicitly order, enable and disable the link from there.

-   visibility: ['public', 'members', 'admins'] (optional, 'public' by default)
    
    This specifies what types of users will see the link in the course navigation. "public" means anyone accessing the course, "members" means only users enrolled in the course, and "admins" means only Teachers, TAs, Designers and account admins will see the link.

-   text: &lt;text&gt; (optional)
    
    This is the default text that will be shown in the left hand navigation as the text of the link. This can be overridden by language-specific settings if desired by using the labels setting.
    This is required if a text value is not set on the main tool configuration.

-   labels: &lt;set of locale-label pairs&gt; (optional)
    
    This can be used to specify different label names for different locales. For example, if an institution supports both English and Spanish interfaces, the text in the link should change depending on the language being displayed. This option lets you support multiple languages for a single tool.

-   enabled: &lt;boolean&gt; (required)

    Whether to enable this selection feature.

<a name="account_navigation"></a>
## Account navigation links
External tools can also be configured to appear as links in 
account-level navigation. If the tool is configured on an account, 
administrators in that account and any of its sub-accounts will see 
the link in their account navigation.


### Settings
All of these settings are contained under "account_navigation"

-   url: &lt;url&gt; (optional)
    
    This is the URL that will be POSTed to when users click the left tab. It can be the same as the tool's URL, or something different. Domain and URL matching are not enforced for account navigation links. In order to prevent security warnings for users, it is recommended that this URL be over SSL (https).
    This is required if a url is not set on the main tool configuration.

-   text: &lt;text&gt; (optional)

    This is the default text that will be shown in the left hand navigation as the text of the link. This can be overridden by language-specific settings if desired by using the labels setting.
    This is required if a text value is not set on the main tool configuration.

-   labels: &lt;set of locale-label pairs&gt; (optional)
    
    This can be used to specify different label names for different locales. For example, if an institution supports both English and Spanish interfaces, the text in the link should change depending on the language being displayed. This option lets you support multiple languages for a single tool.

-   enabled: &lt;boolean&gt; (required)

    Whether to enable this selection feature.

<a name="user_navigation"></a>
## User navigation links
External tools can also be configured to appear as links in 
user-level navigation (i.e. by clicking to see a user's profile). 
User navigation links will only work if they are configured at 
the root account level. If the tool is configured on a root account, 
all users logged in to that account will see the link in their 
profile navigation.


### Settings
All of these settings are contained under "user_navigation"

-   url: &lt;url&gt; (optional)
  
    This is the URL that will be POSTed to when users click the left tab. It can be the same as the tool's URL, or something different. Domain and URL matching are not enforced for user navigation links. In order to prevent security warnings for users, it is recommended that this URL be over SSL (https).
    This is required if a url is not set on the main tool configuration.

-   text: &lt;text&gt; (optional)

    This is the default text that will be shown in the left hand navigation as the text of the link. This can be overridden by language-specific settings if desired by using the labels setting.
    This is required if a text value is not set on the main tool configuration.

-   labels: &lt;set of locale-label pairs&gt; (optional)
    
    This can be used to specify different label names for different locales. For example, if an institution supports both English and Spanish interfaces, the text in the link should change depending on the language being displayed. This option lets you support multiple languages for a single tool.

-   enabled: &lt;boolean&gt; (required)

    Whether to enable this selection feature.
