#!/usr/bin/env bash

# Fetch new user IDs from environment variable
new_user_id_array=$(python -c 'import json, os; print(json.loads(os.environ["DOCUMENT_USER_ID"]))')

# API URL to fetch document permissions
api_url="http://localhost:8000/api/documents/${DOCUMENT_ID}/?full_perms=true"

# Authentication credentials
username=shaquib
password=123456

# Function to send email
send_email() {
    local email="$1"
    local document_name="$2"
    echo "$email"
    local html_content="<html><head><title>Document Access Notification</title></head><body><p>Hello,</p><p>A document with the name '<strong>$document_name</strong>' has been accessed. This is a notification regarding the document access.</p><p>Regards,<br/>Your Organization</p></body></html>"

    local emailData=$(cat <<EOF
{
  "to": ["$email"],
  "from": "$email",
  "subject": "Document Access Notification",
  "text": "$html_content",
  "cc": "",
  "bcc": ""
}
EOF
)
echo "$emailData"

    local resp=$(curl -X POST -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2NTFmZWYyNTRlZTYyNjBmNjVlNjMyODEiLCJkZXRhaWxzIjp7InJvbGUiOiJ1c2VyIiwiaXNFbWFpbFZlcmlmaWVkIjpmYWxzZSwibmFtZSI6ImZha2RlIG5hbWUiLCJlbWFpbCI6ImV4ZGFtcGxlZEBlZHVsYWIuaW4iLCJpZCI6IjY1MWZlZjI1NGVlNjI2MGY2NWU2MzI4MSJ9LCJpYXQiOjE2OTY1OTE2NzYsImV4cCI6MTE1MzAxNjE4ODc2LCJ0eXBlIjoiYWNjZXNzIn0.r6YzFbTo9sBlVyyFYjRpyO_RHWNxN3JhLdHIupC2YXo" -H "Content-Type: application/json" -d "$emailData" "https://devcommunication.edulab.in/api/v2/Email/sendgrid/emailWithHtml/text-html")
    if [ "$resp" = "ok" ]; then
        echo "Email sent"
    else
        echo "Email not sent"
    fi
}

# Wait for the API URL response
api_response=""
while [ -z "$api_response" ]; do
    sleep 1
    api_response=$(curl -sS --user "${username}:${password}" "$api_url")
done

# Extract original file name from API response (replace 'original_file_name' with the actual field name)
original_file_name=$(echo "$api_response" | jq -r '.original_file_name')

# Extract email addresses from new user IDs and send email to each
for user_id in ${new_user_id_array//[,]/}; do
    user_id="${user_id//[}"
    user_id="${user_id//]}"
    if [ "$user_id" != "" ]; then
        user_api_url="http://localhost:8000/api/users/${user_id}/"
        
        # Wait for the user API URL response
        user_response=""
        while [ -z "$user_response" ]; do
            sleep 1
            user_response=$(curl -sS --user "${username}:${password}" "$user_api_url")
        done
        
        user_email=$(echo "$user_response" | jq -r '.email')

        # Check if email is not empty
        if [ -n "$user_email" ]; then
            send_email "$user_email" "$original_file_name"
        fi
    fi
done

# Reset DOCUMENT_USER_ID to empty string
export DOCUMENT_USER_ID=""
