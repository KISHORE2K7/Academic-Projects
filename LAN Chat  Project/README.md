 Lumina - Dual-Engine Zero-Footprint Web Messenger

A high-fidelity, offline-first web messaging application built for local area networks and global peer-to-peer communication. Lumina operates without external runtime installations, cloud accounts, or persistent servers, making it suitable for restricted environments, organizational intranets, and rapid deployment scenarios.

 Overview

Lumina addresses a fundamental gap in modern communication tools: the inability to function when internet connectivity is unavailable. Most messaging platforms depend entirely on centralized cloud infrastructure, rendering them useless during network outages, in air-gapped environments, or within organizations that restrict external traffic.

Lumina solves this by providing two independent communication engines within a single monolithic web application:

1. Offline LAN Mode - Uses a native Windows PowerShell HTTP server to relay messages across devices connected to the same local network, with zero internet dependency.
2. Global Room Mode - Uses WebRTC (via PeerJS) to establish direct peer-to-peer connections over the internet, with ephemeral rooms controlled entirely by the room creator.

No Node.js installation, no npm packages, and no third-party backend services are required for local operation.

 Key Features

- Zero-Dependency Local Hosting: The LAN server runs entirely on native Windows PowerShell using the .NET `System.Net.HttpListener` class. No runtime installations are required.
- Dual-Network Architecture: Seamlessly switch between offline LAN communication and internet-based peer-to-peer rooms from a single interface.
- Ephemeral Room System: In Global Mode, the room creator (Host) controls the room. When the Host disconnects, the room is automatically terminated and all participants are ejected.
- Host-Controlled Room Appearance: The room creator can modify the color theme of the room in real-time. Changes are broadcast to all connected participants via WebRTC data channels.
- Rich Media Support: Send images, files, and voice notes. Media is serialized as Base64 via the FileReader API and transmitted inline without requiring a dedicated media server.
- Markdown Text Formatting: Messages support `**bold**`, `*italic*`, and `` `code` `` syntax, parsed via a custom regular expression pipeline.
- Algorithmic Profile Avatars: User profile colors and initials are generated deterministically from nicknames using a hash-based algorithm, eliminating the need for avatar uploads or external CDN resources.
- Responsive Design: The interface adapts to mobile viewports with a collapsible sidebar drawer, ensuring usability across desktops, tablets, and phones.
- Glassmorphism UI: The interface implements a "Pastel Zen" aesthetic with CSS backdrop filters, radial gradient backgrounds, spring-loaded cubic-bezier animations, and micro-interaction hover effects.

---

 Architecture

```
+------------------------------------------------------------+
|                      index.html                            |
|  (Monolithic Frontend - UI, CSS, Client Logic)             |
+-----------------------------+------------------------------+
                              |
              +---------------+---------------+
              |                               |
   +----------v----------+       +-----------v-----------+
   |   Offline LAN Mode  |       |   Global Room Mode    |
   |                      |       |                       |
   |  server.ps1          |       |  PeerJS (WebRTC)      |
   |  PowerShell HTTP     |       |  Peer-to-Peer via     |
   |  Listener on :3000   |       |  STUN/TURN signaling  |
   |                      |       |                       |
   |  Polling: /sync      |       |  Host/Guest Topology  |
   |  Posting: /send      |       |  DataChannel Relay    |
   +----------------------+       +-----------------------+
```

LAN Mode: The client polls the PowerShell server at 300ms intervals via HTTP `fetch()` calls. Messages are stored in-memory on the server and returned as JSON arrays on each sync cycle.

Global Mode: The Host generates a unique alphanumeric Room ID via PeerJS cloud signaling. Guests connect by entering this ID. The Host acts as a central relay node, forwarding messages between all connected guests through WebRTC DataChannels.

 Prerequisites

- Operating System: Windows 10 or later (PowerShell 5.1+ is pre-installed)
- Browser: Any modern Chromium-based browser (Chrome, Edge, Brave) or Firefox
- For LAN Mode: Devices must be connected to the same local network (Wi-Fi or Ethernet)
- For Global Mode: Active internet connection on both Host and Guest devices

No additional software installations are required.

 Installation and Setup

1. Clone or download this repository:
   ```bash
   git clone https://github.com/<your-username>/lumina-lan-messenger.git
   ```

2. Navigate to the project directory.

