#!/bin/bash

# See: https://github.com/beyond-z/canvas-lms/pull/423/files
echo "https://stagingportal.bebraven.org/bz/courses_for_email?email=brian@bebraven.org"
echo ""
echo "Expect: course_ids = 24, 33, 32, 31, 2, 10, 23, 21, 30, 29, 1, 27, 28, 16, 15"
curl https://stagingportal.bebraven.org/bz/courses_for_email?email=brian@bebraven.org
echo ""
echo "https://stagingportal.bebraven.org/bz/courses_for_email?email=brian+testmaster1@bebraven.org"
echo ""
echo "Expect: course_id = 41"
curl https://stagingportal.bebraven.org/bz/courses_for_email?email=brian%2Btestmaster1@bebraven.org
