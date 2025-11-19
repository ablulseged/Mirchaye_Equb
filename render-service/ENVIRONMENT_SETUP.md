# Setting FIREBASE_SERVICE_ACCOUNT in Render

## Step-by-Step Instructions

**⚠️ RECOMMENDED: Use Base64 encoding (Option 1)** - This avoids issues with newlines in the private key.

### Option 1: Base64 Encoding (Recommended) ✅

#### 1. Get Your Firebase Service Account JSON

Same as below - download the JSON file from Firebase Console.

#### 2. Encode to Base64

**On macOS/Linux:**
```bash
cat serviceAccountKey.json | base64
```

**On Windows (PowerShell):**
```powershell
$content = Get-Content serviceAccountKey.json -Raw -Encoding UTF8
[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
```

**Or use an online tool:**
- Go to https://www.base64encode.org/
- Paste your JSON content
- Click "Encode"
- Copy the Base64 string

#### 3. Set in Render Dashboard

1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Click your service
3. Click **Environment** in the left sidebar
4. Add environment variable:
   - **Key**: `FIREBASE_SERVICE_ACCOUNT_BASE64`
   - **Value**: Paste the Base64 string you generated
5. Click **Save Changes**

✅ **Done!** This is the easiest and most reliable method.

---

### Option 2: Direct JSON (Advanced)

#### 1. Get Your Firebase Service Account JSON

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click the gear icon ⚙️ → **Project Settings**
4. Go to **Service Accounts** tab
5. Click **Generate New Private Key**
6. Click **Generate Key** in the confirmation dialog
7. A JSON file will download

#### 2. Fix Newlines in private_key

The `private_key` field contains line breaks that must be escaped as `\n`.

**Before (wrong):**
```json
"private_key": "-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
-----END PRIVATE KEY-----
"
```

**After (correct):**
```json
"private_key": "-----BEGIN PRIVATE KEY-----\\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\\n-----END PRIVATE KEY-----\\n"
```

You can use a text editor's find/replace:
- Find: `\n` (actual newline)
- Replace: `\\n` (literal \n)

Or use a JSON formatter/minifier that handles this automatically.

#### 3. Copy the JSON Content

1. Open the downloaded JSON file in a text editor
2. Fix the newlines as described above
3. Select **ALL** the content (Ctrl+A / Cmd+A)
4. Copy it (Ctrl+C / Cmd+C)

**IMPORTANT:** The JSON must:
- Start with `{`
- End with `}`
- Have `\n` (escaped) not actual line breaks in private_key
- Be valid JSON (no extra characters before/after)

#### 4. Set in Render Dashboard

1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Click your service
3. Click **Environment** in the left sidebar
4. Add environment variable:
   - **Key**: `FIREBASE_SERVICE_ACCOUNT`
   - **Value**: Paste the ENTIRE JSON you copied (with escaped newlines)
5. **Do NOT:**
   - ❌ Wrap it in quotes
   - ❌ Add extra spaces before/after
   - ❌ Add `export` or any other text
6. Click **Save Changes**

---

### Verify

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

---

## Summary

✅ **Recommended Approach**: Use **Base64 encoding (Option 1)** for the easiest setup.

✅ **Quick Setup Steps**:
1. Download Firebase service account JSON
2. Encode to Base64 (PowerShell script provided)
3. Set `FIREBASE_SERVICE_ACCOUNT_BASE64` in Render Dashboard
4. Save and let Render redeploy

✅ **Verification**: Visit `/test` endpoint to confirm service is running

Your notification service is now ready to handle push notifications from your Flutter app! 🚀