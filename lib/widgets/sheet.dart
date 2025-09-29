import 'package:food_donation_app/authenticate/register_page.dart';
import 'package:food_donation_app/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FeedFoodSheet {
  Widget buildSheet(context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: InkWell(
                          onTap: () {
                            Get.to(() => RegisterPage(isNgo: true));
                          },
                          child: Column(
                            children: [
                              Image.asset(
                                "assets/images/ngo.png",
                                height: 80,
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              const Text(
                                "NGO",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 100,
                        child: VerticalDivider(
                          color: Colors.black54,
                          thickness: 1,
                          width: 20,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: InkWell(
                          onTap: () {
                            Get.to(() => RegisterPage(isNgo: false));
                          },
                          child: Column(
                            children: [
                              Image.asset(
                                "assets/images/volunteer.png",
                                height: 80,
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              const Text(
                                "Volunteer",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          )
        ],
      );
}
