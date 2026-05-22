import 'dart:typed_data';
import '../fmx/bop_codec.dart';

int _foAccepted(Uint8List iv) {
  if (iv.length >= 3 && iv[0] != 0x41 && iv[2] == 0x41) {
    return 3;
  }
  return 1;
}

bool notificationAdvancesSeq(Uint8List inner) {
  final iv = innerForGatewayView(inner);
  if (iv.isEmpty) {
    return false;
  }
  return iv[0] != 0x53;
}

/// Login accepted parsing (supports 10-byte and 30-byte session).
({String sessionName, int nextSeq}) decodeLoginAccepted(Uint8List payload) {
  final bd = ByteData.sublistView(payload);
  if (payload.lengthInBytes >= 39) {
    final session = stripAscii(bd, 1, 30);
    final seq = bd.getUint64(31, Endian.little);
    return (sessionName: session, nextSeq: seq);
  }
  if (payload.lengthInBytes >= 19) {
    final session = stripAscii(bd, 1, 10);
    final seq = bd.getUint64(11, Endian.little);
    return (sessionName: session, nextSeq: seq);
  }
  throw StateError('login accepted too short');
}

({String orderId, int qty, int priceScaled, int instrumentId, bool buySide})? parseAccepted(Uint8List inner) {
  final iv = innerForGatewayView(inner);
  try {
    if (iv.isEmpty) {
      return null;
    }
    // Futures **Accepted** often mirrors **Enter** (`O`) layout with leading `A` at [0]:
    // id @1..30, side @31, qty u64 @32, instrument u64 @40, price i64 @48 (same as encodeEnterOrderFuturesExtended).
    final mirrored = _parseAcceptedEnterMirror(iv);
    if (mirrored != null) {
      return mirrored;
    }
    final fo = _foAccepted(iv);
    if (iv.length <= fo || iv[fo] != 0x41) {
      return null;
    }
    final bd = ByteData.sublistView(iv);
    final dataStart = fo + 1;
    final oidStart = dataStart + 16;
    final orderId = stripAscii(bd, oidStart, 30);
    final qtyOff = oidStart + 30 + 1;
    final buySide = latin1AsciiChar(bd.getUint8(qtyOff - 1)) == 'B';
    final qty = bd.getUint64(qtyOff, Endian.little);
    final instId = bd.getUint64(qtyOff + 8, Endian.little);
    final priceScaled = bd.getInt64(qtyOff + 16, Endian.little);
    return (orderId: orderId, qty: qty, priceScaled: priceScaled, instrumentId: instId, buySide: buySide);
  } catch (_) {
    return null;
  }
}

/// Same field packing as Futures extended Enter (`encodeEnterOrderFuturesExtended`): leading `A` then id/side/qty/inst/price like `O` enter.
({String orderId, int qty, int priceScaled, int instrumentId, bool buySide})? _parseAcceptedEnterMirror(
  Uint8List iv,
) {
  const minNeed = 56;
  if (iv.lengthInBytes < minNeed || iv[0] != 0x41) {
    return null;
  }
  try {
    final bd = ByteData.sublistView(iv);
    final orderId = stripAscii(bd, 1, 30);
    if (orderId.trim().isEmpty) {
      return null;
    }
    final sideByte = latin1AsciiChar(bd.getUint8(31));
    if (sideByte != 'B' && sideByte != 'S') {
      return null;
    }
    final buySide = sideByte == 'B';
    final qty = bd.getUint64(32, Endian.little);
    final instId = bd.getUint64(40, Endian.little);
    final priceScaled = bd.getInt64(48, Endian.little);
    if (qty <= 0 || qty > 0xFFFFFFFFFFFF) {
      return null;
    }
    return (orderId: orderId, qty: qty, priceScaled: priceScaled, instrumentId: instId, buySide: buySide);
  } catch (_) {
    return null;
  }
}

({String orderId, int execQty})? parseExecuted(Uint8List inner) {
  final iv = innerForGatewayView(inner);
  try {
    if (iv.length < 60 || iv[0] != 0x45) {
      return null;
    }
    final bd = ByteData.sublistView(iv);
    const oidStart = 17;
    final oid = stripAscii(bd, oidStart, 30);
    final execQty = bd.getUint64(47, Endian.little);
    return (orderId: oid, execQty: execQty);
  } catch (_) {
    return null;
  }
}

({String orderId, String reason})? parseCancelled(Uint8List inner) {
  final iv = innerForGatewayView(inner);
  try {
    if (iv.length < 50 || iv[0] != 0x43) {
      return null;
    }
    final bd = ByteData.sublistView(iv);
    final oid = stripAscii(bd, 17, 30);
    final r = latin1AsciiChar(iv[47]);
    return (orderId: oid, reason: r);
  } catch (_) {
    return null;
  }
}

({String orderId, int qty, int priceScaled})? parseReplaced(Uint8List inner) {
  final iv = innerForGatewayView(inner);
  try {
    if (iv.length < 156 || iv[0] != 0x55) {
      return null;
    }
    final bd = ByteData.sublistView(iv);
    final oid = stripAscii(bd, 17, 30);
    final qty64 = bd.getUint64(48, Endian.little);
    final px = bd.getInt64(64, Endian.little);
    return (orderId: oid, qty: qty64, priceScaled: px);
  } catch (_) {
    return null;
  }
}

({String orderId, String reason, String reqType})? parseRejected(Uint8List inner) {
  final iv = innerForGatewayView(inner);
  try {
    if (iv.length < 46 || iv[0] != 0x4a) {
      return null;
    }
    final bd = ByteData.sublistView(iv);
    final oid = stripAscii(bd, 9, 30);
    final rc = latin1AsciiChar(iv[39]);
    final rt = latin1AsciiChar(iv[44]);
    return (orderId: oid, reason: rc, reqType: rt);
  } catch (_) {
    return null;
  }
}

String latin1AsciiChar(int b) => String.fromCharCode(b.clamp(0, 127));
