const express = require('express');
require("./mongodb")
const http = require('http');
const { Server } = require('socket.io');
const orderModel = require('./Models/orderModel');

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
socket.on('fetchOrders', async () => {
  try {
    const date = new Date();

    const start = new Date(date);
    start.setUTCHours(0, 0, 0, 0);

    const end = new Date(date);
    end.setUTCHours(23, 59, 59, 999);

    const orders = await orderModel.find({
      createdAt: {
        $gte: start,
        $lte: end,
      },
    });
  console.log("Orders : "+orders)
  let o = orders.filter(e=>e.bill_status=="Pending")
    socket.emit('ordersFetched', o);
  } catch (e) {
    console.error(e);
    socket.emit('ordersFetched', []);
  }
});




  // Handle placeOrder event
  socket.on('placeOrder', async (order) => {
    try {
      // Validate order data
      if (!isValidOrder(order)) {
        socket.emit('error', { message: 'Invalid order data', order });
        console.log('Invalid order data received:', order);
        return;
      }

      // Assign a unique ID if not provided
      const orderWithStatus = {
        ...order,
        status: 'Pending',
        time: order.time || new Date().toISOString(), // Ensure time is set
      };
      await new orderModel(orderWithStatus).save()
      console.log('New order placed:', orderWithStatus);
      io.emit('newOrder', orderWithStatus);
    } catch (error) {
      console.error('Error processing placeOrder:', error);
      socket.emit('error', { message: 'Error processing order', error: error.message });
    }
  });

  // Handle updateStatus event
  socket.on('updateStatus', async ({ orderId, status, sourceSocketId }) => {
  try {
    // Validate input
    if (!orderId || !isValidStatus(status)) {
      socket.emit('error', { message: 'Invalid update data', data: { orderId, status } });
      console.log('Invalid update data received:', { orderId, status });
      return;
    }

    console.log(`Updating order ${orderId} to status: ${status} from socket: ${sourceSocketId}`);

    // Atomically update only if status is different
    const updatedOrder = await orderModel.findOneAndUpdate(
      { id: orderId, status: { $ne: status } }, // Only update if status is different
      { status },
      { new: true } // Return updated document
    );

    if (!updatedOrder) {
      // Order not found OR status is already the same
      const existingOrder = await orderModel.findById(orderId);
      if (!existingOrder) {
        socket.emit('error', { message: `Order ${orderId} not found` });
        console.log(`Order ${orderId} not found`);
      } else {
        console.log(`Order ${orderId} already has status ${status}, skipping update`);
      }
      return;
    }

    // Broadcast the update to other clients
    socket.broadcast.emit('orderUpdated', {
      orderId,
      status,
      sourceSocketId,
    });
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
       orderModel.updateMany(
  { table },                // filter
  { $set: { status: "Paid" } }
);

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
