/*
Manual QR payment section is intentionally kept hidden while Razorpay live
payment is active.

Widget upgradePaymentQrSection() {
  return Container(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: Color(0xFF2E7D32).withValues(alpha: 0.10),
          blurRadius: 20,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          'Scan the QR code',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF07140E),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.asset(
            'assets/images/payment_qr.png',
            height: 280,
            width: double.infinity,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: 14),
        Text(
          'Please make the payment using the QR code and send the payment screenshot via WhatsApp 9226824223',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF07140E),
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
*/
