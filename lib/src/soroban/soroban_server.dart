// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'soroban_auth.dart';
import '../xdr/xdr_data_entry.dart';
import '../xdr/xdr_ledger.dart';
import '../transaction.dart';
import '../requests/request_builder.dart';
import '../xdr/xdr_contract.dart';
import '../xdr/xdr_data_io.dart';
import '../xdr/xdr_type.dart';
import '../util.dart';
import '../xdr/xdr_operation.dart';
import '../xdr/xdr_transaction.dart';

/// This class helps you to connect to a local or remote soroban rpc server
/// and send requests to the server. It parses the results and provides
/// corresponding response objects.
class SorobanServer {
  bool enableLogging = false;
  bool acknowledgeExperimental = false;

  String _serverUrl;
  late Map<String, String> _headers;
  final _dio = dio.Dio();
  Map<String, dynamic> _experimentalErr = {
    'error': {'code': -1, 'message': 'acknowledgeExperimental flag not set'}
  };

  /// Constructor.
  /// Provide the url of the soroban rpc server to initialize this class.
  SorobanServer(this._serverUrl) {
    _headers = {...RequestBuilder.headers};
    _headers.putIfAbsent("Content-Type", () => "application/json");
  }

  /// General node health check request.
  /// See: https://soroban.stellar.org/api/methods/getHealth
  Future<GetHealthResponse> getHealth() async {
    if (!this.acknowledgeExperimental) {
      printExperimentalFlagErr();
      return GetHealthResponse.fromJson(_experimentalErr);
    }

    JsonRpcMethod getHealth = JsonRpcMethod("getHealth");
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getHealth), options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getHealth response: $response");
    }
    return GetHealthResponse.fromJson(response.data);
  }

