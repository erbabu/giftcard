import 'dart:math';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//qr_flutter: ^3.0.1
import 'package:qr_flutter/qr_flutter.dart';
//flutter_barcode_scanner: ^0.1.7
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
//cloud_firestore: ^0.13.0
//firebase_core: ^0.4.4
import 'package:cloud_firestore/cloud_firestore.dart';
//brotherlabelprintdart: ^0.1.0
//import 'package:brotherlabelprintdart/pair.dart';
import 'package:brotherlabelprintdart/print.dart';
import 'package:brotherlabelprintdart/printerModel.dart';
import 'package:brotherlabelprintdart/templateLabel.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _chosenValue = '0';
  String _cardnumber = 'For new number, click -->';
  String _scanBarcode = 'No value read';
  String _output = '';
  int _amount = 0;
  String _associatednumber = '';
  TextEditingController _textController = new TextEditingController();

  //scan the QR code
  Future<void> scanQR() async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", true, ScanMode.QR);
      print(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
    setState(() {
      _scanBarcode = barcodeScanRes;
    });
  }

  //print gift card
  fnPrintGiftCard() async {
    List<TemplateLabel> labels = List<TemplateLabel>();
    //labels.add(TemplateLabel(5, ["testcard1", "25", "qrcard2874628"]));
    labels.add(
        TemplateLabel(1, ["", _scanBarcode, _amount.toString(), _scanBarcode]));
    String result;
    try {
      result = await Brotherlabelprintdart.printLabelFromTemplate(
          "192.168.1.30", PrinterModel.QL_820NWB, labels);
      PrintMessage('Gift card printed');
    } catch (e) {
      result = "An error occured : $e";
    }
  }

  //refresh gift card number
  fnRefreshGCardNumber() {
    String newGCard = utils.CreateRandomDigitsString(19);
    setState(() {
      _cardnumber = newGCard;
      _scanBarcode = newGCard;
    });
  }

  //transaction amount
  TransAmount(String amt) {
    print(amt);
    if (amt == '') {
      this._amount = 0;
    } else {
      this._amount = int.parse(amt);
    }
    return;
  }

  //card associated number
  CardAssociatedNumber(String associatednumber) {
    print('Associated Number: ' + associatednumber);
    setState(() {
      _associatednumber = associatednumber;
    });
    return;
  }

  //validate transaction amount
  bool isValidTransAmount() {
    String msg = '';
    print('istranamt: ' + _amount.toString());
    if (_amount == 0) {
      msg = 'Transaction amount is not valid';
      print(msg);
      setState(() {
        _output = msg;
      });
      return false;
    } else {
      return true;
    }
  }

  //validate scanned qr value
  bool isValidQRvalue() {
    String msg = '';
    print('qr value: ' + _scanBarcode);
    if (_scanBarcode == 'No value read') {
      msg = 'Card number is not valid';
      PrintMessage(msg);
      return false;
    } else {
      return true;
    }
  }

  //print output message
  void PrintMessage(String msg) {
    print(msg);
    setState(() {
      _output = msg;
    });
    return;
  }

  //create a new gift card if there is a value and it's not already there
  void fnCreateCard() {
    if (!isValidTransAmount()) {
      return;
    } else {
      DocumentReference documentReference =
          Firestore.instance.collection('BH2020GCard').document(_scanBarcode);
      documentReference.get().then((datasnapshot) {
        if (!datasnapshot.exists) {
          Map<String, dynamic> GCard = {
            'CardNumber': _scanBarcode,
            'AssociatedNumber': _associatednumber,
            'Balance': _amount,
            'Active': true
          };
          documentReference.setData(GCard).whenComplete(() {
            PrintMessage('GCard Created.');
          });
        } else {
          Map<String, dynamic> GCard = {
            'CardNumber': datasnapshot.data['CardNumber'],
            'AssociatedNumber': _associatednumber,
            'Balance': datasnapshot.data['Balance'],
            'Active': datasnapshot.data['Active']
          };
          documentReference.setData(GCard).whenComplete(() {
            PrintMessage('Gift card already exists, updated ref number.');
          });
        }
      });
      return;
    }
  }

