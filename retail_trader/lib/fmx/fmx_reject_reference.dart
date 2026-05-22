/// FMX BOP “Reject Reason Codes” / “Rejected Request Types” (summary from BOP §11.8).

library;

const Map<String, String> kFmxRejectReasonDescriptions = {
  'A': 'Invalid Order Qualifiers bitmask.',
  'C': 'Trading platform closed.',
  'D': 'Duplicate order limit exceeded.',
  'F': 'Order not found.',
  'G': 'Invalid Order Identifiers.',
  'H': 'Instrument halted / non‑tradable.',
  'I': 'Invalid Buy/Sell indicator.',
  'J': 'Invalid Time In Force.',
  'K': 'Invalid display quantity.',
  'L': 'Invalid Originating Trader.',
  'M': 'Cross market price.',
  'N': 'Invalid order quantity.',
  'O': 'Other.',
  'P': 'Credit / insufficient buying power.',
  'Q': 'Invalid Order Type.',
  'R': 'Leg ratio mismatch.',
  'S': 'Invalid Instrument Id.',
  'T': 'Account not authorized for instrument.',
  'U': 'Timed out — message too old.',
  'X': 'Invalid price.',
  'Y': 'Price exceeds band.',
  'Z': 'Quantity exceeds safety threshold.',
  'a': 'Invalid account.',
  'j': 'Extended protocol required.',
  'm': 'Missing mandatory field.',
  't': 'Error trade.',
};

const Map<String, String> kFmxRejectedRequestTypeDescriptions = {
  'O': 'Enter Order',
  'U': 'Replace Order',
  'X': 'Cancel Order',
};

String fmxRejectReasonCaption(String singleCharReason) =>
    kFmxRejectReasonDescriptions[singleCharReason] ??
    'See FMX BOP §11.8.1 (code: $singleCharReason).';

String fmxRejectedRequestTypeCaption(String singleCharReq) =>
    kFmxRejectedRequestTypeDescriptions[singleCharReq] ??
    'unknown (tag: $singleCharReq)';