/*
  /// Fetch a minimal set of current info about a stellar account.
  Future<GetAccountResponse> getAccount(String accountId) async {
    if (!this.acknowledgeExperimental) {
      printExperimentalFlagErr();
      return GetAccountResponse.fromJson(_experimentalErr);
    }

    JsonRpcMethod getAccount =
        JsonRpcMethod("getAccount", args: {'address': accountId});
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getAccount), options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getAccount response: $response");
    }
    return GetAccountResponse.fromJson(response.data);
  }
*/
  /// For reading the current value of ledger entries directly.
  /// Allows you to directly inspect the current state of a contract,
  /// a contract’s code, or any other ledger entry.
  /// This is a backup way to access your contract data which may
  /// not be available via events or simulateTransaction.
  /// To fetch contract wasm byte-code, use the ContractCode ledger entry key.
  /// See: https://soroban.stellar.org/api/methods/getLedgerEntry
  Future<GetLedgerEntryResponse> getLedgerEntry(String base64EncodedKey) async {
    if (!this.acknowledgeExperimental) {
      printExperimentalFlagErr();
      return GetLedgerEntryResponse.fromJson(_experimentalErr);
    }

    JsonRpcMethod getLedgerEntry =
        JsonRpcMethod("getLedgerEntry", args: {'key': base64EncodedKey});
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getLedgerEntry),
        options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getLedgerEntry response: $response");
    }
    return GetLedgerEntryResponse.fromJson(response.data);
  }

  /// General info about the currently configured network.
  /// See: https://soroban.stellar.org/api/methods/getNetwork
  Future<GetNetworkResponse> getNetwork() async {
    if (!this.acknowledgeExperimental) {
      printExperimentalFlagErr();
      return GetNetworkResponse.fromJson(_experimentalErr);
    }

    JsonRpcMethod getNetwork = JsonRpcMethod("getNetwork");
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getNetwork), options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getNetwork response: $response");
    }
    return GetNetworkResponse.fromJson(response.data);
  }

  /// Submit a trial contract invocation to get back return values,
  /// expected ledger footprint, and expected costs.
  /// See: https://soroban.stellar.org/api/methods/simulateTransaction
  Future<SimulateTransactionResponse> simulateTransaction(
      Transaction transaction) async {
    if (!this.acknowledgeExperimental) {
      printExperimentalFlagErr();
      return SimulateTransactionResponse.fromJson(_experimentalErr);
    }

    String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();

    JsonRpcMethod getAccount =
        JsonRpcMethod("simulateTransaction", args: transactionEnvelopeXdr);
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getAccount), options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("simulateTransaction response: $response");
    }
    return SimulateTransactionResponse.fromJson(response.data);
  }

  /// Submit a real transaction to the stellar network.
  /// This is the only way to make changes “on-chain”.
  /// Unlike Horizon, this does not wait for transaction completion.
  /// It simply validates and enqueues the transaction.
  /// Clients should call getTransactionStatus to learn about
  /// transaction success/failure.
  /// This supports all transactions, not only smart contract-related transactions.
  /// See: https://soroban.stellar.org/api/methods/sendTransaction
  Future<SendTransactionResponse> sendTransaction(
      Transaction transaction) async {
    if (!this.acknowledgeExperimental) {
      printExperimentalFlagErr();
      return SendTransactionResponse.fromJson(_experimentalErr);
    }

    String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();

    JsonRpcMethod getAccount =
        JsonRpcMethod("sendTransaction", args: transactionEnvelopeXdr);
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getAccount), options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("sendTransaction response: $response");
    }
    return SendTransactionResponse.fromJson(response.data);
  }

  /// Clients will poll this to tell when the transaction has been completed.
  /// See: https://soroban.stellar.org/api/methods/getTransaction
  Future<GetTransactionResponse> getTransaction(String transactionHash) async {
    if (!this.acknowledgeExperimental) {
      printExperimentalFlagErr();
      return GetTransactionResponse.fromJson(_experimentalErr);
    }

    JsonRpcMethod getTransactionStatus =
        JsonRpcMethod("getTransaction", args: transactionHash);
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getTransactionStatus),
        options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getTransaction response: $response");
    }
    return GetTransactionResponse.fromJson(response.data);
  }

  /// Clients can request a filtered list of events emitted by a given ledger range.
  /// Soroban-RPC will support querying within a maximum 24 hours of recent ledgers.
  /// Note, this could be used by the client to only prompt a refresh when there is a new ledger with relevant events.
  /// It should also be used by backend Dapp components to "ingest" events into their own database for querying and serving.
  /// If making multiple requests, clients should deduplicate any events received, based on the event's unique id field.
  /// This prevents double-processing in the case of duplicate events being received.
  /// By default soroban-rpc retains the most recent 24 hours of events.
  /// See: https://soroban.stellar.org/api/methods/getEvents
  Future<GetEventsResponse> getEvents(GetEventsRequest request) async {
    if (!this.acknowledgeExperimental) {
      printExperimentalFlagErr();
      return GetEventsResponse.fromJson(_experimentalErr);
    }

    JsonRpcMethod getEvents =
        JsonRpcMethod("getEvents", args: request.getRequestArgs());
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getEvents), options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getEvents response: $response");
    }
    return GetEventsResponse.fromJson(response.data);
  }

  /// Helper method to get the nonce for a given accountId for the contract
  /// specified by the contractId.
  /// Used for contract auth.
  Future<int> getNonce(String accountId, String contractId) async {
    XdrLedgerKey ledgerKey = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA);
    ledgerKey.contractID = XdrHash(Util.hexToBytes(contractId));
    Address address = Address.forAccountId(accountId);
    XdrSCVal nonceKeyVal = XdrSCVal.forNonceKeyWithAddress(address);
    ledgerKey.contractDataKey = nonceKeyVal;
    GetLedgerEntryResponse response =
        await getLedgerEntry(ledgerKey.toBase64EncodedXdrString());
    if (!response.isErrorResponse &&
        response.ledgerEntryDataXdr != null &&
        response.ledgerEntryDataXdr!.contractData != null) {
      XdrSCVal val = response.ledgerEntryDataXdr!.contractData!.val;
      if (val.u64 != null) {
        return val.u64!.uint64;
      }
    }
    return 0;
  }

  printExperimentalFlagErr() {
    print("Error: acknowledgeExperimental flag not set");
  }
}

/// Abstract class for soroban rpc responses.
abstract class SorobanRpcResponse {
  Map<String, dynamic>
      jsonResponse; // JSON response received from the rpc server
  SorobanRpcErrorResponse? error;
  SorobanRpcResponse(this.jsonResponse);
  bool get isErrorResponse => error != null;
}

