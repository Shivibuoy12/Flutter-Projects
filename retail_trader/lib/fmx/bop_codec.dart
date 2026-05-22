/// FMX BOP-compatible framing: login / heartbeat / account probe, Futures extended
/// **Enter (`O`)**, **client Cancel (`X`)**, **Replace (`U`)**, plus server acks (**`A`**, **`C`** cancelled).

library;

import 'dart:convert';
import 'dart:typed_data';

/// Price scale used by Python client (`PRICE_SCALING_FACTOR`).
const int kPriceScalingFactor = 1000000000;

/// Matches Python `(0b010 << 5) | (0b10 << 3) | 0b001`.
const int kFuturesReportingCodes = (2 << 5) | (2 << 3) | 1;

Uint8List _asciiPad(String raw, int len) {
  var s = raw;
  if (s.length > len) {
    s = s.substring(0, len);
  }
  final b = List<int>.filled(len, 0x20);
  final enc = latin1.encode(s);
  for (var i = 0; i < enc.length && i < len; i++) {
    b[i] = enc[i];
  }
  return Uint8List.fromList(b);
}

String stripAscii(ByteData bd, int off, int len) {
  final raw = Uint8List.sublistView(Uint8List.view(bd.buffer), off, off + len);
  return latin1.decode(raw).trimRight();
}

Uint8List _fragmentWithLittleEndianLen(Uint8List body) {
  final mLen = body.lengthInBytes;
  final inner = Uint8List(2 + mLen);
  ByteData.sublistView(inner).setUint16(0, mLen, Endian.little);
  inner.setRange(2, inner.lengthInBytes, body);
  return inner;
}

Uint8List _futuresEnterOrderExtended65({
  required int displayQty,
  required int referencePriceScaled,
  required int reportingCodes,
  required int stopPriceScaled,
  required String account18,
  required String senderLocation4,
  required int smpCode,
  required int expiryTimeNs,
  String clearingMember3 = '   ',
  String tradingMember3 = '   ',
}) {
  // FMX BOP Table 24: extension begins at byte 135 of the Enter (`O`) body.
  // Time In Force stays in the *base* (offset 56) only — repeating it here misplaces Account/A/SMP and yields reject **m**.
  const extLen = 65;
  final ext = Uint8List(extLen);
  final ex = ByteData.sublistView(ext);
  ex.setUint64(0, displayQty, Endian.little);
  ex.setInt64(8, referencePriceScaled, Endian.little);
  ex.setUint8(16, reportingCodes & 0xff);
  ex.setInt64(17, stopPriceScaled, Endian.little);
  ext.setRange(25, 43, _asciiPad(account18, 18));
  ext.setRange(43, 47, _asciiPad(senderLocation4, 4));
  ex.setUint32(47, smpCode & 0xffffffff, Endian.little);
  ex.setUint64(51, expiryTimeNs, Endian.little);
  ext.setRange(59, 62, _asciiPad(clearingMember3, 3));
  ext.setRange(62, 65, _asciiPad(tradingMember3, 3));
  return ext;
}

Uint8List packTransport(String wrapperTypeAscii, Uint8List innerPayload) {
  final wt = latin1.encode(wrapperTypeAscii.substring(0, 1))[0];
  final bodyLen = 1 + innerPayload.lengthInBytes;
  final out = Uint8List(2 + bodyLen);
  final w = ByteData.sublistView(out);
  w.setUint16(0, bodyLen, Endian.little);
  out[2] = wt;
  out.setRange(3, out.lengthInBytes, innerPayload);
  return out;
}

Uint8List packRawFrame(Uint8List payloadNoOuterType) {
  final out = Uint8List(2 + payloadNoOuterType.lengthInBytes);
  ByteData.sublistView(out).setUint16(0, payloadNoOuterType.lengthInBytes, Endian.little);
  out.setRange(2, out.lengthInBytes, payloadNoOuterType);
  return out;
}

Iterable<Uint8List> splitExtendedMessages(Uint8List payload) sync* {
  var i = 0;
  while (i < payload.lengthInBytes) {
    if (i + 2 > payload.lengthInBytes) {
      throw StateError('truncated extended fragment');
    }
    final mLen = ByteData.sublistView(payload, i).getUint16(0, Endian.little);
    i += 2;
    final end = i + mLen;
    if (end > payload.lengthInBytes) {
      throw StateError('truncated extended body');
    }
    yield Uint8List.sublistView(payload, i, end);
    i = end;
  }
}

