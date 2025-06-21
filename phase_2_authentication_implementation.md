
# 🔐 PHASE 2: AUTHENTICATION IMPLEMENTATION

This phase implements user login and session management for sales reps.

## 🧱 Goals
- Enable email/password login via Supabase
- Fetch and store user profile and outlet details
- Maintain user session with automatic login
- Show login UI when not authenticated

---

## 📁 Folder Structure (Additions)

```
lib/
├── screens/
│   └── auth/
│       ├── login_screen.dart
│       └── splash_screen.dart
├── core/
│   └── services/
│       └── auth_service.dart
```

---

## 📦 Supabase Tables Used

- `auth.users` – for authentication
- `profiles` – linked with `auth.users.id`, stores rep info and `outlet_id`

---

## 🔧 Development Steps

1. **Splash Screen**
   - Checks if a session exists via `Supabase.auth.currentSession`
   - If session exists → route to dashboard
   - Else → route to login screen

2. **Login Screen UI**
   - Email and password input fields
   - Login button
   - Loading indicator
   - Error message display

3. **Login Logic**

```dart
final response = await Supabase.instance.client.auth.signInWithPassword(
  email: email,
  password: password,
);

if (response.user != null) {
  // Fetch profile next
}
```

4. **Fetch User Profile**

```dart
final profile = await Supabase.instance.client
  .from('profiles')
  .select()
  .eq('id', Supabase.instance.client.auth.currentUser!.id)
  .single();
```

Store `full_name`, `outlet_id`, and other relevant info in memory or local storage.

5. **Session Persistence**
   - Supabase handles session persistence automatically.
   - On app startup, check `Supabase.auth.currentSession`

6. **Logout Functionality**

```dart
await Supabase.instance.client.auth.signOut();
```

7. **Routing Logic**
   - Authenticated → `DashboardScreen`
   - Not authenticated → `LoginScreen`

8. **Auth Guard**
   - Prevent access to stock/sales screens without active session

---

## ✅ DELIVERABLES FOR PHASE 2

- [x] Splash screen to auto-check session
- [x] Login screen with email/password fields
- [x] Login logic using Supabase
- [x] Profile fetch using `profiles` table
- [x] Navigation to dashboard on login
- [x] Logout button
- [x] Session persistence verified
- [x] Auth route guard applied

---

Once Phase 2 is working correctly and tested, we’ll proceed to **Phase 3: Stock Viewing Implementation**.
