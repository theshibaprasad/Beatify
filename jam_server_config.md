# Jam Server Configuration

## WebSocket Server Setup

The Jam system requires a WebSocket server to handle real-time communication between users. Here's how to set it up:

### Option 1: Simple Node.js Server (Recommended for Development)

Create a `jam-server.js` file:

```javascript
const WebSocket = require('ws');
const http = require('http');
const url = require('url');

const server = http.createServer();
const wss = new WebSocket.Server({ server });

const sessions = new Map();
const users = new Map();

wss.on('connection', (ws, req) => {
  const query = url.parse(req.url, true).query;
  const userId = query.userId;
  const userName = query.userName;
  
  console.log(`User connected: ${userName} (${userId})`);
  
  // Store user connection
  users.set(userId, { ws, userName, sessionId: null });
  
  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      handleMessage(ws, data, userId);
    } catch (error) {
      console.error('Error parsing message:', error);
    }
  });
  
  ws.on('close', () => {
    console.log(`User disconnected: ${userName}`);
    users.delete(userId);
  });
});

function handleMessage(ws, data, userId) {
  switch (data.type) {
    case 'authenticate':
      // User already authenticated on connection
      break;
      
    case 'create_session':
      createSession(data.session, userId);
      break;
      
    case 'join_session':
      joinSession(data.sessionId, userId, data.password);
      break;
      
    case 'leave_session':
      leaveSession(data.sessionId, userId);
      break;
      
    case 'send_message':
      broadcastToSession(data.sessionId, {
        type: 'message',
        id: generateId(),
        sessionId: data.sessionId,
        userId: data.userId,
        userName: data.userName,
        message: data.message,
        timestamp: new Date().toISOString(),
        messageType: 'text'
      });
      break;
      
    case 'add_track':
      broadcastToSession(data.sessionId, {
        type: 'track_added',
        sessionId: data.sessionId,
        track: data.track
      });
      break;
      
    case 'remove_track':
      broadcastToSession(data.sessionId, {
        type: 'track_removed',
        sessionId: data.sessionId,
        trackId: data.trackId
      });
      break;
      
    case 'get_sessions':
      sendAvailableSessions(ws);
      break;
      
    case 'playback_state':
    case 'track_change':
    case 'sync_request':
    case 'sync_response':
      // Broadcast to all participants in session
      broadcastToSession(data.sessionId, data);
      break;
  }
}

function createSession(sessionData, hostId) {
  const sessionId = generateId();
  const session = {
    id: sessionId,
    ...sessionData,
    hostId,
    participants: [sessionData.participants[0]],
    status: 'active',
    createdAt: new Date().toISOString(),
    currentTrackId: null,
    currentPosition: null
  };
  
  sessions.set(sessionId, session);
  
  // Notify creator
  const user = users.get(hostId);
  if (user) {
    user.sessionId = sessionId;
    sendToUser(hostId, {
      type: 'session_created',
      session: session
    });
  }
}

function joinSession(sessionId, userId, password) {
  const session = sessions.get(sessionId);
  if (!session) {
    sendToUser(userId, { type: 'error', message: 'Session not found' });
    return;
  }
  
  if (session.isPrivate && session.password && session.password !== password) {
    sendToUser(userId, { type: 'error', message: 'Invalid password' });
    return;
  }
  
  if (session.participants.length >= session.maxParticipants) {
    sendToUser(userId, { type: 'error', message: 'Session is full' });
    return;
  }
  
  const user = users.get(userId);
  if (user) {
    user.sessionId = sessionId;
    session.participants.push({
      id: userId,
      name: user.userName,
      role: 'participant',
      joinedAt: new Date().toISOString(),
      isOnline: true
    });
    
    // Notify all participants
    broadcastToSession(sessionId, {
      type: 'session_update',
      session: session
    });
  }
}

function leaveSession(sessionId, userId) {
  const session = sessions.get(sessionId);
  if (session) {
    session.participants = session.participants.filter(p => p.id !== userId);
    
    const user = users.get(userId);
    if (user) {
      user.sessionId = null;
    }
    
    if (session.participants.length === 0) {
      sessions.delete(sessionId);
    } else {
      broadcastToSession(sessionId, {
        type: 'session_update',
        session: session
      });
    }
  }
}

function broadcastToSession(sessionId, message) {
  const session = sessions.get(sessionId);
  if (session) {
    session.participants.forEach(participant => {
      const user = users.get(participant.id);
      if (user && user.ws.readyState === WebSocket.OPEN) {
        user.ws.send(JSON.stringify(message));
      }
    });
  }
}

function sendToUser(userId, message) {
  const user = users.get(userId);
  if (user && user.ws.readyState === WebSocket.OPEN) {
    user.ws.send(JSON.stringify(message));
  }
}

function sendAvailableSessions(ws) {
  const availableSessions = Array.from(sessions.values())
    .filter(session => !session.isPrivate && session.status === 'active')
    .map(session => ({
      id: session.id,
      name: session.name,
      description: session.description,
      hostId: session.hostId,
      participants: session.participants,
      status: session.status,
      createdAt: session.createdAt,
      isPrivate: session.isPrivate,
      maxParticipants: session.maxParticipants
    }));
  
  ws.send(JSON.stringify({
    type: 'sessions_list',
    sessions: availableSessions
  }));
}

function generateId() {
  return Math.random().toString(36).substr(2, 9);
}

const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
  console.log(`Jam server running on port ${PORT}`);
});
```

