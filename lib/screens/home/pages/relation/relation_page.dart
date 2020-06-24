import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mentorship_client/extensions/context.dart';
import 'package:mentorship_client/extensions/datetime.dart';
import 'package:mentorship_client/remote/models/task.dart';
import 'package:mentorship_client/remote/requests/task_request.dart';
import 'package:mentorship_client/screens/home/pages/relation/bloc/bloc.dart';
import 'package:mentorship_client/widgets/bold_text.dart';
import 'package:mentorship_client/widgets/loading_indicator.dart';

class RelationPage extends StatefulWidget {
  @override
  _RelationPageState createState() => _RelationPageState();
}

class _RelationPageState extends State<RelationPage> {
  Completer<void> _refreshCompleter;

  @override
  void initState() {
    super.initState();
    _refreshCompleter = Completer<void>();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: TabBar(
          labelColor: Theme.of(context).accentColor,
          tabs: [
            Tab(text: "Details".toUpperCase()),
            Tab(text: "Tasks".toUpperCase()),
          ],
        ),
        body: BlocConsumer<RelationPageBloc, RelationPageState>(listener: (context, state) {
          if (state.message != null && state is RelationPageSuccess) {
            context.showSnackBar(state.message);
            Navigator.of(context).pop();
          }
          if (state is RelationPageShowed) {
            _refreshCompleter?.complete();
            _refreshCompleter = Completer();
          }
        }, builder: (context, state) {
          return BlocBuilder<RelationPageBloc, RelationPageState>(
            builder: (context, state) {
              if (state is RelationPageSuccess) {
                return TabBarView(
                  children: [
                    _buildDetailsTab(context, state),
                    _buildTasksTab(context, state),
                  ],
                );
              }

              if (state is RelationPageFailure) {
                return Center(
                  child: Text(state.message),
                );
              }

              return LoadingIndicator();
            },
          );
        }),
      ),
    );
  }

  Widget _buildDetailsTab(BuildContext context, RelationPageSuccess state) {
    return RefreshIndicator(
      onRefresh: () {
        BlocProvider.of<RelationPageBloc>(context).add(
          RelationPageRefresh(),
        );
        return _refreshCompleter.future;
      },
      child: ListView(
        children: <Widget>[
          Column(
            children: [
              Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BoldText("Mentor: ", state.relation.mentor.name),
                          BoldText("Mentee: ", state.relation.mentee.name),
                          BoldText("End date: ",
                              DateTimeX.fromTimestamp(state.relation.endsOn).toDateString()),
                          BoldText("Notes: ", state.relation.notes),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.55,
                    ),
                    RaisedButton(
                      color: Theme.of(context).accentColor,
                      child: Text("Cancel".toUpperCase(), style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        //ignore: close_sinks
                        final bloc = BlocProvider.of<RelationPageBloc>(context);

                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("Cancel Relation"),
                              content: Text("Are you sure you want to cancel the relation"),
                              actions: [
                                FlatButton(
                                  child: Text("Yes"),
                                  onPressed: () {
                                    bloc.add(RelationPageCancelledRelation(state.relation.id));
                                    Navigator.of(context).pop();
                                  },
                                ),
                                FlatButton(
                                  child: Text("No"),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTasksTab(BuildContext context, RelationPageSuccess state) {
    return Scaffold(
      floatingActionButton: _buildFab(context, state),
      body: Builder(
        builder: (context) {
          if (state.tasks.length == 0) {
            return Center(
              child: Text("There are no tasks"),
            );
          }

          return RefreshIndicator(
            onRefresh: () {
              BlocProvider.of<RelationPageBloc>(context).add(
                RelationPageRefresh(),
              );
              return _refreshCompleter.future;
            },
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: state.tasks.length,
                itemBuilder: (context, index) {
                  Task task = state.tasks[index];
                  //ignore: close_sinks
                  final bloc = BlocProvider.of<RelationPageBloc>(context);

                  return InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Delete task"),
                          content: Text("Are you sure you want to delete the task?"),
                          actions: [
                            FlatButton(
                              child: Text("Delete"),
                              onPressed: () {
                                bloc.add(TaskDeleted(state.relation, task.id));
                                Navigator.of(context).pop();
                                showProgressIndicator(context);
                              },
                            )
                          ],
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (!task.isDone) {
                              bloc.add(TaskCompleted(state.relation, task.id));
                              showProgressIndicator(context);
                            } else
                              context.toast("Task already achieved.");
                          },
                          child: Checkbox(
                            value: task.isDone,
                          ),
                        ),
                        Text(task.description),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFab(BuildContext context, RelationPageSuccess state) {
    final _taskInputController = TextEditingController();

    //ignore: close_sinks
    final bloc = BlocProvider.of<RelationPageBloc>(context);

    return FloatingActionButton(
      child: Icon(
        Icons.add,
        color: Colors.white,
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Create task"),
            content: TextField(
              controller: _taskInputController,
              decoration: InputDecoration(hintText: "Task description"),
            ),
            actions: [
              FlatButton(
                child: Text("Create"),
                onPressed: () {
                  bloc.add(
                    TaskCreated(
                      state.relation,
                      TaskRequest(description: _taskInputController.text),
                    ),
                  );

                  Navigator.of(context).pop();
                  showProgressIndicator(context);
                },
              )
            ],
          ),
        );
      },
    );
  }
}
