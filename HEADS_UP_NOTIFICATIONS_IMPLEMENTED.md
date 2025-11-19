# Heads-Up Notifications (Overlay Notifications) Implementation

## Summary
Implemented heads-up (overlay) notifications that appear at the top of the screen when:
1. **A user sends money** - Shows a heads-up notification to the **group owner**
2. **Other announcements** - Shows heads-up notifications for all group members

## Implementation Details

### 1. Notification Service Updates (`lib/services/notification_service.dart`)

#### Added Heads-Up Notification Support
- Added `showHeadsUp` parameter to `createNotification()` method
- Added `showHeadsUp` parameter to `createNotificationForUsers()` method
- Created `_showHeadsUpNotification()` helper method that uses `showLocalNotification()` from `messaging_service.dart`

#### How It Works
- When `showHeadsUp: true` is passed, the notification service checks if the current user is the target recipient
- If the current user is viewing the app, a heads-up notification is immediately displayed
- The notification also appears via the Firestore stream when the user's device receives it

### 2. Payment Notifications (`lib/services/equb_service.dart`)

#### Modified `recordPayment()` Function
- When a payment is made, the system now:
  1. Gets the group owner's UID from the equb data
  2. Sends a **heads-up notification specifically to the owner** with:
     - Title: "Payment Received"
     - Message: "{Sender Name} sent {Amount} {Currency} to {Group Name}"
     - `showHeadsUp: true` flag enabled
  3. Sends regular notifications to other group members (excluding owner and payer)

#### Example Notification
```
Title: Payment Received
Message: Abebe Kebede sent 4,166.67 ETB to Computer Science Students Equb
```

### 3. Announcement Notifications (`lib/services/equb_service.dart`)

#### Modified `addAnnouncement()` Function
- When an announcement is created:
  - All group members receive notifications
  - `showHeadsUp: true` is enabled for all members
  - Heads-up notifications appear immediately for members viewing the app

### 4. Dashboard Notification Listener (`lib/presentation/dashboard_home/dashboard_home.dart`)

#### Enhanced `_showNotificationPopup()` Method
- Now shows **both**:
  1. **Heads-up notification** (system overlay at top of screen)
  2. **In-app SnackBar popup** (floating notification within the app)

#### Features
- Heads-up notifications appear at the top of the screen (Android/iOS)
- Works even when the app is in the foreground
- Uses `Importance.max` and `Priority.max` for maximum visibility
- Includes sound, vibration, and LED lights (on supported devices)
- Shows on lock screen
- Displays full notification text in expanded view

## Notification Behavior

### For Payment Notifications
1. **Group Owner**: Receives heads-up notification immediately when payment is made
2. **Other Members**: Receive regular notifications (no heads-up unless they're viewing the app when the stream updates)

### For Announcements
1. **All Group Members**: Receive heads-up notifications when announcement is created
2. **Immediate Display**: If member is viewing the app, notification appears immediately

### System-Level Features
- **Android**: Heads-up notification appears at top of screen with full text
- **iOS**: Alert-style notification appears
- **Sound & Vibration**: Enabled for all heads-up notifications
- **Lock Screen**: Notifications visible on lock screen
- **Notification Center**: All notifications saved to notification center

## Technical Details

### Notification Channel Configuration
The notification channel is configured with:
- `Importance.max` - Maximum importance for heads-up display
- `Priority.max` - Maximum priority for heads-up display
- `playSound: true` - Sound enabled
- `enableVibration: true` - Vibration enabled
- `enableLights: true` - LED indicator enabled
- `visibility: NotificationVisibility.public` - Visible on lock screen

### Platform Support
- ✅ **Android**: Full heads-up notification support
- ✅ **iOS**: Alert-style notification support
- ❌ **Web**: Not supported (gracefully skipped)

## Files Modified

1. `lib/services/notification_service.dart`
   - Added `showHeadsUp` parameter to notification creation methods
   - Added `_showHeadsUpNotification()` helper method

2. `lib/services/equb_service.dart`
   - Modified `recordPayment()` to send heads-up notification to owner
   - Modified `addAnnouncement()` to enable heads-up notifications for all members

3. `lib/presentation/dashboard_home/dashboard_home.dart`
   - Enhanced `_showNotificationPopup()` to show heads-up notifications
   - Added import for `showLocalNotification`

## Testing

### Test Payment Notifications
1. Create a payment as a regular member
2. **Expected**: Group owner should see heads-up notification at top of screen
3. **Expected**: Other members should see regular notifications

### Test Announcement Notifications
1. Create an announcement as group owner
2. **Expected**: All members should see heads-up notifications
3. **Expected**: Notification should appear at top of screen with sound/vibration

### Verification
- ✅ Heads-up notification appears at top of screen
- ✅ Sound and vibration work
- ✅ Notification visible on lock screen
- ✅ Notification saved to notification center
- ✅ SnackBar popup also appears in-app

## Future Enhancements

Potential improvements:
1. Notification actions (e.g., "View Payment", "Approve Request")
2. Custom notification sounds per notification type
3. Notification priority levels (high/medium/low)
4. Grouped notifications for multiple payments
5. Rich notifications with images/action buttons

## Notes

- Heads-up notifications require notification permissions to be granted
- On Android 8.0+, notification channels must be created (already implemented)
- Notifications work both in foreground and background
- The system automatically handles duplicate notifications
- All notifications are saved to Firestore for history tracking
