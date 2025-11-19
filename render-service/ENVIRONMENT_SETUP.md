# Setting FIREBASE_SERVICE_ACCOUNT in Render

## Step-by-Step Instructions

### 1. Get Your Firebase Service Account JSON

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click the gear icon ⚙️ → **Project Settings**
4. Go to **Service Accounts** tab
5. Click **Generate New Private Key**
6. Click **Generate Key** in the confirmation dialog
7. A JSON file will download

### 2. Copy the JSON Content

1. Open the downloaded JSON file in a text editor
2. Select **ALL** the content (Ctrl+A / Cmd+A)
3. Copy it (Ctrl+C / Cmd+C)

The JSON should look like this (don't copy this example, use YOUR file):
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "...",
  "client_id": "...",
  "auth_uri": "...",
  "token_uri": "...",
  ...
}
```

**IMPORTANT:** The JSON must:
- Start with `{`
- End with `}`
- Be valid JSON (no extra characters before/after)
- Include all the fields (especially `private_key` which is long)

### 3. Set in Render Dashboard

1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Click your service (e.g., `robot-9qcb`)
3. Click **Environment** in the left sidebar
4. Find or add the environment variable:
   - **Key**: `FIREBASE_SERVICE_ACCOUNT`
   - **Value**: Paste the ENTIRE JSON you copied
5. **Do NOT:**
   - ❌ Wrap it in quotes
   - ❌ Add extra spaces before/after
   - ❌ Add `export` or any other text
   - ❌ Convert it to base64 manually
6. Click **Save Changes**

### 4. Verify

After saving, Render will automatically redeploy. Check the logs:
- Look for: `✅ Successfully parsed FIREBASE_SERVICE_ACCOUNT as JSON`
- If you see errors, the logs will now show helpful troubleshooting tips

## Common Mistakes

### ❌ Wrong: Partial JSON
```
"project_id": "my-project"
```

### ❌ Wrong: Wrapped in quotes
```
"{ \"type\": \"service_account\", ... }"
```

### ❌ Wrong: Extra text
```
export FIREBASE_SERVICE_ACCOUNT={"type":"service_account",...}
```

### ✅ Correct: Full JSON
```
{
  "type": "service_account",
  "project_id": "my-project",
  ...
}
```

## Testing

After deployment, test the service:
- Visit: `https://YOUR_SERVICE_URL/test`
- Should return: `{"status":"connected","message":"Render notification service is running",...}`

## Still Having Issues?

Check the Render logs for:
- Length of the environment variable (should be 1000+ characters)
- First 50 characters preview
- Detailed error messages with troubleshooting tips

The improved error handling will show exactly what's wrong with your JSON.
