// Copyright 2020 Fynn Freyer
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

double STEUER = 1.19;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AngebotsRechnerApp());
}

class AngebotsRechnerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              tabs: <Widget>[
                Tab(icon: Icon(Icons.functions),),
                Tab(icon: Icon(Icons.list),),
              ],
            ),
            title: Text('Angebotsrechner'),
          ),
          body: TabBarView(
              children: <Widget>[
                EingabeMaske(),
                EintragsAnsicht(),
              ],
          ),
        ),
      ),
    );
  }
}

class EingabeMaske extends StatefulWidget {
  EingabeMaske({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EingabeMaskeState();
}

class _EingabeMaskeState extends State<EingabeMaske> {
  final _formKey = GlobalKey<FormState>();

  final _arbeitszeitController = TextEditingController(text: "0");
  final _anfahrtszeitController = TextEditingController(text: "0");
  final _anfahrtskostenpauschaleController = TextEditingController(text: "0");
  final _materialkostenController = TextEditingController(text: "0");

  final _nameController = TextEditingController();

  FocusNode _focusNodeMaterialkosten;
  FocusNode _focusNodeAnfahrtszeit;
  FocusNode _focusNodeAnfahrtspauschale;
  FocusNode _focusNodeArbeitszeit;

  FocusNode _focusNodeName;

  FocusNode _focusNodeSubmit;

  String _ergebnis = "";



  @override
  void initState(){
    super.initState();

    _focusNodeMaterialkosten = FocusNode(debugLabel: "Materialkosten");
    _focusNodeMaterialkosten.addListener(() {
      _handleNumberFocus(_focusNodeMaterialkosten, _materialkostenController);
    });

    _focusNodeAnfahrtszeit = FocusNode(debugLabel: "Anfahrtszeit");
    _focusNodeAnfahrtszeit.addListener(() {
      _handleNumberFocus(_focusNodeAnfahrtszeit, _anfahrtszeitController);
    });

    _focusNodeAnfahrtspauschale = FocusNode(debugLabel: "Anfahrtspauschale");
    _focusNodeAnfahrtspauschale.addListener(() {
      _handleNumberFocus(_focusNodeAnfahrtspauschale, _anfahrtskostenpauschaleController);
    });

    _focusNodeArbeitszeit = FocusNode(debugLabel: "Arbeitszeit");
    _focusNodeArbeitszeit.addListener(() {
      _handleNumberFocus(_focusNodeArbeitszeit, _arbeitszeitController);
    });

    _focusNodeName = FocusNode(debugLabel: "Name");

    _focusNodeSubmit = FocusNode(debugLabel: "Submit");

  }

  void _handleNumberFocus(FocusNode node, TextEditingController controller) {
    if (node.hasFocus && controller.text == "0") {
      setState(() {
        controller.text = "";
      });
    } else if (!node.hasFocus && controller.text == "") {
      setState(() {
        controller.text = "0";
      });
    }
  }

  @override
  void dispose() {
    _arbeitszeitController.dispose();
    _anfahrtszeitController.dispose();
    _anfahrtskostenpauschaleController.dispose();
    _materialkostenController.dispose();

    _nameController.dispose();


    _focusNodeMaterialkosten.dispose();
    _focusNodeAnfahrtszeit.dispose();
    _focusNodeAnfahrtspauschale.dispose();
    _focusNodeArbeitszeit.dispose();

    _focusNodeName.dispose();

    _focusNodeSubmit.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: <Widget>[
            Text("Anfahrt, Abbau und Abtransport"),
            TextFormField(
                focusNode: _focusNodeAnfahrtszeit,
                controller: _anfahrtszeitController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  NumberTextInputFormatter()
                ],
                validator: _feldValidierer,
                decoration: InputDecoration(
                    labelText: "in Mannstunden",
                    icon: Icon(Icons.transfer_within_a_station))),
            Text("\nOder Anfahrtskostenpauschale"),
            TextFormField(
                focusNode: _focusNodeAnfahrtspauschale,
                controller: _anfahrtskostenpauschaleController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  NumberTextInputFormatter()
                ],
                validator: _feldValidierer,
                decoration: InputDecoration(
                    labelText: "in Euro",
                    icon: Icon(Icons.directions_bus))),
            Text("\nMaterialkosten"),
            TextFormField(
                focusNode: _focusNodeMaterialkosten,
                controller: _materialkostenController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  NumberTextInputFormatter()
                ],
                validator: _feldValidierer,
                decoration: InputDecoration(
                  labelText: "in Euro",
                  icon: Icon(Icons.euro_symbol),
                )),
            Text("\nArbeitsstunden in der Werkstatt"),
            TextFormField(
                focusNode: _focusNodeArbeitszeit,
                controller: _arbeitszeitController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  NumberTextInputFormatter()
                ],
                validator: _feldValidierer,
                decoration: InputDecoration(
                    labelText: "in Mannstunden", icon: Icon(Icons.timer))),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: <Widget>[
                  RaisedButton(
                    focusNode: _focusNodeSubmit,
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        // Process data.
                        print(_anfahrtskostenpauschaleController.text);
                        setState(() {
                          _ergebnis = _kosten(
                              _arbeitszeitController.text,
                              _materialkostenController.text,
                              _anfahrtszeitController.text,
                              _anfahrtskostenpauschaleController.text
                          );
                        });
                      }
                    },
                    child: Text('Aufwand errechnen'),
                  ),
                  Spacer(),
                  RaisedButton(
                    focusNode: _focusNodeSubmit,
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        setState(() {
                          resetForm();
                        });
                      }
                    },
                    child: Text('Löschen'),
                  ),
                ],
              )
            ),
            Text(_ergebnis),
            Text("\n\nName des Kunden"),
            TextFormField(
                focusNode: _focusNodeName,
                controller: _nameController,
                decoration: InputDecoration(
                    icon: Icon(Icons.person))),
            RaisedButton(
              focusNode: _focusNodeSubmit,
              color: Colors.blue,
              onPressed: () async {
                if (_formKey.currentState.validate() && _nameController.text.isNotEmpty) {
                  // Process data.
                  var price = _kosten(
                      _arbeitszeitController.text,
                      _materialkostenController.text,
                      _anfahrtszeitController.text,
                      _anfahrtskostenpauschaleController.text
                  );

                  insertCustomerData(_nameController.text, _anfahrtszeitController.text, _materialkostenController.text, _arbeitszeitController.text, price);
                  setState(() {
                    resetForm();
                  });
                }
              },
              child: Text('Daten speichern'),
            ),
          ],
        ),
      ),
    );
  }

  String _feldValidierer(String value) {
    if (value.isNotEmpty) {
      try {
        double.parse(value.replaceAll(",", "."));
      } on FormatException {
        return 'Eingabe entspricht keiner validen Zahl!';
      }
    }
    return null;
  }

  String _kosten(String arbeitszeitString, String materialkostenString,
      String anfahrtszeitString, String anfahrtskostenpauschaleString) {
    double arbeitszeit = arbeitszeitString.isEmpty ? 0 : double.parse(arbeitszeitString.replaceAll(",", "."));
    double materialkosten = materialkostenString.isEmpty ? 0 :
    double.parse(materialkostenString.replaceAll(",", "."));
    double anfahrtszeit = anfahrtszeitString.isEmpty ? 0 :  double.parse(anfahrtszeitString.replaceAll(",", "."));
    double anfahrtskostenpauschale = anfahrtskostenpauschaleString.isEmpty ? 0 :  double.parse(anfahrtskostenpauschaleString.replaceAll(",", "."));

    return _rechnung(arbeitszeit, materialkosten, anfahrtszeit, anfahrtskostenpauschale)
        .toStringAsFixed(2)
        .replaceAll(".", ",") +
        " €";
  }

  double _rechnung(double arbeitszeit, double materialkosten,
      double anfahrtszeit, double anfahrtskostenpauschale) {

    double preis_netto = (anfahrtszeit * 2 * 60) + arbeitszeit * 60;
    double preis_brutto = (preis_netto * STEUER) + anfahrtskostenpauschale + (materialkosten * 1.1);

    return preis_brutto;
  }


  Future<void> insertCustomerData(name, travel, material, work, price) async {
    Database database = await _futureDB;
    database.insert(
      'customers',
      {'name': name,
        'travel': travel,
        'material': material,
        'work': work,
        'price': price,
        'time': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  void resetForm() {
    _arbeitszeitController.text = "0";
    _materialkostenController.text = "0";
    _anfahrtszeitController.text = "0";
    _anfahrtskostenpauschaleController.text = "0";
    _nameController.text = "";
    _ergebnis = "";
  }
}

class EintragsAnsicht extends StatefulWidget {
  EintragsAnsicht({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EintragsAnsichtState();
}

class _EintragsAnsichtState extends State<EintragsAnsicht> {

  Future<List<Eintrag>>_futureEintraege;


  @override
  void initState() {
    super.initState();

    _futureEintraege = requestEintraege();
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(16.0),
        child: FutureBuilder(
            future: _futureEintraege,
            builder: (context, snapshot) {
              List<Widget> children;
              if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, index) {
                    Eintrag eintrag = snapshot.data[snapshot.data.length-(index+1)];
                    return ListTile(
                      leading: Icon(Icons.list),
                      title: Text(eintrag.name),
                      subtitle: Text(eintrag.price),
                      trailing: Column(
                        children: [
                          Text(eintrag.time.day.toString() + "/" + eintrag.time.month.toString() + "/" + eintrag.time.year.toString()),
                          Text(eintrag.time.hour.toString() + ":" + eintrag.time.minute.toString()),
                        ]
                      ),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                children = <Widget>[
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text('Es gab einen Fehler!\nBitte Screenshot an Fynn schicken!\nError: ${snapshot.error}'),
                  )
                ];
              } else {
                children = <Widget>[
                  SizedBox(
                    child: CircularProgressIndicator(),
                    width: 60,
                    height: 60,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('Lade Daten...'),
                  )
                ];
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: children,
                ),
              );
            }
        )
    );
  }
}



Future<Database> requestDB() async{
  return openDatabase(join(await getDatabasesPath(), 'customers.db'),
    onCreate: (db, version) {
      return db.execute(
        "CREATE TABLE customers(id INTEGER PRIMARY KEY, name TEXT, travel TEXT, material TEXT, work TEXT, price TEXT, time TEXT)",
      );
    },
    version: 1,
  );
}

Future<Database> _futureDB = requestDB();

class Eintrag {
  int id;
  String name, travel, material, work, price;
  DateTime time;

  Eintrag({this.id, this.name, this.travel, this.material, this.work, this.price, this.time});
}

Future<List<Eintrag>> requestEintraege() async {
  final Database db = await _futureDB;

  final List<Map<String, dynamic>> maps = await db.query('customers');

  return List.generate(maps.length, (i) {
    return Eintrag(
      id: maps[i]['id'],
      name: maps[i]['name'],
      travel: maps[i]['travel'],
      material: maps[i]['material'],
      work: maps[i]['work'],
      price: maps[i]['price'],
      time: DateTime.parse(maps[i]['time']),
    );
  });
}


class NumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (RegExp(r"^\d*,?\d?\d?$").hasMatch(newValue.text)) {
      return newValue;
    } else {
      return oldValue;
    }
  }

}