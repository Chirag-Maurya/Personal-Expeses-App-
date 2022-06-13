// ignore_for_file: avoid_unnecessary_containers, deprecated_member_use

import 'dart:io';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:personal_expenses/models/transaction.dart';
import 'package:personal_expenses/widgets/chart.dart';
import 'package:personal_expenses/widgets/new_transaction.dart';
import 'package:personal_expenses/widgets/transaction_list.dart';

void main() {
  // WidgetsFlutterBinding.ensureInitialized();
  // SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  //   DeviceOrientation.portraitDown,
  //   ]
  // );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Expenses',
      theme: ThemeData(
          primarySwatch: Colors.purple,
          errorColor: Colors.red,
          accentColor: Colors.amber,
          fontFamily: 'Quicksand',
          textTheme: ThemeData.light().textTheme.copyWith(
                headline6: const TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                button: const TextStyle(color: Colors.white),
              ),
          appBarTheme: AppBarTheme(
            textTheme: ThemeData.light().textTheme.copyWith(
                    headline6: const TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )),
          )),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _isInit = true;
  var _isLoading = false;

  Future<void> fetchAndSetTransactions() async {
    final url = Uri.parse(
        'https://personal-expenses-6f6a0-default-rtdb.firebaseio.com/transactions.json');
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      final List<Transaction> loadedTransactions = [];
      extractedData.forEach((txId, txData) {
        loadedTransactions.add(Transaction(
          id: txId,
          title: txData['title'],
          amount: txData['amount'],
          date: DateTime.parse(txData['date']),
        ));
      });
      _userTransactions = loadedTransactions;
    } catch (error) {
      throw error;
    }
  }

  List<Transaction> _userTransactions = [
    // Transaction(
    //     id: 't1', title: 'New Shoes', amount: 69.99, date: DateTime.now()),
    // Transaction(
    //     id: 't2',
    //     title: 'Weekly Groceries',
    //     amount: 16.53,
    //     date: DateTime.now()),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });
      fetchAndSetTransactions().then((_) {
        setState(() {
          _isLoading = false;
        });
      });
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  bool _ShowChart = false;

  List<Transaction> get _recentTransactions {
    return _userTransactions.where((tx) {
      return tx.date.isAfter(
        DateTime.now().subtract(
          const Duration(days: 7),
        ),
      );
    }).toList();
  }

  Future<void> _addNewTransaction(
      String txTitle, double txAmount, DateTime chosenDate) async {
    final url = Uri.parse(
        'https://personal-expenses-6f6a0-default-rtdb.firebaseio.com/transactions.json');
    try {
      final response = await http.post(
        url,
        body: json.encode({
          'title': txTitle,
          'amount': txAmount,
          'date': chosenDate.toString(),
        }),
      );
      final newTx = Transaction(
        title: txTitle,
        amount: txAmount,
        date: chosenDate,
        id: json.decode(response.body)['name'],
      );

      setState(() {
        _userTransactions.add(newTx);
      });
    } catch (error) {
      throw error;
    }
  }

  void _startAddNewtransaction(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      builder: (bCtx) {
        return GestureDetector(
          onTap: () {},
          child: NewTransaction(_addNewTransaction),
          behavior: HitTestBehavior.opaque,
        );
      },
    );
  }

  Future<void> _deleteTransaction(String id) async {
    final url = Uri.parse(
        'https://personal-expenses-6f6a0-default-rtdb.firebaseio.com/transactions/$id.json');
    final existingTxIndex = _userTransactions.indexWhere((tx) => tx.id == id);
    var existingTx = _userTransactions[existingTxIndex];

    setState(() {
      _userTransactions.removeAt(existingTxIndex);
    });

    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _userTransactions.insert(existingTxIndex, existingTx);
      throw const HttpException('Could not delete Transaction');
    }
    existingTx = null;
  }

  Future<void> _refreshTransactions() async {
    fetchAndSetTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    final PreferredSizeWidget appBar = Platform.isIOS
        ? CupertinoNavigationBar(
            middle: Text('Personal Expenses'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                GestureDetector(
                  child: Icon(CupertinoIcons.add),
                  onTap: () => _startAddNewtransaction(context),
                )
              ],
            ))
        : AppBar(
            title: const Text('Personal Expenses'),
            actions: <Widget>[
              IconButton(
                onPressed: () => _startAddNewtransaction(context),
                icon: const Icon(Icons.add),
              )
            ],
          );

    final txListWidget = Container(
        height: (mediaQuery.size.height -
                appBar.preferredSize.height -
                mediaQuery.padding.top) *
            0.7,
        child: TransactionList(
            _userTransactions, _deleteTransaction, _refreshTransactions));

    final pageBody = _isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : SafeArea(
            child: SingleChildScrollView(
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // ignore: sized_box_for_whitespace
                  if (isLandscape)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('Show Chart',
                            style: Theme.of(context).textTheme.headline6),
                        Switch.adaptive(
                          activeColor: Theme.of(context).accentColor,
                          value: _ShowChart,
                          onChanged: (val) {
                            setState(() {
                              _ShowChart = val;
                            });
                          },
                        ),
                      ],
                    ),
                  if (_userTransactions == null || !isLandscape)
                    Container(
                      height: (mediaQuery.size.height -
                              appBar.preferredSize.height -
                              mediaQuery.padding.top) *
                          0.3,
                      child: Chart(
                        _recentTransactions,
                      ),
                    ),
                  if (!isLandscape) txListWidget,
                  if (isLandscape)
                    _ShowChart
                        ? Container(
                            height: (mediaQuery.size.height -
                                    appBar.preferredSize.height -
                                    mediaQuery.padding.top) *
                                0.7,
                            child: Chart(
                              _recentTransactions,
                            ),
                          )
                        : txListWidget
                ],
              ),
            ),
          );
    return Platform.isIOS
        ? CupertinoPageScaffold(
            child: pageBody,
            navigationBar: appBar,
          )
        : Scaffold(
            appBar: appBar,
            body: pageBody,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: Platform.isIOS
                ? Container()
                : FloatingActionButton(
                    child: const Icon(Icons.add),
                    onPressed: () => _startAddNewtransaction(context),
                  ),
          );
  }
}
