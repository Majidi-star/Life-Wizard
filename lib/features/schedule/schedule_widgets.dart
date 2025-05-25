import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../../main.dart' as app_main;
import 'schedule_bloc.dart';
import 'schedule_event.dart';
import 'schedule_state.dart';
import 'schedule_model.dart';

class ScheduleWidgets {
  static Widget buildDateSelector(BuildContext context) {
    final settingsState = app_main.settingsBloc.state;

    return Card(
      color: settingsState.primaryColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: settingsState.secondaryColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlocBuilder<ScheduleBloc, ScheduleState>(
              builder: (context, state) {
                return SfDateRangePicker(
                  view: DateRangePickerView.month,
                  selectionMode: DateRangePickerSelectionMode.single,
                  monthFormat: 'MMM',
                  headerStyle: DateRangePickerHeaderStyle(
                    textStyle: TextStyle(
                      color: settingsState.secondaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  monthViewSettings: const DateRangePickerMonthViewSettings(
                    firstDayOfWeek: 1,
                    dayFormat: 'EEE',
                    viewHeaderStyle: DateRangePickerViewHeaderStyle(
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  selectionColor: settingsState.secondaryColor,
                  todayHighlightColor: settingsState.thirdlyColor,
                  onSelectionChanged: (args) {
                    if (args.value is DateTime) {
                      final date = args.value as DateTime;
                      context.read<ScheduleBloc>()
                        ..add(UpdateSelectedYear(date.year))
                        ..add(UpdateSelectedMonth(date.month))
                        ..add(UpdateSelectedDay(date.day));
                    }
                  },
                  initialSelectedDate: DateTime(
                    state.selectedYear,
                    state.selectedMonth,
                    state.selectedDay,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
