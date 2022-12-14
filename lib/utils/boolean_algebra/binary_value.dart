import 'package:proof_map/exceptions/invalid_argument_exception.dart';
import 'package:proof_map/extensions/string_extension.dart';
import 'package:proof_map/utils/messages.dart' as messages;

enum BinaryValue { one, zero, dontCare }

extension BinaryValueRepresentation on BinaryValue {
  /// Returns 1 if the binaryValue is BinaryValue.one,
  /// 0 if it is BinaryValue.zero
  /// and x if it is BinaryValue.redundant
  String get representation {
    switch (this) {
      case BinaryValue.one:
        return "1";
      case BinaryValue.zero:
        return "0";
      case BinaryValue.dontCare:
        return "-";
      default:
        return "?";
    }
  }

  /// Converts an integer value to a binary value, with number of bits specified
  /// by the `numberOfBits` argument. </br>
  /// Throws InvalidArgumentException if the integer provides is larger than the
  /// number of bits required to represent it in binary.
  static Iterable<BinaryValue> fromInteger(int integer, int numberOfBits) {
    if (integer > (1 << numberOfBits) - 1) {
      throw InvalidArgumentException(messages
          .mintermBinaryRepresentationOverflow
          .format([(1 << numberOfBits) - 1, integer]));
    }
    List<BinaryValue> binaryRepresentation =
        List.filled(numberOfBits, BinaryValue.zero);

    for (int i = numberOfBits - 1; i >= 0; i--) {
      binaryRepresentation[i] =
          integer % 2 == 0 ? BinaryValue.zero : BinaryValue.one;
      integer ~/= 2;
    }

    return binaryRepresentation;
  }
}
