import 'package:flutter/material.dart';
import 'package:phone_number/phone_number.dart';
import 'package:phone_number_example/main.dart';
import 'package:phone_number_example/models/parse_result.dart';
import 'package:phone_number_example/models/region.dart';
import 'package:phone_number_example/region_picker.dart';
import 'package:phone_number_example/store.dart';

/// TODO: Add previous hardcoded examples
// parse '17449106505' (MX)
// parse list "+48606723456", "+48774843312"
// format '+47234723432', 'BR'

class FunctionsPage extends StatefulWidget {
  final Store store;

  FunctionsPage(this.store);

  @override
  _FunctionsPageState createState() => _FunctionsPageState();
}

class _FunctionsPageState extends State<FunctionsPage> {
  final regionCtrl = TextEditingController();
  final numberCtrl = TextEditingController();
  final key = GlobalKey<FormState>();

  Region? region;
  ParseResult? result;

  bool get hasResult => result != null;
  String? _devicesRegionCode;

  Future<void> parse() async {
    setState(() => result = null);
    if (key.currentState!.validate()) {
      dismissKeyboard(context);
      result = await widget.store.parse(numberCtrl.text, region: region);
      print('Parse Result: $result');
      setState(() {});
    }
  }

  Future<void> format() async {
    if (key.currentState!.validate()) {
      dismissKeyboard(context);
      final formatted = await widget.store.format(numberCtrl.text, region!);
      if (formatted != null) {
        numberCtrl.text = formatted;
        setState(() {});
      }
    }
  }

  Future<void> fetchDevicesRegionCode() async {
    final code = await widget.store.carrierRegionCode();
    setState(() => _devicesRegionCode = code);
  }

  void reset() {
    key.currentState!.reset();
    regionCtrl.text = '';
    numberCtrl.text = '';
    region = null;
    result = null;
    setState(() {});
  }

  Future<void> chooseRegions() async {
    dismissKeyboard(context);

    final regions = await widget.store.getRegions();

    final route = MaterialPageRoute<Region>(
      fullscreenDialog: true,
      builder: (_) => RegionPicker(regions: regions),
    );

    final selectedRegion = await Navigator.of(context).push<Region>(route);

    if (selectedRegion != null) {
      print('Region selected: $selectedRegion');
      regionCtrl.text = "${selectedRegion.name} (+${selectedRegion.prefix})";
      setState(() => region = selectedRegion);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: key,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        children: [
          TextFormField(
            controller: numberCtrl,
            autocorrect: false,
            enableSuggestions: false,
            autofocus: true,
            keyboardType: TextInputType.phone,
            validator: (v) => v?.isEmpty == true ? 'Required' : null,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              helperText: '',
            ),
          ),
          InkWell(
            onTap: chooseRegions,
            child: IgnorePointer(
              child: TextFormField(
                controller: regionCtrl,
                decoration: InputDecoration(
                  labelText: 'Region',
                  helperText: '',
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  child: Text('Validate'),
                  onPressed: regionCtrl.text.isEmpty ? null : validate,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  child: Text('Format'),
                  onPressed: regionCtrl.text.isEmpty ? null : format,
                ),
              ),
              VerticalDivider(),
              Expanded(
                child: ElevatedButton(
                  child: Text('Parse'),
                  onPressed: parse,
                ),
              ),
            ],
          ),
          OutlinedButton(
            child: Text('Reset'),
            onPressed: reset,
          ),
          OutlinedButton(
            child: Text('Region Code'),
            onPressed: fetchDevicesRegionCode,
          ),
          if (_devicesRegionCode != null) RegionCode(code: _devicesRegionCode!),
          SizedBox(height: 20),
          if (hasResult)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Result(result: result!),
            ),
        ],
      ),
    );
  }

  Future<void> validate() async {
    final isValid = await widget.store.validate(numberCtrl.text, region!);
    print('isValid : ' + isValid.toString());
  }
}

class RegionCode extends StatelessWidget {
  const RegionCode({
    Key? key,
    required this.code,
  }) : super(key: key);

  final String code;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Device Region code: '),
          TextSpan(text: code, style: TextStyle(color: Colors.blue)),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class Result extends StatelessWidget {
  final ParseResult result;

  const Result({
    Key? key,
    required this.result,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text("Result:", style: theme.textTheme.headline6),
        SizedBox(height: 10),
        ...(result.hasError)
            ? [
                Text(
                  'Error! (code: ${result.errorCode})',
                  style: theme.textTheme.bodyText1?.copyWith(color: Colors.red),
                ),
              ]
            : [
                _ResultRow(
                  name: 'Type',
                  value: result.phoneNumber!.type.toString().split('.').last,
                ),
                _ResultRow(name: 'E164', value: result.phoneNumber!.e164),
                _ResultRow(
                  name: 'International',
                  value: result.phoneNumber!.international,
                ),
                _ResultRow(
                  name: 'National',
                  value: result.phoneNumber!.national,
                ),
                _ResultRow(
                  name: 'National number',
                  value: result.phoneNumber!.nationalNumber,
                ),
                _ResultRow(
                  name: 'Country code',
                  value: result.phoneNumber!.countryCode,
                ),
              ],
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String name;
  final String value;

  const _ResultRow({
    Key? key,
    required this.name,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(child: Text('$name', style: theme.textTheme.bodyText2)),
          Flexible(child: Text(value, style: theme.textTheme.bodyText1)),
        ],
      ),
    );
  }
}
