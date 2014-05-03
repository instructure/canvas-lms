Importing Extended Tool Configurations
=======================================

Standard LTI tool configurations can be manually entered by users in
the Canvas UI, or set up via the 
<a href="external_tools.html">external tools API</a>. 
In the manual case, since many of the extensions listed here require
more than a few lines of configuration, there is not currently an 
interface for extensions to be manually configured. Instead, we encourage
tool providers to expose a set of URL endpoints that return standard
configuration options for their tool services. Users are still required
to enter their consumer key and shared secret manually, but the rest 
of the configuration should be standard enough that it can be reused for
all users.

If providing a URL configuration endpoint is not an option, you can also
provide your users with raw XML that they can paste in for configuration.

The configuration format is the same format used to import external tools
using Common Cartridge. Examples of valid XML configuration snippets are
found below.

## Standard External Tool Examples

### Minimal configuration, with URL matching
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
        <blti:title>Protractor Tool</blti:title>
        <blti:description>This tool provides an online, interactive protractor for students to use</blti:description>
        <blti:launch_url>https://example.com/tool_redirect</blti:launch_url>
        <blti:extensions platform="canvas.instructure.com">
          <lticm:property name="privacy_level">public</lticm:property>
        </blti:extensions>
    </cartridge_basiclti_link>

### Domain matching, "name only" privacy level
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
        <blti:title>Protractor Tool</blti:title>
        <blti:description>This tool provides an online, interactive protractor for students to use</blti:description>
        <blti:extensions platform="canvas.instructure.com">
          <lticm:property name="privacy_level">name_only</lticm:property>
          <lticm:property name="domain">example.com</lticm:property>
        </blti:extensions>
    </cartridge_basiclti_link>

## Course Navigation External Tool Examples

### Minimal configuration

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
        <blti:launch_url>https://example.com/attendance</blti:launch_url>
        <blti:title>Attendance</blti:title>
        <blti:description>Provides an interactive seating chart and attendance tool</blti:description>
        <blti:extensions platform="canvas.instructure.com">
          <lticm:property name="privacy_level">public</lticm:property>
          <lticm:options name="course_navigation">
            <lticm:property name="enabled">true</lticm:property>
          </lticm:options>
        </blti:extensions>
    </cartridge_basiclti_link>

### Minimal configuration with specific launch url for extension

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
        <blti:launch_url>https://example.com/</blti:launch_url>
        <blti:title>Attendance</blti:title>
        <blti:description>Provides an interactive seating chart and attendance tool</blti:description>
        <blti:extensions platform="canvas.instructure.com">
          <lticm:property name="privacy_level">public</lticm:property>
          <lticm:options name="course_navigation">
            <lticm:property name="url">https://example.com/attendance</lticm:property>
            <lticm:property name="enabled">true</lticm:property>
          </lticm:options>
        </blti:extensions>
    </cartridge_basiclti_link>

### Configuration with specific custom variables for extension

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
        <blti:launch_url>https://example.com/launch</blti:launch_url>
        <blti:title>Mind blowing awesomeness</blti:title>
        <blti:description>Provides something so awesome you'll just have to launch it to believe it</blti:description>
        <blti:extensions platform="canvas.instructure.com">
          <lticm:property name="privacy_level">public</lticm:property>
          <lticm:options name="course_navigation">
            <lticm:property name="enabled">true</lticm:property>
            <lticm:options name="custom_fields">
              <lticm:property name="key1">value1</lticm:property>
              <lticm:property name="key2">value2</lticm:property>
            </lticm:options>
          </lticm:options>
        </blti:extensions>
    </cartridge_basiclti_link>

### Teacher/Admin-only navigation

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
        <blti:launch_url>https://example.com/attendance</blti:launch_url>
        <blti:title>Attendance</blti:title>
        <blti:description>Provides an interactive seating chart and attendance tool</blti:description>
        <blti:extensions platform="canvas.instructure.com">
          <lticm:property name="privacy_level">public</lticm:property>
          <lticm:property name="domain">example.com</lticm:property>
          <lticm:options name="course_navigation">
            <lticm:property name="visibility">admins</lticm:property>
            <lticm:property name="enabled">true</lticm:property>
          </lticm:options>
        </blti:extensions>
    </cartridge_basiclti_link>

