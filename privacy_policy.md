# Privacy Policy for Quizapp

**Last updated: May 3, 2026**

## Overview

Quizapp is an offline, local-area-network (LAN) multiplayer quiz game. This privacy policy explains how the app handles data. The short version: **we collect nothing, store nothing remotely, and share nothing.**

---

## Data We Do NOT Collect

Quizapp does not collect, transmit, or store any personal information on any external server. There are no accounts, no cloud sync, no analytics, and no third-party SDKs that phone home.

---

## What Stays on Your Device

The following data exists **only on your device** and is never sent anywhere outside your local network:

- **Quiz content** you create (questions, answers, images) — stored in a local SQLite database on your device
- **Game history** (scores, rankings from past games) — stored locally in the same SQLite database
- **Player names and avatars** — entered at game time, held in memory for the session only, never written to disk

---

## Local Network Usage

When hosting or joining a game, Quizapp communicates with other devices **on the same Wi-Fi network only** (LAN/hotspot). No data leaves your local network. Specifically:

- The host device opens a TCP socket on port 4567 (local network only)
- Player names and quiz questions are broadcast to other devices on the same network during an active game session
- This communication is purely peer-to-peer over LAN and is not routed through the internet

---

## Permissions Explained

| Permission | Why it's needed |
|---|---|
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | Required by Android 10+ to scan for nearby Wi-Fi devices and use mDNS/NSD (local network service discovery). **Location data is never read, stored, or transmitted.** |
| `CHANGE_WIFI_MULTICAST_STATE` | Needed to send multicast packets for local network device discovery (mDNS). |
| `ACCESS_WIFI_STATE` / `ACCESS_NETWORK_STATE` | Reads the local IP address of the device to display as the host address. Never sent externally. |
| `INTERNET` | Required by the Android networking stack to bind local TCP sockets. The app does not make any internet connections. |
| `CAMERA` | Used to take photos for quiz question images (optional). Photos are stored locally on your device only. |
| `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE` | Used to pick existing photos from your gallery for quiz question images. Images are stored locally only. |

---

## Children's Privacy

Quizapp does not knowingly collect any data from anyone, including children under 13. Since no data is collected at all, the app is safe for all ages.

---

## Changes to This Policy

If the app is updated in a way that changes how data is handled, this policy will be updated and the date at the top will change.

---

## Contact

If you have any questions about this privacy policy, contact:

**Ashwin**
ashwinashwin688@gmail.com

---

*Quizapp — Offline LAN Multiplayer Quiz Game*
