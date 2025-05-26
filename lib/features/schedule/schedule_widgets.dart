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
    final scheduleBloc = context.read<ScheduleBloc>();
    final state = scheduleBloc.state;

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
                  monthViewSettings: DateRangePickerMonthViewSettings(
                    firstDayOfWeek: 1,
                    dayFormat: 'EEE',
                    viewHeaderStyle: DateRangePickerViewHeaderStyle(
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: settingsState.secondaryColor,
                      ),
                    ),
                  ),
                  monthCellStyle: DateRangePickerMonthCellStyle(
                    todayTextStyle: TextStyle(
                      color: Colors.red, // Text color for today's date
                      fontWeight: FontWeight.bold,
                    ),
                    todayCellDecoration: BoxDecoration(
                      color: Colors.red.shade100, // Background for today's date
                      shape: BoxShape.circle,
                    ),
                  ),
                  selectionColor: settingsState.secondaryColor,
                  selectionTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  headerStyle: DateRangePickerHeaderStyle(
                    textStyle: TextStyle(
                      color: settingsState.secondaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onSelectionChanged: (
                    DateRangePickerSelectionChangedArgs args,
                  ) {
                    if (args.value is DateTime) {
                      final selectedDate = args.value as DateTime;
                      scheduleBloc
                        ..add(UpdateSelectedYear(selectedDate.year))
                        ..add(UpdateSelectedMonth(selectedDate.month))
                        ..add(UpdateSelectedDay(selectedDate.day));
                      // Close the popup immediately after selection
                      Navigator.of(context).pop();
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
