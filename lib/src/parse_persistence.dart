import 'package:rapido/rapido.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'dart:async';

class ParsePersistence implements PersistenceProvider {
  final String parseApp;
  final String parseUrl;

  ParsePersistence({this.parseApp, this.parseUrl}) {
    _initializeParse(parseApp, parseUrl);
  }

  @override
  deleteDocument(Document doc) {
    return null;
  }

  @override
  Future loadDocuments(DocumentList documentList,
      {Function onChangedListener}) async {
    ParseResponse apiResponse =
        await ParseObject(documentList.documentType).getAll();

    if (apiResponse.success && apiResponse.result != null) {
      for (ParseObject obj in apiResponse.result) {
        Map<String, dynamic> savedData =
            Map<String, dynamic>.from(obj.getObjectData());
        Map<String, dynamic> newData = {};

        for (String key in savedData.keys) {
          if (key.startsWith("rapido_")) {
            String realKey = key.replaceFirst("rapido_", "_");
            newData[realKey] = savedData[key];
          }
          if (key.endsWith("latlong")) {
            // convert latlongs to the correct type
            Map<String, double> latlongMap = {};
            latlongMap["latitude"] = savedData[key]["latitude"];
            latlongMap["longitude"] = savedData[key]["longitude"];
            newData[key] = latlongMap;

          } else {
            newData[key] = savedData[key];
          }
        }
        Document doc = Document.fromMap(newData,
            persistenceProviders: documentList.persistenceProviders);
        documentList.add(doc);
      }
    }
  }

  @override
  Future<Document> retrieveDocument(String docId) {
    return null;
  }

  @override
  Future<bool> saveDocument(Document doc) {
    ParseObject obj = ParseObject(doc.documentType, debug: true);
    for (String key in doc.keys) {
      String parseKey = key;
      if (key.startsWith("_")) {
        parseKey = "rapido" + parseKey;
      }

      obj.set(parseKey, doc[key]);
    }
    obj.create();
    return null;
  }

  _initializeParse(String parseApp, String parseUrl) {
    Parse().initialize(parseApp, parseUrl, debug: true);
  }
}