### Option 2: Python Server

```python
import asyncio
import websockets
import json
import uuid
from datetime import datetime

class JamServer:
    def __init__(self):
        self.sessions = {}
        self.users = {}
    
    async def handle_client(self, websocket, path):
        user_id = None
        try:
            async for message in websocket:
                data = json.loads(message)
                user_id = data.get('userId')
                
                if data['type'] == 'authenticate':
                    self.users[user_id] = {
                        'websocket': websocket,
                        'name': data['userName'],
                        'session_id': None
                    }
                    await websocket.send(json.dumps({'type': 'authenticated'}))
                
                elif data['type'] == 'create_session':
                    await self.create_session(data['session'], user_id)
                
                elif data['type'] == 'join_session':
                    await self.join_session(data['sessionId'], user_id, data.get('password'))
                
                # Handle other message types...
                
        except websockets.exceptions.ConnectionClosed:
            if user_id and user_id in self.users:
                await self.leave_session(self.users[user_id]['session_id'], user_id)
                del self.users[user_id]
    
    async def create_session(self, session_data, host_id):
        session_id = str(uuid.uuid4())
        session = {
            'id': session_id,
            **session_data,
            'hostId': host_id,
            'status': 'active',
            'createdAt': datetime.now().isoformat()
        }
        self.sessions[session_id] = session
        self.users[host_id]['session_id'] = session_id
        
        await self.users[host_id]['websocket'].send(json.dumps({
            'type': 'session_created',
            'session': session
        }))
    
    async def join_session(self, session_id, user_id, password):
        if session_id not in self.sessions:
            await self.users[user_id]['websocket'].send(json.dumps({
                'type': 'error',
                'message': 'Session not found'
            }))
            return
        
        session = self.sessions[session_id]
        if session.get('isPrivate') and session.get('password') != password:
            await self.users[user_id]['websocket'].send(json.dumps({
                'type': 'error',
                'message': 'Invalid password'
            }))
            return
        
        session['participants'].append({
            'id': user_id,
            'name': self.users[user_id]['name'],
            'role': 'participant',
            'joinedAt': datetime.now().isoformat(),
            'isOnline': True
        })
        
        self.users[user_id]['session_id'] = session_id
        
        # Broadcast to all participants
        await self.broadcast_to_session(session_id, {
            'type': 'session_update',
            'session': session
        })

async def main():
    server = JamServer()
    start_server = websockets.serve(server.handle_client, "localhost", 8080)
    print("Jam server running on ws://localhost:8080")
    await start_server

if __name__ == "__main__":
    asyncio.run(main())
```

### Running the Server

1. **Node.js Server:**
```bash
npm install ws
node jam-server.js
```

2. **Python Server:**
```bash
pip install websockets
python jam-server.py
```

### Production Deployment

For production, consider using:
- **Socket.IO** with Node.js
- **WebSocket support** in your backend framework
- **Cloud services** like Firebase Realtime Database or AWS API Gateway WebSocket

### Environment Configuration

Update the WebSocket URL in `jam_service.dart`:

```dart
// For development
const serverUrl = 'ws://localhost:8080';

// For production
const serverUrl = 'wss://your-domain.com/ws';
```

### Security Considerations

1. **Authentication**: Implement proper user authentication
2. **Rate Limiting**: Prevent spam and abuse
3. **Input Validation**: Validate all incoming messages
4. **CORS**: Configure Cross-Origin Resource Sharing
5. **SSL/TLS**: Use secure WebSocket connections (WSS) in production
