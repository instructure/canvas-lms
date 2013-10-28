Object IDs and SIS IDs
======================

Throughout the API, objects are referenced by internal IDs. You can also
reference objects by SIS ID, by prepending the SIS ID with the name of
the SIS field, like `sis_course_id:`. For instance, to retrieve the
list of assignments for a course with SIS ID of `A1234`:

    /api/v1/courses/sis_course_id:A1234/assignments

The following objects support SIS IDs in the API:

 * `sis_course_id`
 * `sis_login_id`
 * `sis_term_id`
 * `sis_user_id`
 * `sis_account_id`
 * `sis_section_id`
 * `sis_group_id`

Encoding and Escaping
---------------------

SIS IDs should be encoded as UTF-8, and then escaped normally for inclusion in
a URI. For instance the SIS ID `CS/101.11é` is encoded and escaped as
`CS%2F101%2E11%C3%A9`.

Note that some web servers have difficulties with escaped characters,
particularly forward slashes. They may require special configuration to
properly pass encoded slashes to Rails.

For Apache and Passenger, the following settings should be set:

 * [`AllowEncodedSlashes`](http://httpd.apache.org/docs/2.2/mod/core.html#allowencodedslashes) `NoDecode`
 * [`PassengerAllowEncodedSlashes`](http://www.modrails.com/documentation/Users%20guide%20Apache.html#_passengerallowencodedslashes_lt_on_off_gt) `on`

Also beware that if you use [`ProxyPass`](http://httpd.apache.org/docs/2.2/mod/mod_proxy.html#proxypass),
you should enable the `nocanon` option. Similarly,
[`RewriteRule`](https://httpd.apache.org/docs/2.2/mod/mod_rewrite.html#rewriterule)
should use the [`NE`](https://httpd.apache.org/docs/2.2/rewrite/flags.html#flag_ne),
or `noescape` flag. Other modules may also need additional configuration to
prevent double-escaping of `%2f` (/) as `%252f`.

Prior versions of this API documentation described using a hex encoding to
circumvent these issues, since the proper Apache/Passenger configuration was
not known at the time. This format is deprecated, and will no longer be
described, but will continue to be handled by the server for backwards
compatibility.
