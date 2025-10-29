const express = require('express');
const http = require('http');
const socketIo = require('socket.io');

const app = express();
const server = http.createServer(app);

// (1) Restrict CORS to localhost and a placeholder production URL
const io = socketIo(server, {
  cors: {
    origin: [
      'http://localhost:3000',
      'http://localhost:5000',
      'https://your-production-domain.com' // Replace with your actual domain
    ],
    methods: ['GET', 'POST']
  }
});

const PORT = process.env.PORT || 3000;

// (2) Simple fixed token for authentication (beginner-friendly approach)
const AUTH_TOKEN = process.env.AUTH_TOKEN || 'your-secret-token-change-this';

// Room management
const rooms = new Map();

// (3) Helper function for input validation
function isValidRoomId(roomId) {
  // RoomId should be a non-empty string with reasonable length
  return typeof roomId === 'string' && roomId.length > 0 && roomId.length <= 100;
}

function isValidSocketId(socketId) {
  return typeof socketId === 'string' && socketId.length > 0;
}

// (2) Middleware to check authentication token during socket handshake
io.use((socket, next) => {
  const token = socket.handshake.auth.token;
  
  if (token === AUTH_TOKEN) {
    next();
  } else {
    console.log('Authentication failed for socket:', socket.id);
    next(new Error('Authentication failed'));
  }
});

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  // Join room
  socket.on('join-room', (roomId) => {
    // (4) Wrap in try/catch for error handling
    try {
      // (3) Validate roomId
      if (!isValidRoomId(roomId)) {
        console.log('Invalid roomId received:', roomId);
        socket.emit('error', { message: 'Invalid room ID' });
        return;
      }

      socket.join(roomId);
      
      // Store the room in the socket for later reference
      socket.currentRoom = roomId;
      
      if (!rooms.has(roomId)) {
        rooms.set(roomId, new Set());
      }
      rooms.get(roomId).add(socket.id);
      
      // Notify others in the room
      socket.to(roomId).emit('user-joined', socket.id);
      
      console.log(`User ${socket.id} joined room ${roomId}`);
    } catch (error) {
      console.error('Error in join-room:', error);
      socket.emit('error', { message: 'Failed to join room' });
    }
  });

  // (5) Helper function to check if both peers are in the same room
  function getUserRoom(socketId) {
    for (const [roomId, users] of rooms.entries()) {
      if (users.has(socketId)) {
        return roomId;
      }
    }
    return null;
  }

  // WebRTC signaling - offer
  socket.on('offer', (data) => {
    // (4) Wrap in try/catch
    try {
      // (3) Validate data payload
      if (!data || !data.target || !data.offer) {
        console.log('Invalid offer data received');
        socket.emit('error', { message: 'Invalid offer data' });
        return;
      }

      if (!isValidSocketId(data.target)) {
        console.log('Invalid target socket ID in offer');
        socket.emit('error', { message: 'Invalid target ID' });
        return;
      }

      // (5) Check both peers are in the same room
      const senderRoom = getUserRoom(socket.id);
      const targetRoom = getUserRoom(data.target);
      
      if (!senderRoom || !targetRoom || senderRoom !== targetRoom) {
        console.log('Peers not in same room. Sender:', senderRoom, 'Target:', targetRoom);
        socket.emit('error', { message: 'Peers must be in the same room' });
        return;
      }

      socket.to(data.target).emit('offer', {
        offer: data.offer,
        sender: socket.id
      });
    } catch (error) {
      console.error('Error in offer:', error);
      socket.emit('error', { message: 'Failed to send offer' });
    }
  });

  // WebRTC signaling - answer
  socket.on('answer', (data) => {
    // (4) Wrap in try/catch
    try {
      // (3) Validate data payload
      if (!data || !data.target || !data.answer) {
        console.log('Invalid answer data received');
        socket.emit('error', { message: 'Invalid answer data' });
        return;
      }

      if (!isValidSocketId(data.target)) {
        console.log('Invalid target socket ID in answer');
        socket.emit('error', { message: 'Invalid target ID' });
        return;
      }

      // (5) Check both peers are in the same room
      const senderRoom = getUserRoom(socket.id);
      const targetRoom = getUserRoom(data.target);
      
      if (!senderRoom || !targetRoom || senderRoom !== targetRoom) {
        console.log('Peers not in same room. Sender:', senderRoom, 'Target:', targetRoom);
        socket.emit('error', { message: 'Peers must be in the same room' });
        return;
      }

      socket.to(data.target).emit('answer', {
        answer: data.answer,
        sender: socket.id
      });
    } catch (error) {
      console.error('Error in answer:', error);
      socket.emit('error', { message: 'Failed to send answer' });
    }
  });

  // WebRTC signaling - ICE candidate
  socket.on('ice-candidate', (data) => {
    // (4) Wrap in try/catch
    try {
      // (3) Validate data payload
      if (!data || !data.target || !data.candidate) {
        console.log('Invalid ICE candidate data received');
        socket.emit('error', { message: 'Invalid ICE candidate data' });
        return;
      }

      if (!isValidSocketId(data.target)) {
        console.log('Invalid target socket ID in ICE candidate');
        socket.emit('error', { message: 'Invalid target ID' });
        return;
      }

      // (5) Check both peers are in the same room
      const senderRoom = getUserRoom(socket.id);
      const targetRoom = getUserRoom(data.target);
      
      if (!senderRoom || !targetRoom || senderRoom !== targetRoom) {
        console.log('Peers not in same room. Sender:', senderRoom, 'Target:', targetRoom);
        socket.emit('error', { message: 'Peers must be in the same room' });
        return;
      }

      socket.to(data.target).emit('ice-candidate', {
        candidate: data.candidate,
        sender: socket.id
      });
    } catch (error) {
      console.error('Error in ice-candidate:', error);
      socket.emit('error', { message: 'Failed to send ICE candidate' });
    }
  });

  // Leave room
  socket.on('leave-room', (roomId) => {
    // (4) Wrap in try/catch
    try {
      // (3) Validate roomId
      if (!isValidRoomId(roomId)) {
        console.log('Invalid roomId in leave-room:', roomId);
        return;
      }

      socket.leave(roomId);
      
      if (rooms.has(roomId)) {
        rooms.get(roomId).delete(socket.id);
        
        // Clean up empty rooms
        if (rooms.get(roomId).size === 0) {
          rooms.delete(roomId);
        }
      }
      
      // Notify others
      socket.to(roomId).emit('user-left', socket.id);
      
      console.log(`User ${socket.id} left room ${roomId}`);
    } catch (error) {
      console.error('Error in leave-room:', error);
    }
  });

  // Handle disconnection
  socket.on('disconnect', () => {
    // (4) Wrap in try/catch
    try {
      console.log('User disconnected:', socket.id);
      
      // Remove user from all rooms
      for (const [roomId, users] of rooms.entries()) {
        if (users.has(socket.id)) {
          users.delete(socket.id);
          socket.to(roomId).emit('user-left', socket.id);
          
          // Clean up empty rooms
          if (users.size === 0) {
            rooms.delete(roomId);
          }
        }
      }
    } catch (error) {
      console.error('Error in disconnect:', error);
    }
  });
});

server.listen(PORT, () => {
  console.log(`Signaling server running on port ${PORT}`);
  console.log('⚠️  SECURITY: Make sure to set AUTH_TOKEN environment variable in production!');
});
