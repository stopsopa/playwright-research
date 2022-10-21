
S="\\"

cat <<EOF
-w "/code" $S
-v "\$(pwd)/tests:/code/tests" $S
-v "\$(pwd)/node_modules:/code/node_modules" $S
-v "\$(pwd)/playwright-async.config.js:/code/playwright-async.config.js" $S
-v "\$(pwd)/playwright.config.js:/code/playwright.config.js"
EOF