//get balance
  fnGetBalance() {
    if (!isValidQRvalue()) {
      return;
    } else {
      String msg = '';
      DocumentReference documentReference =
          Firestore.instance.collection('BH2020GCard').document(_scanBarcode);
      documentReference.get().then((datasnapshot) {
        if (datasnapshot.exists) {
          PrintMessage('Ref: ' +
              datasnapshot.data['AssociatedNumber'] +
              ' : Bal- \$' +
              datasnapshot.data['Balance'].toString() +
              ' : Active - ' +
              datasnapshot.data['Active'].toString());
        } else {
          PrintMessage('Scanned Gift card is invalid.');
        }
      });
      return;
    }
  }

  //pay from card
  fnPayFromCard() {
    if (!isValidTransAmount()) {
      return;
    } else {
      if (!isValidQRvalue()) {
        return;
      } else {
        DocumentReference documentReference =
            Firestore.instance.collection('BH2020GCard').document(_scanBarcode);
        documentReference.get().then((datasnapshot) {
          if (datasnapshot.exists) {
            if ((datasnapshot.data['Active']) &&
                (datasnapshot.data['Balance'] >= _amount)) {
              Map<String, dynamic> GCard = {
                'CardNumber': datasnapshot.data['CardNumber'],
                'AssociatedNumber': datasnapshot.data['AssociatedNumber'],
                'Balance': (datasnapshot.data['Balance'] - _amount),
                'Active': true
              };
              documentReference.setData(GCard).whenComplete(() {
                PrintMessage('GCard deducted.');
              });
            } else {
              PrintMessage('Gift card is not active / no balance.');
            }
          } else {
            PrintMessage('Scanned Gift card is invalid.');
          }
        });
        return;
      }
    }
  }

  //load to card
  fnLoadCard() {
    if (!isValidTransAmount()) {
      return;
    } else {
      if (!isValidQRvalue()) {
        return;
      } else {
        DocumentReference documentReference =
            Firestore.instance.collection('BH2020GCard').document(_scanBarcode);
        documentReference.get().then((datasnapshot) {
          if (datasnapshot.exists) {
            if (datasnapshot.data['Active']) {
              Map<String, dynamic> GCard = {
                'CardNumber': datasnapshot.data['CardNumber'],
                'AssociatedNumber': datasnapshot.data['AssociatedNumber'],
                'Balance': (datasnapshot.data['Balance'] + _amount),
                'Active': true
              };
              documentReference.setData(GCard).whenComplete(() {
                PrintMessage('GCard Loaded.');
              });
            } else {
              PrintMessage('Scanned Gift card is not active.');
            }
          } else {
            PrintMessage('Scanned Gift card is invalid.');
          }
        });
        return;
      }
    }
  }

  //reactivate card
  fnEnableCard() {
    if (!isValidQRvalue()) {
      return;
    } else {
      DocumentReference documentReference =
          Firestore.instance.collection('BH2020GCard').document(_scanBarcode);
      documentReference.get().then((datasnapshot) {
        if (datasnapshot.exists) {
          if (!datasnapshot.data['Active']) {
            Map<String, dynamic> GCard = {
              'CardNumber': datasnapshot.data['CardNumber'],
              'AssociatedNumber': datasnapshot.data['AssociatedNumber'],
              'Balance': datasnapshot.data['Balance'],
              'Active': true
            };
            documentReference.setData(GCard).whenComplete(() {
              PrintMessage('GCard activated.');
            });
          } else {
            PrintMessage('Scanned Gift card is already active.');
          }
        } else {
          PrintMessage('Scanned Gift card is invalid.');
        }
      });
      return;
    }
  }

  //delete card
  fnDeleteCard() {
    if (!isValidQRvalue()) {
      return;
    } else {
      DocumentReference documentReference =
          Firestore.instance.collection('BH2020GCard').document(_scanBarcode);
      documentReference.get().then((datasnapshot) {
        if (datasnapshot.exists) {
          if (datasnapshot.data['Active']) {
            Map<String, dynamic> GCard = {
              'CardNumber': datasnapshot.data['CardNumber'],
              'AssociatedNumber': datasnapshot.data['AssociatedNumber'],
              'Balance': datasnapshot.data['Balance'],
              'Active': false
            };
            documentReference.setData(GCard).whenComplete(() {
              PrintMessage('GCard marked deleted.');
            });
          } else {
            PrintMessage('Scanned Gift card is not active.');
          }
        } else {
          PrintMessage('Scanned Gift card is invalid.');
        }
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.teal,
        appBar: AppBar(
          backgroundColor: Colors.blue,
          centerTitle: true,
          title: Text(
            'Gift Card - BH2020',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 10,
                ),
                //image and company name
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('images/CloudStore.jpg'),
                    ),
                    Text(
                      'Cloud Store',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                //gift card number
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      _cardnumber,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                      ),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Container(
                      height: 30,
                      width: 50,
                      child: RaisedButton(
                        color: Colors.white,
                        onPressed: () => fnRefreshGCardNumber(),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textColor: Colors.white,
                        child: Image.asset(
                          'images/refresh-button.png',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                //gift card amount and QR code
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Gift Card: \$ ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    DropdownButton<String>(
                      value: _chosenValue,
                      underline: Container(), // this is the magic
                      items: <String>[
                        '0',
                        '5',
                        '10',
                        '15',
                        '20',
                        '25',
                        '50',
                        '100'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(color: Colors.red, fontSize: 30),
                          ),
                        );
                      }).toList(),
                      onChanged: (String value) {
                        print('amount: ' + value);
                        setState(() {
                          _chosenValue = value;
                          _amount = int.parse(value);
                          _textController = TextEditingController(text: value);
                        });
                      },
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Container(
                      color: Colors.white,
                      height: 80.0,
                      width: 80.0,
                      margin: EdgeInsets.all(5),
                      //padding: EdgeInsets.all(5),
                      child: QrImage(
                        data: _cardnumber,
                        version: QrVersions.auto,
                        size: 80,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 5,
                ),
                //print card
                Container(
                  height: 30,
                  width: 300,
                  child: RaisedButton(
                      onPressed: () => fnPrintGiftCard(),
                      color: Colors.blue,
                      textColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: Text("Print Gift Card")),
                ),
                SizedBox(
                  height: 5,
                ),
                //read QR code
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    RaisedButton(
                        onPressed: () => scanQR(),
                        color: Colors.blue,
                        textColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        child: Text("Read GCard QR")),
                    SizedBox(
                      width: 10,
                    ),
                    Text('$_scanBarcode',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        )),
                  ],
                ),
                SizedBox(
                  height: 5,
                ),
//Transaction amount and message
                Row(
                  children: <Widget>[
                    Container(
                      height: 60,
                      width: 80,
                      child: Padding(
                        padding: EdgeInsets.all(5.0),
                        child: TextFormField(
                          controller: _textController,
                          onChanged: (String amt) {
                            TransAmount(amt);
                          },
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                              labelText: 'USD',
                              fillColor: Colors.white,
                              labelStyle: TextStyle(
                                  color: Colors.red,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.blue, width: 2.0))),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text('$_output',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.yellowAccent,
                        )),
                  ],
                ),
                SizedBox(
                  height: 5,
                ),
//Associated number
                Row(
                  children: <Widget>[
                    Text(
                      'Ref Number: ',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Container(
                      width: 200,
                      height: 50,
                      child: Padding(
                        padding: EdgeInsets.all(5.0),
                        child: TextField(
                          onChanged: (String associatednumber) {
                            CardAssociatedNumber(associatednumber);
                          },
                          textAlign: TextAlign.start,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 5,
                ),
                //Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Container(
                      width: 120,
                      child: RaisedButton(
                        color: Colors.blue,
                        onPressed: () => fnGetBalance(),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textColor: Colors.white,
                        child: Text('Check Bal.'),
                      ),
                    ),
                    Container(
                        width: 120,
                        child: RaisedButton(
                          color: Colors.blue,
                          onPressed: () => fnLoadCard(),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          textColor: Colors.white,
                          child: Text('Load GCard'),
                        )),
                    Container(
                      width: 120,
                      child: RaisedButton(
                        color: Colors.blue,
                        onPressed: () => fnPayFromCard(),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textColor: Colors.white,
                        child: Text('Pay by GCard'),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
//Action buttons for create, load and delete card
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Container(
                      width: 120,
                      child: RaisedButton(
                        color: Colors.blue,
                        onPressed: () => fnCreateCard(),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textColor: Colors.white,
                        child: Text('Create GCard'),
                      ),
                    ),
                    Container(
                        width: 120,
                        child: RaisedButton(
                          color: Colors.blue,
                          onPressed: () => fnEnableCard(),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          textColor: Colors.white,
                          child: Text('Enable GCard'),
                        )),
                    Container(
                      width: 120,
                      child: RaisedButton(
                        color: Colors.blue,
                        onPressed: () => fnDeleteCard(),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textColor: Colors.white,
                        child: Text('Delete GCard'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class utils {
  static final Random _random = Random.secure();

  static String CreateRandomDigitsString([int length = 19]) {
    var values = List<int>.generate(length, (i) => _random.nextInt(10));

    return values.join();
  }

  static String CreateCryptoRandomString([int length = 32]) {
    var values = List<int>.generate(length, (i) => _random.nextInt(256));

    return base64Url.encode(values);
  }
}
