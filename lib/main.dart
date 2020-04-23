import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main(){
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _todoController = TextEditingController();

  List _toDoList = []; //lista que armazena as tarefas
  Map<String, dynamic> _lastRemoved;
  int _lastRemodePos;

  @override
  void initState() { //chamado quando incicializamos o estado da tela
    super.initState();

    _readData().then((data){
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }


  void addToDo(){ //atualiza e mostra o item na tela
   setState(() {
     Map<String, dynamic> newToDo = Map();
     newToDo["title"] = _todoController.text;
     _todoController.text = "";
     newToDo["Ok"] = false;
     _toDoList.add(newToDo);
     _saveData();
   });
  }

  Future<Null> _refresh() async{  // atualizar as tarefas e esperar 1 segundo
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b){
        if(a["Ok"]&& !b["Ok"]) return 1;
        else if(!a["Ok"] && b["Ok"]) return -1;
        else return 0;
      });
      _saveData();
    });
    return null;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded( //pra ocupar o espaço necessário da linha nova tarefa
                  child: TextField(
                    controller: _todoController,
                    decoration: InputDecoration(
                        labelText: "Nova tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)
                    ),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: addToDo,
                )
              ]
            ),
          ),
          Expanded (  //lista
            child: RefreshIndicator(onRefresh: _refresh,
            child: ListView.builder( //permite criar lista
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _toDoList.length, //pegar a quantidade de intens
                itemBuilder: buildItem),
            ),

          )
        ],
      ),
    );
  }

  Widget buildItem(context, index){
    return Dismissible(  //permite arrastar algo pra direita
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),  //para saber qual atividade está deslizando
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white,),
        ),  // alinha no canto esquerdo
      ),
      direction: DismissDirection.startToEnd,  // coloca a direção para arrastar
      child: CheckboxListTile( // retorna o Ok ao lado da lista
          title: Text(_toDoList[index]["title"]),
          value: (_toDoList[index]["Ok"]),
          secondary: CircleAvatar(
            child: Icon(_toDoList[index]["Ok"]?
            Icons.check : Icons.error),),
          onChanged: (c){
            print(c);
            setState(() {  // atualiza a lista c o novo estado
              _toDoList[index] ["Ok"] = c;
              _saveData();
            });
          }//chama uma função quando o status muda,
      ),
      onDismissed: (direction){
        setState(() {    //atualiza os dados na tela
         _lastRemoved = Map.from(_toDoList[index]);
         _lastRemodePos = index;
         _toDoList.removeAt(index);

          _saveData();

          final snac = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
            action: SnackBarAction(label: "Desfazer",
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemodePos, _lastRemoved);
                  _saveData();
                 });
                }),
                    duration:(Duration(seconds: 3)),
               );
          Scaffold.of(context).showSnackBar(snac);
         });
      },
    );
  }

  Future<File> _getFile() async {  //função para obter arquivo, async é pq demora, n é instantaneo
    final directory = await getApplicationDocumentsDirectory(); //local q pode armazenar os doc
    return File("${directory.path}/data.json"); //pega o caminho e junta com tarefas.json
  }

  Future<File> _saveData() async{ //salvar algum dado no arquivo
    String data = json.encode(_toDoList); //pega a lista transforma em json e armazena em uma string
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async{  //ler os dados do arquivo
    try {
      final file =  await _getFile();

      return file.readAsString();
    } catch(e){
      return null;
    }
  }
}



