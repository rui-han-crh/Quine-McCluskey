import 'dart:developer';

import 'package:proof_map/app_object.dart';
import 'package:proof_map/exceptions/key_not_found_exception.dart';
import 'package:proof_map/extensions/string_extension.dart';
import 'package:proof_map/model/implicant.dart';
import 'package:proof_map/model/joined_term.dart';
import 'package:proof_map/model/literal_term.dart';
import 'package:proof_map/model/normal_form.dart';
import 'package:proof_map/model/term.dart';
import 'package:proof_map/utils/boolean_algebra/binary_value.dart';
import 'package:proof_map/utils/messages.dart';

class Answer extends AppObject {
  final DisjunctiveNormalForm? _disjunctiveNormalForm;
  final ConjunctiveNormalForm? _conjunctiveNormalForm;
  final Term? _simplestForm;

  final Map<String, LiteralTerm> _headerStringToTermsMap;
  final Iterable<LiteralTerm> headers;

  String get disjunctiveNormalFormString =>
      _disjunctiveNormalForm?.toString() ?? "";

  String get conjuctiveNormalFormString =>
      _conjunctiveNormalForm?.toString() ?? "";

  String get simplestForm => _simplestForm?.postulate ?? "";

  /// Creates a table of string values representing the truth table for the
  /// minterms of the Sum-of-Products expression. The header values specify the
  /// column order of this table.
  Iterable<Iterable<String>> mintermTableValues(
      [Iterable<String>? headerValues]) {
    if (_disjunctiveNormalForm == null) {
      return [];
    }

    List<LiteralTerm> headerTermsOrder = headerValues == null
        ? headers.toList()
        : [
            for (String value in headerValues)
              _headerStringToTermsMap.containsKey(value)
                  ? _headerStringToTermsMap[value]!
                  : throw KeyNotFoundException(keyDoesNotExistInMap
                      .format([value, "headerStringToTermsMap"]))
          ];

    List<Implicant> implicants = _disjunctiveNormalForm!
        .getMinterms(headerTermsOrder)
        .toList()
      ..sort((a, b) => a.binaryString.compareTo(b.binaryString));

    return implicants
        .map((e) => e.mintermBinaryRepresentation.map((e) => e.representation));
  }

  Iterable<Iterable<String>> maxtermTableValues(
      [Iterable<String>? headerValues]) {
    if (_conjunctiveNormalForm == null) {
      return [];
    }

    List<LiteralTerm> headerTermsOrder = headerValues == null
        ? headers.toList()
        : [
            for (String value in headerValues)
              _headerStringToTermsMap.containsKey(value)
                  ? _headerStringToTermsMap[value]!
                  : throw KeyNotFoundException(keyDoesNotExistInMap
                      .format([value, "headerStringToTermsMap"]))
          ];

    List<Implicant> implicants = _conjunctiveNormalForm!
        .getMaxterms(headerTermsOrder)
        .toList()
      ..sort((a, b) => b.binaryString.compareTo(a.binaryString));

    return implicants
        .map((e) => e.maxtermBinaryRepresentation.map((e) => e.representation));
  }

  /// Retrieves the essential prime implicants corresponding to the largest
  /// groups of minterms in the sum of products
  Iterable<Implicant> getMintermEssentialPrimeImplicants(
      [Iterable<String>? headerValues]) {
    if (_disjunctiveNormalForm == null) {
      return [];
    }

    List<LiteralTerm> headerTermsOrder = headerValues == null
        ? headers.toList()
        : verifyHeaderTermsOrder(headerValues);

    return _disjunctiveNormalForm!
        .getEssentialPrimeImplicants(headerTermsOrder);
  }

  // Retrieves the essential prime implicants corresponding to the largest
  // groups of maxterms in the product of sums
  Iterable<Implicant> getMaxtermEssentialPrimeImplicants(
      [Iterable<String>? headerValues]) {
    if (_conjunctiveNormalForm == null) {
      return [];
    }

    List<LiteralTerm> headerTermsOrder = headerValues == null
        ? headers.toList()
        : verifyHeaderTermsOrder(headerValues);

    return _conjunctiveNormalForm!
        .getEssentialPrimeImplicants(headerTermsOrder);
  }

  List<LiteralTerm> verifyHeaderTermsOrder(Iterable<String> headerValues) {
    return [
      for (String value in headerValues)
        _headerStringToTermsMap.containsKey(value)
            ? _headerStringToTermsMap[value]!
            : throw KeyNotFoundException(
                keyDoesNotExistInMap.format([value, "headerStringToTermsMap"]))
    ];
  }

  // I removed the non-nullable assertion operator because as a hack to allow
  // computation to speed up
  Answer(
      {DisjunctiveNormalForm? disjunctiveNormalForm,
      ConjunctiveNormalForm? conjunctiveNormalForm,
      required Term simplestForm})
      : _disjunctiveNormalForm = disjunctiveNormalForm,
        _conjunctiveNormalForm = conjunctiveNormalForm,
        _simplestForm = simplestForm is JoinedTerm
            ? simplestForm.sort((a, b) => a.postulate.compareTo(b.postulate))
            : simplestForm,
        _headerStringToTermsMap = _createHeaderStringToTermsMap(simplestForm),
        headers = simplestForm.getUniqueTerms();

  const Answer.empty()
      : _disjunctiveNormalForm = null,
        _conjunctiveNormalForm = null,
        _simplestForm = null,
        _headerStringToTermsMap = const {},
        headers = const [];

  Answer._(
      {required DisjunctiveNormalForm disjunctiveNormalForm,
      required ConjunctiveNormalForm conjunctiveNormalForm,
      required Term simplestForm,
      required Map<String, LiteralTerm> headerStringToTermsMap,
      required this.headers})
      : _disjunctiveNormalForm = disjunctiveNormalForm,
        _conjunctiveNormalForm = conjunctiveNormalForm,
        _simplestForm = simplestForm,
        _headerStringToTermsMap = headerStringToTermsMap;

  Answer withHeaders(List<String> headers) {
    return Answer._(
        disjunctiveNormalForm: _disjunctiveNormalForm!,
        conjunctiveNormalForm: _conjunctiveNormalForm!,
        simplestForm: _simplestForm!,
        headerStringToTermsMap: _headerStringToTermsMap,
        headers: headers.map((e) => _headerStringToTermsMap[e]!));
  }
}

// Traverses all the terms in the simplest form and creates a map of the header
// strings to the terms. This is used to create the truth table for the minterms
// and maxterms.
Map<String, LiteralTerm> _createHeaderStringToTermsMap(Term simplestForm) {
  Iterable<LiteralTerm> uniqueTerms = simplestForm.getUniqueTerms();

  Map<String, LiteralTerm> stringToTermsMap = {};

  for (LiteralTerm term in uniqueTerms) {
    stringToTermsMap[term.postulate] = term;
    LiteralTerm negated = term.negate();
    stringToTermsMap[negated.postulate] = negated;
  }

  return stringToTermsMap;
}
