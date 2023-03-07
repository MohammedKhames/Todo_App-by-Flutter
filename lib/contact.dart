import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();

  await Hive.openBox('todo');
  await Hive.openBox('darkMode');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: Hive.box('darkMode').listenable(),
        builder: (_, Box box, __) {
          var dark = box.get('isDark', defaultValue: false);
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: !dark ? ThemeMode.light : ThemeMode.dark,
            darkTheme: ThemeData.dark(),
            home: HomePage(),
          );
        });
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _todoCollection = Hive.box('todo');
  final _modeCollection = Hive.box('darkMode');

  List records = [];

  var titleController = TextEditingController();
  var descController = TextEditingController();
  var isDark;
  @override
  void initState() {
    isDark = _modeCollection.get('isDark', defaultValue: false);

    _refresh();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hive Example'),
        actions: [
          Switch(
              value: isDark,
              onChanged: (value) {
                if (isDark) {
                  isDark = false;
                } else {
                  isDark = true;
                }
                _modeCollection.put('isDark', isDark);
                setState(() {});
              })
        ],
      ),
      body: records.isEmpty
          ? Center(
              child: Text(
                'No Data',
                style: TextStyle(fontSize: 28),
              ),
            )
          : ListView.builder(
              itemCount: records.length,
              itemBuilder: (_, index) {
                return Card(
                  color: Colors.orange,
                  margin: EdgeInsets.all(10),
                  elevation: 3,
                  child: ListTile(
                    onTap: () {
                      _showDialog(context, key: index);
                    },
                    title: Text(records[index]['title']),
                    subtitle: Text(records[index]['desc']),
                    trailing: IconButton(
                      onPressed: () {
                        // _todoCollection.clear();
                        // setState(() {});
                        _deleteTodo(index);
                      },
                      icon: Icon(Icons.delete),
                    ),
                  ),
                );
              }),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showDialog(context);
          },
          child: Icon(Icons.add)),
    );
  }

  void _createTodo(Map<String, dynamic> newTodo) async {
    await _todoCollection.add(newTodo);
    _refresh();
  }

  void _refresh() {
    final data = _todoCollection.values.toList();

    setState(() {
      records = data;
    });
  }

  void _deleteTodo(int index) async {
    await _todoCollection.deleteAt(index);
    _refresh();
  }

  void _updateTodo(int key, Map<String, dynamic> updatedTodo) async {
    await _todoCollection.putAt(key, updatedTodo);
    _refresh();
  }

  void _showDialog(BuildContext context, {int? key}) {
    if (key != null) {
      titleController.text = records[key]['title'];
      descController.text = records[key]['desc'];
    }

    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: key != null ? Text('Update Todo') : Text('Add Todo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(hintText: 'Title'),
                ),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(hintText: 'Describtion'),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(primary: Colors.red),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (key != null) {
                    _updateTodo(key, {
                      'title': titleController.text,
                      'desc': descController.text
                    });
                  } else {
                    _createTodo({
                      'title': titleController.text,
                      'desc': descController.text
                    });
                  }

                  titleController.text = '';
                  descController.text = '';
                  Navigator.pop(context);
                },
                child: key != null ? Text('Edit') : Text('Create New'),
              ),
            ],
          );
        });
  }
}