### Disabled by default

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
        <blti:launch_url>https://example.com/attendance</blti:launch_url>
        <blti:title>Attendance</blti:title>
        <blti:description>Provides an interactive seating chart and attendance tool</blti:description>
        <blti:extensions platform="canvas.instructure.com">
          <lticm:property name="privacy_level">public</lticm:property>
          <lticm:property name="domain">example.com</lticm:property>
          <lticm:options name="course_navigation">
            <lticm:property name="default">disabled</lticm:property>
            <lticm:property name="enabled">true</lticm:property>
          </lticm:options>
        </blti:extensions>
    </cartridge_basiclti_link>

### Multiple language support

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
        <blti:title>Attendance</blti:title>
        <blti:description>Provides an interactive seating chart and attendance tool</blti:description>
        <blti:extensions platform="canvas.instructure.com">
          <lticm:property name="privacy_level">public</lticm:property>
          <lticm:property name="domain">example.com</lticm:property>
          <lticm:options name="course_navigation">
            <lticm:property name="url">https://example.com/attendance</lticm:property>
            <lticm:property name="text">Attendance</lticm:property>
            <lticm:property name="enabled">true</lticm:property>
            <lticm:options name="labels">
              <lticm:property name="en">Attendance</lticm:property>
              <lticm:property name="es">Asistencia</lticm:property>
            </lticm:options>
          </lticm:options>
        </blti:extensions>
    </cartridge_basiclti_link>

## Account Navigation External Tool Examples

### Minimal configuration

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
        <blti:launch_url>https://example.com/reports</blti:launch_url>
        <blti:title>Custom Reports</blti:title>
        <blti:description>Department reports pulled from other campus systems</blti:description>
        <blti:extensions platform="canvas.instructure.com">
          <lticm:property name="privacy_level">public</lticm:property>
          <lticm:property name="domain">example.com</lticm:property>
          <lticm:property name="text">Other Reports</lticm:property>
          <lticm:options name="account_navigation">
            <lticm:property name="enabled">true</lticm:property>
          </lticm:options>
        </blti:extensions>
    </cartridge_basiclti_link>

## User Navigation External Tool Examples

### Minimal configuration

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
        <blti:launch_url>https://example.com/profile</blti:launch_url>
        <blti:title>Campus Profile</blti:title>
        <blti:description>Access to campus profile from within Canvas</blti:description>
        <blti:extensions platform="canvas.instructure.com">
          <lticm:property name="privacy_level">public</lticm:property>
          <lticm:property name="domain">example.com</lticm:property>
          <lticm:options name="user_navigation">
            <lticm:property name="enabled">true</lticm:property>
          </lticm:options>
        </blti:extensions>
    </cartridge_basiclti_link>

## Rich Editor External Tool Examples

### Minimal configuration

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
        <blti:launch_url>https://example.com/image_selector</blti:launch_url>
        <blti:title>Image Selector</blti:title>
        <blti:description>This connects to the campus image library and allows inserting images into content directly from this library</blti:description>
        <blti:extensions platform="canvas.instructure.com">
          <lticm:property name="privacy_level">public</lticm:property>
          <lticm:property name="domain">example.com</lticm:property>
          <lticm:property name="text">Image Library</lticm:property>
          <lticm:options name="editor_button">
            <lticm:property name="enabled">true</lticm:property>
            <lticm:property name="icon_url">https://example.com/image_selector.png</lticm:property>
            <lticm:property name="selection_width">500</lticm:property>
            <lticm:property name="selection_height">300</lticm:property>
          </lticm:options>
        </blti:extensions>
    </cartridge_basiclti_link>

