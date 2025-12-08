const Customer = require('../Models/customerModel');

 const getAllCustomers = async (req, res) => {
  try {
    const customers = await Customer.find();
    res.status(200).json(customers);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching customers', error });
  }
};

 const createCustomer = async (req, res) => {
  try {
    const customer = new Customer(req.body);
    await customer.save();
    res.status(201).json(customer);
  } catch (error) {
    res.status(400).json({ message: 'Error creating customer', error });
  }
};

const updateCustomer = async (req, res) => {
  try {
    const customer = await Customer.findOneAndUpdate({ id: req.params.userId }, req.body, { new: true });
    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }
    res.status(200).json(customer);
  } catch (error) {
    res.status(500).json({ message: 'Error updating customer', error });
  }
};

const deleteCustomer = async (req, res) => {
  console.log("Delete request params:", req.params);

  try {
    let customer = await Customer.findOneAndDelete({ id: req.params.userId });

    if (!customer) {
      customer = await Customer.findByIdAndDelete(req.params.userId);
    }

    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }

    res.status(200).json({ message: 'Customer deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting customer', error });
  }
};


module.exports = {createCustomer,getAllCustomers,updateCustomer,deleteCustomer}