Uint8List innerForGatewayView(Uint8List inner) {
  if (inner.length >= 3) {
    final c0 = inner[0];
    final c2 = inner[2];
    final letter0 =
        (c0 >= 0x41 && c0 <= 0x5a) || (c0 >= 0x61 && c0 <= 0x7a);
    final letter2 =
        (c2 >= 0x41 && c2 <= 0x5a) || (c2 >= 0x61 && c2 <= 0x7a);
    if (!letter0 && letter2) {
      return Uint8List.sublistView(inner, 2);
    }
  }
  return inner;
}

/// Futures extended Enter inner: `[u16 len][135 base + 65 ext]` (`O`), per Table 23 + Table 24.
Uint8List encodeEnterOrderFuturesExtended({
  required String orderId,
  required String side,
  required int qty,
  required int instrumentId,
  required int priceScaled,
  required int timeInForce,
  required String orderTypeAscii,
  required String originatingTrader8,
  required String clientTrader18,
  required String instrumentSymbol30,
  int orderQualifiers = 0,
  int legTwo = 0,
  int legOne = 0,
  int displayQty = 0,
  int referencePriceScaled = 0,
  required int reportingCodes,
  int stopPriceScaled = 0,
  required String account18,
  required String senderLocation4,
  required int smpCode,
  required int expiryTimeNs,
}) {
  const baseLen = 135;
  final base = Uint8List(baseLen);
  final bb = ByteData.sublistView(base);
  bb.setUint8(0, 0x4f);
  base.setRange(1, 31, _asciiPad(orderId, 30));
  bb.setUint8(31, side.codeUnitAt(0));
  bb.setUint64(32, qty, Endian.little);
  bb.setUint64(40, instrumentId, Endian.little);
  bb.setInt64(48, priceScaled, Endian.little);
  bb.setInt32(56, timeInForce, Endian.little);
  bb.setUint8(60, latin1.encode(orderTypeAscii.substring(0, 1))[0]);
  base.setRange(61, 69, _asciiPad(originatingTrader8, 8));
  // Liquidity provider (69–76): BOP specifies null — use binary zeros, not spaces.
  base.setRange(69, 77, Uint8List(8));
  bb.setUint8(77, 0);
  base.setRange(78, 96, _asciiPad(clientTrader18, 18));
  base.setRange(96, 126, _asciiPad(instrumentSymbol30, 30));
  bb.setUint8(126, orderQualifiers & 0xff);
  bb.setUint32(127, legTwo, Endian.little);
  bb.setUint32(131, legOne, Endian.little);

  final ext = _futuresEnterOrderExtended65(
    displayQty: displayQty,
    referencePriceScaled: referencePriceScaled,
    reportingCodes: reportingCodes,
    stopPriceScaled: stopPriceScaled,
    account18: account18,
    senderLocation4: senderLocation4,
    smpCode: smpCode,
    expiryTimeNs: expiryTimeNs,
  );

  final innerBody = Uint8List(base.lengthInBytes + ext.lengthInBytes);
  innerBody.setRange(0, base.lengthInBytes, base);
  innerBody.setRange(base.lengthInBytes, innerBody.lengthInBytes, ext);

  return _fragmentWithLittleEndianLen(innerBody);
}

Uint8List _replaceOrderExtended63({
  required int displayQty,
  required int referencePriceScaled,
  required int reportingCodes,
  required int stopPriceScaled,
  required int timeInForce,
  required String account18,
  required String senderLocation4,
  required int smpCode,
  required int expiryTimeNs,
}) {
  // Table 39: display @95, …, TIF @120, Account @124, Sender @142, SMP @146, Expiry @150 (offsets in full Replace body).
  const extLen = 63;
  final ext = Uint8List(extLen);
  final ex = ByteData.sublistView(ext);
  ex.setUint64(0, displayQty, Endian.little);
  ex.setInt64(8, referencePriceScaled, Endian.little);
  ex.setUint8(16, reportingCodes & 0xff);
  ex.setInt64(17, stopPriceScaled, Endian.little);
  ex.setUint32(25, timeInForce & 0xffffffff, Endian.little);
  ext.setRange(29, 47, _asciiPad(account18, 18));
  ext.setRange(47, 51, _asciiPad(senderLocation4, 4));
  ex.setUint32(51, smpCode & 0xffffffff, Endian.little);
  ex.setUint64(55, expiryTimeNs, Endian.little);
  return ext;
}

