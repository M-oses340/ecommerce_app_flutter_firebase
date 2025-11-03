import 'package:ecommerce_app/containers/additional_confirm.dart';
import 'package:ecommerce_app/controllers/db_service.dart';
import 'package:ecommerce_app/models/orders_model.dart';
import 'package:ecommerce_app/utils/date_formatter.dart';
import 'package:flutter/material.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<OrdersModel> _displayedOrders = [];

  /// Tracks orders currently animating cancel button
  Map<String, bool> _isCancelling = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.clear();
      setState(() => _searchQuery = "");
    });
  }

  int totalQuantityCalculator(List<OrderProductModel> products) {
    return products.fold(0, (sum, e) => sum + e.quantity);
  }

  /// 🔥 Cancel order — updates UI and Firestore immediately with undo
  void _cancelOrder(int index, OrdersModel order) async {
    final oldStatus = order.status;

    // Trigger cancel animation on button
    setState(() {
      _isCancelling[order.id] = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    // Update status immediately
    setState(() {
      order.status = "CANCELLED";
      _isCancelling[order.id] = false;
    });

    // Firestore update
    await DbService().updateOrderStatus(
      docId: order.id,
      data: {"status": "CANCELLED"},
    );

    // Snackbar with Undo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Order cancelled"),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: "Undo",
          onPressed: () async {
            setState(() {
              order.status = oldStatus;
            });
            await DbService().updateOrderStatus(
              docId: order.id,
              data: {"status": oldStatus},
            );
          },
        ),
      ),
    );
  }

  Widget statusChip(String status) {
    Color bgColor;
    switch (status.toUpperCase()) {
      case "PAID":
        bgColor = Colors.green.shade600;
        break;
      case "ON_THE_WAY":
        bgColor = Colors.orange.shade700;
        break;
      case "DELIVERED":
        bgColor = Colors.teal.shade700;
        break;
      case "CANCELLED":
        bgColor = Colors.red.shade700;
        break;
      default:
        bgColor = Colors.grey.shade600;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
            ),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(status),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          status.replaceAll("_", " "),
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrdersModel order, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: order.status == "CANCELLED" ? 0.5 : 1.0, // faded if cancelled
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: colorScheme.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ViewOrder(order: order)),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "${totalQuantityCalculator(order.products)} items - KSh ${order.total}",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              statusChip(order.status),
            ],
          ),
          subtitle: Text(
            "Ordered on ${formatSmartDate(order.created_at)}",
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          // Cancel button with animation
          trailing: (order.status == "CANCELLED" || order.status == "DELIVERED")
              ? null
              : AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: _isCancelling[order.id] == true
                ? const SizedBox(
              key: ValueKey("cancel_animating"),
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : PopupMenuButton<String>(
              key: ValueKey("cancel_ready"),
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'cancel') {
                  showDialog(
                    context: context,
                    builder: (context) => AdditionalConfirm(
                      contentText:
                      "Are you sure you want to cancel this order? You can undo within 5 seconds.",
                      onYes: () {
                        Navigator.pop(context);
                        _cancelOrder(index, order);
                      },
                      onNo: () => Navigator.pop(context),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Cancel Order"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: "Search orders (ID, date, status)...",
            hintStyle:
            TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
            prefixIcon:
            Icon(Icons.search, color: colorScheme.onSurfaceVariant),
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.7),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value.trim().toLowerCase());
          },
        ),
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: StreamBuilder(
        stream: DbService().readOrders(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final orders = OrdersModel.fromJsonList(snapshot.data!.docs);
            final filtered = orders.where((order) {
              final q = _searchQuery;
              return q.isEmpty ||
                  order.id.toLowerCase().contains(q) ||
                  order.status.toLowerCase().contains(q) ||
                  formatSmartDate(order.created_at).toLowerCase().contains(q);
            }).toList();

            _displayedOrders = filtered;

            if (_displayedOrders.isEmpty) {
              return Center(
                child: Text(
                  "No matching orders found",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              );
            }

            return AnimatedList(
              key: _listKey,
              initialItemCount: _displayedOrders.length,
              itemBuilder: (context, index, animation) {
                final order = _displayedOrders[index];
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: FadeTransition(
                    opacity: animation,
                    child: _buildOrderCard(context, order, index),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading orders"));
          } else {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          }
        },
      ),
    );
  }
}

/// ✅ ViewOrder Widget (unchanged, with animated statusChip)
class ViewOrder extends StatelessWidget {
  final OrdersModel order;

  const ViewOrder({super.key, required this.order});

  int totalQuantity() {
    return order.products.fold(0, (sum, p) => sum + p.quantity);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details"),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Order ID: ${order.id}",
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text("Placed on ${formatSmartDate(order.created_at)}",
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            statusChip(order.status),
            const SizedBox(height: 20),
            Divider(color: colorScheme.outlineVariant),
            Text("Products (${totalQuantity()} items)",
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface)),
            const SizedBox(height: 10),
            ...order.products.map((p) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(p.image,
                    width: 50, height: 50, fit: BoxFit.cover),
              ),
              title: Text(p.name,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: colorScheme.onSurface)),
              subtitle: Text("${p.quantity} × KSh ${p.single_price}",
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
              trailing: Text("KSh ${p.total_price}",
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface)),
            )),
            const SizedBox(height: 20),
            Divider(color: colorScheme.outlineVariant),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("Delivery Address",
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text(order.address),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("Customer",
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text("${order.name} (${order.phone})"),
            ),
            const SizedBox(height: 20),
            Divider(color: colorScheme.outlineVariant),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Discount", style: theme.textTheme.bodyMedium),
                Text("KSh ${order.discount}"),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total",
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text("KSh ${order.total}",
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget statusChip(String status) {
    Color bgColor;
    switch (status.toUpperCase()) {
      case "PAID":
        bgColor = Colors.green.shade600;
        break;
      case "ON_THE_WAY":
        bgColor = Colors.orange.shade700;
        break;
      case "DELIVERED":
        bgColor = Colors.teal.shade700;
        break;
      case "CANCELLED":
        bgColor = Colors.red.shade700;
        break;
      default:
        bgColor = Colors.grey.shade600;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
            ),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(status),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration:
        BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
        child: Text(status.replaceAll("_", " "),
            style: const TextStyle(color: Colors.white, fontSize: 13)),
      ),
    );
  }
}
