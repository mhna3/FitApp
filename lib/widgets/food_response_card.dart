import 'package:flutter/material.dart';

import '../services/food_service.dart';

class FoodResponseCard extends StatefulWidget {
  final Map<String, dynamic> food;

  const FoodResponseCard({super.key, required this.food});

  @override
  State<FoodResponseCard> createState() => _FoodResponseCardState();
}

class _FoodResponseCardState extends State<FoodResponseCard> {
  final FoodService _foodService = FoodService();
  bool _isAdding = false;
  bool _isAdded = false;

  Future<void> _addFoodItem() async {
    setState(() {
      _isAdding = true;
    });

    try {
      await _foodService.addFoodItem(widget.food);

      setState(() {
        _isAdded = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('${widget.food['food_name']} added to your intake!'),
              ],
            ),
            backgroundColor: Color(0xFF06402B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isAdded = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to add item: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.green.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.green.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child:
                        Text(
                          widget.food['food_name']?.toString().toUpperCase() ?? 'FOOD ITEM',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF06402B),
                            letterSpacing: 1.2,
                          ),
                        ),
                    ),
                  ),
                  if (widget.food['photo'] != null)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16),
                        ),
                        image: DecorationImage(
                          image: NetworkImage(widget.food['photo']['thumb']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    Icons.food_bank,
                    "Quantity",
                    "${widget.food['serving_qty']} ${widget.food['serving_unit']}",
                  ),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.grey.shade300, Colors.transparent],
                      ),
                    ),
                  ),
                  _buildNutrientSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green.shade700),
          SizedBox(width: 8),
          Text(
            "$label: ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12),
        Row(
          children: [
            _buildNutrientCircle(
              "Calories",
              "${widget.food['nf_calories']?.toStringAsFixed(0) ?? '0'}",
              "kcal",
              Colors.orange,
            ),
            _buildNutrientCircle(
              "Protein",
              "${widget.food['nf_protein']?.toStringAsFixed(1) ?? '0'}",
              "grams",
              Colors.purple,
            ),
            _buildNutrientCircle(
              "Carbs",
              "${widget.food['nf_total_carbohydrate']?.toStringAsFixed(1) ?? '0'}",
              "grams",
              Colors.blue,
            ),
            _buildNutrientCircle(
              "Fat",
              "${widget.food['nf_total_fat']?.toStringAsFixed(1) ?? '0'}",
              "grams",
              Colors.red,
            ),
          ],
        ),
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              child: ElevatedButton.icon(
                onPressed: _isAdding || _isAdded ? null : _addFoodItem,
                icon: _isAdding
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : _isAdded
                    ? Icon(Icons.check, color: Colors.white)
                    : Icon(Icons.add, color: Colors.white),
                label: Text(
                  _isAdding
                      ? 'Adding...'
                      : _isAdded
                      ? 'Added!'
                      : 'Add item',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAdded
                      ? Colors.green[600]
                      : Color(0xFF06402B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildNutrientCircle(String label, String value, String unit, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}