LTI Variable Substitutions
==========================

Variable substitution (aka variable expansion) is where custom variables really start to
shine.  They provide a mechanism for tool providers to request that specific, contextual
information be sent across in the launch.  When the tool consumer processes the launch request,
it detects requested variable substitutions and sends the appropriate data where possible.
Adding variable substitutions is exactly the same as adding custom variables, except the values
are variables instead of constants.  This is denoted by prefixing the value with a $.  If the
tool consumer doesn't recognize, or can't substitute, the value it will just send the variable
as if it were are regular custom variable.

This is a fairly new addition to our LTI feature set, but has allowed us to expose a lot of
data to LTI tools without asking them to go back to the Canvas API, which can be expensive
for us and them.  It allows tool providers to be much more surgical when requesting user
data, and it paves the way for us to be more transparent to tool installers, by showing them
exactly what data the LTI tool will be given access to.  On top of all that, variable
substitutions are generally simple to add to Canvas.

There are currently over 45 substitutions available.  Many of the substitutions simply
give access to additional user and context information.  An LTI tool can request things
like SIS ids, names, an avatar image, and an email address.  Other variable substitutions
assist tools with accessibility (prefersHighContrast), course copy (previousCourseIds), and
masquerading users.  Additionally, when we don't provide enough information or customizability
directly through LTI, tools can request everything they need to use the Canvas API for an even
richer experience.
