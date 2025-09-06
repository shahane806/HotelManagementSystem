const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const { v4: uuidv4 } = require('uuid'); // For generating unique order IDs

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*', // Allow all origins for development; restrict in production
  },
});

// In-memory order storage (replace with a database in production)
let orders = [];

app.get('/', (req, res) => {
  res.send('Socket.io server is running');
});

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  // Handle fetchOrders event
  socket.on('fetchOrders', () => {
    console.log(`Fetching all orders for socket: ${socket.id}`);
    socket.emit('ordersFetched', orders);
  });

  // Handle placeOrder event
  socket.on('placeOrder', (order) => {
    try {
      // Validate order data
      if (!isValidOrder(order)) {
        socket.emit('error', { message: 'Invalid order data', order });
        console.log('Invalid order data received:', order);
        return;
      }

      // Assign a unique ID if not provided
      const orderId = order.id || uuidv4();
      const orderWithStatus = {
        ...order,
        id: orderId,
        status: 'Pending',
        time: order.time || new Date().toISOString(), // Ensure time is set
      };

      orders.push(orderWithStatus);
      console.log('New order placed:', orderWithStatus);
      io.emit('newOrder', orderWithStatus);
    } catch (error) {
      console.error('Error processing placeOrder:', error);
      socket.emit('error', { message: 'Error processing order', error: error.message });
    }
  });

  // Handle updateStatus event
  socket.on('updateStatus', ({ orderId, status, sourceSocketId }) => {
    try {
      // Validate update data
      if (!orderId || !isValidStatus(status)) {
        socket.emit('error', { message: 'Invalid update data', data: { orderId, status } });
        console.log('Invalid update data received:', { orderId, status });
        return;
      }

      console.log(`Updating order ${orderId} to status: ${status} from socket: ${sourceSocketId}`);
      const orderExists = orders.some(order => order.id === orderId);
      if (!orderExists) {
        socket.emit('error', { message: `Order ${orderId} not found` });
        console.log(`Order ${orderId} not found`);
        return;
      }

      // Check if status has changed
      const currentOrder = orders.find(order => order.id === orderId);
      if (currentOrder.status === status) {
        console.log(`Order ${orderId} already has status ${status}, skipping update`);
        return;
      }

      orders = orders.map(order =>
        order.id === orderId ? { ...order, status } : order
      );
      // Broadcast to all clients except the sender
      socket.broadcast.emit('orderUpdated', { orderId, status, sourceSocketId });
      console.log(`Broadcasted orderUpdated for order ${orderId} to status ${status}`);
    } catch (error) {
      console.error('Error processing updateStatus:', error);
      socket.emit('error', { message: 'Error updating order status', error: error.message });
    }
  });
  socket.on('payBill', (bill) => {
    try {
      // Validate bill data (add more validation as needed)
      if (!bill || !bill.billId || !bill.table || !bill.totalAmount || !bill.orders) {
        socket.emit('error', { message: 'Invalid bill data', bill });
        console.log('Invalid bill data received:', bill);
        return;
      }

      // Process payment (in real app, integrate with payment gateway)
      // For now, assume success and mark related orders as paid
      const table = bill.table;
      orders = orders.map(order => 
        order.table === table ? { ...order, status: 'Paid' } : order
      );

      // Remove paid orders or archive them (for simplicity, filter out)
      orders = orders.filter(order => order.table !== table);

      console.log('Bill paid for table:', table);
      io.emit('billPaid', { ...bill, success: true });
    } catch (error) {
      console.error('Error processing payBill:', error);
      socket.emit('error', { message: 'Error processing bill payment', error: error.message });
    }
  });
  // Handle fetchBills event
  socket.on('fetchBills', async () => {
    try {
      const bills = await Bill.find({ status: 'Pending' });
      socket.emit('billsFetched', bills.map(b => b.toObject()));
    } catch (error) {
      console.error('Error fetching bills:', error);
      socket.emit('error', { message: 'Failed to fetch bills', error: error.message });
    }
  });
  // Handle disconnect
  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
    // Note: No need to clear listeners here as socket.io handles it
  });
});

// Validate order data
function isValidOrder(order) {
  return (
    order &&
    typeof order === 'object' &&
    order.table &&
    Array.isArray(order.items) &&
    order.items.every(
      item =>
        item.name &&
        typeof item.quantity === 'number' &&
        typeof item.price === 'number'
    ) &&
    typeof order.total === 'number'
  );
}

// Validate status
function isValidStatus(status) {
  const validStatuses = ['Pending', 'Preparing', 'Ready', 'Served'];
  return validStatuses.includes(status);
}

server.listen(3000, () => {
  console.log('Listening on port 3000');
});
