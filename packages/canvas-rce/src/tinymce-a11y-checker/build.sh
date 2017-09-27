#!/bin/bash
docker build -t tinymce-a11y-checker .

docker run tinymce-a11y-checker npm test
unit_status=$?
((unit_status)) && echo "[!] Failed unit tests."

docker run tinymce-a11y-checker npm run fmt-check
fmt_status=$?
((fmt_status)) && echo "[!] Failed format check. Be sure to run: npm run fmt"

((unit_status)) && exit $unit_status
((fmt_status)) && exit $fmt_status
exit 0