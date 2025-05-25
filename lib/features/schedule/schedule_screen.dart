import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/theme_utils.dart';
import '../../main.dart' as app_main;
import 'schedule_bloc.dart';
import 'schedule_event.dart';
import 'schedule_state.dart';
import 'schedule_widgets.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsState = app_main.settingsBloc.state;

    return BlocProvider(
      create: (context) => ScheduleBloc(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: settingsState.primaryColor,
            appBar: AppBar(
              title: const Text('Schedule'),
              backgroundColor: settingsState.thirdlyColor,
            ),
            drawer: const AppDrawer(),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlocBuilder<ScheduleBloc, ScheduleState>(
                    builder: (context, state) {
                      if (state.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state.error != null) {
                        return Center(
                          child: Text(
                            'Error: ${state.error}',
                            style: TextStyle(
                              color: settingsState.secondaryColor,
                            ),
                          ),
                        );
                      }

                      // TODO: Add schedule content here
                      return const Center(
                        child: Text('Schedule content will be added here'),
                      );
                    },
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                final bloc = context.read<ScheduleBloc>();
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return BlocProvider.value(
                      value: bloc,
                      child: Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Select Date',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: settingsState.secondaryColor,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed:
                                        () => Navigator.of(dialogContext).pop(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ScheduleWidgets.buildDateSelector(dialogContext),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              backgroundColor: settingsState.secondaryColor,
              child: const Icon(Icons.calendar_today, color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}
