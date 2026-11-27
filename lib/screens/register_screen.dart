InputDecoration modernInputDecoration({
  required String hint,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(
      icon,
      color: const Color(0xFF64748B),
      size: 21,
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: Color(0xFFE2E8F0),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: Color(0xFF059669),
        width: 1.5,
      ),
    ),
    hintStyle: const TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 14,
    ),
  );
}

Widget buildInput({
  required String label,
  required String hint,
  required IconData icon,
  required TextEditingController controller,
  TextInputType? keyboardType,
  bool obscureText = false,
  Widget? suffixIcon,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF334155),
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: modernInputDecoration(
          hint: hint,
          icon: icon,
          suffixIcon: suffixIcon,
        ),
      ),
    ],
  );
}