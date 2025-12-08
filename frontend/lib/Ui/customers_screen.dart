import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../bloc/CustomersBloc/bloc.dart';
import '../bloc/CustomersBloc/event.dart';
import '../bloc/CustomersBloc/state.dart';
import '../models/user_model.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _aadhaarController = TextEditingController();
  late TabController _tabController;
  bool isEditMode = false;
  UserModel? selectedCustomer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Trigger fetching customers when the screen initializes
    context.read<CustomerBloc>().add(FetchCustomers());
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _aadhaarController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Validate Aadhaar number (12 digits)
  String? _validateAadhaar(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter Aadhaar number';
    }
    if (!RegExp(r'^\d{12}$').hasMatch(value)) {
      return 'Aadhaar number must be 12 digits';
    }
    return null;
  }

  // Validate email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  // Validate mobile
  String? _validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter mobile number';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Mobile number must be 10 digits';
    }
    return null;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final user = UserModel(
        id: isEditMode ? selectedCustomer!.id : const Uuid().v4(),
        fullName: _fullNameController.text,
        email: _emailController.text,
        mobile: _mobileController.text,
        aadhaarNumber: _aadhaarController.text,
      );

      if (isEditMode) {
        // Dispatch UpdateCustomer event
        context.read<CustomerBloc>().add(UpdateCustomer(user));
      } else {
        // Dispatch AddCustomer event
        context.read<CustomerBloc>().add(AddCustomer(user));
      }

      // Reset form
      _resetForm();
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _fullNameController.clear();
    _emailController.clear();
    _mobileController.clear();
    _aadhaarController.clear();
    setState(() {
      isEditMode = false;
      selectedCustomer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar-like header
              Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customers Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 22 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Manage customer registrations',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: isTablet ? 13 : 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // TabBar
              Container(
                margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16, vertical: isTablet ? 12 : 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.indigo,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                  padding: const EdgeInsets.all(4),
                  tabs: [
                    Tab(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: isTablet ? 12 : 10, horizontal: isTablet ? 24 : 16),
                        child: const Text('Register'),
                      ),
                    ),
                    Tab(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: isTablet ? 12 : 10, horizontal: isTablet ? 24 : 16),
                        child: const Text('View All'),
                      ),
                    ),
                  ],
                ),
              ),
              // TabBarView
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Registration Tab
                      Padding(
                        padding: EdgeInsets.all(isTablet ? 20 : 12),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditMode ? 'Update Customer' : 'Register New Customer',
                                  style: TextStyle(
                                    fontSize: isTablet ? 18 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2D3748),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _fullNameController,
                                  decoration: InputDecoration(
                                    hintText: 'Full Name',
                                    prefixIcon: const Icon(Icons.person, color: Colors.indigo),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  style: TextStyle(
                                    fontSize: isTablet ? 16 : 14,
                                    color: const Color(0xFF2D3748),
                                  ),
                                  validator: (value) =>
                                      value!.isEmpty ? 'Please enter full name' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    hintText: 'Email',
                                    prefixIcon: const Icon(Icons.email, color: Colors.indigo),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  style: TextStyle(
                                    fontSize: isTablet ? 16 : 14,
                                    color: const Color(0xFF2D3748),
                                  ),
                                  validator: _validateEmail,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _mobileController,
                                  decoration: InputDecoration(
                                    hintText: 'Mobile Number',
                                    prefixIcon: const Icon(Icons.phone, color: Colors.indigo),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  style: TextStyle(
                                    fontSize: isTablet ? 16 : 14,
                                    color: const Color(0xFF2D3748),
                                  ),
                                  validator: _validateMobile,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _aadhaarController,
                                  decoration: InputDecoration(
                                    hintText: 'Aadhaar Number',
                                    prefixIcon: const Icon(Icons.credit_card, color: Colors.indigo),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  style: TextStyle(
                                    fontSize: isTablet ? 16 : 14,
                                    color: const Color(0xFF2D3748),
                                  ),
                                  validator: _validateAadhaar,
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 20),
                                BlocBuilder<CustomerBloc, CustomerState>(
                                  builder: (context, state) {
                                    bool isLoading = state is CustomerLoading;
                                    return SizedBox(
                                      width: double.infinity,
                                      height: isTablet ? 48 : 40,
                                      child: ElevatedButton.icon(
                                        onPressed: isLoading ? null : _submitForm,
                                        icon: Icon(
                                          isEditMode ? Icons.edit : Icons.person_add,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        label: Text(
                                          isLoading
                                              ? 'Processing...'
                                              : (isEditMode ? 'Update Customer' : 'Register Customer'),
                                          style: TextStyle(
                                            fontSize: isTablet ? 15 : 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          elevation: 1,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // View All Customers Tab
                      Padding(
                        padding: EdgeInsets.all(isTablet ? 20 : 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registered Customers',
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: BlocBuilder<CustomerBloc, CustomerState>(
                                builder: (context, state) {
                                  if (state is CustomerLoading) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  } else if (state is CustomerLoaded) {
                                    final customers = state.customers;
                                    if (customers.isEmpty) {
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.person_off,
                                              size: isTablet ? 56 : 40,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'No customers registered yet',
                                              style: TextStyle(
                                                fontSize: isTablet ? 15 : 13,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Register a customer to see them here',
                                              style: TextStyle(
                                                fontSize: isTablet ? 11 : 10,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return ListView.separated(
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: customers.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final customer = customers[index];
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: ListTile(
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: isTablet ? 16 : 12,
                                              vertical: isTablet ? 8 : 6,
                                            ),
                                            leading: Container(
                                              width: isTablet ? 50 : 40,
                                              height: isTablet ? 50 : 40,
                                              decoration: BoxDecoration(
                                                color: Colors.indigo.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.person,
                                                  color: Colors.indigo,
                                                  size: isTablet ? 24 : 20,
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              customer.fullName,
                                              style: TextStyle(
                                                fontSize: isTablet ? 15 : 13,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF2D3748),
                                              ),
                                            ),
                                            subtitle: Text(
                                              'Email: ${customer.email}\nMobile: ${customer.mobile}\nAadhaar: ${customer.aadhaarNumber}',
                                              style: TextStyle(
                                                fontSize: isTablet ? 12 : 10,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit,
                                                      color: Colors.blue, size: 24),
                                                  onPressed: () {
                                                    setState(() {
                                                      isEditMode = true;
                                                      selectedCustomer = customer;
                                                      _fullNameController.text = customer.fullName;
                                                      _emailController.text = customer.email;
                                                      _mobileController.text = customer.mobile;
                                                      _aadhaarController.text = customer.aadhaarNumber;
                                                    });
                                                    _tabController.animateTo(0);
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete,
                                                      color: Colors.red, size: 24),
                                                  onPressed: () {
                                                    context.read<CustomerBloc>().add(DeleteCustomer(customer.id));
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Customer removed'),
                                                        backgroundColor: Colors.red,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  } else if (state is CustomerError) {
                                    return Center(
                                      child: Text(
                                        'Error: ${state.message}',
                                        style: TextStyle(
                                          fontSize: isTablet ? 15 : 13,
                                          color: Colors.red,
                                        ),
                                      ),
                                    );
                                  }
                                  return const Center(
                                    child: Text('Please wait...'),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}