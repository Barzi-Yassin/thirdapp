import 'dart:html';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SqLiteApp());
}

class SqLiteApp extends StatefulWidget {
  const SqLiteApp({Key? key}) : super(key: key);

  @override
  State<SqLiteApp> createState() => _SqLiteAppState();
}

class _SqLiteAppState extends State<SqLiteApp> {
  int? selectedId;
  final TextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          // leading: Text('input >'),
          title: TextField(
            controller: TextController,
          ),
        ),
        body: Center(
          child: FutureBuilder<List<Grocery>>(
              future: DatabaseHelper.instance.getGroceries(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<Grocery>> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: Text('Loading...'));
                }
                return snapshot.data!.isEmpty
                    ? const Center(child: Text('No Groceries in List.'))
                    : ListView(
                        children: snapshot.data!.map((grocery) {
                          return Center(
                            child: Card(
                              color: selectedId == grocery.id
                                  ? Colors.white70
                                  : Colors.white ,
                              child: ListTile(
                                title: Text(grocery.name),
                                onLongPress: () {
                                  setState(() {
                                    DatabaseHelper.instance.remove(grocery.id!);
                                  });
                                },
                                onTap: () {
                                  setState(() {
                                    if (selectedId == null) {
                                    TextController.text = grocery.name;
                                    selectedId = grocery.id;
                                    } else {
                                    TextController.text = '';
                                    selectedId = null;
                                    }                                    
                                  });
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      );
              }),
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.save),
          onPressed: () async {
            selectedId != null
                ? await DatabaseHelper.instance
                    .update(Grocery(id: selectedId, name: TextController.text))
                : await DatabaseHelper.instance.add(
                    Grocery(name: TextController.text),
                  );
            setState(() {
              TextController.clear();
            });
          },
        ),
      ),
    );
  }
}

class Grocery {
  final int? id;
  final String name;

  Grocery({this.id, required this.name});

  factory Grocery.fromMap(Map<String, dynamic> json) => new Grocery(
        id: json['id'],
        name: json['name'],
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'groceries.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE groceries(
          id INTEGER PRIMARY KEY,
          name TEXT
      )
      ''');
  }

  Future<List<Grocery>> getGroceries() async {
    Database db = await instance.database;
    var groceries = await db.query('groceries', orderBy: 'name');
    List<Grocery> groceryList = groceries.isNotEmpty
        ? groceries.map((c) => Grocery.fromMap(c)).toList()
        : [];
    return groceryList;
  }

  Future<int> add(Grocery grocery) async {
    Database db = await instance.database;
    return await db.insert('groceries', grocery.toMap());
  }

  Future<int> remove(int id) async {
    Database db = await instance.database;
    return await db.delete('groceries', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> update(Grocery grocery) async {
    Database db = await instance.database;
    return await db.update('groceries', grocery.toMap(),
        where: "id = ?", whereArgs: [grocery.id]);
  }
}
