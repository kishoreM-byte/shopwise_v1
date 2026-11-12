class OrderLifecycle {
  const OrderLifecycle._();

  static const String placed = 'placed';
  static const String accepted = 'accepted';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static const Set<String> allStatuses = <String>{
    placed,
    accepted,
    completed,
    cancelled,
  };

  static bool canTransition(String from, String to) {
    final current = from.trim().toLowerCase();
    final next = to.trim().toLowerCase();

    if (!allStatuses.contains(current) || !allStatuses.contains(next)) {
      return false;
    }

    if (current == placed) {
      return next == accepted || next == cancelled;
    }

    if (current == accepted) {
      return next == completed || next == cancelled;
    }

    return false;
  }

  static bool isTerminal(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == completed || normalized == cancelled;
  }
}
