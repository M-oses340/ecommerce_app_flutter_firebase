import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ecommerce_app/models/coupon_model.dart';

class DiscountContainer extends StatefulWidget {
  const DiscountContainer({super.key});

  @override
  State<DiscountContainer> createState() => _DiscountContainerState();
}

class _DiscountContainerState extends State<DiscountContainer> {
  Duration timeLeft = const Duration(hours: 3, minutes: 15, seconds: 30);
  Timer? timer;

  final dummyDiscounts = [
    CouponModel(id: "1", code: "FLASH25", discount: 25, desc: "Smartphones & Accessories"),
    CouponModel(id: "2", code: "DEAL40", discount: 40, desc: "Home Electronics Sale"),
    CouponModel(id: "3", code: "SAVE30", discount: 30, desc: "Fashion Deals"),
    CouponModel(id: "4", code: "BAG20", discount: 20, desc: "Travel & Handbags"),
  ];

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft.inSeconds > 0) {
        setState(() => timeLeft -= const Duration(seconds: 1));
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}h : ${twoDigits(d.inMinutes.remainder(60))}m : ${twoDigits(d.inSeconds.remainder(60))}s";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final discounts = dummyDiscounts;
    final width = MediaQuery.of(context).size.width;

    final bgColor = isDark ? Colors.grey.shade900 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.08);
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;

    // 🔥 adaptive banner color
    final bannerColor =
    isDark ? Colors.orange.shade700 : Colors.red.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🧨 Flash Sale Banner
        Container(
          decoration: BoxDecoration(
            color: bannerColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.flash_on, color: isDark ? Colors.black : Colors.white, size: 22),
                  const Gap(6),
                  Text(
                    "Flash Sale",
                    style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Gap(8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatTime(timeLeft),
                      style: TextStyle(
                        color: isDark ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/discount'),
                child: Text(
                  "See All",
                  style: TextStyle(
                    color: isDark ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),

        const Gap(10),

        // 🛍 Product Cards (snap scroll)
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller:
            PageController(viewportFraction: width < 600 ? 0.55 : 0.4),
            itemCount: discounts.length,
            padEnds: false,
            itemBuilder: (context, index) {
              final discount = discounts[index];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🖼 Product Image
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                      child: Image.network(
                        "https://picsum.photos/seed/${discount.id}/400/300",
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              discount.desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Code: ${discount.code}",
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: bannerColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "SALE",
                                    style: TextStyle(
                                      color:
                                      isDark ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
