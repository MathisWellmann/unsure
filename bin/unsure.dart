import 'dart:async';

import 'package:args/args.dart';
import 'package:unsure/unsure.dart';

Future<int> main(List<String> args) async {
  final argParser = ArgParser();

  argParser
    ..addFlag('help',
        abbr: 'h', help: 'Print this help information.', negatable: false)
    ..addFlag('percentiles',
        abbr: 'p', help: 'Show a table of percentiles.', negatable: false)
    ..addFlag('histogram', help: 'Show the histogram.', defaultsTo: true)
    ..addFlag('padding',
        help: 'Pads the result so it stands out more in the terminal.',
        defaultsTo: true);

  final argResults = argParser.parse(args);
  final formulaString = argResults.rest.join(' ').trim();

  if (argResults['help'] || formulaString.isEmpty) {
    print(_help);
    print(argParser.usage);
    return 2;
  }

  final formula = parseString(formulaString);

  // Show a simple result for formulas that include no uncertainty.
  if (!formula.isStochastic) {
    final value = formula.emit();
    final formatter = Formatter([value, value * 0.95, value * 1.05]);
    final valueString = formatter.format(value);

    if (argResults['padding']) {
      print('\n\t$valueString\n');
      print('Well, that was easy. You seem to be very sure about your inputs.');
    } else {
      print(valueString);
    }

    return 0;
  }

  final calculation = Calculation(formula.emit);
  final result = calculation.run();
  if (argResults['padding']) {
    print('\n\t${result.simple}\n');
    if (result.isInvalid) {
      print('Warning: Most or all of the results of this computation '
          'were invalid values (infinity, not-a-number). '
          'It doesn\'t make sense to run statistics on this formula.');
    } else if (result.hadInvalidValues) {
      print('Warning: Some of the results were invalid values '
          '(infinity, not-a-number). These were simply ignored in computing '
          'the final result.\n');
    }
  } else {
    print(result.simple);
  }

  if (argResults['histogram'] && !result.isInvalid) {
    if (!argResults['padding']) {
      // The result itself doesn't have padding, so we need to add it here.
      print('');
    }
    print('  Histogram:');
    print(result.histogram);
  }

  if (argResults['percentiles'] && !result.isInvalid) {
    print('Percentiles:');
    print(result.percentilesString);
  }

  return 0;
}

const _help = r'''
Run this executable with the formula you're trying to compute. For example:

  $ unsure "4~6 * 1~2"

''';