3. To start the LAN server, double-click `start.bat`. The script will:
   - Request Administrator elevation (required to bind the HTTP listener to the local network interface)
   - Add a Windows Firewall rule for port 3000
   - Start the PowerShell HTTP server
   - Display the local IP address and port for other devices to connect

4. Open the displayed URL (e.g., `http://192.168.1.X:3000`) in a browser on any device connected to the same network.

5. For Global Mode, simply open `index.html` directly in a browser (no server required). Select "Create" to host a room or "Join" to connect to an existing one.

---

 Usage

 LAN Mode (Offline)

1. Run `start.bat` on the host machine.
2. Note the IP address displayed in the terminal window.
3. On any device connected to the same network, open a browser and navigate to the displayed address.
4. Enter a nickname and begin messaging.

 Global Room Mode (Online)

1. Open `index.html` in a browser.
2. Select Create to generate a Private Room ID.
3. Share the Room ID with other participants.
4. Participants select Join and enter the Room ID to connect.
5. The Host can modify the room's color theme using the palette button in the sidebar. Theme changes are applied to all participants in real-time.
6. When the Host closes their browser tab, the room is terminated and all guests are disconnected.

 Project Structure

lumina-lan-messenger/
|-- index.html          # Monolithic frontend (UI + CSS + client-side JavaScript)
|-- server.ps1          # Native PowerShell HTTP server for LAN communication
|-- start.bat           # Launcher script with privilege elevation
|-- server.js           # Alternative Node.js server (optional, not required)
|-- README.md           # Project documentation
```

| File          | Purpose                                                                 |
|---------------|-------------------------------------------------------------------------|
| `index.html`  | Complete application interface, styling, and dual-engine client logic   |
| `server.ps1`  | PowerShell-based HTTP server using .NET HttpListener                    |
| `start.bat`   | Windows batch launcher with automatic privilege elevation               |
| `server.js`   | Optional Node.js server implementation (requires Node.js if used)       |

---

 Technical Details

 PowerShell HTTP Server

The server uses `System.Net.HttpListener` to bind to all network interfaces on port 3000. It exposes three endpoints:

| Endpoint       | Method | Description                                      |
|----------------|--------|--------------------------------------------------|
| `/`            | GET    | Serves the `index.html` file                     |
| `/api/config`  | GET    | Returns the server's local IP address as JSON     |
| `/sync`        | GET    | Returns the current message and group state        |
| `/send`        | POST   | Accepts a JSON message payload to broadcast        |

 WebRTC Peer-to-Peer

- Library: PeerJS v1.5.2 (loaded via CDN)
- Signaling: PeerJS public cloud servers (STUN-based NAT traversal)
- Topology: Star topology with the Host as the central relay node
- Data Format: JSON-serialized strings transmitted over WebRTC DataChannels

 Media Handling

All binary media (images, files, voice notes) are converted to Base64 strings using the `FileReader` API. This approach eliminates the need for multipart form uploads or dedicated file storage servers, at the cost of increased payload size (~33% overhead from Base64 encoding).

 Voice Recording

Voice notes are captured using the `MediaRecorder` API with WebM audio encoding. Recorded audio is converted to a Base64 data URL and transmitted as a standard message payload.

 Limitations

- LAN Mode is currently Windows-only due to its dependency on PowerShell and the .NET `HttpListener` class.
- Message persistence is limited to the server's runtime session (LAN Mode) or the browser session (Global Mode). Messages are not stored permanently.
- Base64 media encoding introduces a ~33% size overhead compared to raw binary transfer. Large files may experience slower transmission times.
- Global Mode depends on PeerJS public signaling servers for initial connection establishment. Once connected, all data flows directly between peers.
- The PowerShell polling mechanism, while optimized at 300ms intervals, is not a true real-time protocol (unlike WebSockets). Perceived latency is minimal but non-zero.

 Future Scope

- End-to-End Encryption: Implement AES-256 encryption for all message payloads before transmission.
- IndexedDB Storage: Replace `localStorage` with IndexedDB for persistent, high-capacity local message archival.
- Cross-Platform Server: Port the PowerShell server to a Python-based HTTP server for Linux and macOS compatibility.
- File Chunking: Implement chunked binary transfer for large files to avoid Base64 memory constraints.
- Read Receipts and Typing Indicators: Add real-time presence signals via additional WebRTC data channel messages.

 License

This project is provided as-is for Educational Use,And Is Made with Help of Google Anti-Gravity. No warranty is expressed or implied.