### Multiple language support

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
        <blti:launch_url>https://example.com/image_selector</blti:launch_url>
        <blti:title>Image Selector</blti:title>
        <blti:description>This connects to the campus image library and allows inserting images into content directly from this library</blti:description>
        <blti:extensions platform="canvas.instructure.com">
          <lticm:property name="privacy_level">public</lticm:property>
          <lticm:property name="domain">example.com</lticm:property>
          <lticm:property name="icon_url">https://example.com/image_selector.png</lticm:property>
          <lticm:options name="editor_button">
            <lticm:property name="enabled">true</lticm:property>
            <lticm:property name="text">Image Library</lticm:property>
            <lticm:property name="selection_width">500</lticm:property>
            <lticm:property name="selection_height">300</lticm:property>
            <lticm:options name="labels">
              <lticm:property name="en">Image Library</lticm:property>
              <lticm:property name="es">Biblioteca de Imágenes</lticm:property>
            </lticm:options>
          </lticm:options>
        </blti:extensions>
    </cartridge_basiclti_link>

## Link Selection External Tool Examples

Remember, best practice is for link selection tools to have domain-level
matching, and to only return URLs matching that domain.

### Minimal configuration

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
        <blti:title>eBook Selector</blti:title>
        <blti:description>Select chapters of available eBooks to insert into course modules</blti:description>
        <blti:extensions platform="canvas.instructure.com">
          <lticm:property name="privacy_level">public</lticm:property>
          <lticm:property name="domain">example.com</lticm:property>
          <lticm:options name="resource_selection">
            <lticm:property name="enabled">true</lticm:property>
            <lticm:property name="url">https://example.com/chapter_selector</lticm:property>
            <lticm:property name="text">eBook Chapter Selector</lticm:property>
            <lticm:property name="selection_width">500</lticm:property>
            <lticm:property name="selection_height">300</lticm:property>
          </lticm:options>
        </blti:extensions>
    </cartridge_basiclti_link>

### Multiple language support

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
        <blti:title>eBook Selector</blti:title>
        <blti:description>Select chapters of available eBooks to insert into course modules</blti:description>
        <blti:extensions platform="canvas.instructure.com">
          <lticm:property name="privacy_level">public</lticm:property>
          <lticm:property name="domain">example.com</lticm:property>
          <lticm:options name="resource_selection">
            <lticm:property name="enabled">true</lticm:property>
            <lticm:property name="url">https://example.com/chapter_selector</lticm:property>
            <lticm:property name="text">eBook Chapter Selector</lticm:property>
            <lticm:property name="selection_width">500</lticm:property>
            <lticm:property name="selection_height">300</lticm:property>
            <lticm:options name="labels">
              <lticm:property name="en">eBook Chapter Selector</lticm:property>
              <lticm:property name="es">eBook Capítulo Selector</lticm:property>
            </lticm:options>
          </lticm:options>
        </blti:extensions>
    </cartridge_basiclti_link>

## Test Environment Setting Examples

External tools can support different LTI environments for different canvas environments.

* __domain__: All url domains in this tool's configuration will be replaced with this domain
* __launch_url__: the blti:launch\_url property that should be used for all canvas test environments.
This property takes precedent over domain changes if both properties are set.

Additionally, the domain and launch\_urls can be set for for each canvas environment
by specifying the environment as part of the property name (ie, test\_launch\_url,
beta\_domain, etc).  When used in this manner, specific environment properties take
precedent over the default values.

### Test Environment Example

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
        <blti:title>Attendance</blti:title>
        <blti:description>Provides an interactive seating chart and attendance tool</blti:description>
        <blti:extensions platform="canvas.instructure.com">
          <lticm:property name="privacy_level">public</lticm:property>
          <lticm:property name="domain">example.com</lticm:property>
          <lticm:options name="course_navigation">
            <lticm:property name="enabled">true</lticm:property>
            <lticm:property name="url">https://example.com/attendance</lticm:property>
            <lticm:property name="text">Attendance</lticm:property>
            <lticm:property name="visibility">admins</lticm:property>
            <lticm:property name="default">disabled</lticm:property>
          </lticm:options>
          <lticm:options name="account_navigation">
            <lticm:property name="enabled">true</lticm:property>
            <lticm:property name="url">https://example.com/attendance_admin</lticm:property>
            <lticm:property name="text">Attendance</lticm:property>
          </lticm:options>
          <lticm:options name="environments">
            <lticm:property name="launch_url">http://test.example.com/content</lticm:property>
            <lticm:property name="domain">test.example.com</lticm:property>
            <lticm:property name="test_launch_url">http://test.example.com/content</lticm:property>
            <lticm:property name="test_domain">test.example.com</lticm:property>
            <lticm:property name="beta_launch_url">http://beta.example.com/content</lticm:property>
            <lticm:property name="beta_domain">beta.example.com</lticm:property>
          </lticm:options>
    </blti:extensions>
    </cartridge_basiclti_link>

