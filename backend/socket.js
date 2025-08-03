const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);

app.get('/', (req, res) => {
  res.send('Socket.io server is running');
});

const io = new Server(server, {
  cors: {
    origin: '*',
  },
});

let orders = [];

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  socket.on('placeOrder', (order) => {
    // Use the orderId provided by the client, ensure status is set to Pending
    const orderWithStatus = { ...order, status: 'Pending' };
    orders.push(orderWithStatus);
    console.log('New order placed:', orderWithStatus);
    io.emit('newOrder', orderWithStatus);
  });

  socket.on('updateStatus', ({ orderId, status }) => {
    console.log(`Updating order ${orderId} to status: ${status}`);
    orders = orders.map(order =>
      order.id === orderId ? { ...order, status } : order
    );
    io.emit('orderUpdated', { orderId, status });
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

server.listen(3000, () => {
  console.log('Listening on port 3000');
});