/// General node health check response.
/// See: https://soroban.stellar.org/api/methods/getHealth
class GetHealthResponse extends SorobanRpcResponse {
  /// Health status e.g. "healthy"
  String? status;
  static const String HEALTHY = "healthy";

  GetHealthResponse(Map<String, dynamic> jsonResponse) : super(jsonResponse);

  factory GetHealthResponse.fromJson(Map<String, dynamic> json) {
    GetHealthResponse response = GetHealthResponse(json);
    if (json['result'] != null) {
      response.status = json['result']['status'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// See: https://soroban.stellar.org/api/methods/getLatestLedger
class GetLatestLedgerResponse extends SorobanRpcResponse {
  /// hash of the latest ledger as a hex-encoded string.
  String? id;

  /// Stellar Core protocol version associated with the latest ledger.
  String? protocolVersion;

  /// Sequence number of the latest ledger.
  String? sequence;

  GetLatestLedgerResponse(Map<String, dynamic> jsonResponse)
      : super(jsonResponse);

  factory GetLatestLedgerResponse.fromJson(Map<String, dynamic> json) {
    GetLatestLedgerResponse response = GetLatestLedgerResponse(json);
    if (json['result'] != null) {
      response.id = json['result']['id'];
      response.protocolVersion = json['result']['protocolVersion'];
      response.sequence = json['result']['sequence'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// Error response.
class SorobanRpcErrorResponse {
  Map<String, dynamic>
      jsonResponse; // JSON response received from the rpc server
  String? code; // error code
  String? message;
  Map<String, dynamic>? data;

  SorobanRpcErrorResponse(this.jsonResponse);

  factory SorobanRpcErrorResponse.fromJson(Map<String, dynamic> json) {
    SorobanRpcErrorResponse response = SorobanRpcErrorResponse(json);
    if (json['error'] != null) {
      var jErrCode = json['error']['code'];
      if (jErrCode != null) {
        response.code = jErrCode.toString();
      }
      response.message = json['error']['message'];
      response.data = json['error']['data'];
    }
    return response;
  }
}

/*
/// Response for fetching current info about a stellar account.
class GetAccountResponse extends SorobanRpcResponse
    with TransactionBuilderAccount {
  /// Account Id of the account
  String? _id;

  /// Current sequence number of the account
  int? _sequenceNumber;

  GetAccountResponse(Map<String, dynamic> jsonResponse) : super(jsonResponse);

  bool get accountMissing => error?.code == "-32600" ? true : false;

  factory GetAccountResponse.fromJson(Map<String, dynamic> json) {
    GetAccountResponse response = GetAccountResponse(json);
    if (json['result'] != null) {
      response._id = json['result']['id'];
      response._sequenceNumber = int.parse(json['result']['sequence']);
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }

  @override
  String get accountId =>
      _id != null ? _id! : throw Exception("response has no account id");

  @override
  void incrementSequenceNumber() {
    if (_sequenceNumber != null) {
      _sequenceNumber = _sequenceNumber! + 1;
    }
  }

  @override
  int get incrementedSequenceNumber => _sequenceNumber != null
      ? _sequenceNumber! + 1
      : throw Exception("response has no sequence number");

  @override
  MuxedAccount get muxedAccount => _id != null
      ? MuxedAccount(_id!, null)
      : throw Exception("response has no muxed account");

  @override
  int get sequenceNumber => _sequenceNumber != null
      ? _sequenceNumber!
      : throw Exception("response has no sequence number");
}
*/

/// Response when reading the current values of ledger entries.
/// See: https://soroban.stellar.org/api/methods/getLedgerEntry
class GetLedgerEntryResponse extends SorobanRpcResponse {
  /// The current value of the given ledger entry  (serialized in a base64 string)
  String? ledgerEntryData;

  /// The ledger number of the last time this entry was updated (optional)
  String? lastModifiedLedgerSeq;

  /// The current latest ledger observed by the node when this response was generated.
  String? latestLedger;

  XdrLedgerEntryData? get ledgerEntryDataXdr => ledgerEntryData == null
      ? null
      : XdrLedgerEntryData.fromBase64EncodedXdrString(ledgerEntryData!);

  GetLedgerEntryResponse(Map<String, dynamic> jsonResponse)
      : super(jsonResponse);

  factory GetLedgerEntryResponse.fromJson(Map<String, dynamic> json) {
    GetLedgerEntryResponse response = GetLedgerEntryResponse(json);

    if (json['result'] != null) {
      response.ledgerEntryData = json['result']['xdr'];
      response.lastModifiedLedgerSeq = json['result']['lastModifiedLedgerSeq'];
      response.latestLedger = json['result']['latestLedger'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// See: https://soroban.stellar.org/api/methods/getNetwork
class GetNetworkResponse extends SorobanRpcResponse {
  String? friendbotUrl;
  String? passphrase;
  String? protocolVersion;

  GetNetworkResponse(Map<String, dynamic> jsonResponse) : super(jsonResponse);

  factory GetNetworkResponse.fromJson(Map<String, dynamic> json) {
    GetNetworkResponse response = GetNetworkResponse(json);
    if (json['result'] != null) {
      response.friendbotUrl = json['result']['friendbotUrl'];
      response.passphrase = json['result']['passphrase'];
      response.protocolVersion = json['result']['protocolVersion'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// Response that will be received when submitting a trial contract invocation.
/// See: https://soroban.stellar.org/api/methods/simulateTransaction
class SimulateTransactionResponse extends SorobanRpcResponse {
  /// Stringified-number of the current latest ledger observed by the node when this response was generated.
  String? latestLedger;

  /// If error is present then results will not be in the response
  /// There will be one results object for each operation in the transaction.
  List<SimulateTransactionResult>? results;

  /// Information about the fees expected, instructions used, etc.
  SimulateTransactionCost? cost;

  SimulateTransactionResponse(Map<String, dynamic> jsonResponse)
      : super(jsonResponse);

  /// (optional) only present if the transaction failed.
  /// This field will include more details from stellar-core about why the invoke host function call failed.
  String? resultError;

  factory SimulateTransactionResponse.fromJson(Map<String, dynamic> json) {
    SimulateTransactionResponse response = SimulateTransactionResponse(json);
    if (json['result'] != null) {
      response.resultError = json['result']['error'];
      if (json['result']['results'] != null) {
        response.results = List<SimulateTransactionResult>.from(json['result']
                ['results']
            .map((e) => SimulateTransactionResult.fromJson(e)));
      }
      response.latestLedger = json['result']['latestLedger'];
      if (json['result']['cost'] != null) {
        response.cost =
            SimulateTransactionCost.fromJson(json['result']['cost']);
      }
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }

  Footprint? getFootprint() {
    if (results != null && results!.length > 0) {
      return results![0].footprint;
    }
    return null;
  }

  Footprint? get footprint => getFootprint();

  List<ContractAuth>? getContractAuth() {
    if (results != null && results!.length > 0 && results![0].auth != null) {
      List<ContractAuth> result = List<ContractAuth>.empty(growable: true);
      for (String nextAuthXdr in results![0].auth!) {
        result.add(ContractAuth.fromBase64EncodedXdr(nextAuthXdr));
      }
      return result;
    }
    return null;
  }

  List<ContractAuth>? get contractAuth => getContractAuth();
}

/// Used as a part of simulate transaction.
/// See: https://soroban.stellar.org/api/methods/simulateTransaction
class SimulateTransactionResult {
  /// (optional) Only present on success. xdr-encoded return value of the contract call operation.
  String? xdr;

  /// The contract data ledger keys which were accessed when simulating this operation. (XdrLedgerFootprint serialized in a base64 string)
  Footprint? footprint;

  /// Per-address authorizations recorded when simulating this operation. (an array of XdrContractAuth serialized base64 strings)
  List<String>? auth;

  /// Events emitted during the contract invocation. (an array of XdrDiagnosticEvent serialized base64 strings)
  List<String>? events;

  SimulateTransactionResult(this.xdr, this.footprint, this.auth, this.events);

  factory SimulateTransactionResult.fromJson(Map<String, dynamic> json) {
    String xdr = json['xdr'];
    Footprint? footprint;
    String? footStr = json['footprint'];
    if (footStr != null && footStr.trim() != "") {
      footprint =
          Footprint(XdrLedgerFootprint.fromBase64EncodedXdrString(footStr));
    }
    List<String>? auth;
    if (json['auth'] != null) {
      auth = List<String>.from(json['auth'].map((e) => e));
    }

    List<String>? events;
    if (json['events'] != null) {
      auth = List<String>.from(json['events'].map((e) => e));
    }
    return SimulateTransactionResult(xdr, footprint, auth, events);
  }

  ///  Only present on success. Return value of the contract call operation.
  XdrSCVal? get value =>
      xdr != null ? XdrSCVal.fromBase64EncodedXdrString(xdr!) : null;
}

/// Response when submitting a real transaction to the stellar network.
/// See: https://soroban.stellar.org/api/methods/sendTransaction
class SendTransactionResponse extends SorobanRpcResponse {
  /// represents the status value returned by stellar-core when an error occurred from submitting a transaction
  static const String STATUS_ERROR = "ERROR";

  /// represents the status value returned by stellar-core when a transaction has been accepted for processing
  static const String STATUS_PENDING = "PENDING";

  /// represents the status value returned by stellar-core when a submitted transaction is a duplicate
  static const String STATUS_DUPLICATE = "DUPLICATE";

  /// represents the status value returned by stellar-core when a submitted transaction was not included in the
  static const String STATUS_TRY_AGAIN_LATER = "TRY_AGAIN_LATER";

  /// The transaction hash (in an hex-encoded string).
  String? hash;

  /// The current status of the transaction by hash, one of: ERROR, PENDING, DUPLICATE, TRY_AGAIN_LATER
  /// ERROR represents the status value returned by stellar-core when an error occurred from submitting a transaction
  /// PENDING represents the status value returned by stellar-core when a transaction has been accepted for processing
  /// DUPLICATE represents the status value returned by stellar-core when a submitted transaction is a duplicate
  /// TRY_AGAIN_LATER represents the status value returned by stellar-core when a submitted transaction was not included in the
  /// previous 4 ledgers and get banned for being added in the next few ledgers.
  String? status;

  /// The latest ledger known to Soroban-RPC at the time it handled the sendTransaction() request.
  String? latestLedger;

  /// The unix timestamp of the close time of the latest ledger known to Soroban-RPC at the time it handled the sendTransaction() request.
  String? latestLedgerCloseTime;

  ///  (optional) If the transaction status is ERROR, this will be a base64 encoded string of the raw TransactionResult XDR struct containing details on why stellar-core rejected the transaction.
  String? errorResultXdr;

  SendTransactionResponse(Map<String, dynamic> jsonResponse)
      : super(jsonResponse);

  factory SendTransactionResponse.fromJson(Map<String, dynamic> json) {
    SendTransactionResponse response = SendTransactionResponse(json);
    if (json['result'] != null) {
      response.hash = json['result']['hash'];
      response.status = json['result']['status'];
      response.latestLedger = json['result']['latestLedger'];
      response.latestLedgerCloseTime = json['result']['latestLedgerCloseTime'];
      response.errorResultXdr = json['result']['errorResultXdr'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/*
/// Internal error used within some of the responses.
class GetTransactionError extends SorobanRpcResponse {
  /// Short unique string representing the type of error
  String? code;

  /// Human friendly summary of the error
  String? message;

  /// (optional) More data related to the error if available
  Map<String, dynamic>? data;

  GetTransactionError(Map<String, dynamic> jsonResponse)
      : super(jsonResponse);

  factory GetTransactionError.fromJson(Map<String, dynamic> json) {
    GetTransactionError response = GetTransactionError(json);
    response.code = json['code'];
    response.message = json['message'];
    response.data = json['data'];
    return response;
  }
}
*/

/// Response when polling the rpc server to find out if a transaction has been
/// completed.
/// See https://soroban.stellar.org/api/methods/getTransaction
class GetTransactionResponse extends SorobanRpcResponse {
  static const String STATUS_SUCCESS = "SUCCESS";
  static const String STATUS_NOT_FOUND = "NOT_FOUND";
  static const String STATUS_FAILED = "FAILED";

  /// The current status of the transaction by hash, one of: SUCCESS, NOT_FOUND, FAILED
  String? status;

  /// The latest ledger known to Soroban-RPC at the time it handled the getTransaction() request.
  String? latestLedger;

  /// The unix timestamp of the close time of the latest ledger known to Soroban-RPC at the time it handled the getTransaction() request.
  String? latestLedgerCloseTime;

  /// The oldest ledger ingested by Soroban-RPC at the time it handled the getTransaction() request.
  String? oldestLedger;

  /// The unix timestamp of the close time of the oldest ledger ingested by Soroban-RPC at the time it handled the getTransaction() request.
  String? oldestLedgerCloseTime;

  /// (optional) The sequence of the ledger which included the transaction. This field is only present if status is SUCCESS or FAILED.
  String? ledger;

  ///  (optional) The unix timestamp of when the transaction was included in the ledger. This field is only present if status is SUCCESS or FAILED.
  String? createdAt;

  /// (optional) The index of the transaction among all transactions included in the ledger. This field is only present if status is SUCCESS or FAILED.
  int? applicationOrder;

  /// (optional) Indicates whether the transaction was fee bumped. This field is only present if status is SUCCESS or FAILED.
  bool? feeBump;

  /// (optional) A base64 encoded string of the raw TransactionEnvelope XDR struct for this transaction.
  String? envelopeXdr;

  /// (optional) A base64 encoded string of the raw TransactionResult XDR struct for this transaction. This field is only present if status is SUCCESS or FAILED.
  String? resultXdr;

  /// (optional) A base64 encoded string of the raw TransactionMeta XDR struct for this transaction.
  String? resultMetaXdr;

  GetTransactionResponse(Map<String, dynamic> jsonResponse)
      : super(jsonResponse);

  factory GetTransactionResponse.fromJson(Map<String, dynamic> json) {
    GetTransactionResponse response = GetTransactionResponse(json);
    if (json['result'] != null) {
      response.status = json['result']['status'];
      response.latestLedger = json['result']['latestLedger'];
      response.latestLedgerCloseTime = json['result']['latestLedgerCloseTime'];
      response.oldestLedger = json['result']['oldestLedger'];
      response.oldestLedgerCloseTime = json['result']['oldestLedgerCloseTime'];
      response.ledger = json['result']['ledger'];
      response.createdAt = json['result']['createdAt'];
      response.applicationOrder =
          convertToInt(json['result']['applicationOrder']);
      response.feeBump = json['result']['feeBump'];
      response.envelopeXdr = json['result']['envelopeXdr'];
      response.resultXdr = json['result']['resultXdr'];
      response.resultMetaXdr = json['result']['resultMetaXdr'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }

  static int? convertToInt(var src) {
    if (src == null) return null;
    if (src is int) return src;
    if (src is String) return int.parse(src);
    throw Exception("Not integer");
  }

  /// Extracts the wasm id from the response if the transaction installed a contract
  String? getWasmId() {
    return _getBinHex();
  }

  /// Extracts the contract is from the response if the transaction created a contract
  String? getContractId() {
    return _getBinHex();
  }

  /// Extracts the result value from the first entry on success
  XdrSCVal? getResultValue() {
    if (error != null || status != STATUS_SUCCESS || resultMetaXdr == null) {
      return null;
    }
    
    XdrTransactionMeta meta =
        XdrTransactionMeta.fromBase64EncodedXdrString(resultMetaXdr!);
    List<XdrOperationResult>? results = meta.v3?.txResult.result.results; // :)
    if (results == null || results.length == 0) {
      return null;
    }
    return results.first.tr?.invokeHostFunctionResult?.success; // ;)
  }

  String? _getBinHex() {
    XdrDataValue? bin = _getBin();
    if (bin != null) {
      return Util.bytesToHex(bin.dataValue);
    }
    return null;
  }

  XdrDataValue? _getBin() {
    XdrSCVal? xdrVal = getResultValue();
    return xdrVal?.bytes;
  }
}

/// Holds the request parameters for getEvents.
/// See: https://soroban.stellar.org/api/methods/getEvents
class GetEventsRequest {
  /// Stringified ledger sequence number to fetch events after (inclusive).
  /// The getEvents method will return an error if startLedger is less than the oldest ledger stored in this node,
  /// or greater than the latest ledger seen by this node.
  /// If a cursor is included in the request, startLedger must be omitted.
  String? startLedger;

  /// List of filters for the returned events. Events matching any of the filters are included.
  /// To match a filter, an event must match both a contractId and a topic.
  /// Maximum 5 filters are allowed per request.
  List<EventFilter>? filters;

  /// Pagination
  List<PaginationOptions>? paginationOptions;

  GetEventsRequest(this.startLedger, {this.filters, this.paginationOptions});

  Map<String, dynamic> getRequestArgs() {
    var map = <String, dynamic>{};
    if (startLedger != null) {
      map['startLedger'] = startLedger;
    }
    if (filters != null) {
      List<Map<String, dynamic>> values =
          List<Map<String, dynamic>>.empty(growable: true);
      for (EventFilter filter in filters!) {
        values.add(filter.getRequestArgs());
      }
      map['filters'] = values;
    }
    if (paginationOptions != null) {
      List<Map<String, dynamic>> values =
          List<Map<String, dynamic>>.empty(growable: true);
      for (PaginationOptions options in paginationOptions!) {
        values.add(options.getRequestArgs());
      }
      map['pagination'] = values;
    }
    return map;
  }
}

/// Event filter for the getEvents request.
/// See: https://soroban.stellar.org/api/methods/getEvents
class EventFilter {
  /// (optional) A comma separated list of event types (system, contract, or diagnostic)
  /// used to filter events. If omitted, all event types are included.
  String? type;

  /// (optional) List of contract ids to query for events.
  /// If omitted, return events for all contracts.
  /// Maximum 5 contract IDs are allowed per request.
  List<String>? contractIds;

  /// (optional) List of topic filters. If omitted, query for all events.
  /// If multiple filters are specified, events will be included if they match any of the filters.
  /// Maximum 5 filters are allowed per request.
  List<TopicFilter>? topics;

  EventFilter({this.type, this.contractIds, this.topics});

  Map<String, dynamic> getRequestArgs() {
    var map = <String, dynamic>{};
    if (type != null) {
      map['type'] = type!;
    }
    if (contractIds != null) {
      map['contractIds'] = contractIds!;
    }
    if (topics != null) {
      List<Map<String, dynamic>> values =
          List<Map<String, dynamic>>.empty(growable: true);
      for (TopicFilter filter in topics!) {
        values.add(filter.getRequestArgs());
      }
      map['topics'] = values;
    }
    return map;
  }
}

/// Part of the getEvents request parameters.
/// https://soroban.stellar.org/api/methods/getEvents
/// TODO: update this!
class TopicFilter {
  String? wildcard;
  List<XdrSCVal>? scVal;

  TopicFilter({this.wildcard, this.scVal});

  Map<String, dynamic> getRequestArgs() {
    var map = <String, dynamic>{};
    if (wildcard != null) {
      map['wildcard'] = wildcard!;
    }
    if (scVal != null) {
      List<String> xdrValues = List<String>.empty(growable: true);
      for (XdrSCVal value in scVal!) {
        xdrValues.add(value.toBase64EncodedXdrString());
      }
      map['scval'] = xdrValues;
    }
    return map;
  }
}

class PaginationOptions {
  String? cursor;
  int? limit;

  PaginationOptions({this.cursor, this.limit});

  Map<String, dynamic> getRequestArgs() {
    var map = <String, dynamic>{};
    if (cursor != null) {
      map['cursor'] = cursor!;
    }
    if (limit != null) {
      map['limit'] = limit!;
    }
    return map;
  }
}

class GetEventsResponse extends SorobanRpcResponse {
  String? latestLedger;

  /// If error is present then results will not be in the response
  List<EventInfo>? events;

  GetEventsResponse(Map<String, dynamic> jsonResponse) : super(jsonResponse);

  factory GetEventsResponse.fromJson(Map<String, dynamic> json) {
    GetEventsResponse response = GetEventsResponse(json);
    if (json['result'] != null) {
      if (json['result']['events'] != null) {
        response.events = List<EventInfo>.from(
            json['result']['events'].map((e) => EventInfo.fromJson(e)));
      }
      response.latestLedger = json['result']['latestLedger'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

class EventInfo {
  String type;
  String ledger;
  String ledgerCloseAt;
  String contractId;
  String id;
  String paginationToken;
  List<String> topic;
  EventInfoValue value;

  EventInfo(this.type, this.ledger, this.ledgerCloseAt, this.contractId,
      this.id, this.paginationToken, this.topic, this.value);

  factory EventInfo.fromJson(Map<String, dynamic> json) {
    List<String> topic = List<String>.from(json['topic'].map((e) => e));
    EventInfoValue value = EventInfoValue.fromJson(json['value']);
    return EventInfo(json['type'], json['ledger'], json['ledgerClosedAt'],
        json['contractId'], json['id'], json['pagingToken'], topic, value);
  }
}

class EventInfoValue {
  String xdr;

  EventInfoValue(this.xdr);

  factory EventInfoValue.fromJson(Map<String, dynamic> json) {
    return EventInfoValue(json['xdr']);
  }
}
/*
/// Used as a part of get transaction status and send transaction.
class TransactionStatusResult {
  /// xdr-encoded return value of the contract call
  String xdr;
  TransactionStatusResult(this.xdr);

  factory TransactionStatusResult.fromJson(Map<String, dynamic> json) =>
      TransactionStatusResult(json['xdr']);

  XdrSCVal get value => XdrSCVal.fromBase64EncodedXdrString(xdr);
}*/

/// Information about the fees expected, instructions used, etc.
class SimulateTransactionCost {
  /// Stringified-number of the total cpu instructions consumed by this transaction
  String cpuInsns;

  /// Stringified-number of the total memory bytes allocated by this transaction
  String memBytes;

  SimulateTransactionCost(this.cpuInsns, this.memBytes);

  factory SimulateTransactionCost.fromJson(Map<String, dynamic> json) =>
      SimulateTransactionCost(json['cpuInsns'], json['memBytes']);
}

/// Footprint received when simulating a transaction.
/// Contains utility functions.
class Footprint {
  XdrLedgerFootprint xdrFootprint;
  Footprint(this.xdrFootprint);

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrLedgerFootprint.encode(xdrOutputStream, this.xdrFootprint);
    return base64Encode(xdrOutputStream.bytes);
  }

  static Footprint fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return Footprint(XdrLedgerFootprint.decode(XdrDataInputStream(bytes)));
  }

  /// if found, returns the contract code ledger key as base64 encoded xdr string
  String? getContractCodeLedgerKey() {
    return _findFirstKeyOfType(XdrLedgerEntryType.CONTRACT_CODE)
        ?.toBase64EncodedXdrString();
  }

  /// if found, returns the contract code ledger key as XdrLedgerKey
  XdrLedgerKey? getContractCodeXdrLedgerKey() {
    return _findFirstKeyOfType(XdrLedgerEntryType.CONTRACT_CODE);
  }

  /// if found, returns the contract data ledger key as base64 encoded xdr string
  String? getContractDataLedgerKey() {
    return _findFirstKeyOfType(XdrLedgerEntryType.CONTRACT_DATA)
        ?.toBase64EncodedXdrString();
  }

  /// if found, returns the contract code ledger key as XdrLedgerKey
  XdrLedgerKey? getContractDataXdrLedgerKey() {
    return _findFirstKeyOfType(XdrLedgerEntryType.CONTRACT_DATA);
  }

  XdrLedgerKey? _findFirstKeyOfType(XdrLedgerEntryType type) {
    for (XdrLedgerKey key in xdrFootprint.readOnly) {
      if (key.discriminant == type) {
        return key;
      }
    }
    for (XdrLedgerKey key in xdrFootprint.readWrite) {
      if (key.discriminant == type) {
        return key;
      }
    }
    return null;
  }
}

/// Holds name and args of a method request for JSON-RPC v2
///
/// Initialize with a string method name and list or map of params
/// if [notify] is true, output format will be as 'notification'
/// [id] is an int automatically generated from hashCode
class JsonRpcMethod {
  /// [method] is the name of the method at the server
  String method;

  /// [args] is arguments to the method at the server. May be Map or List or nil
  Object? args;

  /// Do we care about the response value?
  bool notify = false;

  /// private. It's auto-generated, but we hold on to it in case we need it
  /// more than once. id is null for notifications.
  int? _id;

  /// constructor
  JsonRpcMethod(this.method, {this.args, this.notify = false});

  /// create id from hashcode when first requested
  dynamic get id {
    _id ??= hashCode;
    return notify ? null : _id;
  }

  /// output the map representation of this instance for processing into JSON
  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map = {'jsonrpc': '2.0', 'method': method};
    if (args != null) {
      map['params'] = (args is List || args is Map) ? args : [args];
    }
    if (!notify) map['id'] = id;
    return map;
  }

  @override
  String toString() => 'JsonRpcMethod: ${toJson()}';
}