## Combined External Tool Configuration Examples

External tools can support multiple extensions in a single tool since each 
extension will have its own tool launch URL. Remember, though, that link
selection tools should have domain-level matching set, and URLs returned
by the service should be scoped to the matching domain.

### Course navigation and account navigation

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
        <blti:title>Attendance</blti:title>
        <blti:description>Provides an interactive seating chart and attendance tool</blti:description>
        <blti:extensions platform="canvas.instructure.com">
          <lticm:property name="privacy_level">public</lticm:property>
          <lticm:property name="domain">example.com</lticm:property>
          <lticm:options name="course_navigation">
            <lticm:property name="enabled">true</lticm:property>
            <lticm:property name="url">https://example.com/attendance</lticm:property>
            <lticm:property name="text">Attendance</lticm:property>
            <lticm:property name="visibility">admins</lticm:property>
            <lticm:property name="default">disabled</lticm:property>
          </lticm:options>
          <lticm:options name="account_navigation">
            <lticm:property name="enabled">true</lticm:property>
            <lticm:property name="url">https://example.com/attendance_admin</lticm:property>
            <lticm:property name="text">Attendance</lticm:property>
          </lticm:options>
        </blti:extensions>
    </cartridge_basiclti_link>

### Course navigation and account navigation with shared url and text

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
        <blti:launch_url>https://example.com/attendance</blti:launch_url>
        <blti:title>Attendance</blti:title>
        <blti:description>Provides an interactive seating chart and attendance tool</blti:description>
        <blti:extensions platform="canvas.instructure.com">
          <lticm:property name="privacy_level">public</lticm:property>
          <lticm:property name="text">Attendance</lticm:property>
          <lticm:options name="course_navigation">
            <lticm:property name="enabled">true</lticm:property>
            <lticm:property name="visibility">admins</lticm:property>
            <lticm:property name="default">disabled</lticm:property>
          </lticm:options>
          <lticm:options name="account_navigation">
            <lticm:property name="enabled">true</lticm:property>
          </lticm:options>
        </blti:extensions>
    </cartridge_basiclti_link>

### Rich editor and link selection with multiple language support

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
        <blti:launch_url>https://example.com/wiki</blti:launch_url>
        <blti:title>Global Wiki</blti:title>
        <blti:description>Institution-wide wiki tool with all the trimmings</blti:description>
        <blti:extensions platform="canvas.instructure.com">
          <lticm:property name="privacy_level">public</lticm:property>
          <lticm:property name="domain">example.com</lticm:property>
          <lticm:property name="icon_url">https://example.com/wiki.png</lticm:property>
          <lticm:property name="text">Build/Link to Wiki Page</lticm:property>
          <lticm:options name="labels">
              <lticm:property name="en-US">Build/Link to Wiki Page</lticm:property>
              <lticm:property name="en-GB">Build/Link to Wiki Page</lticm:property>
            </lticm:options>
          <lticm:options name="editor_button">
            <lticm:property name="enabled">true</lticm:property>
            <lticm:property name="selection_width">500</lticm:property>
            <lticm:property name="selection_height">300</lticm:property>
          </lticm:options>
          <lticm:options name="resource_selection">
            <lticm:property name="enabled">true</lticm:property>
            <lticm:property name="selection_width">500</lticm:property>
            <lticm:property name="selection_height">300</lticm:property>
          </lticm:options>
        </blti:extensions>
    </cartridge_basiclti_link>