/// Futures extended **client Cancel** (BOP Table 36 + 37): type **`X`**, order id `@1–30`,
/// reserved `@31–40`, sender `@41–44`, client trader `@45–62`. Server **`C`** ack is parsed separately.
Uint8List encodeCancelOrderFuturesExtended({
  required String orderToCancel30,
  required String senderLocation4,
  required String clientTrader18,
}) {
  const innerLen = 63;
  final body = Uint8List(innerLen);
  body[0] = 0x58;
  body.setRange(1, 31, _asciiPad(orderToCancel30, 30));
  // 31–40 reserved (zeros).
  body.setRange(41, 45, _asciiPad(senderLocation4, 4));
  body.setRange(45, 63, _asciiPad(clientTrader18, 18));
  return _fragmentWithLittleEndianLen(body);
}

/// Futures extended **Replace** (BOP Tables 38 + 39): `U` `@0`, existing id `@1–30`, replacement id `@31–60`,
/// qty `@61`, price `@69`, client trader `@77–94`, then 63‑byte extended section from `@95`.
Uint8List encodeReplaceOrderFuturesExtended({
  required String orderToReplace30,
  required String newClientOrderId30,
  required int qty,
  required int priceScaled,
  required int timeInForce,
  required String clientTrader18,
  required int reportingCodes,
  required String account18,
  required String senderLocation4,
  required int smpCode,
  int displayQty = 0,
  int referencePriceScaled = 0,
  int stopPriceScaled = 0,
  int expiryTimeNs = 0,
}) {
  const baseLen = 95;
  final base = Uint8List(baseLen);
  final bd = ByteData.sublistView(base);
  bd.setUint8(0, 0x55);
  base.setRange(1, 31, _asciiPad(orderToReplace30, 30));
  base.setRange(31, 61, _asciiPad(newClientOrderId30, 30));
  bd.setUint64(61, qty, Endian.little);
  bd.setInt64(69, priceScaled, Endian.little);
  base.setRange(77, 95, _asciiPad(clientTrader18, 18));

  final ext = _replaceOrderExtended63(
    displayQty: displayQty,
    referencePriceScaled: referencePriceScaled,
    reportingCodes: reportingCodes,
    stopPriceScaled: stopPriceScaled,
    timeInForce: timeInForce,
    account18: account18,
    senderLocation4: senderLocation4,
    smpCode: smpCode,
    expiryTimeNs: expiryTimeNs,
  );

  final innerBody = Uint8List(baseLen + ext.lengthInBytes);
  innerBody.setRange(0, baseLen, base);
  innerBody.setRange(baseLen, innerBody.lengthInBytes, ext);
  return _fragmentWithLittleEndianLen(innerBody);
}

Uint8List encodeLoginFrame({
  required String user8,
  required String password10,
  required String session10,
  required int seq,
}) {
  final pay = Uint8List(1 + 8 + 10 + 10 + 8);
  final bd = ByteData.sublistView(pay);
  bd.setUint8(0, 0x4c);
  pay.setRange(1, 9, _asciiPad(user8, 8));
  pay.setRange(9, 19, _asciiPad(password10, 10));
  pay.setRange(19, 29, _asciiPad(session10, 10));
  bd.setUint64(29, seq, Endian.little);
  return packRawFrame(pay);
}

Uint8List encodeHeartbeat() {
  final one = Uint8List(1)..[0] = 0x52;
  return packRawFrame(one);
}

Uint8List encodeAccountRequest({required String trader8}) {
  final inner = Uint8List(1 + 1 + 8);
  inner[0] = 0x54;
  inner[1] = 0x01;
  inner.setRange(2, 10, _asciiPad(trader8, 8));
  return packTransport('U', inner);
}
