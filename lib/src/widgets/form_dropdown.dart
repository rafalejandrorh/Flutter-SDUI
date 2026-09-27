import 'package:flutter/material.dart';
import 'package:stac/stac.dart';

class FormDropdownModel {
  const FormDropdownModel({required this.menu, this.id});

  final StacDropdownMenu menu;
  final String? id;

  factory FormDropdownModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return FormDropdownModel(
      menu: StacDropdownMenu.fromJson(json),
      id: rawId is String && rawId.isNotEmpty ? rawId : null,
    );
  }
}

/// `dropdownMenu` that writes `id` into the surrounding Stac form.
///
/// Stac 1.5 parses the menu but never copies `id` or the selection into
/// `StacFormScope`, so `getFormValue` cannot read it.
class FormDropdownMenuParser implements StacParser<FormDropdownModel> {
  const FormDropdownMenuParser();

  @override
  String get type => 'dropdownMenu';

  @override
  FormDropdownModel getModel(Map<String, dynamic> json) =>
      FormDropdownModel.fromJson(json);

  @override
  Widget parse(BuildContext context, FormDropdownModel model) {
    return FormDropdownMenu(model: model);
  }
}

class FormDropdownMenu extends StatefulWidget {
  const FormDropdownMenu({super.key, required this.model});

  final FormDropdownModel model;

  @override
  State<FormDropdownMenu> createState() => _FormDropdownMenuState();
}

class _FormDropdownMenuState extends State<FormDropdownMenu> {
  var _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) {
      return;
    }
    _seeded = true;
    final id = widget.model.id;
    final initial = widget.model.menu.initialSelection;
    if (id == null || initial == null) {
      return;
    }
    StacFormScope.of(context)?.formData[id] = initial;
  }

  @override
  Widget build(BuildContext context) {
    final menu = widget.model.menu;
    final entries =
        menu.dropdownMenuEntries
            ?.map((entry) => entry.parse(context))
            .whereType<DropdownMenuEntry<Object>>()
            .toList() ??
        const <DropdownMenuEntry<Object>>[];

    return DropdownMenu<Object>(
      initialSelection: menu.initialSelection,
      dropdownMenuEntries: entries,
      enabled: menu.enabled ?? true,
      width: menu.width,
      label: menu.label?.parse(context),
      hintText: menu.hintText,
      onSelected: (value) {
        final id = widget.model.id;
        if (id == null || value == null) {
          return;
        }
        StacFormScope.of(context)?.formData[id] = value;
      },
    );
  }
}
