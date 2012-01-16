Object IDs and SIS IDs
======================

Throughout the API, objects are referenced by internal ids. You can also
reference objects by sis id, by prepending the sis id with the name of
the sis field, like "sis\_course\_id:". For instance, to retrieve the
list of assignments for a course with sis id of 'A1234':

    /api/v1/courses/sis_course_id:A1234/assignments.json

Escaping and Hex Encoding
-------------------------

SIS IDs can be URL escaped as usual, for instance the ID "CS/101.11" could
be escaped as "CS%2F101%2E11". However, various releases of web servers and
Rails environments have bugs related to escaping of characters such as
"/" and ".". So it is recommended that SIS IDs be encoded using a hex
string notation, similar to a hex digest, where UTF-8 bytes are
encoded to hex digits and displayed as Ascii, high nibble first.

For instance, the string "CS/101.11" would be encoded as
"43532f3130312e3131". To perform this encoding in Ruby:

    "CS/101.11".unpack("H*")[0]

The SIS ID is then included in the URL as usual, but prefixed with
"hex:", for instance:

    /api/v1/courses/hex:sis_course_id:43532f3130312e3131/assignments.json
