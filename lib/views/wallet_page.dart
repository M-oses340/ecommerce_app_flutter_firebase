import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/controllers/wallet_controller.dart';
import 'package:ecommerce_app/views/wallet_deposit_page.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final WalletController _walletController = WalletController();

  Future<void> _refreshData() async {
    // Trigger rebuild to refresh streams
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wallet"),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _walletController.walletStream,
        builder: (context, snapshot) {
          // 🔹 Handle Errors
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading wallet data",
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          // 🔹 Shimmer Loading
          if (!snapshot.hasData) {
            return _buildShimmerLoader(theme);
          }

          final data = snapshot.data?.data() ?? {};
          final double balance = (data["wallet_balance"] ?? 0).toDouble();

          return Column(
            children: [
              const SizedBox(height: 30),

              // 🔹 Wallet Balance Card
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: theme.colorScheme.primaryContainer.withOpacity(0.95),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        "Available Balance",
                        style: theme.textTheme.titleMedium!
                            .copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "KSh ${balance.toStringAsFixed(2)}",
                        style: theme.textTheme.headlineMedium!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WalletDepositPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text("Deposit"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 🔹 Transactions Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      "Recent Transactions",
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 🔹 Transactions List with Refresh
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _walletController.transactionsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text("Error loading transactions"),
                        );
                      }

                      if (!snapshot.hasData) {
                        return _buildTransactionShimmer();
                      }

                      final transactions = snapshot.data!.docs;

                      if (transactions.isEmpty) {
                        return const Center(
                          child: Text("No transactions yet"),
                        );
                      }

                      return Scrollbar(
                        thumbVisibility: true,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final t = transactions[index].data();
                            final type = (t["type"] ?? "").toString();
                            final amount = (t["amount"] ?? 0).toDouble();
                            final desc = t["source"] ?? t["reason"] ?? "";
                            final timestamp = t["timestamp"] as Timestamp?;
                            final time = timestamp != null
                                ? DateFormat('MMM d, yyyy • hh:mm a')
                                .format(timestamp.toDate())
                                : "";

                            final isCredit =
                            type.toLowerCase().contains("credit");

                            return Card(
                              color: index.isEven
                                  ? theme.colorScheme.surfaceVariant
                                  .withOpacity(0.3)
                                  : theme.colorScheme.surface,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: Icon(
                                  isCredit
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  color:
                                  isCredit ? Colors.green : Colors.redAccent,
                                ),
                                title: Text(
                                  "${isCredit ? "Credit" : "Debit"} - KSh ${amount.toStringAsFixed(2)}",
                                  style: theme.textTheme.bodyLarge,
                                ),
                                subtitle: Text(
                                  desc,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  time,
                                  style: theme.textTheme.bodySmall!
                                      .copyWith(color: Colors.grey),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🔹 Shimmer Loader for Balance Section
  Widget _buildShimmerLoader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: theme.colorScheme.surfaceVariant,
        highlightColor: theme.colorScheme.surface,
        child: Column(
          children: [
            const SizedBox(height: 60),
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              height: 20,
              width: 160,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            _buildTransactionShimmer(),
          ],
        ),
      ),
    );
  }

  // 🔹 Shimmer Loader for Transactions
  Widget _buildTransactionShimmer() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: 6,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
