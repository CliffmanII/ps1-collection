$filepath = read-host "Enter file path"
get-filehash $filepath -algorithm sha1 | format-list