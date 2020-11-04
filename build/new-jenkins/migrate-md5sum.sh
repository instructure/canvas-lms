find db/migrate/*.rb -type f -exec md5sum {} \; | sort -k 2 | md5sum | cut -d ' ' -f 1
