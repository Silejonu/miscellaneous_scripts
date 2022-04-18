#!/usr/bin/bash
find . \( -iname '._*' -o -iname '.fseventsd' -o -iname '.Spotlight-V100' -o -iname '.TemporaryItems' -o -iname '.Trash*' -o -iname '.DS_Store' -o -iname 'Thumbs.db' -o -iname 'System Volume Information' \) -exec rm -rf {} \;
