// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_expenses/widgets/adaptive_flat_button.dart';

class NewTransaction extends StatefulWidget {
  final Function addTx;

  NewTransaction(this.addTx);

  @override
  State<NewTransaction> createState() => _NewTransactionState();
}

class _NewTransactionState extends State<NewTransaction> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate;
  var _isLoading = false;

  Future<void> _submitData() async {
    setState(() {
      _isLoading = true;
    });

    if (_amountController.text.isEmpty) {
      return;
    }

    final enteredTitle = _titleController.text;
    final enteredAmount = double.parse(_amountController.text);

    if (enteredTitle.isEmpty || enteredAmount <= 0 || _selectedDate == null) {
      return;
    }
    try {
      await widget.addTx(
        enteredTitle,
        enteredAmount,
        _selectedDate,
      );
    } catch (error) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
            title: const Text('An Error Occured'),
            content: const Text("Something Went wrong."),
            actions: <Widget>[
              FlatButton(
                child: const Text('Okay'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              )
            ]),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pop(); // closes the top most screen that is opened
    }
  }

  void _presentDatePicker() {
    showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2019),
            lastDate: DateTime.now())
        .then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : SingleChildScrollView(
            child: Card(
              elevation: 5,
              child: Container(
                padding: EdgeInsets.only(
                    top: 10,
                    left: 10,
                    right: 10,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    TextField(
                      decoration: const InputDecoration(labelText: 'Title'),
                      controller: _titleController,
                      onSubmitted: (_) => _submitData(),
                      // onChanged: (val) {
                      //   titleInput = val;
                      // },
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Amount'),
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) => _submitData(),
                      // onChanged: (val) {
                      //   amountInput = val;
                      // },
                    ),
                    Container(
                      height: 70,
                      child: Row(children: <Widget>[
                        Expanded(
                          child: Text(
                            _selectedDate == null
                                ? 'No Date Chosen'
                                : "Picked Date: ${DateFormat.yMd().format(_selectedDate)}",
                          ),
                        ),
                        AdaptiveFlatButton("Choose Date", _presentDatePicker)
                      ]),
                    ),
                    RaisedButton(
                      child: const Text('Add Transaction'),
                      color: Theme.of(context).primaryColor,
                      textColor: Theme.of(context).textTheme.button?.color,
                      onPressed: _submitData,
                    )
                  ],
                ),
              ),
            ),
          );
  }
}
