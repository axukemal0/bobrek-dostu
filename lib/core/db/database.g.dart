// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AppSettingsRowsTable extends AppSettingsRows
    with TableInfo<$AppSettingsRowsTable, AppSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsRowsTable createAlias(String alias) {
    return $AppSettingsRowsTable(attachedDatabase, alias);
  }
}

class AppSettingsRow extends DataClass implements Insertable<AppSettingsRow> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const AppSettingsRow({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsRowsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsRowsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSettingsRow copyWith({String? key, String? value, DateTime? updatedAt}) =>
      AppSettingsRow(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSettingsRow copyWithCompanion(AppSettingsRowsCompanion data) {
    return AppSettingsRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsRowsCompanion extends UpdateCompanion<AppSettingsRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsRowsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsRowsCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSettingsRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsRowsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsRowsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRowsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClinicalChangeRowsTable extends ClinicalChangeRows
    with TableInfo<$ClinicalChangeRowsTable, ClinicalChangeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClinicalChangeRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _valueKeyMeta = const VerificationMeta(
    'valueKey',
  );
  @override
  late final GeneratedColumn<String> valueKey = GeneratedColumn<String>(
    'value_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _oldTextMeta = const VerificationMeta(
    'oldText',
  );
  @override
  late final GeneratedColumn<String> oldText = GeneratedColumn<String>(
    'old_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _newTextMeta = const VerificationMeta(
    'newText',
  );
  @override
  late final GeneratedColumn<String> newText = GeneratedColumn<String>(
    'new_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  @override
  late final GeneratedColumn<DateTime> changedAt = GeneratedColumn<DateTime>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    valueKey,
    oldText,
    newText,
    note,
    changedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clinical_change_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClinicalChangeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('value_key')) {
      context.handle(
        _valueKeyMeta,
        valueKey.isAcceptableOrUnknown(data['value_key']!, _valueKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_valueKeyMeta);
    }
    if (data.containsKey('old_text')) {
      context.handle(
        _oldTextMeta,
        oldText.isAcceptableOrUnknown(data['old_text']!, _oldTextMeta),
      );
    }
    if (data.containsKey('new_text')) {
      context.handle(
        _newTextMeta,
        newText.isAcceptableOrUnknown(data['new_text']!, _newTextMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClinicalChangeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClinicalChangeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      valueKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_key'],
      )!,
      oldText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}old_text'],
      ),
      newText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}new_text'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}changed_at'],
      )!,
    );
  }

  @override
  $ClinicalChangeRowsTable createAlias(String alias) {
    return $ClinicalChangeRowsTable(attachedDatabase, alias);
  }
}

class ClinicalChangeRow extends DataClass
    implements Insertable<ClinicalChangeRow> {
  final int id;
  final String valueKey;
  final String? oldText;
  final String? newText;
  final String? note;
  final DateTime changedAt;
  const ClinicalChangeRow({
    required this.id,
    required this.valueKey,
    this.oldText,
    this.newText,
    this.note,
    required this.changedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['value_key'] = Variable<String>(valueKey);
    if (!nullToAbsent || oldText != null) {
      map['old_text'] = Variable<String>(oldText);
    }
    if (!nullToAbsent || newText != null) {
      map['new_text'] = Variable<String>(newText);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['changed_at'] = Variable<DateTime>(changedAt);
    return map;
  }

  ClinicalChangeRowsCompanion toCompanion(bool nullToAbsent) {
    return ClinicalChangeRowsCompanion(
      id: Value(id),
      valueKey: Value(valueKey),
      oldText: oldText == null && nullToAbsent
          ? const Value.absent()
          : Value(oldText),
      newText: newText == null && nullToAbsent
          ? const Value.absent()
          : Value(newText),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      changedAt: Value(changedAt),
    );
  }

  factory ClinicalChangeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClinicalChangeRow(
      id: serializer.fromJson<int>(json['id']),
      valueKey: serializer.fromJson<String>(json['valueKey']),
      oldText: serializer.fromJson<String?>(json['oldText']),
      newText: serializer.fromJson<String?>(json['newText']),
      note: serializer.fromJson<String?>(json['note']),
      changedAt: serializer.fromJson<DateTime>(json['changedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'valueKey': serializer.toJson<String>(valueKey),
      'oldText': serializer.toJson<String?>(oldText),
      'newText': serializer.toJson<String?>(newText),
      'note': serializer.toJson<String?>(note),
      'changedAt': serializer.toJson<DateTime>(changedAt),
    };
  }

  ClinicalChangeRow copyWith({
    int? id,
    String? valueKey,
    Value<String?> oldText = const Value.absent(),
    Value<String?> newText = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? changedAt,
  }) => ClinicalChangeRow(
    id: id ?? this.id,
    valueKey: valueKey ?? this.valueKey,
    oldText: oldText.present ? oldText.value : this.oldText,
    newText: newText.present ? newText.value : this.newText,
    note: note.present ? note.value : this.note,
    changedAt: changedAt ?? this.changedAt,
  );
  ClinicalChangeRow copyWithCompanion(ClinicalChangeRowsCompanion data) {
    return ClinicalChangeRow(
      id: data.id.present ? data.id.value : this.id,
      valueKey: data.valueKey.present ? data.valueKey.value : this.valueKey,
      oldText: data.oldText.present ? data.oldText.value : this.oldText,
      newText: data.newText.present ? data.newText.value : this.newText,
      note: data.note.present ? data.note.value : this.note,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClinicalChangeRow(')
          ..write('id: $id, ')
          ..write('valueKey: $valueKey, ')
          ..write('oldText: $oldText, ')
          ..write('newText: $newText, ')
          ..write('note: $note, ')
          ..write('changedAt: $changedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, valueKey, oldText, newText, note, changedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClinicalChangeRow &&
          other.id == this.id &&
          other.valueKey == this.valueKey &&
          other.oldText == this.oldText &&
          other.newText == this.newText &&
          other.note == this.note &&
          other.changedAt == this.changedAt);
}

class ClinicalChangeRowsCompanion extends UpdateCompanion<ClinicalChangeRow> {
  final Value<int> id;
  final Value<String> valueKey;
  final Value<String?> oldText;
  final Value<String?> newText;
  final Value<String?> note;
  final Value<DateTime> changedAt;
  const ClinicalChangeRowsCompanion({
    this.id = const Value.absent(),
    this.valueKey = const Value.absent(),
    this.oldText = const Value.absent(),
    this.newText = const Value.absent(),
    this.note = const Value.absent(),
    this.changedAt = const Value.absent(),
  });
  ClinicalChangeRowsCompanion.insert({
    this.id = const Value.absent(),
    required String valueKey,
    this.oldText = const Value.absent(),
    this.newText = const Value.absent(),
    this.note = const Value.absent(),
    this.changedAt = const Value.absent(),
  }) : valueKey = Value(valueKey);
  static Insertable<ClinicalChangeRow> custom({
    Expression<int>? id,
    Expression<String>? valueKey,
    Expression<String>? oldText,
    Expression<String>? newText,
    Expression<String>? note,
    Expression<DateTime>? changedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (valueKey != null) 'value_key': valueKey,
      if (oldText != null) 'old_text': oldText,
      if (newText != null) 'new_text': newText,
      if (note != null) 'note': note,
      if (changedAt != null) 'changed_at': changedAt,
    });
  }

  ClinicalChangeRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? valueKey,
    Value<String?>? oldText,
    Value<String?>? newText,
    Value<String?>? note,
    Value<DateTime>? changedAt,
  }) {
    return ClinicalChangeRowsCompanion(
      id: id ?? this.id,
      valueKey: valueKey ?? this.valueKey,
      oldText: oldText ?? this.oldText,
      newText: newText ?? this.newText,
      note: note ?? this.note,
      changedAt: changedAt ?? this.changedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (valueKey.present) {
      map['value_key'] = Variable<String>(valueKey.value);
    }
    if (oldText.present) {
      map['old_text'] = Variable<String>(oldText.value);
    }
    if (newText.present) {
      map['new_text'] = Variable<String>(newText.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<DateTime>(changedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClinicalChangeRowsCompanion(')
          ..write('id: $id, ')
          ..write('valueKey: $valueKey, ')
          ..write('oldText: $oldText, ')
          ..write('newText: $newText, ')
          ..write('note: $note, ')
          ..write('changedAt: $changedAt')
          ..write(')'))
        .toString();
  }
}

class $ProfileRowsTable extends ProfileRows
    with TableInfo<$ProfileRowsTable, ProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birthYearMeta = const VerificationMeta(
    'birthYear',
  );
  @override
  late final GeneratedColumn<int> birthYear = GeneratedColumn<int>(
    'birth_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _treatmentModeMeta = const VerificationMeta(
    'treatmentMode',
  );
  @override
  late final GeneratedColumn<String> treatmentMode = GeneratedColumn<String>(
    'treatment_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dialysisDaysMeta = const VerificationMeta(
    'dialysisDays',
  );
  @override
  late final GeneratedColumn<String> dialysisDays = GeneratedColumn<String>(
    'dialysis_days',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _comorbiditiesMeta = const VerificationMeta(
    'comorbidities',
  );
  @override
  late final GeneratedColumn<String> comorbidities = GeneratedColumn<String>(
    'comorbidities',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _allergiesMeta = const VerificationMeta(
    'allergies',
  );
  @override
  late final GeneratedColumn<String> allergies = GeneratedColumn<String>(
    'allergies',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dislikedFoodsMeta = const VerificationMeta(
    'dislikedFoods',
  );
  @override
  late final GeneratedColumn<String> dislikedFoods = GeneratedColumn<String>(
    'disliked_foods',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doctorNameMeta = const VerificationMeta(
    'doctorName',
  );
  @override
  late final GeneratedColumn<String> doctorName = GeneratedColumn<String>(
    'doctor_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doctorPhoneMeta = const VerificationMeta(
    'doctorPhone',
  );
  @override
  late final GeneratedColumn<String> doctorPhone = GeneratedColumn<String>(
    'doctor_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hospitalMeta = const VerificationMeta(
    'hospital',
  );
  @override
  late final GeneratedColumn<String> hospital = GeneratedColumn<String>(
    'hospital',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expertModeMeta = const VerificationMeta(
    'expertMode',
  );
  @override
  late final GeneratedColumn<bool> expertMode = GeneratedColumn<bool>(
    'expert_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("expert_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    birthYear,
    heightCm,
    weightKg,
    treatmentMode,
    dialysisDays,
    comorbidities,
    allergies,
    dislikedFoods,
    doctorName,
    doctorPhone,
    hospital,
    expertMode,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('birth_year')) {
      context.handle(
        _birthYearMeta,
        birthYear.isAcceptableOrUnknown(data['birth_year']!, _birthYearMeta),
      );
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('treatment_mode')) {
      context.handle(
        _treatmentModeMeta,
        treatmentMode.isAcceptableOrUnknown(
          data['treatment_mode']!,
          _treatmentModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_treatmentModeMeta);
    }
    if (data.containsKey('dialysis_days')) {
      context.handle(
        _dialysisDaysMeta,
        dialysisDays.isAcceptableOrUnknown(
          data['dialysis_days']!,
          _dialysisDaysMeta,
        ),
      );
    }
    if (data.containsKey('comorbidities')) {
      context.handle(
        _comorbiditiesMeta,
        comorbidities.isAcceptableOrUnknown(
          data['comorbidities']!,
          _comorbiditiesMeta,
        ),
      );
    }
    if (data.containsKey('allergies')) {
      context.handle(
        _allergiesMeta,
        allergies.isAcceptableOrUnknown(data['allergies']!, _allergiesMeta),
      );
    }
    if (data.containsKey('disliked_foods')) {
      context.handle(
        _dislikedFoodsMeta,
        dislikedFoods.isAcceptableOrUnknown(
          data['disliked_foods']!,
          _dislikedFoodsMeta,
        ),
      );
    }
    if (data.containsKey('doctor_name')) {
      context.handle(
        _doctorNameMeta,
        doctorName.isAcceptableOrUnknown(data['doctor_name']!, _doctorNameMeta),
      );
    }
    if (data.containsKey('doctor_phone')) {
      context.handle(
        _doctorPhoneMeta,
        doctorPhone.isAcceptableOrUnknown(
          data['doctor_phone']!,
          _doctorPhoneMeta,
        ),
      );
    }
    if (data.containsKey('hospital')) {
      context.handle(
        _hospitalMeta,
        hospital.isAcceptableOrUnknown(data['hospital']!, _hospitalMeta),
      );
    }
    if (data.containsKey('expert_mode')) {
      context.handle(
        _expertModeMeta,
        expertMode.isAcceptableOrUnknown(data['expert_mode']!, _expertModeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      birthYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}birth_year'],
      ),
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      treatmentMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}treatment_mode'],
      )!,
      dialysisDays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dialysis_days'],
      ),
      comorbidities: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comorbidities'],
      ),
      allergies: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allergies'],
      ),
      dislikedFoods: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}disliked_foods'],
      ),
      doctorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doctor_name'],
      ),
      doctorPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doctor_phone'],
      ),
      hospital: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hospital'],
      ),
      expertMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}expert_mode'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProfileRowsTable createAlias(String alias) {
    return $ProfileRowsTable(attachedDatabase, alias);
  }
}

class ProfileRow extends DataClass implements Insertable<ProfileRow> {
  final int id;
  final String name;
  final int? birthYear;
  final double? heightCm;
  final double? weightKg;
  final String treatmentMode;

  /// Hemodiyaliz günleri: "1,3,5" (1 = Pazartesi).
  final String? dialysisDays;
  final String? comorbidities;
  final String? allergies;
  final String? dislikedFoods;
  final String? doctorName;
  final String? doctorPhone;
  final String? hospital;
  final bool expertMode;
  final DateTime createdAt;
  const ProfileRow({
    required this.id,
    required this.name,
    this.birthYear,
    this.heightCm,
    this.weightKg,
    required this.treatmentMode,
    this.dialysisDays,
    this.comorbidities,
    this.allergies,
    this.dislikedFoods,
    this.doctorName,
    this.doctorPhone,
    this.hospital,
    required this.expertMode,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || birthYear != null) {
      map['birth_year'] = Variable<int>(birthYear);
    }
    if (!nullToAbsent || heightCm != null) {
      map['height_cm'] = Variable<double>(heightCm);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    map['treatment_mode'] = Variable<String>(treatmentMode);
    if (!nullToAbsent || dialysisDays != null) {
      map['dialysis_days'] = Variable<String>(dialysisDays);
    }
    if (!nullToAbsent || comorbidities != null) {
      map['comorbidities'] = Variable<String>(comorbidities);
    }
    if (!nullToAbsent || allergies != null) {
      map['allergies'] = Variable<String>(allergies);
    }
    if (!nullToAbsent || dislikedFoods != null) {
      map['disliked_foods'] = Variable<String>(dislikedFoods);
    }
    if (!nullToAbsent || doctorName != null) {
      map['doctor_name'] = Variable<String>(doctorName);
    }
    if (!nullToAbsent || doctorPhone != null) {
      map['doctor_phone'] = Variable<String>(doctorPhone);
    }
    if (!nullToAbsent || hospital != null) {
      map['hospital'] = Variable<String>(hospital);
    }
    map['expert_mode'] = Variable<bool>(expertMode);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProfileRowsCompanion toCompanion(bool nullToAbsent) {
    return ProfileRowsCompanion(
      id: Value(id),
      name: Value(name),
      birthYear: birthYear == null && nullToAbsent
          ? const Value.absent()
          : Value(birthYear),
      heightCm: heightCm == null && nullToAbsent
          ? const Value.absent()
          : Value(heightCm),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      treatmentMode: Value(treatmentMode),
      dialysisDays: dialysisDays == null && nullToAbsent
          ? const Value.absent()
          : Value(dialysisDays),
      comorbidities: comorbidities == null && nullToAbsent
          ? const Value.absent()
          : Value(comorbidities),
      allergies: allergies == null && nullToAbsent
          ? const Value.absent()
          : Value(allergies),
      dislikedFoods: dislikedFoods == null && nullToAbsent
          ? const Value.absent()
          : Value(dislikedFoods),
      doctorName: doctorName == null && nullToAbsent
          ? const Value.absent()
          : Value(doctorName),
      doctorPhone: doctorPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(doctorPhone),
      hospital: hospital == null && nullToAbsent
          ? const Value.absent()
          : Value(hospital),
      expertMode: Value(expertMode),
      createdAt: Value(createdAt),
    );
  }

  factory ProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      birthYear: serializer.fromJson<int?>(json['birthYear']),
      heightCm: serializer.fromJson<double?>(json['heightCm']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      treatmentMode: serializer.fromJson<String>(json['treatmentMode']),
      dialysisDays: serializer.fromJson<String?>(json['dialysisDays']),
      comorbidities: serializer.fromJson<String?>(json['comorbidities']),
      allergies: serializer.fromJson<String?>(json['allergies']),
      dislikedFoods: serializer.fromJson<String?>(json['dislikedFoods']),
      doctorName: serializer.fromJson<String?>(json['doctorName']),
      doctorPhone: serializer.fromJson<String?>(json['doctorPhone']),
      hospital: serializer.fromJson<String?>(json['hospital']),
      expertMode: serializer.fromJson<bool>(json['expertMode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'birthYear': serializer.toJson<int?>(birthYear),
      'heightCm': serializer.toJson<double?>(heightCm),
      'weightKg': serializer.toJson<double?>(weightKg),
      'treatmentMode': serializer.toJson<String>(treatmentMode),
      'dialysisDays': serializer.toJson<String?>(dialysisDays),
      'comorbidities': serializer.toJson<String?>(comorbidities),
      'allergies': serializer.toJson<String?>(allergies),
      'dislikedFoods': serializer.toJson<String?>(dislikedFoods),
      'doctorName': serializer.toJson<String?>(doctorName),
      'doctorPhone': serializer.toJson<String?>(doctorPhone),
      'hospital': serializer.toJson<String?>(hospital),
      'expertMode': serializer.toJson<bool>(expertMode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ProfileRow copyWith({
    int? id,
    String? name,
    Value<int?> birthYear = const Value.absent(),
    Value<double?> heightCm = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    String? treatmentMode,
    Value<String?> dialysisDays = const Value.absent(),
    Value<String?> comorbidities = const Value.absent(),
    Value<String?> allergies = const Value.absent(),
    Value<String?> dislikedFoods = const Value.absent(),
    Value<String?> doctorName = const Value.absent(),
    Value<String?> doctorPhone = const Value.absent(),
    Value<String?> hospital = const Value.absent(),
    bool? expertMode,
    DateTime? createdAt,
  }) => ProfileRow(
    id: id ?? this.id,
    name: name ?? this.name,
    birthYear: birthYear.present ? birthYear.value : this.birthYear,
    heightCm: heightCm.present ? heightCm.value : this.heightCm,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    treatmentMode: treatmentMode ?? this.treatmentMode,
    dialysisDays: dialysisDays.present ? dialysisDays.value : this.dialysisDays,
    comorbidities: comorbidities.present
        ? comorbidities.value
        : this.comorbidities,
    allergies: allergies.present ? allergies.value : this.allergies,
    dislikedFoods: dislikedFoods.present
        ? dislikedFoods.value
        : this.dislikedFoods,
    doctorName: doctorName.present ? doctorName.value : this.doctorName,
    doctorPhone: doctorPhone.present ? doctorPhone.value : this.doctorPhone,
    hospital: hospital.present ? hospital.value : this.hospital,
    expertMode: expertMode ?? this.expertMode,
    createdAt: createdAt ?? this.createdAt,
  );
  ProfileRow copyWithCompanion(ProfileRowsCompanion data) {
    return ProfileRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      birthYear: data.birthYear.present ? data.birthYear.value : this.birthYear,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      treatmentMode: data.treatmentMode.present
          ? data.treatmentMode.value
          : this.treatmentMode,
      dialysisDays: data.dialysisDays.present
          ? data.dialysisDays.value
          : this.dialysisDays,
      comorbidities: data.comorbidities.present
          ? data.comorbidities.value
          : this.comorbidities,
      allergies: data.allergies.present ? data.allergies.value : this.allergies,
      dislikedFoods: data.dislikedFoods.present
          ? data.dislikedFoods.value
          : this.dislikedFoods,
      doctorName: data.doctorName.present
          ? data.doctorName.value
          : this.doctorName,
      doctorPhone: data.doctorPhone.present
          ? data.doctorPhone.value
          : this.doctorPhone,
      hospital: data.hospital.present ? data.hospital.value : this.hospital,
      expertMode: data.expertMode.present
          ? data.expertMode.value
          : this.expertMode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('birthYear: $birthYear, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('treatmentMode: $treatmentMode, ')
          ..write('dialysisDays: $dialysisDays, ')
          ..write('comorbidities: $comorbidities, ')
          ..write('allergies: $allergies, ')
          ..write('dislikedFoods: $dislikedFoods, ')
          ..write('doctorName: $doctorName, ')
          ..write('doctorPhone: $doctorPhone, ')
          ..write('hospital: $hospital, ')
          ..write('expertMode: $expertMode, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    birthYear,
    heightCm,
    weightKg,
    treatmentMode,
    dialysisDays,
    comorbidities,
    allergies,
    dislikedFoods,
    doctorName,
    doctorPhone,
    hospital,
    expertMode,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.birthYear == this.birthYear &&
          other.heightCm == this.heightCm &&
          other.weightKg == this.weightKg &&
          other.treatmentMode == this.treatmentMode &&
          other.dialysisDays == this.dialysisDays &&
          other.comorbidities == this.comorbidities &&
          other.allergies == this.allergies &&
          other.dislikedFoods == this.dislikedFoods &&
          other.doctorName == this.doctorName &&
          other.doctorPhone == this.doctorPhone &&
          other.hospital == this.hospital &&
          other.expertMode == this.expertMode &&
          other.createdAt == this.createdAt);
}

class ProfileRowsCompanion extends UpdateCompanion<ProfileRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int?> birthYear;
  final Value<double?> heightCm;
  final Value<double?> weightKg;
  final Value<String> treatmentMode;
  final Value<String?> dialysisDays;
  final Value<String?> comorbidities;
  final Value<String?> allergies;
  final Value<String?> dislikedFoods;
  final Value<String?> doctorName;
  final Value<String?> doctorPhone;
  final Value<String?> hospital;
  final Value<bool> expertMode;
  final Value<DateTime> createdAt;
  const ProfileRowsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.birthYear = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.treatmentMode = const Value.absent(),
    this.dialysisDays = const Value.absent(),
    this.comorbidities = const Value.absent(),
    this.allergies = const Value.absent(),
    this.dislikedFoods = const Value.absent(),
    this.doctorName = const Value.absent(),
    this.doctorPhone = const Value.absent(),
    this.hospital = const Value.absent(),
    this.expertMode = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProfileRowsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.birthYear = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    required String treatmentMode,
    this.dialysisDays = const Value.absent(),
    this.comorbidities = const Value.absent(),
    this.allergies = const Value.absent(),
    this.dislikedFoods = const Value.absent(),
    this.doctorName = const Value.absent(),
    this.doctorPhone = const Value.absent(),
    this.hospital = const Value.absent(),
    this.expertMode = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       treatmentMode = Value(treatmentMode);
  static Insertable<ProfileRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? birthYear,
    Expression<double>? heightCm,
    Expression<double>? weightKg,
    Expression<String>? treatmentMode,
    Expression<String>? dialysisDays,
    Expression<String>? comorbidities,
    Expression<String>? allergies,
    Expression<String>? dislikedFoods,
    Expression<String>? doctorName,
    Expression<String>? doctorPhone,
    Expression<String>? hospital,
    Expression<bool>? expertMode,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (birthYear != null) 'birth_year': birthYear,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (treatmentMode != null) 'treatment_mode': treatmentMode,
      if (dialysisDays != null) 'dialysis_days': dialysisDays,
      if (comorbidities != null) 'comorbidities': comorbidities,
      if (allergies != null) 'allergies': allergies,
      if (dislikedFoods != null) 'disliked_foods': dislikedFoods,
      if (doctorName != null) 'doctor_name': doctorName,
      if (doctorPhone != null) 'doctor_phone': doctorPhone,
      if (hospital != null) 'hospital': hospital,
      if (expertMode != null) 'expert_mode': expertMode,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProfileRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int?>? birthYear,
    Value<double?>? heightCm,
    Value<double?>? weightKg,
    Value<String>? treatmentMode,
    Value<String?>? dialysisDays,
    Value<String?>? comorbidities,
    Value<String?>? allergies,
    Value<String?>? dislikedFoods,
    Value<String?>? doctorName,
    Value<String?>? doctorPhone,
    Value<String?>? hospital,
    Value<bool>? expertMode,
    Value<DateTime>? createdAt,
  }) {
    return ProfileRowsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      birthYear: birthYear ?? this.birthYear,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      treatmentMode: treatmentMode ?? this.treatmentMode,
      dialysisDays: dialysisDays ?? this.dialysisDays,
      comorbidities: comorbidities ?? this.comorbidities,
      allergies: allergies ?? this.allergies,
      dislikedFoods: dislikedFoods ?? this.dislikedFoods,
      doctorName: doctorName ?? this.doctorName,
      doctorPhone: doctorPhone ?? this.doctorPhone,
      hospital: hospital ?? this.hospital,
      expertMode: expertMode ?? this.expertMode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (birthYear.present) {
      map['birth_year'] = Variable<int>(birthYear.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (treatmentMode.present) {
      map['treatment_mode'] = Variable<String>(treatmentMode.value);
    }
    if (dialysisDays.present) {
      map['dialysis_days'] = Variable<String>(dialysisDays.value);
    }
    if (comorbidities.present) {
      map['comorbidities'] = Variable<String>(comorbidities.value);
    }
    if (allergies.present) {
      map['allergies'] = Variable<String>(allergies.value);
    }
    if (dislikedFoods.present) {
      map['disliked_foods'] = Variable<String>(dislikedFoods.value);
    }
    if (doctorName.present) {
      map['doctor_name'] = Variable<String>(doctorName.value);
    }
    if (doctorPhone.present) {
      map['doctor_phone'] = Variable<String>(doctorPhone.value);
    }
    if (hospital.present) {
      map['hospital'] = Variable<String>(hospital.value);
    }
    if (expertMode.present) {
      map['expert_mode'] = Variable<bool>(expertMode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRowsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('birthYear: $birthYear, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('treatmentMode: $treatmentMode, ')
          ..write('dialysisDays: $dialysisDays, ')
          ..write('comorbidities: $comorbidities, ')
          ..write('allergies: $allergies, ')
          ..write('dislikedFoods: $dislikedFoods, ')
          ..write('doctorName: $doctorName, ')
          ..write('doctorPhone: $doctorPhone, ')
          ..write('hospital: $hospital, ')
          ..write('expertMode: $expertMode, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $EmergencyContactRowsTable extends EmergencyContactRows
    with TableInfo<$EmergencyContactRowsTable, EmergencyContactRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmergencyContactRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relationMeta = const VerificationMeta(
    'relation',
  );
  @override
  late final GeneratedColumn<String> relation = GeneratedColumn<String>(
    'relation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _autoSmsEnabledMeta = const VerificationMeta(
    'autoSmsEnabled',
  );
  @override
  late final GeneratedColumn<bool> autoSmsEnabled = GeneratedColumn<bool>(
    'auto_sms_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_sms_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    phone,
    relation,
    autoSmsEnabled,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'emergency_contact_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<EmergencyContactRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('relation')) {
      context.handle(
        _relationMeta,
        relation.isAcceptableOrUnknown(data['relation']!, _relationMeta),
      );
    }
    if (data.containsKey('auto_sms_enabled')) {
      context.handle(
        _autoSmsEnabledMeta,
        autoSmsEnabled.isAcceptableOrUnknown(
          data['auto_sms_enabled']!,
          _autoSmsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EmergencyContactRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmergencyContactRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      relation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relation'],
      ),
      autoSmsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_sms_enabled'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $EmergencyContactRowsTable createAlias(String alias) {
    return $EmergencyContactRowsTable(attachedDatabase, alias);
  }
}

class EmergencyContactRow extends DataClass
    implements Insertable<EmergencyContactRow> {
  final int id;
  final String name;
  final String phone;
  final String? relation;
  final bool autoSmsEnabled;
  final int sortOrder;
  const EmergencyContactRow({
    required this.id,
    required this.name,
    required this.phone,
    this.relation,
    required this.autoSmsEnabled,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    if (!nullToAbsent || relation != null) {
      map['relation'] = Variable<String>(relation);
    }
    map['auto_sms_enabled'] = Variable<bool>(autoSmsEnabled);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  EmergencyContactRowsCompanion toCompanion(bool nullToAbsent) {
    return EmergencyContactRowsCompanion(
      id: Value(id),
      name: Value(name),
      phone: Value(phone),
      relation: relation == null && nullToAbsent
          ? const Value.absent()
          : Value(relation),
      autoSmsEnabled: Value(autoSmsEnabled),
      sortOrder: Value(sortOrder),
    );
  }

  factory EmergencyContactRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmergencyContactRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      relation: serializer.fromJson<String?>(json['relation']),
      autoSmsEnabled: serializer.fromJson<bool>(json['autoSmsEnabled']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'relation': serializer.toJson<String?>(relation),
      'autoSmsEnabled': serializer.toJson<bool>(autoSmsEnabled),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  EmergencyContactRow copyWith({
    int? id,
    String? name,
    String? phone,
    Value<String?> relation = const Value.absent(),
    bool? autoSmsEnabled,
    int? sortOrder,
  }) => EmergencyContactRow(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    relation: relation.present ? relation.value : this.relation,
    autoSmsEnabled: autoSmsEnabled ?? this.autoSmsEnabled,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  EmergencyContactRow copyWithCompanion(EmergencyContactRowsCompanion data) {
    return EmergencyContactRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      relation: data.relation.present ? data.relation.value : this.relation,
      autoSmsEnabled: data.autoSmsEnabled.present
          ? data.autoSmsEnabled.value
          : this.autoSmsEnabled,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmergencyContactRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('relation: $relation, ')
          ..write('autoSmsEnabled: $autoSmsEnabled, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, phone, relation, autoSmsEnabled, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmergencyContactRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.relation == this.relation &&
          other.autoSmsEnabled == this.autoSmsEnabled &&
          other.sortOrder == this.sortOrder);
}

class EmergencyContactRowsCompanion
    extends UpdateCompanion<EmergencyContactRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> phone;
  final Value<String?> relation;
  final Value<bool> autoSmsEnabled;
  final Value<int> sortOrder;
  const EmergencyContactRowsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.relation = const Value.absent(),
    this.autoSmsEnabled = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  EmergencyContactRowsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String phone,
    this.relation = const Value.absent(),
    this.autoSmsEnabled = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : name = Value(name),
       phone = Value(phone);
  static Insertable<EmergencyContactRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? relation,
    Expression<bool>? autoSmsEnabled,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (relation != null) 'relation': relation,
      if (autoSmsEnabled != null) 'auto_sms_enabled': autoSmsEnabled,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  EmergencyContactRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? phone,
    Value<String?>? relation,
    Value<bool>? autoSmsEnabled,
    Value<int>? sortOrder,
  }) {
    return EmergencyContactRowsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relation: relation ?? this.relation,
      autoSmsEnabled: autoSmsEnabled ?? this.autoSmsEnabled,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (relation.present) {
      map['relation'] = Variable<String>(relation.value);
    }
    if (autoSmsEnabled.present) {
      map['auto_sms_enabled'] = Variable<bool>(autoSmsEnabled.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmergencyContactRowsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('relation: $relation, ')
          ..write('autoSmsEnabled: $autoSmsEnabled, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $FoodItemRowsTable extends FoodItemRows
    with TableInfo<$FoodItemRowsTable, FoodItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodItemRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sodiumMgMeta = const VerificationMeta(
    'sodiumMg',
  );
  @override
  late final GeneratedColumn<double> sodiumMg = GeneratedColumn<double>(
    'sodium_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _potassiumMgMeta = const VerificationMeta(
    'potassiumMg',
  );
  @override
  late final GeneratedColumn<double> potassiumMg = GeneratedColumn<double>(
    'potassium_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phosphorusMgMeta = const VerificationMeta(
    'phosphorusMg',
  );
  @override
  late final GeneratedColumn<double> phosphorusMg = GeneratedColumn<double>(
    'phosphorus_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fluidMlMeta = const VerificationMeta(
    'fluidMl',
  );
  @override
  late final GeneratedColumn<double> fluidMl = GeneratedColumn<double>(
    'fluid_ml',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _portionGMeta = const VerificationMeta(
    'portionG',
  );
  @override
  late final GeneratedColumn<double> portionG = GeneratedColumn<double>(
    'portion_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _portionLabelMeta = const VerificationMeta(
    'portionLabel',
  );
  @override
  late final GeneratedColumn<String> portionLabel = GeneratedColumn<String>(
    'portion_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('user'),
  );
  static const VerificationMeta _sourceNoteMeta = const VerificationMeta(
    'sourceNote',
  );
  @override
  late final GeneratedColumn<String> sourceNote = GeneratedColumn<String>(
    'source_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isApproximateMeta = const VerificationMeta(
    'isApproximate',
  );
  @override
  late final GeneratedColumn<bool> isApproximate = GeneratedColumn<bool>(
    'is_approximate',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_approximate" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    category,
    kcal,
    proteinG,
    sodiumMg,
    potassiumMg,
    phosphorusMg,
    fluidMl,
    portionG,
    portionLabel,
    source,
    sourceNote,
    barcode,
    isApproximate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_item_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    }
    if (data.containsKey('sodium_mg')) {
      context.handle(
        _sodiumMgMeta,
        sodiumMg.isAcceptableOrUnknown(data['sodium_mg']!, _sodiumMgMeta),
      );
    }
    if (data.containsKey('potassium_mg')) {
      context.handle(
        _potassiumMgMeta,
        potassiumMg.isAcceptableOrUnknown(
          data['potassium_mg']!,
          _potassiumMgMeta,
        ),
      );
    }
    if (data.containsKey('phosphorus_mg')) {
      context.handle(
        _phosphorusMgMeta,
        phosphorusMg.isAcceptableOrUnknown(
          data['phosphorus_mg']!,
          _phosphorusMgMeta,
        ),
      );
    }
    if (data.containsKey('fluid_ml')) {
      context.handle(
        _fluidMlMeta,
        fluidMl.isAcceptableOrUnknown(data['fluid_ml']!, _fluidMlMeta),
      );
    }
    if (data.containsKey('portion_g')) {
      context.handle(
        _portionGMeta,
        portionG.isAcceptableOrUnknown(data['portion_g']!, _portionGMeta),
      );
    }
    if (data.containsKey('portion_label')) {
      context.handle(
        _portionLabelMeta,
        portionLabel.isAcceptableOrUnknown(
          data['portion_label']!,
          _portionLabelMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('source_note')) {
      context.handle(
        _sourceNoteMeta,
        sourceNote.isAcceptableOrUnknown(data['source_note']!, _sourceNoteMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('is_approximate')) {
      context.handle(
        _isApproximateMeta,
        isApproximate.isAcceptableOrUnknown(
          data['is_approximate']!,
          _isApproximateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal'],
      ),
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      ),
      sodiumMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sodium_mg'],
      ),
      potassiumMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}potassium_mg'],
      ),
      phosphorusMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}phosphorus_mg'],
      ),
      fluidMl: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fluid_ml'],
      ),
      portionG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}portion_g'],
      ),
      portionLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}portion_label'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_note'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      isApproximate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_approximate'],
      )!,
    );
  }

  @override
  $FoodItemRowsTable createAlias(String alias) {
    return $FoodItemRowsTable(attachedDatabase, alias);
  }
}

class FoodItemRow extends DataClass implements Insertable<FoodItemRow> {
  final int id;
  final String name;
  final String? category;

  /// 100 g başına değerler. null = bilinmiyor (sıfır DEĞİL).
  final double? kcal;
  final double? proteinG;
  final double? sodiumMg;
  final double? potassiumMg;
  final double? phosphorusMg;
  final double? fluidMl;

  /// Tipik porsiyon gramı (arayüzde öneri).
  final double? portionG;
  final String? portionLabel;

  /// 'local' (yerel JSON), 'off' (Open Food Facts), 'user', 'ai'
  final String source;
  final String? sourceNote;
  final String? barcode;
  final bool isApproximate;
  const FoodItemRow({
    required this.id,
    required this.name,
    this.category,
    this.kcal,
    this.proteinG,
    this.sodiumMg,
    this.potassiumMg,
    this.phosphorusMg,
    this.fluidMl,
    this.portionG,
    this.portionLabel,
    required this.source,
    this.sourceNote,
    this.barcode,
    required this.isApproximate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || kcal != null) {
      map['kcal'] = Variable<double>(kcal);
    }
    if (!nullToAbsent || proteinG != null) {
      map['protein_g'] = Variable<double>(proteinG);
    }
    if (!nullToAbsent || sodiumMg != null) {
      map['sodium_mg'] = Variable<double>(sodiumMg);
    }
    if (!nullToAbsent || potassiumMg != null) {
      map['potassium_mg'] = Variable<double>(potassiumMg);
    }
    if (!nullToAbsent || phosphorusMg != null) {
      map['phosphorus_mg'] = Variable<double>(phosphorusMg);
    }
    if (!nullToAbsent || fluidMl != null) {
      map['fluid_ml'] = Variable<double>(fluidMl);
    }
    if (!nullToAbsent || portionG != null) {
      map['portion_g'] = Variable<double>(portionG);
    }
    if (!nullToAbsent || portionLabel != null) {
      map['portion_label'] = Variable<String>(portionLabel);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || sourceNote != null) {
      map['source_note'] = Variable<String>(sourceNote);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['is_approximate'] = Variable<bool>(isApproximate);
    return map;
  }

  FoodItemRowsCompanion toCompanion(bool nullToAbsent) {
    return FoodItemRowsCompanion(
      id: Value(id),
      name: Value(name),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      kcal: kcal == null && nullToAbsent ? const Value.absent() : Value(kcal),
      proteinG: proteinG == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinG),
      sodiumMg: sodiumMg == null && nullToAbsent
          ? const Value.absent()
          : Value(sodiumMg),
      potassiumMg: potassiumMg == null && nullToAbsent
          ? const Value.absent()
          : Value(potassiumMg),
      phosphorusMg: phosphorusMg == null && nullToAbsent
          ? const Value.absent()
          : Value(phosphorusMg),
      fluidMl: fluidMl == null && nullToAbsent
          ? const Value.absent()
          : Value(fluidMl),
      portionG: portionG == null && nullToAbsent
          ? const Value.absent()
          : Value(portionG),
      portionLabel: portionLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(portionLabel),
      source: Value(source),
      sourceNote: sourceNote == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceNote),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      isApproximate: Value(isApproximate),
    );
  }

  factory FoodItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodItemRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String?>(json['category']),
      kcal: serializer.fromJson<double?>(json['kcal']),
      proteinG: serializer.fromJson<double?>(json['proteinG']),
      sodiumMg: serializer.fromJson<double?>(json['sodiumMg']),
      potassiumMg: serializer.fromJson<double?>(json['potassiumMg']),
      phosphorusMg: serializer.fromJson<double?>(json['phosphorusMg']),
      fluidMl: serializer.fromJson<double?>(json['fluidMl']),
      portionG: serializer.fromJson<double?>(json['portionG']),
      portionLabel: serializer.fromJson<String?>(json['portionLabel']),
      source: serializer.fromJson<String>(json['source']),
      sourceNote: serializer.fromJson<String?>(json['sourceNote']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      isApproximate: serializer.fromJson<bool>(json['isApproximate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String?>(category),
      'kcal': serializer.toJson<double?>(kcal),
      'proteinG': serializer.toJson<double?>(proteinG),
      'sodiumMg': serializer.toJson<double?>(sodiumMg),
      'potassiumMg': serializer.toJson<double?>(potassiumMg),
      'phosphorusMg': serializer.toJson<double?>(phosphorusMg),
      'fluidMl': serializer.toJson<double?>(fluidMl),
      'portionG': serializer.toJson<double?>(portionG),
      'portionLabel': serializer.toJson<String?>(portionLabel),
      'source': serializer.toJson<String>(source),
      'sourceNote': serializer.toJson<String?>(sourceNote),
      'barcode': serializer.toJson<String?>(barcode),
      'isApproximate': serializer.toJson<bool>(isApproximate),
    };
  }

  FoodItemRow copyWith({
    int? id,
    String? name,
    Value<String?> category = const Value.absent(),
    Value<double?> kcal = const Value.absent(),
    Value<double?> proteinG = const Value.absent(),
    Value<double?> sodiumMg = const Value.absent(),
    Value<double?> potassiumMg = const Value.absent(),
    Value<double?> phosphorusMg = const Value.absent(),
    Value<double?> fluidMl = const Value.absent(),
    Value<double?> portionG = const Value.absent(),
    Value<String?> portionLabel = const Value.absent(),
    String? source,
    Value<String?> sourceNote = const Value.absent(),
    Value<String?> barcode = const Value.absent(),
    bool? isApproximate,
  }) => FoodItemRow(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category.present ? category.value : this.category,
    kcal: kcal.present ? kcal.value : this.kcal,
    proteinG: proteinG.present ? proteinG.value : this.proteinG,
    sodiumMg: sodiumMg.present ? sodiumMg.value : this.sodiumMg,
    potassiumMg: potassiumMg.present ? potassiumMg.value : this.potassiumMg,
    phosphorusMg: phosphorusMg.present ? phosphorusMg.value : this.phosphorusMg,
    fluidMl: fluidMl.present ? fluidMl.value : this.fluidMl,
    portionG: portionG.present ? portionG.value : this.portionG,
    portionLabel: portionLabel.present ? portionLabel.value : this.portionLabel,
    source: source ?? this.source,
    sourceNote: sourceNote.present ? sourceNote.value : this.sourceNote,
    barcode: barcode.present ? barcode.value : this.barcode,
    isApproximate: isApproximate ?? this.isApproximate,
  );
  FoodItemRow copyWithCompanion(FoodItemRowsCompanion data) {
    return FoodItemRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      sodiumMg: data.sodiumMg.present ? data.sodiumMg.value : this.sodiumMg,
      potassiumMg: data.potassiumMg.present
          ? data.potassiumMg.value
          : this.potassiumMg,
      phosphorusMg: data.phosphorusMg.present
          ? data.phosphorusMg.value
          : this.phosphorusMg,
      fluidMl: data.fluidMl.present ? data.fluidMl.value : this.fluidMl,
      portionG: data.portionG.present ? data.portionG.value : this.portionG,
      portionLabel: data.portionLabel.present
          ? data.portionLabel.value
          : this.portionLabel,
      source: data.source.present ? data.source.value : this.source,
      sourceNote: data.sourceNote.present
          ? data.sourceNote.value
          : this.sourceNote,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      isApproximate: data.isApproximate.present
          ? data.isApproximate.value
          : this.isApproximate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodItemRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('sodiumMg: $sodiumMg, ')
          ..write('potassiumMg: $potassiumMg, ')
          ..write('phosphorusMg: $phosphorusMg, ')
          ..write('fluidMl: $fluidMl, ')
          ..write('portionG: $portionG, ')
          ..write('portionLabel: $portionLabel, ')
          ..write('source: $source, ')
          ..write('sourceNote: $sourceNote, ')
          ..write('barcode: $barcode, ')
          ..write('isApproximate: $isApproximate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    kcal,
    proteinG,
    sodiumMg,
    potassiumMg,
    phosphorusMg,
    fluidMl,
    portionG,
    portionLabel,
    source,
    sourceNote,
    barcode,
    isApproximate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodItemRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.kcal == this.kcal &&
          other.proteinG == this.proteinG &&
          other.sodiumMg == this.sodiumMg &&
          other.potassiumMg == this.potassiumMg &&
          other.phosphorusMg == this.phosphorusMg &&
          other.fluidMl == this.fluidMl &&
          other.portionG == this.portionG &&
          other.portionLabel == this.portionLabel &&
          other.source == this.source &&
          other.sourceNote == this.sourceNote &&
          other.barcode == this.barcode &&
          other.isApproximate == this.isApproximate);
}

class FoodItemRowsCompanion extends UpdateCompanion<FoodItemRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> category;
  final Value<double?> kcal;
  final Value<double?> proteinG;
  final Value<double?> sodiumMg;
  final Value<double?> potassiumMg;
  final Value<double?> phosphorusMg;
  final Value<double?> fluidMl;
  final Value<double?> portionG;
  final Value<String?> portionLabel;
  final Value<String> source;
  final Value<String?> sourceNote;
  final Value<String?> barcode;
  final Value<bool> isApproximate;
  const FoodItemRowsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.sodiumMg = const Value.absent(),
    this.potassiumMg = const Value.absent(),
    this.phosphorusMg = const Value.absent(),
    this.fluidMl = const Value.absent(),
    this.portionG = const Value.absent(),
    this.portionLabel = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceNote = const Value.absent(),
    this.barcode = const Value.absent(),
    this.isApproximate = const Value.absent(),
  });
  FoodItemRowsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.category = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.sodiumMg = const Value.absent(),
    this.potassiumMg = const Value.absent(),
    this.phosphorusMg = const Value.absent(),
    this.fluidMl = const Value.absent(),
    this.portionG = const Value.absent(),
    this.portionLabel = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceNote = const Value.absent(),
    this.barcode = const Value.absent(),
    this.isApproximate = const Value.absent(),
  }) : name = Value(name);
  static Insertable<FoodItemRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<double>? kcal,
    Expression<double>? proteinG,
    Expression<double>? sodiumMg,
    Expression<double>? potassiumMg,
    Expression<double>? phosphorusMg,
    Expression<double>? fluidMl,
    Expression<double>? portionG,
    Expression<String>? portionLabel,
    Expression<String>? source,
    Expression<String>? sourceNote,
    Expression<String>? barcode,
    Expression<bool>? isApproximate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (kcal != null) 'kcal': kcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (sodiumMg != null) 'sodium_mg': sodiumMg,
      if (potassiumMg != null) 'potassium_mg': potassiumMg,
      if (phosphorusMg != null) 'phosphorus_mg': phosphorusMg,
      if (fluidMl != null) 'fluid_ml': fluidMl,
      if (portionG != null) 'portion_g': portionG,
      if (portionLabel != null) 'portion_label': portionLabel,
      if (source != null) 'source': source,
      if (sourceNote != null) 'source_note': sourceNote,
      if (barcode != null) 'barcode': barcode,
      if (isApproximate != null) 'is_approximate': isApproximate,
    });
  }

  FoodItemRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? category,
    Value<double?>? kcal,
    Value<double?>? proteinG,
    Value<double?>? sodiumMg,
    Value<double?>? potassiumMg,
    Value<double?>? phosphorusMg,
    Value<double?>? fluidMl,
    Value<double?>? portionG,
    Value<String?>? portionLabel,
    Value<String>? source,
    Value<String?>? sourceNote,
    Value<String?>? barcode,
    Value<bool>? isApproximate,
  }) {
    return FoodItemRowsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      kcal: kcal ?? this.kcal,
      proteinG: proteinG ?? this.proteinG,
      sodiumMg: sodiumMg ?? this.sodiumMg,
      potassiumMg: potassiumMg ?? this.potassiumMg,
      phosphorusMg: phosphorusMg ?? this.phosphorusMg,
      fluidMl: fluidMl ?? this.fluidMl,
      portionG: portionG ?? this.portionG,
      portionLabel: portionLabel ?? this.portionLabel,
      source: source ?? this.source,
      sourceNote: sourceNote ?? this.sourceNote,
      barcode: barcode ?? this.barcode,
      isApproximate: isApproximate ?? this.isApproximate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (sodiumMg.present) {
      map['sodium_mg'] = Variable<double>(sodiumMg.value);
    }
    if (potassiumMg.present) {
      map['potassium_mg'] = Variable<double>(potassiumMg.value);
    }
    if (phosphorusMg.present) {
      map['phosphorus_mg'] = Variable<double>(phosphorusMg.value);
    }
    if (fluidMl.present) {
      map['fluid_ml'] = Variable<double>(fluidMl.value);
    }
    if (portionG.present) {
      map['portion_g'] = Variable<double>(portionG.value);
    }
    if (portionLabel.present) {
      map['portion_label'] = Variable<String>(portionLabel.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceNote.present) {
      map['source_note'] = Variable<String>(sourceNote.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (isApproximate.present) {
      map['is_approximate'] = Variable<bool>(isApproximate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodItemRowsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('sodiumMg: $sodiumMg, ')
          ..write('potassiumMg: $potassiumMg, ')
          ..write('phosphorusMg: $phosphorusMg, ')
          ..write('fluidMl: $fluidMl, ')
          ..write('portionG: $portionG, ')
          ..write('portionLabel: $portionLabel, ')
          ..write('source: $source, ')
          ..write('sourceNote: $sourceNote, ')
          ..write('barcode: $barcode, ')
          ..write('isApproximate: $isApproximate')
          ..write(')'))
        .toString();
  }
}

class $FoodLogRowsTable extends FoodLogRows
    with TableInfo<$FoodLogRowsTable, FoodLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodLogRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _foodItemIdMeta = const VerificationMeta(
    'foodItemId',
  );
  @override
  late final GeneratedColumn<int> foodItemId = GeneratedColumn<int>(
    'food_item_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sodiumMgMeta = const VerificationMeta(
    'sodiumMg',
  );
  @override
  late final GeneratedColumn<double> sodiumMg = GeneratedColumn<double>(
    'sodium_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _potassiumMgMeta = const VerificationMeta(
    'potassiumMg',
  );
  @override
  late final GeneratedColumn<double> potassiumMg = GeneratedColumn<double>(
    'potassium_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phosphorusMgMeta = const VerificationMeta(
    'phosphorusMg',
  );
  @override
  late final GeneratedColumn<double> phosphorusMg = GeneratedColumn<double>(
    'phosphorus_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fluidMlMeta = const VerificationMeta(
    'fluidMl',
  );
  @override
  late final GeneratedColumn<double> fluidMl = GeneratedColumn<double>(
    'fluid_ml',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mealTypeMeta = const VerificationMeta(
    'mealType',
  );
  @override
  late final GeneratedColumn<String> mealType = GeneratedColumn<String>(
    'meal_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<String> confidence = GeneratedColumn<String>(
    'confidence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _consumedAtMeta = const VerificationMeta(
    'consumedAt',
  );
  @override
  late final GeneratedColumn<DateTime> consumedAt = GeneratedColumn<DateTime>(
    'consumed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    foodItemId,
    label,
    grams,
    kcal,
    proteinG,
    sodiumMg,
    potassiumMg,
    phosphorusMg,
    fluidMl,
    mealType,
    origin,
    confidence,
    note,
    consumedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_log_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('food_item_id')) {
      context.handle(
        _foodItemIdMeta,
        foodItemId.isAcceptableOrUnknown(
          data['food_item_id']!,
          _foodItemIdMeta,
        ),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    }
    if (data.containsKey('sodium_mg')) {
      context.handle(
        _sodiumMgMeta,
        sodiumMg.isAcceptableOrUnknown(data['sodium_mg']!, _sodiumMgMeta),
      );
    }
    if (data.containsKey('potassium_mg')) {
      context.handle(
        _potassiumMgMeta,
        potassiumMg.isAcceptableOrUnknown(
          data['potassium_mg']!,
          _potassiumMgMeta,
        ),
      );
    }
    if (data.containsKey('phosphorus_mg')) {
      context.handle(
        _phosphorusMgMeta,
        phosphorusMg.isAcceptableOrUnknown(
          data['phosphorus_mg']!,
          _phosphorusMgMeta,
        ),
      );
    }
    if (data.containsKey('fluid_ml')) {
      context.handle(
        _fluidMlMeta,
        fluidMl.isAcceptableOrUnknown(data['fluid_ml']!, _fluidMlMeta),
      );
    }
    if (data.containsKey('meal_type')) {
      context.handle(
        _mealTypeMeta,
        mealType.isAcceptableOrUnknown(data['meal_type']!, _mealTypeMeta),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('consumed_at')) {
      context.handle(
        _consumedAtMeta,
        consumedAt.isAcceptableOrUnknown(data['consumed_at']!, _consumedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_consumedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      foodItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}food_item_id'],
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal'],
      ),
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      ),
      sodiumMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sodium_mg'],
      ),
      potassiumMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}potassium_mg'],
      ),
      phosphorusMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}phosphorus_mg'],
      ),
      fluidMl: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fluid_ml'],
      ),
      mealType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_type'],
      ),
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confidence'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      consumedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}consumed_at'],
      )!,
    );
  }

  @override
  $FoodLogRowsTable createAlias(String alias) {
    return $FoodLogRowsTable(attachedDatabase, alias);
  }
}

class FoodLogRow extends DataClass implements Insertable<FoodLogRow> {
  final int id;
  final int? foodItemId;

  /// Serbest metin kaydı (AI analizi veya elle giriş).
  final String label;
  final double grams;

  /// Hesaplanmış değerler kaydedilir (besin tanımı sonradan değişebilir).
  final double? kcal;
  final double? proteinG;
  final double? sodiumMg;
  final double? potassiumMg;
  final double? phosphorusMg;
  final double? fluidMl;
  final String? mealType;
  final String origin;

  /// AI tahmini ise güven düzeyi: 'low' | 'medium' | 'high'
  final String? confidence;
  final String? note;
  final DateTime consumedAt;
  const FoodLogRow({
    required this.id,
    this.foodItemId,
    required this.label,
    required this.grams,
    this.kcal,
    this.proteinG,
    this.sodiumMg,
    this.potassiumMg,
    this.phosphorusMg,
    this.fluidMl,
    this.mealType,
    required this.origin,
    this.confidence,
    this.note,
    required this.consumedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || foodItemId != null) {
      map['food_item_id'] = Variable<int>(foodItemId);
    }
    map['label'] = Variable<String>(label);
    map['grams'] = Variable<double>(grams);
    if (!nullToAbsent || kcal != null) {
      map['kcal'] = Variable<double>(kcal);
    }
    if (!nullToAbsent || proteinG != null) {
      map['protein_g'] = Variable<double>(proteinG);
    }
    if (!nullToAbsent || sodiumMg != null) {
      map['sodium_mg'] = Variable<double>(sodiumMg);
    }
    if (!nullToAbsent || potassiumMg != null) {
      map['potassium_mg'] = Variable<double>(potassiumMg);
    }
    if (!nullToAbsent || phosphorusMg != null) {
      map['phosphorus_mg'] = Variable<double>(phosphorusMg);
    }
    if (!nullToAbsent || fluidMl != null) {
      map['fluid_ml'] = Variable<double>(fluidMl);
    }
    if (!nullToAbsent || mealType != null) {
      map['meal_type'] = Variable<String>(mealType);
    }
    map['origin'] = Variable<String>(origin);
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<String>(confidence);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['consumed_at'] = Variable<DateTime>(consumedAt);
    return map;
  }

  FoodLogRowsCompanion toCompanion(bool nullToAbsent) {
    return FoodLogRowsCompanion(
      id: Value(id),
      foodItemId: foodItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(foodItemId),
      label: Value(label),
      grams: Value(grams),
      kcal: kcal == null && nullToAbsent ? const Value.absent() : Value(kcal),
      proteinG: proteinG == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinG),
      sodiumMg: sodiumMg == null && nullToAbsent
          ? const Value.absent()
          : Value(sodiumMg),
      potassiumMg: potassiumMg == null && nullToAbsent
          ? const Value.absent()
          : Value(potassiumMg),
      phosphorusMg: phosphorusMg == null && nullToAbsent
          ? const Value.absent()
          : Value(phosphorusMg),
      fluidMl: fluidMl == null && nullToAbsent
          ? const Value.absent()
          : Value(fluidMl),
      mealType: mealType == null && nullToAbsent
          ? const Value.absent()
          : Value(mealType),
      origin: Value(origin),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      consumedAt: Value(consumedAt),
    );
  }

  factory FoodLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodLogRow(
      id: serializer.fromJson<int>(json['id']),
      foodItemId: serializer.fromJson<int?>(json['foodItemId']),
      label: serializer.fromJson<String>(json['label']),
      grams: serializer.fromJson<double>(json['grams']),
      kcal: serializer.fromJson<double?>(json['kcal']),
      proteinG: serializer.fromJson<double?>(json['proteinG']),
      sodiumMg: serializer.fromJson<double?>(json['sodiumMg']),
      potassiumMg: serializer.fromJson<double?>(json['potassiumMg']),
      phosphorusMg: serializer.fromJson<double?>(json['phosphorusMg']),
      fluidMl: serializer.fromJson<double?>(json['fluidMl']),
      mealType: serializer.fromJson<String?>(json['mealType']),
      origin: serializer.fromJson<String>(json['origin']),
      confidence: serializer.fromJson<String?>(json['confidence']),
      note: serializer.fromJson<String?>(json['note']),
      consumedAt: serializer.fromJson<DateTime>(json['consumedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'foodItemId': serializer.toJson<int?>(foodItemId),
      'label': serializer.toJson<String>(label),
      'grams': serializer.toJson<double>(grams),
      'kcal': serializer.toJson<double?>(kcal),
      'proteinG': serializer.toJson<double?>(proteinG),
      'sodiumMg': serializer.toJson<double?>(sodiumMg),
      'potassiumMg': serializer.toJson<double?>(potassiumMg),
      'phosphorusMg': serializer.toJson<double?>(phosphorusMg),
      'fluidMl': serializer.toJson<double?>(fluidMl),
      'mealType': serializer.toJson<String?>(mealType),
      'origin': serializer.toJson<String>(origin),
      'confidence': serializer.toJson<String?>(confidence),
      'note': serializer.toJson<String?>(note),
      'consumedAt': serializer.toJson<DateTime>(consumedAt),
    };
  }

  FoodLogRow copyWith({
    int? id,
    Value<int?> foodItemId = const Value.absent(),
    String? label,
    double? grams,
    Value<double?> kcal = const Value.absent(),
    Value<double?> proteinG = const Value.absent(),
    Value<double?> sodiumMg = const Value.absent(),
    Value<double?> potassiumMg = const Value.absent(),
    Value<double?> phosphorusMg = const Value.absent(),
    Value<double?> fluidMl = const Value.absent(),
    Value<String?> mealType = const Value.absent(),
    String? origin,
    Value<String?> confidence = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? consumedAt,
  }) => FoodLogRow(
    id: id ?? this.id,
    foodItemId: foodItemId.present ? foodItemId.value : this.foodItemId,
    label: label ?? this.label,
    grams: grams ?? this.grams,
    kcal: kcal.present ? kcal.value : this.kcal,
    proteinG: proteinG.present ? proteinG.value : this.proteinG,
    sodiumMg: sodiumMg.present ? sodiumMg.value : this.sodiumMg,
    potassiumMg: potassiumMg.present ? potassiumMg.value : this.potassiumMg,
    phosphorusMg: phosphorusMg.present ? phosphorusMg.value : this.phosphorusMg,
    fluidMl: fluidMl.present ? fluidMl.value : this.fluidMl,
    mealType: mealType.present ? mealType.value : this.mealType,
    origin: origin ?? this.origin,
    confidence: confidence.present ? confidence.value : this.confidence,
    note: note.present ? note.value : this.note,
    consumedAt: consumedAt ?? this.consumedAt,
  );
  FoodLogRow copyWithCompanion(FoodLogRowsCompanion data) {
    return FoodLogRow(
      id: data.id.present ? data.id.value : this.id,
      foodItemId: data.foodItemId.present
          ? data.foodItemId.value
          : this.foodItemId,
      label: data.label.present ? data.label.value : this.label,
      grams: data.grams.present ? data.grams.value : this.grams,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      sodiumMg: data.sodiumMg.present ? data.sodiumMg.value : this.sodiumMg,
      potassiumMg: data.potassiumMg.present
          ? data.potassiumMg.value
          : this.potassiumMg,
      phosphorusMg: data.phosphorusMg.present
          ? data.phosphorusMg.value
          : this.phosphorusMg,
      fluidMl: data.fluidMl.present ? data.fluidMl.value : this.fluidMl,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
      origin: data.origin.present ? data.origin.value : this.origin,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      note: data.note.present ? data.note.value : this.note,
      consumedAt: data.consumedAt.present
          ? data.consumedAt.value
          : this.consumedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodLogRow(')
          ..write('id: $id, ')
          ..write('foodItemId: $foodItemId, ')
          ..write('label: $label, ')
          ..write('grams: $grams, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('sodiumMg: $sodiumMg, ')
          ..write('potassiumMg: $potassiumMg, ')
          ..write('phosphorusMg: $phosphorusMg, ')
          ..write('fluidMl: $fluidMl, ')
          ..write('mealType: $mealType, ')
          ..write('origin: $origin, ')
          ..write('confidence: $confidence, ')
          ..write('note: $note, ')
          ..write('consumedAt: $consumedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    foodItemId,
    label,
    grams,
    kcal,
    proteinG,
    sodiumMg,
    potassiumMg,
    phosphorusMg,
    fluidMl,
    mealType,
    origin,
    confidence,
    note,
    consumedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodLogRow &&
          other.id == this.id &&
          other.foodItemId == this.foodItemId &&
          other.label == this.label &&
          other.grams == this.grams &&
          other.kcal == this.kcal &&
          other.proteinG == this.proteinG &&
          other.sodiumMg == this.sodiumMg &&
          other.potassiumMg == this.potassiumMg &&
          other.phosphorusMg == this.phosphorusMg &&
          other.fluidMl == this.fluidMl &&
          other.mealType == this.mealType &&
          other.origin == this.origin &&
          other.confidence == this.confidence &&
          other.note == this.note &&
          other.consumedAt == this.consumedAt);
}

class FoodLogRowsCompanion extends UpdateCompanion<FoodLogRow> {
  final Value<int> id;
  final Value<int?> foodItemId;
  final Value<String> label;
  final Value<double> grams;
  final Value<double?> kcal;
  final Value<double?> proteinG;
  final Value<double?> sodiumMg;
  final Value<double?> potassiumMg;
  final Value<double?> phosphorusMg;
  final Value<double?> fluidMl;
  final Value<String?> mealType;
  final Value<String> origin;
  final Value<String?> confidence;
  final Value<String?> note;
  final Value<DateTime> consumedAt;
  const FoodLogRowsCompanion({
    this.id = const Value.absent(),
    this.foodItemId = const Value.absent(),
    this.label = const Value.absent(),
    this.grams = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.sodiumMg = const Value.absent(),
    this.potassiumMg = const Value.absent(),
    this.phosphorusMg = const Value.absent(),
    this.fluidMl = const Value.absent(),
    this.mealType = const Value.absent(),
    this.origin = const Value.absent(),
    this.confidence = const Value.absent(),
    this.note = const Value.absent(),
    this.consumedAt = const Value.absent(),
  });
  FoodLogRowsCompanion.insert({
    this.id = const Value.absent(),
    this.foodItemId = const Value.absent(),
    required String label,
    required double grams,
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.sodiumMg = const Value.absent(),
    this.potassiumMg = const Value.absent(),
    this.phosphorusMg = const Value.absent(),
    this.fluidMl = const Value.absent(),
    this.mealType = const Value.absent(),
    this.origin = const Value.absent(),
    this.confidence = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime consumedAt,
  }) : label = Value(label),
       grams = Value(grams),
       consumedAt = Value(consumedAt);
  static Insertable<FoodLogRow> custom({
    Expression<int>? id,
    Expression<int>? foodItemId,
    Expression<String>? label,
    Expression<double>? grams,
    Expression<double>? kcal,
    Expression<double>? proteinG,
    Expression<double>? sodiumMg,
    Expression<double>? potassiumMg,
    Expression<double>? phosphorusMg,
    Expression<double>? fluidMl,
    Expression<String>? mealType,
    Expression<String>? origin,
    Expression<String>? confidence,
    Expression<String>? note,
    Expression<DateTime>? consumedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (foodItemId != null) 'food_item_id': foodItemId,
      if (label != null) 'label': label,
      if (grams != null) 'grams': grams,
      if (kcal != null) 'kcal': kcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (sodiumMg != null) 'sodium_mg': sodiumMg,
      if (potassiumMg != null) 'potassium_mg': potassiumMg,
      if (phosphorusMg != null) 'phosphorus_mg': phosphorusMg,
      if (fluidMl != null) 'fluid_ml': fluidMl,
      if (mealType != null) 'meal_type': mealType,
      if (origin != null) 'origin': origin,
      if (confidence != null) 'confidence': confidence,
      if (note != null) 'note': note,
      if (consumedAt != null) 'consumed_at': consumedAt,
    });
  }

  FoodLogRowsCompanion copyWith({
    Value<int>? id,
    Value<int?>? foodItemId,
    Value<String>? label,
    Value<double>? grams,
    Value<double?>? kcal,
    Value<double?>? proteinG,
    Value<double?>? sodiumMg,
    Value<double?>? potassiumMg,
    Value<double?>? phosphorusMg,
    Value<double?>? fluidMl,
    Value<String?>? mealType,
    Value<String>? origin,
    Value<String?>? confidence,
    Value<String?>? note,
    Value<DateTime>? consumedAt,
  }) {
    return FoodLogRowsCompanion(
      id: id ?? this.id,
      foodItemId: foodItemId ?? this.foodItemId,
      label: label ?? this.label,
      grams: grams ?? this.grams,
      kcal: kcal ?? this.kcal,
      proteinG: proteinG ?? this.proteinG,
      sodiumMg: sodiumMg ?? this.sodiumMg,
      potassiumMg: potassiumMg ?? this.potassiumMg,
      phosphorusMg: phosphorusMg ?? this.phosphorusMg,
      fluidMl: fluidMl ?? this.fluidMl,
      mealType: mealType ?? this.mealType,
      origin: origin ?? this.origin,
      confidence: confidence ?? this.confidence,
      note: note ?? this.note,
      consumedAt: consumedAt ?? this.consumedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (foodItemId.present) {
      map['food_item_id'] = Variable<int>(foodItemId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (sodiumMg.present) {
      map['sodium_mg'] = Variable<double>(sodiumMg.value);
    }
    if (potassiumMg.present) {
      map['potassium_mg'] = Variable<double>(potassiumMg.value);
    }
    if (phosphorusMg.present) {
      map['phosphorus_mg'] = Variable<double>(phosphorusMg.value);
    }
    if (fluidMl.present) {
      map['fluid_ml'] = Variable<double>(fluidMl.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<String>(mealType.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<String>(confidence.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (consumedAt.present) {
      map['consumed_at'] = Variable<DateTime>(consumedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodLogRowsCompanion(')
          ..write('id: $id, ')
          ..write('foodItemId: $foodItemId, ')
          ..write('label: $label, ')
          ..write('grams: $grams, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('sodiumMg: $sodiumMg, ')
          ..write('potassiumMg: $potassiumMg, ')
          ..write('phosphorusMg: $phosphorusMg, ')
          ..write('fluidMl: $fluidMl, ')
          ..write('mealType: $mealType, ')
          ..write('origin: $origin, ')
          ..write('confidence: $confidence, ')
          ..write('note: $note, ')
          ..write('consumedAt: $consumedAt')
          ..write(')'))
        .toString();
  }
}

class $FluidLogRowsTable extends FluidLogRows
    with TableInfo<$FluidLogRowsTable, FluidLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FluidLogRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mlMeta = const VerificationMeta('ml');
  @override
  late final GeneratedColumn<int> ml = GeneratedColumn<int>(
    'ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('drink'),
  );
  static const VerificationMeta _consumedAtMeta = const VerificationMeta(
    'consumedAt',
  );
  @override
  late final GeneratedColumn<DateTime> consumedAt = GeneratedColumn<DateTime>(
    'consumed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, label, ml, kind, consumedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fluid_log_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<FluidLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('ml')) {
      context.handle(_mlMeta, ml.isAcceptableOrUnknown(data['ml']!, _mlMeta));
    } else if (isInserting) {
      context.missing(_mlMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('consumed_at')) {
      context.handle(
        _consumedAtMeta,
        consumedAt.isAcceptableOrUnknown(data['consumed_at']!, _consumedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_consumedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FluidLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FluidLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      ml: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ml'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      consumedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}consumed_at'],
      )!,
    );
  }

  @override
  $FluidLogRowsTable createAlias(String alias) {
    return $FluidLogRowsTable(attachedDatabase, alias);
  }
}

class FluidLogRow extends DataClass implements Insertable<FluidLogRow> {
  final int id;
  final String label;
  final int ml;
  final String kind;
  final DateTime consumedAt;
  const FluidLogRow({
    required this.id,
    required this.label,
    required this.ml,
    required this.kind,
    required this.consumedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['label'] = Variable<String>(label);
    map['ml'] = Variable<int>(ml);
    map['kind'] = Variable<String>(kind);
    map['consumed_at'] = Variable<DateTime>(consumedAt);
    return map;
  }

  FluidLogRowsCompanion toCompanion(bool nullToAbsent) {
    return FluidLogRowsCompanion(
      id: Value(id),
      label: Value(label),
      ml: Value(ml),
      kind: Value(kind),
      consumedAt: Value(consumedAt),
    );
  }

  factory FluidLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FluidLogRow(
      id: serializer.fromJson<int>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      ml: serializer.fromJson<int>(json['ml']),
      kind: serializer.fromJson<String>(json['kind']),
      consumedAt: serializer.fromJson<DateTime>(json['consumedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'label': serializer.toJson<String>(label),
      'ml': serializer.toJson<int>(ml),
      'kind': serializer.toJson<String>(kind),
      'consumedAt': serializer.toJson<DateTime>(consumedAt),
    };
  }

  FluidLogRow copyWith({
    int? id,
    String? label,
    int? ml,
    String? kind,
    DateTime? consumedAt,
  }) => FluidLogRow(
    id: id ?? this.id,
    label: label ?? this.label,
    ml: ml ?? this.ml,
    kind: kind ?? this.kind,
    consumedAt: consumedAt ?? this.consumedAt,
  );
  FluidLogRow copyWithCompanion(FluidLogRowsCompanion data) {
    return FluidLogRow(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      ml: data.ml.present ? data.ml.value : this.ml,
      kind: data.kind.present ? data.kind.value : this.kind,
      consumedAt: data.consumedAt.present
          ? data.consumedAt.value
          : this.consumedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FluidLogRow(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('ml: $ml, ')
          ..write('kind: $kind, ')
          ..write('consumedAt: $consumedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label, ml, kind, consumedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FluidLogRow &&
          other.id == this.id &&
          other.label == this.label &&
          other.ml == this.ml &&
          other.kind == this.kind &&
          other.consumedAt == this.consumedAt);
}

class FluidLogRowsCompanion extends UpdateCompanion<FluidLogRow> {
  final Value<int> id;
  final Value<String> label;
  final Value<int> ml;
  final Value<String> kind;
  final Value<DateTime> consumedAt;
  const FluidLogRowsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.ml = const Value.absent(),
    this.kind = const Value.absent(),
    this.consumedAt = const Value.absent(),
  });
  FluidLogRowsCompanion.insert({
    this.id = const Value.absent(),
    required String label,
    required int ml,
    this.kind = const Value.absent(),
    required DateTime consumedAt,
  }) : label = Value(label),
       ml = Value(ml),
       consumedAt = Value(consumedAt);
  static Insertable<FluidLogRow> custom({
    Expression<int>? id,
    Expression<String>? label,
    Expression<int>? ml,
    Expression<String>? kind,
    Expression<DateTime>? consumedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (ml != null) 'ml': ml,
      if (kind != null) 'kind': kind,
      if (consumedAt != null) 'consumed_at': consumedAt,
    });
  }

  FluidLogRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? label,
    Value<int>? ml,
    Value<String>? kind,
    Value<DateTime>? consumedAt,
  }) {
    return FluidLogRowsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      ml: ml ?? this.ml,
      kind: kind ?? this.kind,
      consumedAt: consumedAt ?? this.consumedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (ml.present) {
      map['ml'] = Variable<int>(ml.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (consumedAt.present) {
      map['consumed_at'] = Variable<DateTime>(consumedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FluidLogRowsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('ml: $ml, ')
          ..write('kind: $kind, ')
          ..write('consumedAt: $consumedAt')
          ..write(')'))
        .toString();
  }
}

class $LabResultRowsTable extends LabResultRows
    with TableInfo<$LabResultRowsTable, LabResultRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LabResultRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _analyteMeta = const VerificationMeta(
    'analyte',
  );
  @override
  late final GeneratedColumn<String> analyte = GeneratedColumn<String>(
    'analyte',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _analyteLabelMeta = const VerificationMeta(
    'analyteLabel',
  );
  @override
  late final GeneratedColumn<String> analyteLabel = GeneratedColumn<String>(
    'analyte_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refMinMeta = const VerificationMeta('refMin');
  @override
  late final GeneratedColumn<double> refMin = GeneratedColumn<double>(
    'ref_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _refMaxMeta = const VerificationMeta('refMax');
  @override
  late final GeneratedColumn<double> refMax = GeneratedColumn<double>(
    'ref_max',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labNameMeta = const VerificationMeta(
    'labName',
  );
  @override
  late final GeneratedColumn<String> labName = GeneratedColumn<String>(
    'lab_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _confirmedByUserMeta = const VerificationMeta(
    'confirmedByUser',
  );
  @override
  late final GeneratedColumn<bool> confirmedByUser = GeneratedColumn<bool>(
    'confirmed_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("confirmed_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
    'taken_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    analyte,
    analyteLabel,
    value,
    unit,
    refMin,
    refMax,
    labName,
    origin,
    confirmedByUser,
    note,
    takenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lab_result_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<LabResultRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('analyte')) {
      context.handle(
        _analyteMeta,
        analyte.isAcceptableOrUnknown(data['analyte']!, _analyteMeta),
      );
    } else if (isInserting) {
      context.missing(_analyteMeta);
    }
    if (data.containsKey('analyte_label')) {
      context.handle(
        _analyteLabelMeta,
        analyteLabel.isAcceptableOrUnknown(
          data['analyte_label']!,
          _analyteLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_analyteLabelMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('ref_min')) {
      context.handle(
        _refMinMeta,
        refMin.isAcceptableOrUnknown(data['ref_min']!, _refMinMeta),
      );
    }
    if (data.containsKey('ref_max')) {
      context.handle(
        _refMaxMeta,
        refMax.isAcceptableOrUnknown(data['ref_max']!, _refMaxMeta),
      );
    }
    if (data.containsKey('lab_name')) {
      context.handle(
        _labNameMeta,
        labName.isAcceptableOrUnknown(data['lab_name']!, _labNameMeta),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('confirmed_by_user')) {
      context.handle(
        _confirmedByUserMeta,
        confirmedByUser.isAcceptableOrUnknown(
          data['confirmed_by_user']!,
          _confirmedByUserMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_takenAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LabResultRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LabResultRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      analyte: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}analyte'],
      )!,
      analyteLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}analyte_label'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      refMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ref_min'],
      ),
      refMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ref_max'],
      ),
      labName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lab_name'],
      ),
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      confirmedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}confirmed_by_user'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      )!,
    );
  }

  @override
  $LabResultRowsTable createAlias(String alias) {
    return $LabResultRowsTable(attachedDatabase, alias);
  }
}

class LabResultRow extends DataClass implements Insertable<LabResultRow> {
  final int id;

  /// Klinik tanım anahtarı ('lab_hemoglobin' vb.) veya serbest ad.
  final String analyte;
  final String analyteLabel;
  final double value;
  final String unit;

  /// Kullanıcının laboratuvarının referans aralığı.
  final double? refMin;
  final double? refMax;
  final String? labName;

  /// 'manual' | 'ocr'
  final String origin;
  final bool confirmedByUser;
  final String? note;
  final DateTime takenAt;
  const LabResultRow({
    required this.id,
    required this.analyte,
    required this.analyteLabel,
    required this.value,
    required this.unit,
    this.refMin,
    this.refMax,
    this.labName,
    required this.origin,
    required this.confirmedByUser,
    this.note,
    required this.takenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['analyte'] = Variable<String>(analyte);
    map['analyte_label'] = Variable<String>(analyteLabel);
    map['value'] = Variable<double>(value);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || refMin != null) {
      map['ref_min'] = Variable<double>(refMin);
    }
    if (!nullToAbsent || refMax != null) {
      map['ref_max'] = Variable<double>(refMax);
    }
    if (!nullToAbsent || labName != null) {
      map['lab_name'] = Variable<String>(labName);
    }
    map['origin'] = Variable<String>(origin);
    map['confirmed_by_user'] = Variable<bool>(confirmedByUser);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['taken_at'] = Variable<DateTime>(takenAt);
    return map;
  }

  LabResultRowsCompanion toCompanion(bool nullToAbsent) {
    return LabResultRowsCompanion(
      id: Value(id),
      analyte: Value(analyte),
      analyteLabel: Value(analyteLabel),
      value: Value(value),
      unit: Value(unit),
      refMin: refMin == null && nullToAbsent
          ? const Value.absent()
          : Value(refMin),
      refMax: refMax == null && nullToAbsent
          ? const Value.absent()
          : Value(refMax),
      labName: labName == null && nullToAbsent
          ? const Value.absent()
          : Value(labName),
      origin: Value(origin),
      confirmedByUser: Value(confirmedByUser),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      takenAt: Value(takenAt),
    );
  }

  factory LabResultRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LabResultRow(
      id: serializer.fromJson<int>(json['id']),
      analyte: serializer.fromJson<String>(json['analyte']),
      analyteLabel: serializer.fromJson<String>(json['analyteLabel']),
      value: serializer.fromJson<double>(json['value']),
      unit: serializer.fromJson<String>(json['unit']),
      refMin: serializer.fromJson<double?>(json['refMin']),
      refMax: serializer.fromJson<double?>(json['refMax']),
      labName: serializer.fromJson<String?>(json['labName']),
      origin: serializer.fromJson<String>(json['origin']),
      confirmedByUser: serializer.fromJson<bool>(json['confirmedByUser']),
      note: serializer.fromJson<String?>(json['note']),
      takenAt: serializer.fromJson<DateTime>(json['takenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'analyte': serializer.toJson<String>(analyte),
      'analyteLabel': serializer.toJson<String>(analyteLabel),
      'value': serializer.toJson<double>(value),
      'unit': serializer.toJson<String>(unit),
      'refMin': serializer.toJson<double?>(refMin),
      'refMax': serializer.toJson<double?>(refMax),
      'labName': serializer.toJson<String?>(labName),
      'origin': serializer.toJson<String>(origin),
      'confirmedByUser': serializer.toJson<bool>(confirmedByUser),
      'note': serializer.toJson<String?>(note),
      'takenAt': serializer.toJson<DateTime>(takenAt),
    };
  }

  LabResultRow copyWith({
    int? id,
    String? analyte,
    String? analyteLabel,
    double? value,
    String? unit,
    Value<double?> refMin = const Value.absent(),
    Value<double?> refMax = const Value.absent(),
    Value<String?> labName = const Value.absent(),
    String? origin,
    bool? confirmedByUser,
    Value<String?> note = const Value.absent(),
    DateTime? takenAt,
  }) => LabResultRow(
    id: id ?? this.id,
    analyte: analyte ?? this.analyte,
    analyteLabel: analyteLabel ?? this.analyteLabel,
    value: value ?? this.value,
    unit: unit ?? this.unit,
    refMin: refMin.present ? refMin.value : this.refMin,
    refMax: refMax.present ? refMax.value : this.refMax,
    labName: labName.present ? labName.value : this.labName,
    origin: origin ?? this.origin,
    confirmedByUser: confirmedByUser ?? this.confirmedByUser,
    note: note.present ? note.value : this.note,
    takenAt: takenAt ?? this.takenAt,
  );
  LabResultRow copyWithCompanion(LabResultRowsCompanion data) {
    return LabResultRow(
      id: data.id.present ? data.id.value : this.id,
      analyte: data.analyte.present ? data.analyte.value : this.analyte,
      analyteLabel: data.analyteLabel.present
          ? data.analyteLabel.value
          : this.analyteLabel,
      value: data.value.present ? data.value.value : this.value,
      unit: data.unit.present ? data.unit.value : this.unit,
      refMin: data.refMin.present ? data.refMin.value : this.refMin,
      refMax: data.refMax.present ? data.refMax.value : this.refMax,
      labName: data.labName.present ? data.labName.value : this.labName,
      origin: data.origin.present ? data.origin.value : this.origin,
      confirmedByUser: data.confirmedByUser.present
          ? data.confirmedByUser.value
          : this.confirmedByUser,
      note: data.note.present ? data.note.value : this.note,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LabResultRow(')
          ..write('id: $id, ')
          ..write('analyte: $analyte, ')
          ..write('analyteLabel: $analyteLabel, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('refMin: $refMin, ')
          ..write('refMax: $refMax, ')
          ..write('labName: $labName, ')
          ..write('origin: $origin, ')
          ..write('confirmedByUser: $confirmedByUser, ')
          ..write('note: $note, ')
          ..write('takenAt: $takenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    analyte,
    analyteLabel,
    value,
    unit,
    refMin,
    refMax,
    labName,
    origin,
    confirmedByUser,
    note,
    takenAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LabResultRow &&
          other.id == this.id &&
          other.analyte == this.analyte &&
          other.analyteLabel == this.analyteLabel &&
          other.value == this.value &&
          other.unit == this.unit &&
          other.refMin == this.refMin &&
          other.refMax == this.refMax &&
          other.labName == this.labName &&
          other.origin == this.origin &&
          other.confirmedByUser == this.confirmedByUser &&
          other.note == this.note &&
          other.takenAt == this.takenAt);
}

class LabResultRowsCompanion extends UpdateCompanion<LabResultRow> {
  final Value<int> id;
  final Value<String> analyte;
  final Value<String> analyteLabel;
  final Value<double> value;
  final Value<String> unit;
  final Value<double?> refMin;
  final Value<double?> refMax;
  final Value<String?> labName;
  final Value<String> origin;
  final Value<bool> confirmedByUser;
  final Value<String?> note;
  final Value<DateTime> takenAt;
  const LabResultRowsCompanion({
    this.id = const Value.absent(),
    this.analyte = const Value.absent(),
    this.analyteLabel = const Value.absent(),
    this.value = const Value.absent(),
    this.unit = const Value.absent(),
    this.refMin = const Value.absent(),
    this.refMax = const Value.absent(),
    this.labName = const Value.absent(),
    this.origin = const Value.absent(),
    this.confirmedByUser = const Value.absent(),
    this.note = const Value.absent(),
    this.takenAt = const Value.absent(),
  });
  LabResultRowsCompanion.insert({
    this.id = const Value.absent(),
    required String analyte,
    required String analyteLabel,
    required double value,
    required String unit,
    this.refMin = const Value.absent(),
    this.refMax = const Value.absent(),
    this.labName = const Value.absent(),
    this.origin = const Value.absent(),
    this.confirmedByUser = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime takenAt,
  }) : analyte = Value(analyte),
       analyteLabel = Value(analyteLabel),
       value = Value(value),
       unit = Value(unit),
       takenAt = Value(takenAt);
  static Insertable<LabResultRow> custom({
    Expression<int>? id,
    Expression<String>? analyte,
    Expression<String>? analyteLabel,
    Expression<double>? value,
    Expression<String>? unit,
    Expression<double>? refMin,
    Expression<double>? refMax,
    Expression<String>? labName,
    Expression<String>? origin,
    Expression<bool>? confirmedByUser,
    Expression<String>? note,
    Expression<DateTime>? takenAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (analyte != null) 'analyte': analyte,
      if (analyteLabel != null) 'analyte_label': analyteLabel,
      if (value != null) 'value': value,
      if (unit != null) 'unit': unit,
      if (refMin != null) 'ref_min': refMin,
      if (refMax != null) 'ref_max': refMax,
      if (labName != null) 'lab_name': labName,
      if (origin != null) 'origin': origin,
      if (confirmedByUser != null) 'confirmed_by_user': confirmedByUser,
      if (note != null) 'note': note,
      if (takenAt != null) 'taken_at': takenAt,
    });
  }

  LabResultRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? analyte,
    Value<String>? analyteLabel,
    Value<double>? value,
    Value<String>? unit,
    Value<double?>? refMin,
    Value<double?>? refMax,
    Value<String?>? labName,
    Value<String>? origin,
    Value<bool>? confirmedByUser,
    Value<String?>? note,
    Value<DateTime>? takenAt,
  }) {
    return LabResultRowsCompanion(
      id: id ?? this.id,
      analyte: analyte ?? this.analyte,
      analyteLabel: analyteLabel ?? this.analyteLabel,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      refMin: refMin ?? this.refMin,
      refMax: refMax ?? this.refMax,
      labName: labName ?? this.labName,
      origin: origin ?? this.origin,
      confirmedByUser: confirmedByUser ?? this.confirmedByUser,
      note: note ?? this.note,
      takenAt: takenAt ?? this.takenAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (analyte.present) {
      map['analyte'] = Variable<String>(analyte.value);
    }
    if (analyteLabel.present) {
      map['analyte_label'] = Variable<String>(analyteLabel.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (refMin.present) {
      map['ref_min'] = Variable<double>(refMin.value);
    }
    if (refMax.present) {
      map['ref_max'] = Variable<double>(refMax.value);
    }
    if (labName.present) {
      map['lab_name'] = Variable<String>(labName.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (confirmedByUser.present) {
      map['confirmed_by_user'] = Variable<bool>(confirmedByUser.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LabResultRowsCompanion(')
          ..write('id: $id, ')
          ..write('analyte: $analyte, ')
          ..write('analyteLabel: $analyteLabel, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('refMin: $refMin, ')
          ..write('refMax: $refMax, ')
          ..write('labName: $labName, ')
          ..write('origin: $origin, ')
          ..write('confirmedByUser: $confirmedByUser, ')
          ..write('note: $note, ')
          ..write('takenAt: $takenAt')
          ..write(')'))
        .toString();
  }
}

class $AppointmentRowsTable extends AppointmentRows
    with TableInfo<$AppointmentRowsTable, AppointmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppointmentRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startsAtMeta = const VerificationMeta(
    'startsAt',
  );
  @override
  late final GeneratedColumn<DateTime> startsAt = GeneratedColumn<DateTime>(
    'starts_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderEnabledMeta = const VerificationMeta(
    'reminderEnabled',
  );
  @override
  late final GeneratedColumn<bool> reminderEnabled = GeneratedColumn<bool>(
    'reminder_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminder_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _reminderMinutesBeforeMeta =
      const VerificationMeta('reminderMinutesBefore');
  @override
  late final GeneratedColumn<int> reminderMinutesBefore = GeneratedColumn<int>(
    'reminder_minutes_before',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(120),
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    kind,
    location,
    note,
    startsAt,
    durationMinutes,
    reminderEnabled,
    reminderMinutesBefore,
    completed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'appointment_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppointmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('starts_at')) {
      context.handle(
        _startsAtMeta,
        startsAt.isAcceptableOrUnknown(data['starts_at']!, _startsAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startsAtMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('reminder_enabled')) {
      context.handle(
        _reminderEnabledMeta,
        reminderEnabled.isAcceptableOrUnknown(
          data['reminder_enabled']!,
          _reminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('reminder_minutes_before')) {
      context.handle(
        _reminderMinutesBeforeMeta,
        reminderMinutesBefore.isAcceptableOrUnknown(
          data['reminder_minutes_before']!,
          _reminderMinutesBeforeMeta,
        ),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppointmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppointmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      startsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}starts_at'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      ),
      reminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reminder_enabled'],
      )!,
      reminderMinutesBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minutes_before'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
    );
  }

  @override
  $AppointmentRowsTable createAlias(String alias) {
    return $AppointmentRowsTable(attachedDatabase, alias);
  }
}

class AppointmentRow extends DataClass implements Insertable<AppointmentRow> {
  final int id;
  final String title;

  /// 'dialysis' | 'checkup' | 'lab' | 'other'
  final String kind;
  final String? location;
  final String? note;
  final DateTime startsAt;
  final int? durationMinutes;
  final bool reminderEnabled;
  final int reminderMinutesBefore;
  final bool completed;
  const AppointmentRow({
    required this.id,
    required this.title,
    required this.kind,
    this.location,
    this.note,
    required this.startsAt,
    this.durationMinutes,
    required this.reminderEnabled,
    required this.reminderMinutesBefore,
    required this.completed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['starts_at'] = Variable<DateTime>(startsAt);
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    map['reminder_enabled'] = Variable<bool>(reminderEnabled);
    map['reminder_minutes_before'] = Variable<int>(reminderMinutesBefore);
    map['completed'] = Variable<bool>(completed);
    return map;
  }

  AppointmentRowsCompanion toCompanion(bool nullToAbsent) {
    return AppointmentRowsCompanion(
      id: Value(id),
      title: Value(title),
      kind: Value(kind),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      startsAt: Value(startsAt),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      reminderEnabled: Value(reminderEnabled),
      reminderMinutesBefore: Value(reminderMinutesBefore),
      completed: Value(completed),
    );
  }

  factory AppointmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppointmentRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      kind: serializer.fromJson<String>(json['kind']),
      location: serializer.fromJson<String?>(json['location']),
      note: serializer.fromJson<String?>(json['note']),
      startsAt: serializer.fromJson<DateTime>(json['startsAt']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      reminderEnabled: serializer.fromJson<bool>(json['reminderEnabled']),
      reminderMinutesBefore: serializer.fromJson<int>(
        json['reminderMinutesBefore'],
      ),
      completed: serializer.fromJson<bool>(json['completed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'kind': serializer.toJson<String>(kind),
      'location': serializer.toJson<String?>(location),
      'note': serializer.toJson<String?>(note),
      'startsAt': serializer.toJson<DateTime>(startsAt),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'reminderEnabled': serializer.toJson<bool>(reminderEnabled),
      'reminderMinutesBefore': serializer.toJson<int>(reminderMinutesBefore),
      'completed': serializer.toJson<bool>(completed),
    };
  }

  AppointmentRow copyWith({
    int? id,
    String? title,
    String? kind,
    Value<String?> location = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? startsAt,
    Value<int?> durationMinutes = const Value.absent(),
    bool? reminderEnabled,
    int? reminderMinutesBefore,
    bool? completed,
  }) => AppointmentRow(
    id: id ?? this.id,
    title: title ?? this.title,
    kind: kind ?? this.kind,
    location: location.present ? location.value : this.location,
    note: note.present ? note.value : this.note,
    startsAt: startsAt ?? this.startsAt,
    durationMinutes: durationMinutes.present
        ? durationMinutes.value
        : this.durationMinutes,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
    completed: completed ?? this.completed,
  );
  AppointmentRow copyWithCompanion(AppointmentRowsCompanion data) {
    return AppointmentRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      kind: data.kind.present ? data.kind.value : this.kind,
      location: data.location.present ? data.location.value : this.location,
      note: data.note.present ? data.note.value : this.note,
      startsAt: data.startsAt.present ? data.startsAt.value : this.startsAt,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      reminderEnabled: data.reminderEnabled.present
          ? data.reminderEnabled.value
          : this.reminderEnabled,
      reminderMinutesBefore: data.reminderMinutesBefore.present
          ? data.reminderMinutesBefore.value
          : this.reminderMinutesBefore,
      completed: data.completed.present ? data.completed.value : this.completed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppointmentRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('location: $location, ')
          ..write('note: $note, ')
          ..write('startsAt: $startsAt, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('reminderMinutesBefore: $reminderMinutesBefore, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    kind,
    location,
    note,
    startsAt,
    durationMinutes,
    reminderEnabled,
    reminderMinutesBefore,
    completed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppointmentRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.kind == this.kind &&
          other.location == this.location &&
          other.note == this.note &&
          other.startsAt == this.startsAt &&
          other.durationMinutes == this.durationMinutes &&
          other.reminderEnabled == this.reminderEnabled &&
          other.reminderMinutesBefore == this.reminderMinutesBefore &&
          other.completed == this.completed);
}

class AppointmentRowsCompanion extends UpdateCompanion<AppointmentRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> kind;
  final Value<String?> location;
  final Value<String?> note;
  final Value<DateTime> startsAt;
  final Value<int?> durationMinutes;
  final Value<bool> reminderEnabled;
  final Value<int> reminderMinutesBefore;
  final Value<bool> completed;
  const AppointmentRowsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.kind = const Value.absent(),
    this.location = const Value.absent(),
    this.note = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.reminderMinutesBefore = const Value.absent(),
    this.completed = const Value.absent(),
  });
  AppointmentRowsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String kind,
    this.location = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime startsAt,
    this.durationMinutes = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.reminderMinutesBefore = const Value.absent(),
    this.completed = const Value.absent(),
  }) : title = Value(title),
       kind = Value(kind),
       startsAt = Value(startsAt);
  static Insertable<AppointmentRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? kind,
    Expression<String>? location,
    Expression<String>? note,
    Expression<DateTime>? startsAt,
    Expression<int>? durationMinutes,
    Expression<bool>? reminderEnabled,
    Expression<int>? reminderMinutesBefore,
    Expression<bool>? completed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (kind != null) 'kind': kind,
      if (location != null) 'location': location,
      if (note != null) 'note': note,
      if (startsAt != null) 'starts_at': startsAt,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (reminderEnabled != null) 'reminder_enabled': reminderEnabled,
      if (reminderMinutesBefore != null)
        'reminder_minutes_before': reminderMinutesBefore,
      if (completed != null) 'completed': completed,
    });
  }

  AppointmentRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? kind,
    Value<String?>? location,
    Value<String?>? note,
    Value<DateTime>? startsAt,
    Value<int?>? durationMinutes,
    Value<bool>? reminderEnabled,
    Value<int>? reminderMinutesBefore,
    Value<bool>? completed,
  }) {
    return AppointmentRowsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      location: location ?? this.location,
      note: note ?? this.note,
      startsAt: startsAt ?? this.startsAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      completed: completed ?? this.completed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (startsAt.present) {
      map['starts_at'] = Variable<DateTime>(startsAt.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (reminderEnabled.present) {
      map['reminder_enabled'] = Variable<bool>(reminderEnabled.value);
    }
    if (reminderMinutesBefore.present) {
      map['reminder_minutes_before'] = Variable<int>(
        reminderMinutesBefore.value,
      );
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppointmentRowsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('location: $location, ')
          ..write('note: $note, ')
          ..write('startsAt: $startsAt, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('reminderMinutesBefore: $reminderMinutesBefore, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }
}

class $MedicationRowsTable extends MedicationRows
    with TableInfo<$MedicationRowsTable, MedicationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doseMeta = const VerificationMeta('dose');
  @override
  late final GeneratedColumn<String> dose = GeneratedColumn<String>(
    'dose',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formMeta = const VerificationMeta('form');
  @override
  late final GeneratedColumn<String> form = GeneratedColumn<String>(
    'form',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timesMeta = const VerificationMeta('times');
  @override
  late final GeneratedColumn<String> times = GeneratedColumn<String>(
    'times',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekdaysMeta = const VerificationMeta(
    'weekdays',
  );
  @override
  late final GeneratedColumn<String> weekdays = GeneratedColumn<String>(
    'weekdays',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockCountMeta = const VerificationMeta(
    'stockCount',
  );
  @override
  late final GeneratedColumn<int> stockCount = GeneratedColumn<int>(
    'stock_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockWarnAtMeta = const VerificationMeta(
    'stockWarnAt',
  );
  @override
  late final GeneratedColumn<int> stockWarnAt = GeneratedColumn<int>(
    'stock_warn_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(7),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _riskAcknowledgedMeta = const VerificationMeta(
    'riskAcknowledged',
  );
  @override
  late final GeneratedColumn<String> riskAcknowledged = GeneratedColumn<String>(
    'risk_acknowledged',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    dose,
    form,
    times,
    weekdays,
    stockCount,
    stockWarnAt,
    note,
    active,
    riskAcknowledged,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medication_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('dose')) {
      context.handle(
        _doseMeta,
        dose.isAcceptableOrUnknown(data['dose']!, _doseMeta),
      );
    }
    if (data.containsKey('form')) {
      context.handle(
        _formMeta,
        form.isAcceptableOrUnknown(data['form']!, _formMeta),
      );
    }
    if (data.containsKey('times')) {
      context.handle(
        _timesMeta,
        times.isAcceptableOrUnknown(data['times']!, _timesMeta),
      );
    } else if (isInserting) {
      context.missing(_timesMeta);
    }
    if (data.containsKey('weekdays')) {
      context.handle(
        _weekdaysMeta,
        weekdays.isAcceptableOrUnknown(data['weekdays']!, _weekdaysMeta),
      );
    }
    if (data.containsKey('stock_count')) {
      context.handle(
        _stockCountMeta,
        stockCount.isAcceptableOrUnknown(data['stock_count']!, _stockCountMeta),
      );
    }
    if (data.containsKey('stock_warn_at')) {
      context.handle(
        _stockWarnAtMeta,
        stockWarnAt.isAcceptableOrUnknown(
          data['stock_warn_at']!,
          _stockWarnAtMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('risk_acknowledged')) {
      context.handle(
        _riskAcknowledgedMeta,
        riskAcknowledged.isAcceptableOrUnknown(
          data['risk_acknowledged']!,
          _riskAcknowledgedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      dose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dose'],
      ),
      form: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}form'],
      ),
      times: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}times'],
      )!,
      weekdays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weekdays'],
      ),
      stockCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_count'],
      ),
      stockWarnAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_warn_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      riskAcknowledged: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}risk_acknowledged'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MedicationRowsTable createAlias(String alias) {
    return $MedicationRowsTable(attachedDatabase, alias);
  }
}

class MedicationRow extends DataClass implements Insertable<MedicationRow> {
  final int id;
  final String name;
  final String? dose;
  final String? form;

  /// Günlük saatler: "08:00,20:00"
  final String times;

  /// Haftanın günleri ("1,2,3,4,5,6,7") veya null = her gün.
  final String? weekdays;
  final int? stockCount;
  final int stockWarnAt;
  final String? note;
  final bool active;

  /// Risk taramasında eşleşen uyarı (varsa) — kullanıcı onayladıysa saklanır.
  final String? riskAcknowledged;
  final DateTime createdAt;
  const MedicationRow({
    required this.id,
    required this.name,
    this.dose,
    this.form,
    required this.times,
    this.weekdays,
    this.stockCount,
    required this.stockWarnAt,
    this.note,
    required this.active,
    this.riskAcknowledged,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || dose != null) {
      map['dose'] = Variable<String>(dose);
    }
    if (!nullToAbsent || form != null) {
      map['form'] = Variable<String>(form);
    }
    map['times'] = Variable<String>(times);
    if (!nullToAbsent || weekdays != null) {
      map['weekdays'] = Variable<String>(weekdays);
    }
    if (!nullToAbsent || stockCount != null) {
      map['stock_count'] = Variable<int>(stockCount);
    }
    map['stock_warn_at'] = Variable<int>(stockWarnAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['active'] = Variable<bool>(active);
    if (!nullToAbsent || riskAcknowledged != null) {
      map['risk_acknowledged'] = Variable<String>(riskAcknowledged);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MedicationRowsCompanion toCompanion(bool nullToAbsent) {
    return MedicationRowsCompanion(
      id: Value(id),
      name: Value(name),
      dose: dose == null && nullToAbsent ? const Value.absent() : Value(dose),
      form: form == null && nullToAbsent ? const Value.absent() : Value(form),
      times: Value(times),
      weekdays: weekdays == null && nullToAbsent
          ? const Value.absent()
          : Value(weekdays),
      stockCount: stockCount == null && nullToAbsent
          ? const Value.absent()
          : Value(stockCount),
      stockWarnAt: Value(stockWarnAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      active: Value(active),
      riskAcknowledged: riskAcknowledged == null && nullToAbsent
          ? const Value.absent()
          : Value(riskAcknowledged),
      createdAt: Value(createdAt),
    );
  }

  factory MedicationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      dose: serializer.fromJson<String?>(json['dose']),
      form: serializer.fromJson<String?>(json['form']),
      times: serializer.fromJson<String>(json['times']),
      weekdays: serializer.fromJson<String?>(json['weekdays']),
      stockCount: serializer.fromJson<int?>(json['stockCount']),
      stockWarnAt: serializer.fromJson<int>(json['stockWarnAt']),
      note: serializer.fromJson<String?>(json['note']),
      active: serializer.fromJson<bool>(json['active']),
      riskAcknowledged: serializer.fromJson<String?>(json['riskAcknowledged']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'dose': serializer.toJson<String?>(dose),
      'form': serializer.toJson<String?>(form),
      'times': serializer.toJson<String>(times),
      'weekdays': serializer.toJson<String?>(weekdays),
      'stockCount': serializer.toJson<int?>(stockCount),
      'stockWarnAt': serializer.toJson<int>(stockWarnAt),
      'note': serializer.toJson<String?>(note),
      'active': serializer.toJson<bool>(active),
      'riskAcknowledged': serializer.toJson<String?>(riskAcknowledged),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MedicationRow copyWith({
    int? id,
    String? name,
    Value<String?> dose = const Value.absent(),
    Value<String?> form = const Value.absent(),
    String? times,
    Value<String?> weekdays = const Value.absent(),
    Value<int?> stockCount = const Value.absent(),
    int? stockWarnAt,
    Value<String?> note = const Value.absent(),
    bool? active,
    Value<String?> riskAcknowledged = const Value.absent(),
    DateTime? createdAt,
  }) => MedicationRow(
    id: id ?? this.id,
    name: name ?? this.name,
    dose: dose.present ? dose.value : this.dose,
    form: form.present ? form.value : this.form,
    times: times ?? this.times,
    weekdays: weekdays.present ? weekdays.value : this.weekdays,
    stockCount: stockCount.present ? stockCount.value : this.stockCount,
    stockWarnAt: stockWarnAt ?? this.stockWarnAt,
    note: note.present ? note.value : this.note,
    active: active ?? this.active,
    riskAcknowledged: riskAcknowledged.present
        ? riskAcknowledged.value
        : this.riskAcknowledged,
    createdAt: createdAt ?? this.createdAt,
  );
  MedicationRow copyWithCompanion(MedicationRowsCompanion data) {
    return MedicationRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      dose: data.dose.present ? data.dose.value : this.dose,
      form: data.form.present ? data.form.value : this.form,
      times: data.times.present ? data.times.value : this.times,
      weekdays: data.weekdays.present ? data.weekdays.value : this.weekdays,
      stockCount: data.stockCount.present
          ? data.stockCount.value
          : this.stockCount,
      stockWarnAt: data.stockWarnAt.present
          ? data.stockWarnAt.value
          : this.stockWarnAt,
      note: data.note.present ? data.note.value : this.note,
      active: data.active.present ? data.active.value : this.active,
      riskAcknowledged: data.riskAcknowledged.present
          ? data.riskAcknowledged.value
          : this.riskAcknowledged,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dose: $dose, ')
          ..write('form: $form, ')
          ..write('times: $times, ')
          ..write('weekdays: $weekdays, ')
          ..write('stockCount: $stockCount, ')
          ..write('stockWarnAt: $stockWarnAt, ')
          ..write('note: $note, ')
          ..write('active: $active, ')
          ..write('riskAcknowledged: $riskAcknowledged, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    dose,
    form,
    times,
    weekdays,
    stockCount,
    stockWarnAt,
    note,
    active,
    riskAcknowledged,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.dose == this.dose &&
          other.form == this.form &&
          other.times == this.times &&
          other.weekdays == this.weekdays &&
          other.stockCount == this.stockCount &&
          other.stockWarnAt == this.stockWarnAt &&
          other.note == this.note &&
          other.active == this.active &&
          other.riskAcknowledged == this.riskAcknowledged &&
          other.createdAt == this.createdAt);
}

class MedicationRowsCompanion extends UpdateCompanion<MedicationRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> dose;
  final Value<String?> form;
  final Value<String> times;
  final Value<String?> weekdays;
  final Value<int?> stockCount;
  final Value<int> stockWarnAt;
  final Value<String?> note;
  final Value<bool> active;
  final Value<String?> riskAcknowledged;
  final Value<DateTime> createdAt;
  const MedicationRowsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.dose = const Value.absent(),
    this.form = const Value.absent(),
    this.times = const Value.absent(),
    this.weekdays = const Value.absent(),
    this.stockCount = const Value.absent(),
    this.stockWarnAt = const Value.absent(),
    this.note = const Value.absent(),
    this.active = const Value.absent(),
    this.riskAcknowledged = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MedicationRowsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.dose = const Value.absent(),
    this.form = const Value.absent(),
    required String times,
    this.weekdays = const Value.absent(),
    this.stockCount = const Value.absent(),
    this.stockWarnAt = const Value.absent(),
    this.note = const Value.absent(),
    this.active = const Value.absent(),
    this.riskAcknowledged = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       times = Value(times);
  static Insertable<MedicationRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? dose,
    Expression<String>? form,
    Expression<String>? times,
    Expression<String>? weekdays,
    Expression<int>? stockCount,
    Expression<int>? stockWarnAt,
    Expression<String>? note,
    Expression<bool>? active,
    Expression<String>? riskAcknowledged,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (dose != null) 'dose': dose,
      if (form != null) 'form': form,
      if (times != null) 'times': times,
      if (weekdays != null) 'weekdays': weekdays,
      if (stockCount != null) 'stock_count': stockCount,
      if (stockWarnAt != null) 'stock_warn_at': stockWarnAt,
      if (note != null) 'note': note,
      if (active != null) 'active': active,
      if (riskAcknowledged != null) 'risk_acknowledged': riskAcknowledged,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MedicationRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? dose,
    Value<String?>? form,
    Value<String>? times,
    Value<String?>? weekdays,
    Value<int?>? stockCount,
    Value<int>? stockWarnAt,
    Value<String?>? note,
    Value<bool>? active,
    Value<String?>? riskAcknowledged,
    Value<DateTime>? createdAt,
  }) {
    return MedicationRowsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      form: form ?? this.form,
      times: times ?? this.times,
      weekdays: weekdays ?? this.weekdays,
      stockCount: stockCount ?? this.stockCount,
      stockWarnAt: stockWarnAt ?? this.stockWarnAt,
      note: note ?? this.note,
      active: active ?? this.active,
      riskAcknowledged: riskAcknowledged ?? this.riskAcknowledged,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dose.present) {
      map['dose'] = Variable<String>(dose.value);
    }
    if (form.present) {
      map['form'] = Variable<String>(form.value);
    }
    if (times.present) {
      map['times'] = Variable<String>(times.value);
    }
    if (weekdays.present) {
      map['weekdays'] = Variable<String>(weekdays.value);
    }
    if (stockCount.present) {
      map['stock_count'] = Variable<int>(stockCount.value);
    }
    if (stockWarnAt.present) {
      map['stock_warn_at'] = Variable<int>(stockWarnAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (riskAcknowledged.present) {
      map['risk_acknowledged'] = Variable<String>(riskAcknowledged.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationRowsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dose: $dose, ')
          ..write('form: $form, ')
          ..write('times: $times, ')
          ..write('weekdays: $weekdays, ')
          ..write('stockCount: $stockCount, ')
          ..write('stockWarnAt: $stockWarnAt, ')
          ..write('note: $note, ')
          ..write('active: $active, ')
          ..write('riskAcknowledged: $riskAcknowledged, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MedicationDoseRowsTable extends MedicationDoseRows
    with TableInfo<$MedicationDoseRowsTable, MedicationDoseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationDoseRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<int> medicationId = GeneratedColumn<int>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
    'taken_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _snoozedUntilMeta = const VerificationMeta(
    'snoozedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> snoozedUntil = GeneratedColumn<DateTime>(
    'snoozed_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    medicationId,
    scheduledAt,
    takenAt,
    status,
    snoozedUntil,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medication_dose_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationDoseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('snoozed_until')) {
      context.handle(
        _snoozedUntilMeta,
        snoozedUntil.isAcceptableOrUnknown(
          data['snoozed_until']!,
          _snoozedUntilMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationDoseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationDoseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}medication_id'],
      )!,
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      )!,
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      snoozedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}snoozed_until'],
      ),
    );
  }

  @override
  $MedicationDoseRowsTable createAlias(String alias) {
    return $MedicationDoseRowsTable(attachedDatabase, alias);
  }
}

class MedicationDoseRow extends DataClass
    implements Insertable<MedicationDoseRow> {
  final int id;
  final int medicationId;
  final DateTime scheduledAt;
  final DateTime? takenAt;

  /// 'pending' | 'taken' | 'skipped' | 'snoozed'
  final String status;
  final DateTime? snoozedUntil;
  const MedicationDoseRow({
    required this.id,
    required this.medicationId,
    required this.scheduledAt,
    this.takenAt,
    required this.status,
    this.snoozedUntil,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['medication_id'] = Variable<int>(medicationId);
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    if (!nullToAbsent || takenAt != null) {
      map['taken_at'] = Variable<DateTime>(takenAt);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || snoozedUntil != null) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil);
    }
    return map;
  }

  MedicationDoseRowsCompanion toCompanion(bool nullToAbsent) {
    return MedicationDoseRowsCompanion(
      id: Value(id),
      medicationId: Value(medicationId),
      scheduledAt: Value(scheduledAt),
      takenAt: takenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(takenAt),
      status: Value(status),
      snoozedUntil: snoozedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozedUntil),
    );
  }

  factory MedicationDoseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationDoseRow(
      id: serializer.fromJson<int>(json['id']),
      medicationId: serializer.fromJson<int>(json['medicationId']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      takenAt: serializer.fromJson<DateTime?>(json['takenAt']),
      status: serializer.fromJson<String>(json['status']),
      snoozedUntil: serializer.fromJson<DateTime?>(json['snoozedUntil']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'medicationId': serializer.toJson<int>(medicationId),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'takenAt': serializer.toJson<DateTime?>(takenAt),
      'status': serializer.toJson<String>(status),
      'snoozedUntil': serializer.toJson<DateTime?>(snoozedUntil),
    };
  }

  MedicationDoseRow copyWith({
    int? id,
    int? medicationId,
    DateTime? scheduledAt,
    Value<DateTime?> takenAt = const Value.absent(),
    String? status,
    Value<DateTime?> snoozedUntil = const Value.absent(),
  }) => MedicationDoseRow(
    id: id ?? this.id,
    medicationId: medicationId ?? this.medicationId,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    takenAt: takenAt.present ? takenAt.value : this.takenAt,
    status: status ?? this.status,
    snoozedUntil: snoozedUntil.present ? snoozedUntil.value : this.snoozedUntil,
  );
  MedicationDoseRow copyWithCompanion(MedicationDoseRowsCompanion data) {
    return MedicationDoseRow(
      id: data.id.present ? data.id.value : this.id,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      status: data.status.present ? data.status.value : this.status,
      snoozedUntil: data.snoozedUntil.present
          ? data.snoozedUntil.value
          : this.snoozedUntil,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationDoseRow(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('takenAt: $takenAt, ')
          ..write('status: $status, ')
          ..write('snoozedUntil: $snoozedUntil')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, medicationId, scheduledAt, takenAt, status, snoozedUntil);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationDoseRow &&
          other.id == this.id &&
          other.medicationId == this.medicationId &&
          other.scheduledAt == this.scheduledAt &&
          other.takenAt == this.takenAt &&
          other.status == this.status &&
          other.snoozedUntil == this.snoozedUntil);
}

class MedicationDoseRowsCompanion extends UpdateCompanion<MedicationDoseRow> {
  final Value<int> id;
  final Value<int> medicationId;
  final Value<DateTime> scheduledAt;
  final Value<DateTime?> takenAt;
  final Value<String> status;
  final Value<DateTime?> snoozedUntil;
  const MedicationDoseRowsCompanion({
    this.id = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.status = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
  });
  MedicationDoseRowsCompanion.insert({
    this.id = const Value.absent(),
    required int medicationId,
    required DateTime scheduledAt,
    this.takenAt = const Value.absent(),
    this.status = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
  }) : medicationId = Value(medicationId),
       scheduledAt = Value(scheduledAt);
  static Insertable<MedicationDoseRow> custom({
    Expression<int>? id,
    Expression<int>? medicationId,
    Expression<DateTime>? scheduledAt,
    Expression<DateTime>? takenAt,
    Expression<String>? status,
    Expression<DateTime>? snoozedUntil,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medicationId != null) 'medication_id': medicationId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (takenAt != null) 'taken_at': takenAt,
      if (status != null) 'status': status,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
    });
  }

  MedicationDoseRowsCompanion copyWith({
    Value<int>? id,
    Value<int>? medicationId,
    Value<DateTime>? scheduledAt,
    Value<DateTime?>? takenAt,
    Value<String>? status,
    Value<DateTime?>? snoozedUntil,
  }) {
    return MedicationDoseRowsCompanion(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      takenAt: takenAt ?? this.takenAt,
      status: status ?? this.status,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<int>(medicationId.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationDoseRowsCompanion(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('takenAt: $takenAt, ')
          ..write('status: $status, ')
          ..write('snoozedUntil: $snoozedUntil')
          ..write(')'))
        .toString();
  }
}

class $VitalRowsTable extends VitalRows
    with TableInfo<$VitalRowsTable, VitalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VitalRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _edemaLevelMeta = const VerificationMeta(
    'edemaLevel',
  );
  @override
  late final GeneratedColumn<int> edemaLevel = GeneratedColumn<int>(
    'edema_level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urineMlMeta = const VerificationMeta(
    'urineMl',
  );
  @override
  late final GeneratedColumn<int> urineMl = GeneratedColumn<int>(
    'urine_ml',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _systolicMeta = const VerificationMeta(
    'systolic',
  );
  @override
  late final GeneratedColumn<int> systolic = GeneratedColumn<int>(
    'systolic',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _diastolicMeta = const VerificationMeta(
    'diastolic',
  );
  @override
  late final GeneratedColumn<int> diastolic = GeneratedColumn<int>(
    'diastolic',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heartRateMeta = const VerificationMeta(
    'heartRate',
  );
  @override
  late final GeneratedColumn<int> heartRate = GeneratedColumn<int>(
    'heart_rate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _temperatureCMeta = const VerificationMeta(
    'temperatureC',
  );
  @override
  late final GeneratedColumn<double> temperatureC = GeneratedColumn<double>(
    'temperature_c',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spo2Meta = const VerificationMeta('spo2');
  @override
  late final GeneratedColumn<int> spo2 = GeneratedColumn<int>(
    'spo2',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _glucoseMgDlMeta = const VerificationMeta(
    'glucoseMgDl',
  );
  @override
  late final GeneratedColumn<double> glucoseMgDl = GeneratedColumn<double>(
    'glucose_mg_dl',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dialysisPhaseMeta = const VerificationMeta(
    'dialysisPhase',
  );
  @override
  late final GeneratedColumn<String> dialysisPhase = GeneratedColumn<String>(
    'dialysis_phase',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _measuredAtMeta = const VerificationMeta(
    'measuredAt',
  );
  @override
  late final GeneratedColumn<DateTime> measuredAt = GeneratedColumn<DateTime>(
    'measured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    weightKg,
    edemaLevel,
    urineMl,
    systolic,
    diastolic,
    heartRate,
    temperatureC,
    spo2,
    glucoseMgDl,
    note,
    dialysisPhase,
    measuredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vital_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<VitalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('edema_level')) {
      context.handle(
        _edemaLevelMeta,
        edemaLevel.isAcceptableOrUnknown(data['edema_level']!, _edemaLevelMeta),
      );
    }
    if (data.containsKey('urine_ml')) {
      context.handle(
        _urineMlMeta,
        urineMl.isAcceptableOrUnknown(data['urine_ml']!, _urineMlMeta),
      );
    }
    if (data.containsKey('systolic')) {
      context.handle(
        _systolicMeta,
        systolic.isAcceptableOrUnknown(data['systolic']!, _systolicMeta),
      );
    }
    if (data.containsKey('diastolic')) {
      context.handle(
        _diastolicMeta,
        diastolic.isAcceptableOrUnknown(data['diastolic']!, _diastolicMeta),
      );
    }
    if (data.containsKey('heart_rate')) {
      context.handle(
        _heartRateMeta,
        heartRate.isAcceptableOrUnknown(data['heart_rate']!, _heartRateMeta),
      );
    }
    if (data.containsKey('temperature_c')) {
      context.handle(
        _temperatureCMeta,
        temperatureC.isAcceptableOrUnknown(
          data['temperature_c']!,
          _temperatureCMeta,
        ),
      );
    }
    if (data.containsKey('spo2')) {
      context.handle(
        _spo2Meta,
        spo2.isAcceptableOrUnknown(data['spo2']!, _spo2Meta),
      );
    }
    if (data.containsKey('glucose_mg_dl')) {
      context.handle(
        _glucoseMgDlMeta,
        glucoseMgDl.isAcceptableOrUnknown(
          data['glucose_mg_dl']!,
          _glucoseMgDlMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('dialysis_phase')) {
      context.handle(
        _dialysisPhaseMeta,
        dialysisPhase.isAcceptableOrUnknown(
          data['dialysis_phase']!,
          _dialysisPhaseMeta,
        ),
      );
    }
    if (data.containsKey('measured_at')) {
      context.handle(
        _measuredAtMeta,
        measuredAt.isAcceptableOrUnknown(data['measured_at']!, _measuredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_measuredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VitalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VitalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      edemaLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edema_level'],
      ),
      urineMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}urine_ml'],
      ),
      systolic: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}systolic'],
      ),
      diastolic: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}diastolic'],
      ),
      heartRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}heart_rate'],
      ),
      temperatureC: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature_c'],
      ),
      spo2: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}spo2'],
      ),
      glucoseMgDl: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}glucose_mg_dl'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      dialysisPhase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dialysis_phase'],
      ),
      measuredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}measured_at'],
      )!,
    );
  }

  @override
  $VitalRowsTable createAlias(String alias) {
    return $VitalRowsTable(attachedDatabase, alias);
  }
}

class VitalRow extends DataClass implements Insertable<VitalRow> {
  final int id;
  final double? weightKg;

  /// 0 = yok, 1 = hafif, 2 = orta, 3 = belirgin
  final int? edemaLevel;
  final int? urineMl;
  final int? systolic;
  final int? diastolic;
  final int? heartRate;
  final double? temperatureC;
  final int? spo2;
  final double? glucoseMgDl;
  final String? note;

  /// Diyaliz seansı öncesi/sonrası işareti: 'pre' | 'post' | null
  final String? dialysisPhase;
  final DateTime measuredAt;
  const VitalRow({
    required this.id,
    this.weightKg,
    this.edemaLevel,
    this.urineMl,
    this.systolic,
    this.diastolic,
    this.heartRate,
    this.temperatureC,
    this.spo2,
    this.glucoseMgDl,
    this.note,
    this.dialysisPhase,
    required this.measuredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || edemaLevel != null) {
      map['edema_level'] = Variable<int>(edemaLevel);
    }
    if (!nullToAbsent || urineMl != null) {
      map['urine_ml'] = Variable<int>(urineMl);
    }
    if (!nullToAbsent || systolic != null) {
      map['systolic'] = Variable<int>(systolic);
    }
    if (!nullToAbsent || diastolic != null) {
      map['diastolic'] = Variable<int>(diastolic);
    }
    if (!nullToAbsent || heartRate != null) {
      map['heart_rate'] = Variable<int>(heartRate);
    }
    if (!nullToAbsent || temperatureC != null) {
      map['temperature_c'] = Variable<double>(temperatureC);
    }
    if (!nullToAbsent || spo2 != null) {
      map['spo2'] = Variable<int>(spo2);
    }
    if (!nullToAbsent || glucoseMgDl != null) {
      map['glucose_mg_dl'] = Variable<double>(glucoseMgDl);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || dialysisPhase != null) {
      map['dialysis_phase'] = Variable<String>(dialysisPhase);
    }
    map['measured_at'] = Variable<DateTime>(measuredAt);
    return map;
  }

  VitalRowsCompanion toCompanion(bool nullToAbsent) {
    return VitalRowsCompanion(
      id: Value(id),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      edemaLevel: edemaLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(edemaLevel),
      urineMl: urineMl == null && nullToAbsent
          ? const Value.absent()
          : Value(urineMl),
      systolic: systolic == null && nullToAbsent
          ? const Value.absent()
          : Value(systolic),
      diastolic: diastolic == null && nullToAbsent
          ? const Value.absent()
          : Value(diastolic),
      heartRate: heartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(heartRate),
      temperatureC: temperatureC == null && nullToAbsent
          ? const Value.absent()
          : Value(temperatureC),
      spo2: spo2 == null && nullToAbsent ? const Value.absent() : Value(spo2),
      glucoseMgDl: glucoseMgDl == null && nullToAbsent
          ? const Value.absent()
          : Value(glucoseMgDl),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      dialysisPhase: dialysisPhase == null && nullToAbsent
          ? const Value.absent()
          : Value(dialysisPhase),
      measuredAt: Value(measuredAt),
    );
  }

  factory VitalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VitalRow(
      id: serializer.fromJson<int>(json['id']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      edemaLevel: serializer.fromJson<int?>(json['edemaLevel']),
      urineMl: serializer.fromJson<int?>(json['urineMl']),
      systolic: serializer.fromJson<int?>(json['systolic']),
      diastolic: serializer.fromJson<int?>(json['diastolic']),
      heartRate: serializer.fromJson<int?>(json['heartRate']),
      temperatureC: serializer.fromJson<double?>(json['temperatureC']),
      spo2: serializer.fromJson<int?>(json['spo2']),
      glucoseMgDl: serializer.fromJson<double?>(json['glucoseMgDl']),
      note: serializer.fromJson<String?>(json['note']),
      dialysisPhase: serializer.fromJson<String?>(json['dialysisPhase']),
      measuredAt: serializer.fromJson<DateTime>(json['measuredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'weightKg': serializer.toJson<double?>(weightKg),
      'edemaLevel': serializer.toJson<int?>(edemaLevel),
      'urineMl': serializer.toJson<int?>(urineMl),
      'systolic': serializer.toJson<int?>(systolic),
      'diastolic': serializer.toJson<int?>(diastolic),
      'heartRate': serializer.toJson<int?>(heartRate),
      'temperatureC': serializer.toJson<double?>(temperatureC),
      'spo2': serializer.toJson<int?>(spo2),
      'glucoseMgDl': serializer.toJson<double?>(glucoseMgDl),
      'note': serializer.toJson<String?>(note),
      'dialysisPhase': serializer.toJson<String?>(dialysisPhase),
      'measuredAt': serializer.toJson<DateTime>(measuredAt),
    };
  }

  VitalRow copyWith({
    int? id,
    Value<double?> weightKg = const Value.absent(),
    Value<int?> edemaLevel = const Value.absent(),
    Value<int?> urineMl = const Value.absent(),
    Value<int?> systolic = const Value.absent(),
    Value<int?> diastolic = const Value.absent(),
    Value<int?> heartRate = const Value.absent(),
    Value<double?> temperatureC = const Value.absent(),
    Value<int?> spo2 = const Value.absent(),
    Value<double?> glucoseMgDl = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> dialysisPhase = const Value.absent(),
    DateTime? measuredAt,
  }) => VitalRow(
    id: id ?? this.id,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    edemaLevel: edemaLevel.present ? edemaLevel.value : this.edemaLevel,
    urineMl: urineMl.present ? urineMl.value : this.urineMl,
    systolic: systolic.present ? systolic.value : this.systolic,
    diastolic: diastolic.present ? diastolic.value : this.diastolic,
    heartRate: heartRate.present ? heartRate.value : this.heartRate,
    temperatureC: temperatureC.present ? temperatureC.value : this.temperatureC,
    spo2: spo2.present ? spo2.value : this.spo2,
    glucoseMgDl: glucoseMgDl.present ? glucoseMgDl.value : this.glucoseMgDl,
    note: note.present ? note.value : this.note,
    dialysisPhase: dialysisPhase.present
        ? dialysisPhase.value
        : this.dialysisPhase,
    measuredAt: measuredAt ?? this.measuredAt,
  );
  VitalRow copyWithCompanion(VitalRowsCompanion data) {
    return VitalRow(
      id: data.id.present ? data.id.value : this.id,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      edemaLevel: data.edemaLevel.present
          ? data.edemaLevel.value
          : this.edemaLevel,
      urineMl: data.urineMl.present ? data.urineMl.value : this.urineMl,
      systolic: data.systolic.present ? data.systolic.value : this.systolic,
      diastolic: data.diastolic.present ? data.diastolic.value : this.diastolic,
      heartRate: data.heartRate.present ? data.heartRate.value : this.heartRate,
      temperatureC: data.temperatureC.present
          ? data.temperatureC.value
          : this.temperatureC,
      spo2: data.spo2.present ? data.spo2.value : this.spo2,
      glucoseMgDl: data.glucoseMgDl.present
          ? data.glucoseMgDl.value
          : this.glucoseMgDl,
      note: data.note.present ? data.note.value : this.note,
      dialysisPhase: data.dialysisPhase.present
          ? data.dialysisPhase.value
          : this.dialysisPhase,
      measuredAt: data.measuredAt.present
          ? data.measuredAt.value
          : this.measuredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VitalRow(')
          ..write('id: $id, ')
          ..write('weightKg: $weightKg, ')
          ..write('edemaLevel: $edemaLevel, ')
          ..write('urineMl: $urineMl, ')
          ..write('systolic: $systolic, ')
          ..write('diastolic: $diastolic, ')
          ..write('heartRate: $heartRate, ')
          ..write('temperatureC: $temperatureC, ')
          ..write('spo2: $spo2, ')
          ..write('glucoseMgDl: $glucoseMgDl, ')
          ..write('note: $note, ')
          ..write('dialysisPhase: $dialysisPhase, ')
          ..write('measuredAt: $measuredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    weightKg,
    edemaLevel,
    urineMl,
    systolic,
    diastolic,
    heartRate,
    temperatureC,
    spo2,
    glucoseMgDl,
    note,
    dialysisPhase,
    measuredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VitalRow &&
          other.id == this.id &&
          other.weightKg == this.weightKg &&
          other.edemaLevel == this.edemaLevel &&
          other.urineMl == this.urineMl &&
          other.systolic == this.systolic &&
          other.diastolic == this.diastolic &&
          other.heartRate == this.heartRate &&
          other.temperatureC == this.temperatureC &&
          other.spo2 == this.spo2 &&
          other.glucoseMgDl == this.glucoseMgDl &&
          other.note == this.note &&
          other.dialysisPhase == this.dialysisPhase &&
          other.measuredAt == this.measuredAt);
}

class VitalRowsCompanion extends UpdateCompanion<VitalRow> {
  final Value<int> id;
  final Value<double?> weightKg;
  final Value<int?> edemaLevel;
  final Value<int?> urineMl;
  final Value<int?> systolic;
  final Value<int?> diastolic;
  final Value<int?> heartRate;
  final Value<double?> temperatureC;
  final Value<int?> spo2;
  final Value<double?> glucoseMgDl;
  final Value<String?> note;
  final Value<String?> dialysisPhase;
  final Value<DateTime> measuredAt;
  const VitalRowsCompanion({
    this.id = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.edemaLevel = const Value.absent(),
    this.urineMl = const Value.absent(),
    this.systolic = const Value.absent(),
    this.diastolic = const Value.absent(),
    this.heartRate = const Value.absent(),
    this.temperatureC = const Value.absent(),
    this.spo2 = const Value.absent(),
    this.glucoseMgDl = const Value.absent(),
    this.note = const Value.absent(),
    this.dialysisPhase = const Value.absent(),
    this.measuredAt = const Value.absent(),
  });
  VitalRowsCompanion.insert({
    this.id = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.edemaLevel = const Value.absent(),
    this.urineMl = const Value.absent(),
    this.systolic = const Value.absent(),
    this.diastolic = const Value.absent(),
    this.heartRate = const Value.absent(),
    this.temperatureC = const Value.absent(),
    this.spo2 = const Value.absent(),
    this.glucoseMgDl = const Value.absent(),
    this.note = const Value.absent(),
    this.dialysisPhase = const Value.absent(),
    required DateTime measuredAt,
  }) : measuredAt = Value(measuredAt);
  static Insertable<VitalRow> custom({
    Expression<int>? id,
    Expression<double>? weightKg,
    Expression<int>? edemaLevel,
    Expression<int>? urineMl,
    Expression<int>? systolic,
    Expression<int>? diastolic,
    Expression<int>? heartRate,
    Expression<double>? temperatureC,
    Expression<int>? spo2,
    Expression<double>? glucoseMgDl,
    Expression<String>? note,
    Expression<String>? dialysisPhase,
    Expression<DateTime>? measuredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weightKg != null) 'weight_kg': weightKg,
      if (edemaLevel != null) 'edema_level': edemaLevel,
      if (urineMl != null) 'urine_ml': urineMl,
      if (systolic != null) 'systolic': systolic,
      if (diastolic != null) 'diastolic': diastolic,
      if (heartRate != null) 'heart_rate': heartRate,
      if (temperatureC != null) 'temperature_c': temperatureC,
      if (spo2 != null) 'spo2': spo2,
      if (glucoseMgDl != null) 'glucose_mg_dl': glucoseMgDl,
      if (note != null) 'note': note,
      if (dialysisPhase != null) 'dialysis_phase': dialysisPhase,
      if (measuredAt != null) 'measured_at': measuredAt,
    });
  }

  VitalRowsCompanion copyWith({
    Value<int>? id,
    Value<double?>? weightKg,
    Value<int?>? edemaLevel,
    Value<int?>? urineMl,
    Value<int?>? systolic,
    Value<int?>? diastolic,
    Value<int?>? heartRate,
    Value<double?>? temperatureC,
    Value<int?>? spo2,
    Value<double?>? glucoseMgDl,
    Value<String?>? note,
    Value<String?>? dialysisPhase,
    Value<DateTime>? measuredAt,
  }) {
    return VitalRowsCompanion(
      id: id ?? this.id,
      weightKg: weightKg ?? this.weightKg,
      edemaLevel: edemaLevel ?? this.edemaLevel,
      urineMl: urineMl ?? this.urineMl,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      heartRate: heartRate ?? this.heartRate,
      temperatureC: temperatureC ?? this.temperatureC,
      spo2: spo2 ?? this.spo2,
      glucoseMgDl: glucoseMgDl ?? this.glucoseMgDl,
      note: note ?? this.note,
      dialysisPhase: dialysisPhase ?? this.dialysisPhase,
      measuredAt: measuredAt ?? this.measuredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (edemaLevel.present) {
      map['edema_level'] = Variable<int>(edemaLevel.value);
    }
    if (urineMl.present) {
      map['urine_ml'] = Variable<int>(urineMl.value);
    }
    if (systolic.present) {
      map['systolic'] = Variable<int>(systolic.value);
    }
    if (diastolic.present) {
      map['diastolic'] = Variable<int>(diastolic.value);
    }
    if (heartRate.present) {
      map['heart_rate'] = Variable<int>(heartRate.value);
    }
    if (temperatureC.present) {
      map['temperature_c'] = Variable<double>(temperatureC.value);
    }
    if (spo2.present) {
      map['spo2'] = Variable<int>(spo2.value);
    }
    if (glucoseMgDl.present) {
      map['glucose_mg_dl'] = Variable<double>(glucoseMgDl.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (dialysisPhase.present) {
      map['dialysis_phase'] = Variable<String>(dialysisPhase.value);
    }
    if (measuredAt.present) {
      map['measured_at'] = Variable<DateTime>(measuredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VitalRowsCompanion(')
          ..write('id: $id, ')
          ..write('weightKg: $weightKg, ')
          ..write('edemaLevel: $edemaLevel, ')
          ..write('urineMl: $urineMl, ')
          ..write('systolic: $systolic, ')
          ..write('diastolic: $diastolic, ')
          ..write('heartRate: $heartRate, ')
          ..write('temperatureC: $temperatureC, ')
          ..write('spo2: $spo2, ')
          ..write('glucoseMgDl: $glucoseMgDl, ')
          ..write('note: $note, ')
          ..write('dialysisPhase: $dialysisPhase, ')
          ..write('measuredAt: $measuredAt')
          ..write(')'))
        .toString();
  }
}

class $DietPlanRowsTable extends DietPlanRows
    with TableInfo<$DietPlanRowsTable, DietPlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DietPlanRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, content, active, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diet_plan_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<DietPlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DietPlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DietPlanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DietPlanRowsTable createAlias(String alias) {
    return $DietPlanRowsTable(attachedDatabase, alias);
  }
}

class DietPlanRow extends DataClass implements Insertable<DietPlanRow> {
  final int id;
  final String title;
  final String content;
  final bool active;
  final DateTime createdAt;
  const DietPlanRow({
    required this.id,
    required this.title,
    required this.content,
    required this.active,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DietPlanRowsCompanion toCompanion(bool nullToAbsent) {
    return DietPlanRowsCompanion(
      id: Value(id),
      title: Value(title),
      content: Value(content),
      active: Value(active),
      createdAt: Value(createdAt),
    );
  }

  factory DietPlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DietPlanRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DietPlanRow copyWith({
    int? id,
    String? title,
    String? content,
    bool? active,
    DateTime? createdAt,
  }) => DietPlanRow(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
  );
  DietPlanRow copyWithCompanion(DietPlanRowsCompanion data) {
    return DietPlanRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DietPlanRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, content, active, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DietPlanRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.active == this.active &&
          other.createdAt == this.createdAt);
}

class DietPlanRowsCompanion extends UpdateCompanion<DietPlanRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> content;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  const DietPlanRowsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DietPlanRowsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String content,
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : title = Value(title),
       content = Value(content);
  static Insertable<DietPlanRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DietPlanRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? content,
    Value<bool>? active,
    Value<DateTime>? createdAt,
  }) {
    return DietPlanRowsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DietPlanRowsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DietAdherenceRowsTable extends DietAdherenceRows
    with TableInfo<$DietAdherenceRowsTable, DietAdherenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DietAdherenceRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _percentMeta = const VerificationMeta(
    'percent',
  );
  @override
  late final GeneratedColumn<int> percent = GeneratedColumn<int>(
    'percent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, planId, day, percent, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diet_adherence_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<DietAdherenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('percent')) {
      context.handle(
        _percentMeta,
        percent.isAcceptableOrUnknown(data['percent']!, _percentMeta),
      );
    } else if (isInserting) {
      context.missing(_percentMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DietAdherenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DietAdherenceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}day'],
      )!,
      percent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}percent'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $DietAdherenceRowsTable createAlias(String alias) {
    return $DietAdherenceRowsTable(attachedDatabase, alias);
  }
}

class DietAdherenceRow extends DataClass
    implements Insertable<DietAdherenceRow> {
  final int id;
  final int planId;
  final DateTime day;

  /// 0-100 arası kullanıcı değerlendirmesi.
  final int percent;
  final String? note;
  const DietAdherenceRow({
    required this.id,
    required this.planId,
    required this.day,
    required this.percent,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plan_id'] = Variable<int>(planId);
    map['day'] = Variable<DateTime>(day);
    map['percent'] = Variable<int>(percent);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  DietAdherenceRowsCompanion toCompanion(bool nullToAbsent) {
    return DietAdherenceRowsCompanion(
      id: Value(id),
      planId: Value(planId),
      day: Value(day),
      percent: Value(percent),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory DietAdherenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DietAdherenceRow(
      id: serializer.fromJson<int>(json['id']),
      planId: serializer.fromJson<int>(json['planId']),
      day: serializer.fromJson<DateTime>(json['day']),
      percent: serializer.fromJson<int>(json['percent']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'planId': serializer.toJson<int>(planId),
      'day': serializer.toJson<DateTime>(day),
      'percent': serializer.toJson<int>(percent),
      'note': serializer.toJson<String?>(note),
    };
  }

  DietAdherenceRow copyWith({
    int? id,
    int? planId,
    DateTime? day,
    int? percent,
    Value<String?> note = const Value.absent(),
  }) => DietAdherenceRow(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    day: day ?? this.day,
    percent: percent ?? this.percent,
    note: note.present ? note.value : this.note,
  );
  DietAdherenceRow copyWithCompanion(DietAdherenceRowsCompanion data) {
    return DietAdherenceRow(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      day: data.day.present ? data.day.value : this.day,
      percent: data.percent.present ? data.percent.value : this.percent,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DietAdherenceRow(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('day: $day, ')
          ..write('percent: $percent, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, planId, day, percent, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DietAdherenceRow &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.day == this.day &&
          other.percent == this.percent &&
          other.note == this.note);
}

class DietAdherenceRowsCompanion extends UpdateCompanion<DietAdherenceRow> {
  final Value<int> id;
  final Value<int> planId;
  final Value<DateTime> day;
  final Value<int> percent;
  final Value<String?> note;
  const DietAdherenceRowsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.day = const Value.absent(),
    this.percent = const Value.absent(),
    this.note = const Value.absent(),
  });
  DietAdherenceRowsCompanion.insert({
    this.id = const Value.absent(),
    required int planId,
    required DateTime day,
    required int percent,
    this.note = const Value.absent(),
  }) : planId = Value(planId),
       day = Value(day),
       percent = Value(percent);
  static Insertable<DietAdherenceRow> custom({
    Expression<int>? id,
    Expression<int>? planId,
    Expression<DateTime>? day,
    Expression<int>? percent,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (day != null) 'day': day,
      if (percent != null) 'percent': percent,
      if (note != null) 'note': note,
    });
  }

  DietAdherenceRowsCompanion copyWith({
    Value<int>? id,
    Value<int>? planId,
    Value<DateTime>? day,
    Value<int>? percent,
    Value<String?>? note,
  }) {
    return DietAdherenceRowsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      day: day ?? this.day,
      percent: percent ?? this.percent,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (percent.present) {
      map['percent'] = Variable<int>(percent.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DietAdherenceRowsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('day: $day, ')
          ..write('percent: $percent, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $ChatMessageRowsTable extends ChatMessageRows
    with TableInfo<$ChatMessageRowsTable, ChatMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessageRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inputTokensMeta = const VerificationMeta(
    'inputTokens',
  );
  @override
  late final GeneratedColumn<int> inputTokens = GeneratedColumn<int>(
    'input_tokens',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outputTokensMeta = const VerificationMeta(
    'outputTokens',
  );
  @override
  late final GeneratedColumn<int> outputTokens = GeneratedColumn<int>(
    'output_tokens',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    role,
    content,
    imagePath,
    model,
    inputTokens,
    outputTokens,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_message_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatMessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('input_tokens')) {
      context.handle(
        _inputTokensMeta,
        inputTokens.isAcceptableOrUnknown(
          data['input_tokens']!,
          _inputTokensMeta,
        ),
      );
    }
    if (data.containsKey('output_tokens')) {
      context.handle(
        _outputTokensMeta,
        outputTokens.isAcceptableOrUnknown(
          data['output_tokens']!,
          _outputTokensMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      inputTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}input_tokens'],
      ),
      outputTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}output_tokens'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ChatMessageRowsTable createAlias(String alias) {
    return $ChatMessageRowsTable(attachedDatabase, alias);
  }
}

class ChatMessageRow extends DataClass implements Insertable<ChatMessageRow> {
  final int id;

  /// 'user' | 'assistant' | 'system_note'
  final String role;
  final String content;

  /// Gönderilen görselin yerel yolu (varsa).
  final String? imagePath;
  final String? model;
  final int? inputTokens;
  final int? outputTokens;
  final DateTime createdAt;
  const ChatMessageRow({
    required this.id,
    required this.role,
    required this.content,
    this.imagePath,
    this.model,
    this.inputTokens,
    this.outputTokens,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || inputTokens != null) {
      map['input_tokens'] = Variable<int>(inputTokens);
    }
    if (!nullToAbsent || outputTokens != null) {
      map['output_tokens'] = Variable<int>(outputTokens);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChatMessageRowsCompanion toCompanion(bool nullToAbsent) {
    return ChatMessageRowsCompanion(
      id: Value(id),
      role: Value(role),
      content: Value(content),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      inputTokens: inputTokens == null && nullToAbsent
          ? const Value.absent()
          : Value(inputTokens),
      outputTokens: outputTokens == null && nullToAbsent
          ? const Value.absent()
          : Value(outputTokens),
      createdAt: Value(createdAt),
    );
  }

  factory ChatMessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessageRow(
      id: serializer.fromJson<int>(json['id']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      model: serializer.fromJson<String?>(json['model']),
      inputTokens: serializer.fromJson<int?>(json['inputTokens']),
      outputTokens: serializer.fromJson<int?>(json['outputTokens']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'imagePath': serializer.toJson<String?>(imagePath),
      'model': serializer.toJson<String?>(model),
      'inputTokens': serializer.toJson<int?>(inputTokens),
      'outputTokens': serializer.toJson<int?>(outputTokens),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChatMessageRow copyWith({
    int? id,
    String? role,
    String? content,
    Value<String?> imagePath = const Value.absent(),
    Value<String?> model = const Value.absent(),
    Value<int?> inputTokens = const Value.absent(),
    Value<int?> outputTokens = const Value.absent(),
    DateTime? createdAt,
  }) => ChatMessageRow(
    id: id ?? this.id,
    role: role ?? this.role,
    content: content ?? this.content,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    model: model.present ? model.value : this.model,
    inputTokens: inputTokens.present ? inputTokens.value : this.inputTokens,
    outputTokens: outputTokens.present ? outputTokens.value : this.outputTokens,
    createdAt: createdAt ?? this.createdAt,
  );
  ChatMessageRow copyWithCompanion(ChatMessageRowsCompanion data) {
    return ChatMessageRow(
      id: data.id.present ? data.id.value : this.id,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      model: data.model.present ? data.model.value : this.model,
      inputTokens: data.inputTokens.present
          ? data.inputTokens.value
          : this.inputTokens,
      outputTokens: data.outputTokens.present
          ? data.outputTokens.value
          : this.outputTokens,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessageRow(')
          ..write('id: $id, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('imagePath: $imagePath, ')
          ..write('model: $model, ')
          ..write('inputTokens: $inputTokens, ')
          ..write('outputTokens: $outputTokens, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    role,
    content,
    imagePath,
    model,
    inputTokens,
    outputTokens,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessageRow &&
          other.id == this.id &&
          other.role == this.role &&
          other.content == this.content &&
          other.imagePath == this.imagePath &&
          other.model == this.model &&
          other.inputTokens == this.inputTokens &&
          other.outputTokens == this.outputTokens &&
          other.createdAt == this.createdAt);
}

class ChatMessageRowsCompanion extends UpdateCompanion<ChatMessageRow> {
  final Value<int> id;
  final Value<String> role;
  final Value<String> content;
  final Value<String?> imagePath;
  final Value<String?> model;
  final Value<int?> inputTokens;
  final Value<int?> outputTokens;
  final Value<DateTime> createdAt;
  const ChatMessageRowsCompanion({
    this.id = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.model = const Value.absent(),
    this.inputTokens = const Value.absent(),
    this.outputTokens = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ChatMessageRowsCompanion.insert({
    this.id = const Value.absent(),
    required String role,
    required String content,
    this.imagePath = const Value.absent(),
    this.model = const Value.absent(),
    this.inputTokens = const Value.absent(),
    this.outputTokens = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : role = Value(role),
       content = Value(content);
  static Insertable<ChatMessageRow> custom({
    Expression<int>? id,
    Expression<String>? role,
    Expression<String>? content,
    Expression<String>? imagePath,
    Expression<String>? model,
    Expression<int>? inputTokens,
    Expression<int>? outputTokens,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (imagePath != null) 'image_path': imagePath,
      if (model != null) 'model': model,
      if (inputTokens != null) 'input_tokens': inputTokens,
      if (outputTokens != null) 'output_tokens': outputTokens,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ChatMessageRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? role,
    Value<String>? content,
    Value<String?>? imagePath,
    Value<String?>? model,
    Value<int?>? inputTokens,
    Value<int?>? outputTokens,
    Value<DateTime>? createdAt,
  }) {
    return ChatMessageRowsCompanion(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      model: model ?? this.model,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (inputTokens.present) {
      map['input_tokens'] = Variable<int>(inputTokens.value);
    }
    if (outputTokens.present) {
      map['output_tokens'] = Variable<int>(outputTokens.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessageRowsCompanion(')
          ..write('id: $id, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('imagePath: $imagePath, ')
          ..write('model: $model, ')
          ..write('inputTokens: $inputTokens, ')
          ..write('outputTokens: $outputTokens, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TravelPlanRowsTable extends TravelPlanRows
    with TableInfo<$TravelPlanRowsTable, TravelPlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TravelPlanRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _destinationMeta = const VerificationMeta(
    'destination',
  );
  @override
  late final GeneratedColumn<String> destination = GeneratedColumn<String>(
    'destination',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startsAtMeta = const VerificationMeta(
    'startsAt',
  );
  @override
  late final GeneratedColumn<DateTime> startsAt = GeneratedColumn<DateTime>(
    'starts_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _daysMeta = const VerificationMeta('days');
  @override
  late final GeneratedColumn<int> days = GeneratedColumn<int>(
    'days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planMarkdownMeta = const VerificationMeta(
    'planMarkdown',
  );
  @override
  late final GeneratedColumn<String> planMarkdown = GeneratedColumn<String>(
    'plan_markdown',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionsMeta = const VerificationMeta(
    'options',
  );
  @override
  late final GeneratedColumn<String> options = GeneratedColumn<String>(
    'options',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    destination,
    startsAt,
    days,
    planMarkdown,
    options,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'travel_plan_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<TravelPlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('destination')) {
      context.handle(
        _destinationMeta,
        destination.isAcceptableOrUnknown(
          data['destination']!,
          _destinationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_destinationMeta);
    }
    if (data.containsKey('starts_at')) {
      context.handle(
        _startsAtMeta,
        startsAt.isAcceptableOrUnknown(data['starts_at']!, _startsAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startsAtMeta);
    }
    if (data.containsKey('days')) {
      context.handle(
        _daysMeta,
        days.isAcceptableOrUnknown(data['days']!, _daysMeta),
      );
    } else if (isInserting) {
      context.missing(_daysMeta);
    }
    if (data.containsKey('plan_markdown')) {
      context.handle(
        _planMarkdownMeta,
        planMarkdown.isAcceptableOrUnknown(
          data['plan_markdown']!,
          _planMarkdownMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_planMarkdownMeta);
    }
    if (data.containsKey('options')) {
      context.handle(
        _optionsMeta,
        options.isAcceptableOrUnknown(data['options']!, _optionsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TravelPlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TravelPlanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      destination: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination'],
      )!,
      startsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}starts_at'],
      )!,
      days: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days'],
      )!,
      planMarkdown: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_markdown'],
      )!,
      options: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TravelPlanRowsTable createAlias(String alias) {
    return $TravelPlanRowsTable(attachedDatabase, alias);
  }
}

class TravelPlanRow extends DataClass implements Insertable<TravelPlanRow> {
  final int id;
  final String destination;
  final DateTime startsAt;
  final int days;
  final String planMarkdown;
  final String? options;
  final DateTime createdAt;
  const TravelPlanRow({
    required this.id,
    required this.destination,
    required this.startsAt,
    required this.days,
    required this.planMarkdown,
    this.options,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['destination'] = Variable<String>(destination);
    map['starts_at'] = Variable<DateTime>(startsAt);
    map['days'] = Variable<int>(days);
    map['plan_markdown'] = Variable<String>(planMarkdown);
    if (!nullToAbsent || options != null) {
      map['options'] = Variable<String>(options);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TravelPlanRowsCompanion toCompanion(bool nullToAbsent) {
    return TravelPlanRowsCompanion(
      id: Value(id),
      destination: Value(destination),
      startsAt: Value(startsAt),
      days: Value(days),
      planMarkdown: Value(planMarkdown),
      options: options == null && nullToAbsent
          ? const Value.absent()
          : Value(options),
      createdAt: Value(createdAt),
    );
  }

  factory TravelPlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TravelPlanRow(
      id: serializer.fromJson<int>(json['id']),
      destination: serializer.fromJson<String>(json['destination']),
      startsAt: serializer.fromJson<DateTime>(json['startsAt']),
      days: serializer.fromJson<int>(json['days']),
      planMarkdown: serializer.fromJson<String>(json['planMarkdown']),
      options: serializer.fromJson<String?>(json['options']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'destination': serializer.toJson<String>(destination),
      'startsAt': serializer.toJson<DateTime>(startsAt),
      'days': serializer.toJson<int>(days),
      'planMarkdown': serializer.toJson<String>(planMarkdown),
      'options': serializer.toJson<String?>(options),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TravelPlanRow copyWith({
    int? id,
    String? destination,
    DateTime? startsAt,
    int? days,
    String? planMarkdown,
    Value<String?> options = const Value.absent(),
    DateTime? createdAt,
  }) => TravelPlanRow(
    id: id ?? this.id,
    destination: destination ?? this.destination,
    startsAt: startsAt ?? this.startsAt,
    days: days ?? this.days,
    planMarkdown: planMarkdown ?? this.planMarkdown,
    options: options.present ? options.value : this.options,
    createdAt: createdAt ?? this.createdAt,
  );
  TravelPlanRow copyWithCompanion(TravelPlanRowsCompanion data) {
    return TravelPlanRow(
      id: data.id.present ? data.id.value : this.id,
      destination: data.destination.present
          ? data.destination.value
          : this.destination,
      startsAt: data.startsAt.present ? data.startsAt.value : this.startsAt,
      days: data.days.present ? data.days.value : this.days,
      planMarkdown: data.planMarkdown.present
          ? data.planMarkdown.value
          : this.planMarkdown,
      options: data.options.present ? data.options.value : this.options,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TravelPlanRow(')
          ..write('id: $id, ')
          ..write('destination: $destination, ')
          ..write('startsAt: $startsAt, ')
          ..write('days: $days, ')
          ..write('planMarkdown: $planMarkdown, ')
          ..write('options: $options, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    destination,
    startsAt,
    days,
    planMarkdown,
    options,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TravelPlanRow &&
          other.id == this.id &&
          other.destination == this.destination &&
          other.startsAt == this.startsAt &&
          other.days == this.days &&
          other.planMarkdown == this.planMarkdown &&
          other.options == this.options &&
          other.createdAt == this.createdAt);
}

class TravelPlanRowsCompanion extends UpdateCompanion<TravelPlanRow> {
  final Value<int> id;
  final Value<String> destination;
  final Value<DateTime> startsAt;
  final Value<int> days;
  final Value<String> planMarkdown;
  final Value<String?> options;
  final Value<DateTime> createdAt;
  const TravelPlanRowsCompanion({
    this.id = const Value.absent(),
    this.destination = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.days = const Value.absent(),
    this.planMarkdown = const Value.absent(),
    this.options = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TravelPlanRowsCompanion.insert({
    this.id = const Value.absent(),
    required String destination,
    required DateTime startsAt,
    required int days,
    required String planMarkdown,
    this.options = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : destination = Value(destination),
       startsAt = Value(startsAt),
       days = Value(days),
       planMarkdown = Value(planMarkdown);
  static Insertable<TravelPlanRow> custom({
    Expression<int>? id,
    Expression<String>? destination,
    Expression<DateTime>? startsAt,
    Expression<int>? days,
    Expression<String>? planMarkdown,
    Expression<String>? options,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (destination != null) 'destination': destination,
      if (startsAt != null) 'starts_at': startsAt,
      if (days != null) 'days': days,
      if (planMarkdown != null) 'plan_markdown': planMarkdown,
      if (options != null) 'options': options,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TravelPlanRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? destination,
    Value<DateTime>? startsAt,
    Value<int>? days,
    Value<String>? planMarkdown,
    Value<String?>? options,
    Value<DateTime>? createdAt,
  }) {
    return TravelPlanRowsCompanion(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      startsAt: startsAt ?? this.startsAt,
      days: days ?? this.days,
      planMarkdown: planMarkdown ?? this.planMarkdown,
      options: options ?? this.options,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (destination.present) {
      map['destination'] = Variable<String>(destination.value);
    }
    if (startsAt.present) {
      map['starts_at'] = Variable<DateTime>(startsAt.value);
    }
    if (days.present) {
      map['days'] = Variable<int>(days.value);
    }
    if (planMarkdown.present) {
      map['plan_markdown'] = Variable<String>(planMarkdown.value);
    }
    if (options.present) {
      map['options'] = Variable<String>(options.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TravelPlanRowsCompanion(')
          ..write('id: $id, ')
          ..write('destination: $destination, ')
          ..write('startsAt: $startsAt, ')
          ..write('days: $days, ')
          ..write('planMarkdown: $planMarkdown, ')
          ..write('options: $options, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ArticleRowsTable extends ArticleRows
    with TableInfo<$ArticleRowsTable, ArticleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArticleRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkMeta = const VerificationMeta('link');
  @override
  late final GeneratedColumn<String> link = GeneratedColumn<String>(
    'link',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceNameMeta = const VerificationMeta(
    'sourceName',
  );
  @override
  late final GeneratedColumn<String> sourceName = GeneratedColumn<String>(
    'source_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> publishedAt = GeneratedColumn<DateTime>(
    'published_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _savedOfflineMeta = const VerificationMeta(
    'savedOffline',
  );
  @override
  late final GeneratedColumn<bool> savedOffline = GeneratedColumn<bool>(
    'saved_offline',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("saved_offline" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    summary,
    body,
    link,
    sourceName,
    origin,
    publishedAt,
    fetchedAt,
    savedOffline,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'article_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArticleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('link')) {
      context.handle(
        _linkMeta,
        link.isAcceptableOrUnknown(data['link']!, _linkMeta),
      );
    }
    if (data.containsKey('source_name')) {
      context.handle(
        _sourceNameMeta,
        sourceName.isAcceptableOrUnknown(data['source_name']!, _sourceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceNameMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    }
    if (data.containsKey('saved_offline')) {
      context.handle(
        _savedOfflineMeta,
        savedOffline.isAcceptableOrUnknown(
          data['saved_offline']!,
          _savedOfflineMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ArticleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArticleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      ),
      link: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}link'],
      ),
      sourceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_name'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}published_at'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      savedOffline: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}saved_offline'],
      )!,
    );
  }

  @override
  $ArticleRowsTable createAlias(String alias) {
    return $ArticleRowsTable(attachedDatabase, alias);
  }
}

class ArticleRow extends DataClass implements Insertable<ArticleRow> {
  final int id;
  final String title;
  final String? summary;
  final String? body;
  final String? link;
  final String sourceName;

  /// 'rss' | 'builtin'
  final String origin;
  final DateTime? publishedAt;
  final DateTime fetchedAt;
  final bool savedOffline;
  const ArticleRow({
    required this.id,
    required this.title,
    this.summary,
    this.body,
    this.link,
    required this.sourceName,
    required this.origin,
    this.publishedAt,
    required this.fetchedAt,
    required this.savedOffline,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    if (!nullToAbsent || link != null) {
      map['link'] = Variable<String>(link);
    }
    map['source_name'] = Variable<String>(sourceName);
    map['origin'] = Variable<String>(origin);
    if (!nullToAbsent || publishedAt != null) {
      map['published_at'] = Variable<DateTime>(publishedAt);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    map['saved_offline'] = Variable<bool>(savedOffline);
    return map;
  }

  ArticleRowsCompanion toCompanion(bool nullToAbsent) {
    return ArticleRowsCompanion(
      id: Value(id),
      title: Value(title),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      link: link == null && nullToAbsent ? const Value.absent() : Value(link),
      sourceName: Value(sourceName),
      origin: Value(origin),
      publishedAt: publishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(publishedAt),
      fetchedAt: Value(fetchedAt),
      savedOffline: Value(savedOffline),
    );
  }

  factory ArticleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArticleRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      summary: serializer.fromJson<String?>(json['summary']),
      body: serializer.fromJson<String?>(json['body']),
      link: serializer.fromJson<String?>(json['link']),
      sourceName: serializer.fromJson<String>(json['sourceName']),
      origin: serializer.fromJson<String>(json['origin']),
      publishedAt: serializer.fromJson<DateTime?>(json['publishedAt']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      savedOffline: serializer.fromJson<bool>(json['savedOffline']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'summary': serializer.toJson<String?>(summary),
      'body': serializer.toJson<String?>(body),
      'link': serializer.toJson<String?>(link),
      'sourceName': serializer.toJson<String>(sourceName),
      'origin': serializer.toJson<String>(origin),
      'publishedAt': serializer.toJson<DateTime?>(publishedAt),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'savedOffline': serializer.toJson<bool>(savedOffline),
    };
  }

  ArticleRow copyWith({
    int? id,
    String? title,
    Value<String?> summary = const Value.absent(),
    Value<String?> body = const Value.absent(),
    Value<String?> link = const Value.absent(),
    String? sourceName,
    String? origin,
    Value<DateTime?> publishedAt = const Value.absent(),
    DateTime? fetchedAt,
    bool? savedOffline,
  }) => ArticleRow(
    id: id ?? this.id,
    title: title ?? this.title,
    summary: summary.present ? summary.value : this.summary,
    body: body.present ? body.value : this.body,
    link: link.present ? link.value : this.link,
    sourceName: sourceName ?? this.sourceName,
    origin: origin ?? this.origin,
    publishedAt: publishedAt.present ? publishedAt.value : this.publishedAt,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    savedOffline: savedOffline ?? this.savedOffline,
  );
  ArticleRow copyWithCompanion(ArticleRowsCompanion data) {
    return ArticleRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      summary: data.summary.present ? data.summary.value : this.summary,
      body: data.body.present ? data.body.value : this.body,
      link: data.link.present ? data.link.value : this.link,
      sourceName: data.sourceName.present
          ? data.sourceName.value
          : this.sourceName,
      origin: data.origin.present ? data.origin.value : this.origin,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      savedOffline: data.savedOffline.present
          ? data.savedOffline.value
          : this.savedOffline,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArticleRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('body: $body, ')
          ..write('link: $link, ')
          ..write('sourceName: $sourceName, ')
          ..write('origin: $origin, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('savedOffline: $savedOffline')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    summary,
    body,
    link,
    sourceName,
    origin,
    publishedAt,
    fetchedAt,
    savedOffline,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArticleRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.summary == this.summary &&
          other.body == this.body &&
          other.link == this.link &&
          other.sourceName == this.sourceName &&
          other.origin == this.origin &&
          other.publishedAt == this.publishedAt &&
          other.fetchedAt == this.fetchedAt &&
          other.savedOffline == this.savedOffline);
}

class ArticleRowsCompanion extends UpdateCompanion<ArticleRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> summary;
  final Value<String?> body;
  final Value<String?> link;
  final Value<String> sourceName;
  final Value<String> origin;
  final Value<DateTime?> publishedAt;
  final Value<DateTime> fetchedAt;
  final Value<bool> savedOffline;
  const ArticleRowsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.summary = const Value.absent(),
    this.body = const Value.absent(),
    this.link = const Value.absent(),
    this.sourceName = const Value.absent(),
    this.origin = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.savedOffline = const Value.absent(),
  });
  ArticleRowsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.summary = const Value.absent(),
    this.body = const Value.absent(),
    this.link = const Value.absent(),
    required String sourceName,
    required String origin,
    this.publishedAt = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.savedOffline = const Value.absent(),
  }) : title = Value(title),
       sourceName = Value(sourceName),
       origin = Value(origin);
  static Insertable<ArticleRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? summary,
    Expression<String>? body,
    Expression<String>? link,
    Expression<String>? sourceName,
    Expression<String>? origin,
    Expression<DateTime>? publishedAt,
    Expression<DateTime>? fetchedAt,
    Expression<bool>? savedOffline,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (summary != null) 'summary': summary,
      if (body != null) 'body': body,
      if (link != null) 'link': link,
      if (sourceName != null) 'source_name': sourceName,
      if (origin != null) 'origin': origin,
      if (publishedAt != null) 'published_at': publishedAt,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (savedOffline != null) 'saved_offline': savedOffline,
    });
  }

  ArticleRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? summary,
    Value<String?>? body,
    Value<String?>? link,
    Value<String>? sourceName,
    Value<String>? origin,
    Value<DateTime?>? publishedAt,
    Value<DateTime>? fetchedAt,
    Value<bool>? savedOffline,
  }) {
    return ArticleRowsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      body: body ?? this.body,
      link: link ?? this.link,
      sourceName: sourceName ?? this.sourceName,
      origin: origin ?? this.origin,
      publishedAt: publishedAt ?? this.publishedAt,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      savedOffline: savedOffline ?? this.savedOffline,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (link.present) {
      map['link'] = Variable<String>(link.value);
    }
    if (sourceName.present) {
      map['source_name'] = Variable<String>(sourceName.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<DateTime>(publishedAt.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (savedOffline.present) {
      map['saved_offline'] = Variable<bool>(savedOffline.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArticleRowsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('body: $body, ')
          ..write('link: $link, ')
          ..write('sourceName: $sourceName, ')
          ..write('origin: $origin, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('savedOffline: $savedOffline')
          ..write(')'))
        .toString();
  }
}

class $HttpCacheRowsTable extends HttpCacheRows
    with TableInfo<$HttpCacheRowsTable, HttpCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HttpCacheRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [cacheKey, body, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'http_cache_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<HttpCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  HttpCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HttpCacheRow(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $HttpCacheRowsTable createAlias(String alias) {
    return $HttpCacheRowsTable(attachedDatabase, alias);
  }
}

class HttpCacheRow extends DataClass implements Insertable<HttpCacheRow> {
  final String cacheKey;
  final String body;
  final DateTime fetchedAt;
  const HttpCacheRow({
    required this.cacheKey,
    required this.body,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['body'] = Variable<String>(body);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  HttpCacheRowsCompanion toCompanion(bool nullToAbsent) {
    return HttpCacheRowsCompanion(
      cacheKey: Value(cacheKey),
      body: Value(body),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory HttpCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HttpCacheRow(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      body: serializer.fromJson<String>(json['body']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'body': serializer.toJson<String>(body),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  HttpCacheRow copyWith({
    String? cacheKey,
    String? body,
    DateTime? fetchedAt,
  }) => HttpCacheRow(
    cacheKey: cacheKey ?? this.cacheKey,
    body: body ?? this.body,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  HttpCacheRow copyWithCompanion(HttpCacheRowsCompanion data) {
    return HttpCacheRow(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      body: data.body.present ? data.body.value : this.body,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HttpCacheRow(')
          ..write('cacheKey: $cacheKey, ')
          ..write('body: $body, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cacheKey, body, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HttpCacheRow &&
          other.cacheKey == this.cacheKey &&
          other.body == this.body &&
          other.fetchedAt == this.fetchedAt);
}

class HttpCacheRowsCompanion extends UpdateCompanion<HttpCacheRow> {
  final Value<String> cacheKey;
  final Value<String> body;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const HttpCacheRowsCompanion({
    this.cacheKey = const Value.absent(),
    this.body = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HttpCacheRowsCompanion.insert({
    required String cacheKey,
    required String body,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       body = Value(body),
       fetchedAt = Value(fetchedAt);
  static Insertable<HttpCacheRow> custom({
    Expression<String>? cacheKey,
    Expression<String>? body,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (body != null) 'body': body,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HttpCacheRowsCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? body,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return HttpCacheRowsCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      body: body ?? this.body,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HttpCacheRowsCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('body: $body, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationLogRowsTable extends NotificationLogRows
    with TableInfo<$NotificationLogRowsTable, NotificationLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationLogRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, category, title, body, sentAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_log_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      ),
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      )!,
    );
  }

  @override
  $NotificationLogRowsTable createAlias(String alias) {
    return $NotificationLogRowsTable(attachedDatabase, alias);
  }
}

class NotificationLogRow extends DataClass
    implements Insertable<NotificationLogRow> {
  final int id;

  /// 'medication' | 'appointment' | 'smart' | 'summary'
  final String category;
  final String title;
  final String? body;
  final DateTime sentAt;
  const NotificationLogRow({
    required this.id,
    required this.category,
    required this.title,
    this.body,
    required this.sentAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category'] = Variable<String>(category);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    map['sent_at'] = Variable<DateTime>(sentAt);
    return map;
  }

  NotificationLogRowsCompanion toCompanion(bool nullToAbsent) {
    return NotificationLogRowsCompanion(
      id: Value(id),
      category: Value(category),
      title: Value(title),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      sentAt: Value(sentAt),
    );
  }

  factory NotificationLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationLogRow(
      id: serializer.fromJson<int>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String?>(json['body']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'category': serializer.toJson<String>(category),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String?>(body),
      'sentAt': serializer.toJson<DateTime>(sentAt),
    };
  }

  NotificationLogRow copyWith({
    int? id,
    String? category,
    String? title,
    Value<String?> body = const Value.absent(),
    DateTime? sentAt,
  }) => NotificationLogRow(
    id: id ?? this.id,
    category: category ?? this.category,
    title: title ?? this.title,
    body: body.present ? body.value : this.body,
    sentAt: sentAt ?? this.sentAt,
  );
  NotificationLogRow copyWithCompanion(NotificationLogRowsCompanion data) {
    return NotificationLogRow(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationLogRow(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('sentAt: $sentAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, category, title, body, sentAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationLogRow &&
          other.id == this.id &&
          other.category == this.category &&
          other.title == this.title &&
          other.body == this.body &&
          other.sentAt == this.sentAt);
}

class NotificationLogRowsCompanion extends UpdateCompanion<NotificationLogRow> {
  final Value<int> id;
  final Value<String> category;
  final Value<String> title;
  final Value<String?> body;
  final Value<DateTime> sentAt;
  const NotificationLogRowsCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.sentAt = const Value.absent(),
  });
  NotificationLogRowsCompanion.insert({
    this.id = const Value.absent(),
    required String category,
    required String title,
    this.body = const Value.absent(),
    this.sentAt = const Value.absent(),
  }) : category = Value(category),
       title = Value(title);
  static Insertable<NotificationLogRow> custom({
    Expression<int>? id,
    Expression<String>? category,
    Expression<String>? title,
    Expression<String>? body,
    Expression<DateTime>? sentAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (sentAt != null) 'sent_at': sentAt,
    });
  }

  NotificationLogRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? category,
    Value<String>? title,
    Value<String?>? body,
    Value<DateTime>? sentAt,
  }) {
    return NotificationLogRowsCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      body: body ?? this.body,
      sentAt: sentAt ?? this.sentAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationLogRowsCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('sentAt: $sentAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSettingsRowsTable appSettingsRows = $AppSettingsRowsTable(
    this,
  );
  late final $ClinicalChangeRowsTable clinicalChangeRows =
      $ClinicalChangeRowsTable(this);
  late final $ProfileRowsTable profileRows = $ProfileRowsTable(this);
  late final $EmergencyContactRowsTable emergencyContactRows =
      $EmergencyContactRowsTable(this);
  late final $FoodItemRowsTable foodItemRows = $FoodItemRowsTable(this);
  late final $FoodLogRowsTable foodLogRows = $FoodLogRowsTable(this);
  late final $FluidLogRowsTable fluidLogRows = $FluidLogRowsTable(this);
  late final $LabResultRowsTable labResultRows = $LabResultRowsTable(this);
  late final $AppointmentRowsTable appointmentRows = $AppointmentRowsTable(
    this,
  );
  late final $MedicationRowsTable medicationRows = $MedicationRowsTable(this);
  late final $MedicationDoseRowsTable medicationDoseRows =
      $MedicationDoseRowsTable(this);
  late final $VitalRowsTable vitalRows = $VitalRowsTable(this);
  late final $DietPlanRowsTable dietPlanRows = $DietPlanRowsTable(this);
  late final $DietAdherenceRowsTable dietAdherenceRows =
      $DietAdherenceRowsTable(this);
  late final $ChatMessageRowsTable chatMessageRows = $ChatMessageRowsTable(
    this,
  );
  late final $TravelPlanRowsTable travelPlanRows = $TravelPlanRowsTable(this);
  late final $ArticleRowsTable articleRows = $ArticleRowsTable(this);
  late final $HttpCacheRowsTable httpCacheRows = $HttpCacheRowsTable(this);
  late final $NotificationLogRowsTable notificationLogRows =
      $NotificationLogRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettingsRows,
    clinicalChangeRows,
    profileRows,
    emergencyContactRows,
    foodItemRows,
    foodLogRows,
    fluidLogRows,
    labResultRows,
    appointmentRows,
    medicationRows,
    medicationDoseRows,
    vitalRows,
    dietPlanRows,
    dietAdherenceRows,
    chatMessageRows,
    travelPlanRows,
    articleRows,
    httpCacheRows,
    notificationLogRows,
  ];
}

typedef $$AppSettingsRowsTableCreateCompanionBuilder =
    AppSettingsRowsCompanion Function({
      required String key,
      required String value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsRowsTableUpdateCompanionBuilder =
    AppSettingsRowsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppSettingsRowsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsRowsTable> {
  $$AppSettingsRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsRowsTable> {
  $$AppSettingsRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsRowsTable> {
  $$AppSettingsRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsRowsTable,
          AppSettingsRow,
          $$AppSettingsRowsTableFilterComposer,
          $$AppSettingsRowsTableOrderingComposer,
          $$AppSettingsRowsTableAnnotationComposer,
          $$AppSettingsRowsTableCreateCompanionBuilder,
          $$AppSettingsRowsTableUpdateCompanionBuilder,
          (
            AppSettingsRow,
            BaseReferences<
              _$AppDatabase,
              $AppSettingsRowsTable,
              AppSettingsRow
            >,
          ),
          AppSettingsRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsRowsTableTableManager(
    _$AppDatabase db,
    $AppSettingsRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsRowsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsRowsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsRowsTable,
      AppSettingsRow,
      $$AppSettingsRowsTableFilterComposer,
      $$AppSettingsRowsTableOrderingComposer,
      $$AppSettingsRowsTableAnnotationComposer,
      $$AppSettingsRowsTableCreateCompanionBuilder,
      $$AppSettingsRowsTableUpdateCompanionBuilder,
      (
        AppSettingsRow,
        BaseReferences<_$AppDatabase, $AppSettingsRowsTable, AppSettingsRow>,
      ),
      AppSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$ClinicalChangeRowsTableCreateCompanionBuilder =
    ClinicalChangeRowsCompanion Function({
      Value<int> id,
      required String valueKey,
      Value<String?> oldText,
      Value<String?> newText,
      Value<String?> note,
      Value<DateTime> changedAt,
    });
typedef $$ClinicalChangeRowsTableUpdateCompanionBuilder =
    ClinicalChangeRowsCompanion Function({
      Value<int> id,
      Value<String> valueKey,
      Value<String?> oldText,
      Value<String?> newText,
      Value<String?> note,
      Value<DateTime> changedAt,
    });

class $$ClinicalChangeRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ClinicalChangeRowsTable> {
  $$ClinicalChangeRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueKey => $composableBuilder(
    column: $table.valueKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get oldText => $composableBuilder(
    column: $table.oldText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get newText => $composableBuilder(
    column: $table.newText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClinicalChangeRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClinicalChangeRowsTable> {
  $$ClinicalChangeRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueKey => $composableBuilder(
    column: $table.valueKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get oldText => $composableBuilder(
    column: $table.oldText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get newText => $composableBuilder(
    column: $table.newText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClinicalChangeRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClinicalChangeRowsTable> {
  $$ClinicalChangeRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get valueKey =>
      $composableBuilder(column: $table.valueKey, builder: (column) => column);

  GeneratedColumn<String> get oldText =>
      $composableBuilder(column: $table.oldText, builder: (column) => column);

  GeneratedColumn<String> get newText =>
      $composableBuilder(column: $table.newText, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);
}

class $$ClinicalChangeRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClinicalChangeRowsTable,
          ClinicalChangeRow,
          $$ClinicalChangeRowsTableFilterComposer,
          $$ClinicalChangeRowsTableOrderingComposer,
          $$ClinicalChangeRowsTableAnnotationComposer,
          $$ClinicalChangeRowsTableCreateCompanionBuilder,
          $$ClinicalChangeRowsTableUpdateCompanionBuilder,
          (
            ClinicalChangeRow,
            BaseReferences<
              _$AppDatabase,
              $ClinicalChangeRowsTable,
              ClinicalChangeRow
            >,
          ),
          ClinicalChangeRow,
          PrefetchHooks Function()
        > {
  $$ClinicalChangeRowsTableTableManager(
    _$AppDatabase db,
    $ClinicalChangeRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClinicalChangeRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClinicalChangeRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClinicalChangeRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> valueKey = const Value.absent(),
                Value<String?> oldText = const Value.absent(),
                Value<String?> newText = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
              }) => ClinicalChangeRowsCompanion(
                id: id,
                valueKey: valueKey,
                oldText: oldText,
                newText: newText,
                note: note,
                changedAt: changedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String valueKey,
                Value<String?> oldText = const Value.absent(),
                Value<String?> newText = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
              }) => ClinicalChangeRowsCompanion.insert(
                id: id,
                valueKey: valueKey,
                oldText: oldText,
                newText: newText,
                note: note,
                changedAt: changedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClinicalChangeRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClinicalChangeRowsTable,
      ClinicalChangeRow,
      $$ClinicalChangeRowsTableFilterComposer,
      $$ClinicalChangeRowsTableOrderingComposer,
      $$ClinicalChangeRowsTableAnnotationComposer,
      $$ClinicalChangeRowsTableCreateCompanionBuilder,
      $$ClinicalChangeRowsTableUpdateCompanionBuilder,
      (
        ClinicalChangeRow,
        BaseReferences<
          _$AppDatabase,
          $ClinicalChangeRowsTable,
          ClinicalChangeRow
        >,
      ),
      ClinicalChangeRow,
      PrefetchHooks Function()
    >;
typedef $$ProfileRowsTableCreateCompanionBuilder =
    ProfileRowsCompanion Function({
      Value<int> id,
      required String name,
      Value<int?> birthYear,
      Value<double?> heightCm,
      Value<double?> weightKg,
      required String treatmentMode,
      Value<String?> dialysisDays,
      Value<String?> comorbidities,
      Value<String?> allergies,
      Value<String?> dislikedFoods,
      Value<String?> doctorName,
      Value<String?> doctorPhone,
      Value<String?> hospital,
      Value<bool> expertMode,
      Value<DateTime> createdAt,
    });
typedef $$ProfileRowsTableUpdateCompanionBuilder =
    ProfileRowsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int?> birthYear,
      Value<double?> heightCm,
      Value<double?> weightKg,
      Value<String> treatmentMode,
      Value<String?> dialysisDays,
      Value<String?> comorbidities,
      Value<String?> allergies,
      Value<String?> dislikedFoods,
      Value<String?> doctorName,
      Value<String?> doctorPhone,
      Value<String?> hospital,
      Value<bool> expertMode,
      Value<DateTime> createdAt,
    });

class $$ProfileRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ProfileRowsTable> {
  $$ProfileRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get birthYear => $composableBuilder(
    column: $table.birthYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get treatmentMode => $composableBuilder(
    column: $table.treatmentMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dialysisDays => $composableBuilder(
    column: $table.dialysisDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comorbidities => $composableBuilder(
    column: $table.comorbidities,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allergies => $composableBuilder(
    column: $table.allergies,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dislikedFoods => $composableBuilder(
    column: $table.dislikedFoods,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get doctorName => $composableBuilder(
    column: $table.doctorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get doctorPhone => $composableBuilder(
    column: $table.doctorPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hospital => $composableBuilder(
    column: $table.hospital,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get expertMode => $composableBuilder(
    column: $table.expertMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfileRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfileRowsTable> {
  $$ProfileRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get birthYear => $composableBuilder(
    column: $table.birthYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get treatmentMode => $composableBuilder(
    column: $table.treatmentMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dialysisDays => $composableBuilder(
    column: $table.dialysisDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comorbidities => $composableBuilder(
    column: $table.comorbidities,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allergies => $composableBuilder(
    column: $table.allergies,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dislikedFoods => $composableBuilder(
    column: $table.dislikedFoods,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doctorName => $composableBuilder(
    column: $table.doctorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doctorPhone => $composableBuilder(
    column: $table.doctorPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hospital => $composableBuilder(
    column: $table.hospital,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get expertMode => $composableBuilder(
    column: $table.expertMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfileRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfileRowsTable> {
  $$ProfileRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get birthYear =>
      $composableBuilder(column: $table.birthYear, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<String> get treatmentMode => $composableBuilder(
    column: $table.treatmentMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dialysisDays => $composableBuilder(
    column: $table.dialysisDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get comorbidities => $composableBuilder(
    column: $table.comorbidities,
    builder: (column) => column,
  );

  GeneratedColumn<String> get allergies =>
      $composableBuilder(column: $table.allergies, builder: (column) => column);

  GeneratedColumn<String> get dislikedFoods => $composableBuilder(
    column: $table.dislikedFoods,
    builder: (column) => column,
  );

  GeneratedColumn<String> get doctorName => $composableBuilder(
    column: $table.doctorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get doctorPhone => $composableBuilder(
    column: $table.doctorPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hospital =>
      $composableBuilder(column: $table.hospital, builder: (column) => column);

  GeneratedColumn<bool> get expertMode => $composableBuilder(
    column: $table.expertMode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProfileRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfileRowsTable,
          ProfileRow,
          $$ProfileRowsTableFilterComposer,
          $$ProfileRowsTableOrderingComposer,
          $$ProfileRowsTableAnnotationComposer,
          $$ProfileRowsTableCreateCompanionBuilder,
          $$ProfileRowsTableUpdateCompanionBuilder,
          (
            ProfileRow,
            BaseReferences<_$AppDatabase, $ProfileRowsTable, ProfileRow>,
          ),
          ProfileRow,
          PrefetchHooks Function()
        > {
  $$ProfileRowsTableTableManager(_$AppDatabase db, $ProfileRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> birthYear = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<String> treatmentMode = const Value.absent(),
                Value<String?> dialysisDays = const Value.absent(),
                Value<String?> comorbidities = const Value.absent(),
                Value<String?> allergies = const Value.absent(),
                Value<String?> dislikedFoods = const Value.absent(),
                Value<String?> doctorName = const Value.absent(),
                Value<String?> doctorPhone = const Value.absent(),
                Value<String?> hospital = const Value.absent(),
                Value<bool> expertMode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProfileRowsCompanion(
                id: id,
                name: name,
                birthYear: birthYear,
                heightCm: heightCm,
                weightKg: weightKg,
                treatmentMode: treatmentMode,
                dialysisDays: dialysisDays,
                comorbidities: comorbidities,
                allergies: allergies,
                dislikedFoods: dislikedFoods,
                doctorName: doctorName,
                doctorPhone: doctorPhone,
                hospital: hospital,
                expertMode: expertMode,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int?> birthYear = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                required String treatmentMode,
                Value<String?> dialysisDays = const Value.absent(),
                Value<String?> comorbidities = const Value.absent(),
                Value<String?> allergies = const Value.absent(),
                Value<String?> dislikedFoods = const Value.absent(),
                Value<String?> doctorName = const Value.absent(),
                Value<String?> doctorPhone = const Value.absent(),
                Value<String?> hospital = const Value.absent(),
                Value<bool> expertMode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProfileRowsCompanion.insert(
                id: id,
                name: name,
                birthYear: birthYear,
                heightCm: heightCm,
                weightKg: weightKg,
                treatmentMode: treatmentMode,
                dialysisDays: dialysisDays,
                comorbidities: comorbidities,
                allergies: allergies,
                dislikedFoods: dislikedFoods,
                doctorName: doctorName,
                doctorPhone: doctorPhone,
                hospital: hospital,
                expertMode: expertMode,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfileRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfileRowsTable,
      ProfileRow,
      $$ProfileRowsTableFilterComposer,
      $$ProfileRowsTableOrderingComposer,
      $$ProfileRowsTableAnnotationComposer,
      $$ProfileRowsTableCreateCompanionBuilder,
      $$ProfileRowsTableUpdateCompanionBuilder,
      (
        ProfileRow,
        BaseReferences<_$AppDatabase, $ProfileRowsTable, ProfileRow>,
      ),
      ProfileRow,
      PrefetchHooks Function()
    >;
typedef $$EmergencyContactRowsTableCreateCompanionBuilder =
    EmergencyContactRowsCompanion Function({
      Value<int> id,
      required String name,
      required String phone,
      Value<String?> relation,
      Value<bool> autoSmsEnabled,
      Value<int> sortOrder,
    });
typedef $$EmergencyContactRowsTableUpdateCompanionBuilder =
    EmergencyContactRowsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> phone,
      Value<String?> relation,
      Value<bool> autoSmsEnabled,
      Value<int> sortOrder,
    });

class $$EmergencyContactRowsTableFilterComposer
    extends Composer<_$AppDatabase, $EmergencyContactRowsTable> {
  $$EmergencyContactRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relation => $composableBuilder(
    column: $table.relation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoSmsEnabled => $composableBuilder(
    column: $table.autoSmsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EmergencyContactRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $EmergencyContactRowsTable> {
  $$EmergencyContactRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relation => $composableBuilder(
    column: $table.relation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoSmsEnabled => $composableBuilder(
    column: $table.autoSmsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EmergencyContactRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmergencyContactRowsTable> {
  $$EmergencyContactRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get relation =>
      $composableBuilder(column: $table.relation, builder: (column) => column);

  GeneratedColumn<bool> get autoSmsEnabled => $composableBuilder(
    column: $table.autoSmsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$EmergencyContactRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmergencyContactRowsTable,
          EmergencyContactRow,
          $$EmergencyContactRowsTableFilterComposer,
          $$EmergencyContactRowsTableOrderingComposer,
          $$EmergencyContactRowsTableAnnotationComposer,
          $$EmergencyContactRowsTableCreateCompanionBuilder,
          $$EmergencyContactRowsTableUpdateCompanionBuilder,
          (
            EmergencyContactRow,
            BaseReferences<
              _$AppDatabase,
              $EmergencyContactRowsTable,
              EmergencyContactRow
            >,
          ),
          EmergencyContactRow,
          PrefetchHooks Function()
        > {
  $$EmergencyContactRowsTableTableManager(
    _$AppDatabase db,
    $EmergencyContactRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmergencyContactRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmergencyContactRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EmergencyContactRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String?> relation = const Value.absent(),
                Value<bool> autoSmsEnabled = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => EmergencyContactRowsCompanion(
                id: id,
                name: name,
                phone: phone,
                relation: relation,
                autoSmsEnabled: autoSmsEnabled,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String phone,
                Value<String?> relation = const Value.absent(),
                Value<bool> autoSmsEnabled = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => EmergencyContactRowsCompanion.insert(
                id: id,
                name: name,
                phone: phone,
                relation: relation,
                autoSmsEnabled: autoSmsEnabled,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EmergencyContactRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmergencyContactRowsTable,
      EmergencyContactRow,
      $$EmergencyContactRowsTableFilterComposer,
      $$EmergencyContactRowsTableOrderingComposer,
      $$EmergencyContactRowsTableAnnotationComposer,
      $$EmergencyContactRowsTableCreateCompanionBuilder,
      $$EmergencyContactRowsTableUpdateCompanionBuilder,
      (
        EmergencyContactRow,
        BaseReferences<
          _$AppDatabase,
          $EmergencyContactRowsTable,
          EmergencyContactRow
        >,
      ),
      EmergencyContactRow,
      PrefetchHooks Function()
    >;
typedef $$FoodItemRowsTableCreateCompanionBuilder =
    FoodItemRowsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> category,
      Value<double?> kcal,
      Value<double?> proteinG,
      Value<double?> sodiumMg,
      Value<double?> potassiumMg,
      Value<double?> phosphorusMg,
      Value<double?> fluidMl,
      Value<double?> portionG,
      Value<String?> portionLabel,
      Value<String> source,
      Value<String?> sourceNote,
      Value<String?> barcode,
      Value<bool> isApproximate,
    });
typedef $$FoodItemRowsTableUpdateCompanionBuilder =
    FoodItemRowsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> category,
      Value<double?> kcal,
      Value<double?> proteinG,
      Value<double?> sodiumMg,
      Value<double?> potassiumMg,
      Value<double?> phosphorusMg,
      Value<double?> fluidMl,
      Value<double?> portionG,
      Value<String?> portionLabel,
      Value<String> source,
      Value<String?> sourceNote,
      Value<String?> barcode,
      Value<bool> isApproximate,
    });

class $$FoodItemRowsTableFilterComposer
    extends Composer<_$AppDatabase, $FoodItemRowsTable> {
  $$FoodItemRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sodiumMg => $composableBuilder(
    column: $table.sodiumMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get potassiumMg => $composableBuilder(
    column: $table.potassiumMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get phosphorusMg => $composableBuilder(
    column: $table.phosphorusMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fluidMl => $composableBuilder(
    column: $table.fluidMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get portionG => $composableBuilder(
    column: $table.portionG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get portionLabel => $composableBuilder(
    column: $table.portionLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceNote => $composableBuilder(
    column: $table.sourceNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isApproximate => $composableBuilder(
    column: $table.isApproximate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodItemRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodItemRowsTable> {
  $$FoodItemRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sodiumMg => $composableBuilder(
    column: $table.sodiumMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get potassiumMg => $composableBuilder(
    column: $table.potassiumMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get phosphorusMg => $composableBuilder(
    column: $table.phosphorusMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fluidMl => $composableBuilder(
    column: $table.fluidMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get portionG => $composableBuilder(
    column: $table.portionG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get portionLabel => $composableBuilder(
    column: $table.portionLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceNote => $composableBuilder(
    column: $table.sourceNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isApproximate => $composableBuilder(
    column: $table.isApproximate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodItemRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodItemRowsTable> {
  $$FoodItemRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get sodiumMg =>
      $composableBuilder(column: $table.sodiumMg, builder: (column) => column);

  GeneratedColumn<double> get potassiumMg => $composableBuilder(
    column: $table.potassiumMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get phosphorusMg => $composableBuilder(
    column: $table.phosphorusMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fluidMl =>
      $composableBuilder(column: $table.fluidMl, builder: (column) => column);

  GeneratedColumn<double> get portionG =>
      $composableBuilder(column: $table.portionG, builder: (column) => column);

  GeneratedColumn<String> get portionLabel => $composableBuilder(
    column: $table.portionLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceNote => $composableBuilder(
    column: $table.sourceNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<bool> get isApproximate => $composableBuilder(
    column: $table.isApproximate,
    builder: (column) => column,
  );
}

class $$FoodItemRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodItemRowsTable,
          FoodItemRow,
          $$FoodItemRowsTableFilterComposer,
          $$FoodItemRowsTableOrderingComposer,
          $$FoodItemRowsTableAnnotationComposer,
          $$FoodItemRowsTableCreateCompanionBuilder,
          $$FoodItemRowsTableUpdateCompanionBuilder,
          (
            FoodItemRow,
            BaseReferences<_$AppDatabase, $FoodItemRowsTable, FoodItemRow>,
          ),
          FoodItemRow,
          PrefetchHooks Function()
        > {
  $$FoodItemRowsTableTableManager(_$AppDatabase db, $FoodItemRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodItemRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodItemRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodItemRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<double?> kcal = const Value.absent(),
                Value<double?> proteinG = const Value.absent(),
                Value<double?> sodiumMg = const Value.absent(),
                Value<double?> potassiumMg = const Value.absent(),
                Value<double?> phosphorusMg = const Value.absent(),
                Value<double?> fluidMl = const Value.absent(),
                Value<double?> portionG = const Value.absent(),
                Value<String?> portionLabel = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> sourceNote = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<bool> isApproximate = const Value.absent(),
              }) => FoodItemRowsCompanion(
                id: id,
                name: name,
                category: category,
                kcal: kcal,
                proteinG: proteinG,
                sodiumMg: sodiumMg,
                potassiumMg: potassiumMg,
                phosphorusMg: phosphorusMg,
                fluidMl: fluidMl,
                portionG: portionG,
                portionLabel: portionLabel,
                source: source,
                sourceNote: sourceNote,
                barcode: barcode,
                isApproximate: isApproximate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> category = const Value.absent(),
                Value<double?> kcal = const Value.absent(),
                Value<double?> proteinG = const Value.absent(),
                Value<double?> sodiumMg = const Value.absent(),
                Value<double?> potassiumMg = const Value.absent(),
                Value<double?> phosphorusMg = const Value.absent(),
                Value<double?> fluidMl = const Value.absent(),
                Value<double?> portionG = const Value.absent(),
                Value<String?> portionLabel = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> sourceNote = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<bool> isApproximate = const Value.absent(),
              }) => FoodItemRowsCompanion.insert(
                id: id,
                name: name,
                category: category,
                kcal: kcal,
                proteinG: proteinG,
                sodiumMg: sodiumMg,
                potassiumMg: potassiumMg,
                phosphorusMg: phosphorusMg,
                fluidMl: fluidMl,
                portionG: portionG,
                portionLabel: portionLabel,
                source: source,
                sourceNote: sourceNote,
                barcode: barcode,
                isApproximate: isApproximate,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodItemRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodItemRowsTable,
      FoodItemRow,
      $$FoodItemRowsTableFilterComposer,
      $$FoodItemRowsTableOrderingComposer,
      $$FoodItemRowsTableAnnotationComposer,
      $$FoodItemRowsTableCreateCompanionBuilder,
      $$FoodItemRowsTableUpdateCompanionBuilder,
      (
        FoodItemRow,
        BaseReferences<_$AppDatabase, $FoodItemRowsTable, FoodItemRow>,
      ),
      FoodItemRow,
      PrefetchHooks Function()
    >;
typedef $$FoodLogRowsTableCreateCompanionBuilder =
    FoodLogRowsCompanion Function({
      Value<int> id,
      Value<int?> foodItemId,
      required String label,
      required double grams,
      Value<double?> kcal,
      Value<double?> proteinG,
      Value<double?> sodiumMg,
      Value<double?> potassiumMg,
      Value<double?> phosphorusMg,
      Value<double?> fluidMl,
      Value<String?> mealType,
      Value<String> origin,
      Value<String?> confidence,
      Value<String?> note,
      required DateTime consumedAt,
    });
typedef $$FoodLogRowsTableUpdateCompanionBuilder =
    FoodLogRowsCompanion Function({
      Value<int> id,
      Value<int?> foodItemId,
      Value<String> label,
      Value<double> grams,
      Value<double?> kcal,
      Value<double?> proteinG,
      Value<double?> sodiumMg,
      Value<double?> potassiumMg,
      Value<double?> phosphorusMg,
      Value<double?> fluidMl,
      Value<String?> mealType,
      Value<String> origin,
      Value<String?> confidence,
      Value<String?> note,
      Value<DateTime> consumedAt,
    });

class $$FoodLogRowsTableFilterComposer
    extends Composer<_$AppDatabase, $FoodLogRowsTable> {
  $$FoodLogRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get foodItemId => $composableBuilder(
    column: $table.foodItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sodiumMg => $composableBuilder(
    column: $table.sodiumMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get potassiumMg => $composableBuilder(
    column: $table.potassiumMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get phosphorusMg => $composableBuilder(
    column: $table.phosphorusMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fluidMl => $composableBuilder(
    column: $table.fluidMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodLogRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodLogRowsTable> {
  $$FoodLogRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get foodItemId => $composableBuilder(
    column: $table.foodItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sodiumMg => $composableBuilder(
    column: $table.sodiumMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get potassiumMg => $composableBuilder(
    column: $table.potassiumMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get phosphorusMg => $composableBuilder(
    column: $table.phosphorusMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fluidMl => $composableBuilder(
    column: $table.fluidMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodLogRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodLogRowsTable> {
  $$FoodLogRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get foodItemId => $composableBuilder(
    column: $table.foodItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get sodiumMg =>
      $composableBuilder(column: $table.sodiumMg, builder: (column) => column);

  GeneratedColumn<double> get potassiumMg => $composableBuilder(
    column: $table.potassiumMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get phosphorusMg => $composableBuilder(
    column: $table.phosphorusMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fluidMl =>
      $composableBuilder(column: $table.fluidMl, builder: (column) => column);

  GeneratedColumn<String> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => column,
  );
}

class $$FoodLogRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodLogRowsTable,
          FoodLogRow,
          $$FoodLogRowsTableFilterComposer,
          $$FoodLogRowsTableOrderingComposer,
          $$FoodLogRowsTableAnnotationComposer,
          $$FoodLogRowsTableCreateCompanionBuilder,
          $$FoodLogRowsTableUpdateCompanionBuilder,
          (
            FoodLogRow,
            BaseReferences<_$AppDatabase, $FoodLogRowsTable, FoodLogRow>,
          ),
          FoodLogRow,
          PrefetchHooks Function()
        > {
  $$FoodLogRowsTableTableManager(_$AppDatabase db, $FoodLogRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodLogRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodLogRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodLogRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> foodItemId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<double?> kcal = const Value.absent(),
                Value<double?> proteinG = const Value.absent(),
                Value<double?> sodiumMg = const Value.absent(),
                Value<double?> potassiumMg = const Value.absent(),
                Value<double?> phosphorusMg = const Value.absent(),
                Value<double?> fluidMl = const Value.absent(),
                Value<String?> mealType = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String?> confidence = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> consumedAt = const Value.absent(),
              }) => FoodLogRowsCompanion(
                id: id,
                foodItemId: foodItemId,
                label: label,
                grams: grams,
                kcal: kcal,
                proteinG: proteinG,
                sodiumMg: sodiumMg,
                potassiumMg: potassiumMg,
                phosphorusMg: phosphorusMg,
                fluidMl: fluidMl,
                mealType: mealType,
                origin: origin,
                confidence: confidence,
                note: note,
                consumedAt: consumedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> foodItemId = const Value.absent(),
                required String label,
                required double grams,
                Value<double?> kcal = const Value.absent(),
                Value<double?> proteinG = const Value.absent(),
                Value<double?> sodiumMg = const Value.absent(),
                Value<double?> potassiumMg = const Value.absent(),
                Value<double?> phosphorusMg = const Value.absent(),
                Value<double?> fluidMl = const Value.absent(),
                Value<String?> mealType = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String?> confidence = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime consumedAt,
              }) => FoodLogRowsCompanion.insert(
                id: id,
                foodItemId: foodItemId,
                label: label,
                grams: grams,
                kcal: kcal,
                proteinG: proteinG,
                sodiumMg: sodiumMg,
                potassiumMg: potassiumMg,
                phosphorusMg: phosphorusMg,
                fluidMl: fluidMl,
                mealType: mealType,
                origin: origin,
                confidence: confidence,
                note: note,
                consumedAt: consumedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodLogRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodLogRowsTable,
      FoodLogRow,
      $$FoodLogRowsTableFilterComposer,
      $$FoodLogRowsTableOrderingComposer,
      $$FoodLogRowsTableAnnotationComposer,
      $$FoodLogRowsTableCreateCompanionBuilder,
      $$FoodLogRowsTableUpdateCompanionBuilder,
      (
        FoodLogRow,
        BaseReferences<_$AppDatabase, $FoodLogRowsTable, FoodLogRow>,
      ),
      FoodLogRow,
      PrefetchHooks Function()
    >;
typedef $$FluidLogRowsTableCreateCompanionBuilder =
    FluidLogRowsCompanion Function({
      Value<int> id,
      required String label,
      required int ml,
      Value<String> kind,
      required DateTime consumedAt,
    });
typedef $$FluidLogRowsTableUpdateCompanionBuilder =
    FluidLogRowsCompanion Function({
      Value<int> id,
      Value<String> label,
      Value<int> ml,
      Value<String> kind,
      Value<DateTime> consumedAt,
    });

class $$FluidLogRowsTableFilterComposer
    extends Composer<_$AppDatabase, $FluidLogRowsTable> {
  $$FluidLogRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ml => $composableBuilder(
    column: $table.ml,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FluidLogRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $FluidLogRowsTable> {
  $$FluidLogRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ml => $composableBuilder(
    column: $table.ml,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FluidLogRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FluidLogRowsTable> {
  $$FluidLogRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get ml =>
      $composableBuilder(column: $table.ml, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => column,
  );
}

class $$FluidLogRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FluidLogRowsTable,
          FluidLogRow,
          $$FluidLogRowsTableFilterComposer,
          $$FluidLogRowsTableOrderingComposer,
          $$FluidLogRowsTableAnnotationComposer,
          $$FluidLogRowsTableCreateCompanionBuilder,
          $$FluidLogRowsTableUpdateCompanionBuilder,
          (
            FluidLogRow,
            BaseReferences<_$AppDatabase, $FluidLogRowsTable, FluidLogRow>,
          ),
          FluidLogRow,
          PrefetchHooks Function()
        > {
  $$FluidLogRowsTableTableManager(_$AppDatabase db, $FluidLogRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FluidLogRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FluidLogRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FluidLogRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> ml = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<DateTime> consumedAt = const Value.absent(),
              }) => FluidLogRowsCompanion(
                id: id,
                label: label,
                ml: ml,
                kind: kind,
                consumedAt: consumedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String label,
                required int ml,
                Value<String> kind = const Value.absent(),
                required DateTime consumedAt,
              }) => FluidLogRowsCompanion.insert(
                id: id,
                label: label,
                ml: ml,
                kind: kind,
                consumedAt: consumedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FluidLogRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FluidLogRowsTable,
      FluidLogRow,
      $$FluidLogRowsTableFilterComposer,
      $$FluidLogRowsTableOrderingComposer,
      $$FluidLogRowsTableAnnotationComposer,
      $$FluidLogRowsTableCreateCompanionBuilder,
      $$FluidLogRowsTableUpdateCompanionBuilder,
      (
        FluidLogRow,
        BaseReferences<_$AppDatabase, $FluidLogRowsTable, FluidLogRow>,
      ),
      FluidLogRow,
      PrefetchHooks Function()
    >;
typedef $$LabResultRowsTableCreateCompanionBuilder =
    LabResultRowsCompanion Function({
      Value<int> id,
      required String analyte,
      required String analyteLabel,
      required double value,
      required String unit,
      Value<double?> refMin,
      Value<double?> refMax,
      Value<String?> labName,
      Value<String> origin,
      Value<bool> confirmedByUser,
      Value<String?> note,
      required DateTime takenAt,
    });
typedef $$LabResultRowsTableUpdateCompanionBuilder =
    LabResultRowsCompanion Function({
      Value<int> id,
      Value<String> analyte,
      Value<String> analyteLabel,
      Value<double> value,
      Value<String> unit,
      Value<double?> refMin,
      Value<double?> refMax,
      Value<String?> labName,
      Value<String> origin,
      Value<bool> confirmedByUser,
      Value<String?> note,
      Value<DateTime> takenAt,
    });

class $$LabResultRowsTableFilterComposer
    extends Composer<_$AppDatabase, $LabResultRowsTable> {
  $$LabResultRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get analyte => $composableBuilder(
    column: $table.analyte,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get analyteLabel => $composableBuilder(
    column: $table.analyteLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get refMin => $composableBuilder(
    column: $table.refMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get refMax => $composableBuilder(
    column: $table.refMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labName => $composableBuilder(
    column: $table.labName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get confirmedByUser => $composableBuilder(
    column: $table.confirmedByUser,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LabResultRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $LabResultRowsTable> {
  $$LabResultRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get analyte => $composableBuilder(
    column: $table.analyte,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get analyteLabel => $composableBuilder(
    column: $table.analyteLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get refMin => $composableBuilder(
    column: $table.refMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get refMax => $composableBuilder(
    column: $table.refMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labName => $composableBuilder(
    column: $table.labName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get confirmedByUser => $composableBuilder(
    column: $table.confirmedByUser,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LabResultRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LabResultRowsTable> {
  $$LabResultRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get analyte =>
      $composableBuilder(column: $table.analyte, builder: (column) => column);

  GeneratedColumn<String> get analyteLabel => $composableBuilder(
    column: $table.analyteLabel,
    builder: (column) => column,
  );

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get refMin =>
      $composableBuilder(column: $table.refMin, builder: (column) => column);

  GeneratedColumn<double> get refMax =>
      $composableBuilder(column: $table.refMax, builder: (column) => column);

  GeneratedColumn<String> get labName =>
      $composableBuilder(column: $table.labName, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<bool> get confirmedByUser => $composableBuilder(
    column: $table.confirmedByUser,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);
}

class $$LabResultRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LabResultRowsTable,
          LabResultRow,
          $$LabResultRowsTableFilterComposer,
          $$LabResultRowsTableOrderingComposer,
          $$LabResultRowsTableAnnotationComposer,
          $$LabResultRowsTableCreateCompanionBuilder,
          $$LabResultRowsTableUpdateCompanionBuilder,
          (
            LabResultRow,
            BaseReferences<_$AppDatabase, $LabResultRowsTable, LabResultRow>,
          ),
          LabResultRow,
          PrefetchHooks Function()
        > {
  $$LabResultRowsTableTableManager(_$AppDatabase db, $LabResultRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LabResultRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LabResultRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LabResultRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> analyte = const Value.absent(),
                Value<String> analyteLabel = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double?> refMin = const Value.absent(),
                Value<double?> refMax = const Value.absent(),
                Value<String?> labName = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<bool> confirmedByUser = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> takenAt = const Value.absent(),
              }) => LabResultRowsCompanion(
                id: id,
                analyte: analyte,
                analyteLabel: analyteLabel,
                value: value,
                unit: unit,
                refMin: refMin,
                refMax: refMax,
                labName: labName,
                origin: origin,
                confirmedByUser: confirmedByUser,
                note: note,
                takenAt: takenAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String analyte,
                required String analyteLabel,
                required double value,
                required String unit,
                Value<double?> refMin = const Value.absent(),
                Value<double?> refMax = const Value.absent(),
                Value<String?> labName = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<bool> confirmedByUser = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime takenAt,
              }) => LabResultRowsCompanion.insert(
                id: id,
                analyte: analyte,
                analyteLabel: analyteLabel,
                value: value,
                unit: unit,
                refMin: refMin,
                refMax: refMax,
                labName: labName,
                origin: origin,
                confirmedByUser: confirmedByUser,
                note: note,
                takenAt: takenAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LabResultRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LabResultRowsTable,
      LabResultRow,
      $$LabResultRowsTableFilterComposer,
      $$LabResultRowsTableOrderingComposer,
      $$LabResultRowsTableAnnotationComposer,
      $$LabResultRowsTableCreateCompanionBuilder,
      $$LabResultRowsTableUpdateCompanionBuilder,
      (
        LabResultRow,
        BaseReferences<_$AppDatabase, $LabResultRowsTable, LabResultRow>,
      ),
      LabResultRow,
      PrefetchHooks Function()
    >;
typedef $$AppointmentRowsTableCreateCompanionBuilder =
    AppointmentRowsCompanion Function({
      Value<int> id,
      required String title,
      required String kind,
      Value<String?> location,
      Value<String?> note,
      required DateTime startsAt,
      Value<int?> durationMinutes,
      Value<bool> reminderEnabled,
      Value<int> reminderMinutesBefore,
      Value<bool> completed,
    });
typedef $$AppointmentRowsTableUpdateCompanionBuilder =
    AppointmentRowsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> kind,
      Value<String?> location,
      Value<String?> note,
      Value<DateTime> startsAt,
      Value<int?> durationMinutes,
      Value<bool> reminderEnabled,
      Value<int> reminderMinutesBefore,
      Value<bool> completed,
    });

class $$AppointmentRowsTableFilterComposer
    extends Composer<_$AppDatabase, $AppointmentRowsTable> {
  $$AppointmentRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinutesBefore => $composableBuilder(
    column: $table.reminderMinutesBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppointmentRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppointmentRowsTable> {
  $$AppointmentRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinutesBefore => $composableBuilder(
    column: $table.reminderMinutesBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppointmentRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppointmentRowsTable> {
  $$AppointmentRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get startsAt =>
      $composableBuilder(column: $table.startsAt, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderMinutesBefore => $composableBuilder(
    column: $table.reminderMinutesBefore,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);
}

class $$AppointmentRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppointmentRowsTable,
          AppointmentRow,
          $$AppointmentRowsTableFilterComposer,
          $$AppointmentRowsTableOrderingComposer,
          $$AppointmentRowsTableAnnotationComposer,
          $$AppointmentRowsTableCreateCompanionBuilder,
          $$AppointmentRowsTableUpdateCompanionBuilder,
          (
            AppointmentRow,
            BaseReferences<
              _$AppDatabase,
              $AppointmentRowsTable,
              AppointmentRow
            >,
          ),
          AppointmentRow,
          PrefetchHooks Function()
        > {
  $$AppointmentRowsTableTableManager(
    _$AppDatabase db,
    $AppointmentRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppointmentRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppointmentRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppointmentRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> startsAt = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<int> reminderMinutesBefore = const Value.absent(),
                Value<bool> completed = const Value.absent(),
              }) => AppointmentRowsCompanion(
                id: id,
                title: title,
                kind: kind,
                location: location,
                note: note,
                startsAt: startsAt,
                durationMinutes: durationMinutes,
                reminderEnabled: reminderEnabled,
                reminderMinutesBefore: reminderMinutesBefore,
                completed: completed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String kind,
                Value<String?> location = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime startsAt,
                Value<int?> durationMinutes = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<int> reminderMinutesBefore = const Value.absent(),
                Value<bool> completed = const Value.absent(),
              }) => AppointmentRowsCompanion.insert(
                id: id,
                title: title,
                kind: kind,
                location: location,
                note: note,
                startsAt: startsAt,
                durationMinutes: durationMinutes,
                reminderEnabled: reminderEnabled,
                reminderMinutesBefore: reminderMinutesBefore,
                completed: completed,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppointmentRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppointmentRowsTable,
      AppointmentRow,
      $$AppointmentRowsTableFilterComposer,
      $$AppointmentRowsTableOrderingComposer,
      $$AppointmentRowsTableAnnotationComposer,
      $$AppointmentRowsTableCreateCompanionBuilder,
      $$AppointmentRowsTableUpdateCompanionBuilder,
      (
        AppointmentRow,
        BaseReferences<_$AppDatabase, $AppointmentRowsTable, AppointmentRow>,
      ),
      AppointmentRow,
      PrefetchHooks Function()
    >;
typedef $$MedicationRowsTableCreateCompanionBuilder =
    MedicationRowsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> dose,
      Value<String?> form,
      required String times,
      Value<String?> weekdays,
      Value<int?> stockCount,
      Value<int> stockWarnAt,
      Value<String?> note,
      Value<bool> active,
      Value<String?> riskAcknowledged,
      Value<DateTime> createdAt,
    });
typedef $$MedicationRowsTableUpdateCompanionBuilder =
    MedicationRowsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> dose,
      Value<String?> form,
      Value<String> times,
      Value<String?> weekdays,
      Value<int?> stockCount,
      Value<int> stockWarnAt,
      Value<String?> note,
      Value<bool> active,
      Value<String?> riskAcknowledged,
      Value<DateTime> createdAt,
    });

class $$MedicationRowsTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationRowsTable> {
  $$MedicationRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dose => $composableBuilder(
    column: $table.dose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get form => $composableBuilder(
    column: $table.form,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get times => $composableBuilder(
    column: $table.times,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weekdays => $composableBuilder(
    column: $table.weekdays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stockCount => $composableBuilder(
    column: $table.stockCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stockWarnAt => $composableBuilder(
    column: $table.stockWarnAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get riskAcknowledged => $composableBuilder(
    column: $table.riskAcknowledged,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MedicationRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationRowsTable> {
  $$MedicationRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dose => $composableBuilder(
    column: $table.dose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get form => $composableBuilder(
    column: $table.form,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get times => $composableBuilder(
    column: $table.times,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weekdays => $composableBuilder(
    column: $table.weekdays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stockCount => $composableBuilder(
    column: $table.stockCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stockWarnAt => $composableBuilder(
    column: $table.stockWarnAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get riskAcknowledged => $composableBuilder(
    column: $table.riskAcknowledged,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicationRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationRowsTable> {
  $$MedicationRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get dose =>
      $composableBuilder(column: $table.dose, builder: (column) => column);

  GeneratedColumn<String> get form =>
      $composableBuilder(column: $table.form, builder: (column) => column);

  GeneratedColumn<String> get times =>
      $composableBuilder(column: $table.times, builder: (column) => column);

  GeneratedColumn<String> get weekdays =>
      $composableBuilder(column: $table.weekdays, builder: (column) => column);

  GeneratedColumn<int> get stockCount => $composableBuilder(
    column: $table.stockCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stockWarnAt => $composableBuilder(
    column: $table.stockWarnAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<String> get riskAcknowledged => $composableBuilder(
    column: $table.riskAcknowledged,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MedicationRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationRowsTable,
          MedicationRow,
          $$MedicationRowsTableFilterComposer,
          $$MedicationRowsTableOrderingComposer,
          $$MedicationRowsTableAnnotationComposer,
          $$MedicationRowsTableCreateCompanionBuilder,
          $$MedicationRowsTableUpdateCompanionBuilder,
          (
            MedicationRow,
            BaseReferences<_$AppDatabase, $MedicationRowsTable, MedicationRow>,
          ),
          MedicationRow,
          PrefetchHooks Function()
        > {
  $$MedicationRowsTableTableManager(
    _$AppDatabase db,
    $MedicationRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicationRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> dose = const Value.absent(),
                Value<String?> form = const Value.absent(),
                Value<String> times = const Value.absent(),
                Value<String?> weekdays = const Value.absent(),
                Value<int?> stockCount = const Value.absent(),
                Value<int> stockWarnAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<String?> riskAcknowledged = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MedicationRowsCompanion(
                id: id,
                name: name,
                dose: dose,
                form: form,
                times: times,
                weekdays: weekdays,
                stockCount: stockCount,
                stockWarnAt: stockWarnAt,
                note: note,
                active: active,
                riskAcknowledged: riskAcknowledged,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> dose = const Value.absent(),
                Value<String?> form = const Value.absent(),
                required String times,
                Value<String?> weekdays = const Value.absent(),
                Value<int?> stockCount = const Value.absent(),
                Value<int> stockWarnAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<String?> riskAcknowledged = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MedicationRowsCompanion.insert(
                id: id,
                name: name,
                dose: dose,
                form: form,
                times: times,
                weekdays: weekdays,
                stockCount: stockCount,
                stockWarnAt: stockWarnAt,
                note: note,
                active: active,
                riskAcknowledged: riskAcknowledged,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MedicationRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationRowsTable,
      MedicationRow,
      $$MedicationRowsTableFilterComposer,
      $$MedicationRowsTableOrderingComposer,
      $$MedicationRowsTableAnnotationComposer,
      $$MedicationRowsTableCreateCompanionBuilder,
      $$MedicationRowsTableUpdateCompanionBuilder,
      (
        MedicationRow,
        BaseReferences<_$AppDatabase, $MedicationRowsTable, MedicationRow>,
      ),
      MedicationRow,
      PrefetchHooks Function()
    >;
typedef $$MedicationDoseRowsTableCreateCompanionBuilder =
    MedicationDoseRowsCompanion Function({
      Value<int> id,
      required int medicationId,
      required DateTime scheduledAt,
      Value<DateTime?> takenAt,
      Value<String> status,
      Value<DateTime?> snoozedUntil,
    });
typedef $$MedicationDoseRowsTableUpdateCompanionBuilder =
    MedicationDoseRowsCompanion Function({
      Value<int> id,
      Value<int> medicationId,
      Value<DateTime> scheduledAt,
      Value<DateTime?> takenAt,
      Value<String> status,
      Value<DateTime?> snoozedUntil,
    });

class $$MedicationDoseRowsTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationDoseRowsTable> {
  $$MedicationDoseRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MedicationDoseRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationDoseRowsTable> {
  $$MedicationDoseRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicationDoseRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationDoseRowsTable> {
  $$MedicationDoseRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => column,
  );
}

class $$MedicationDoseRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationDoseRowsTable,
          MedicationDoseRow,
          $$MedicationDoseRowsTableFilterComposer,
          $$MedicationDoseRowsTableOrderingComposer,
          $$MedicationDoseRowsTableAnnotationComposer,
          $$MedicationDoseRowsTableCreateCompanionBuilder,
          $$MedicationDoseRowsTableUpdateCompanionBuilder,
          (
            MedicationDoseRow,
            BaseReferences<
              _$AppDatabase,
              $MedicationDoseRowsTable,
              MedicationDoseRow
            >,
          ),
          MedicationDoseRow,
          PrefetchHooks Function()
        > {
  $$MedicationDoseRowsTableTableManager(
    _$AppDatabase db,
    $MedicationDoseRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationDoseRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationDoseRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicationDoseRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> medicationId = const Value.absent(),
                Value<DateTime> scheduledAt = const Value.absent(),
                Value<DateTime?> takenAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> snoozedUntil = const Value.absent(),
              }) => MedicationDoseRowsCompanion(
                id: id,
                medicationId: medicationId,
                scheduledAt: scheduledAt,
                takenAt: takenAt,
                status: status,
                snoozedUntil: snoozedUntil,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int medicationId,
                required DateTime scheduledAt,
                Value<DateTime?> takenAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> snoozedUntil = const Value.absent(),
              }) => MedicationDoseRowsCompanion.insert(
                id: id,
                medicationId: medicationId,
                scheduledAt: scheduledAt,
                takenAt: takenAt,
                status: status,
                snoozedUntil: snoozedUntil,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MedicationDoseRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationDoseRowsTable,
      MedicationDoseRow,
      $$MedicationDoseRowsTableFilterComposer,
      $$MedicationDoseRowsTableOrderingComposer,
      $$MedicationDoseRowsTableAnnotationComposer,
      $$MedicationDoseRowsTableCreateCompanionBuilder,
      $$MedicationDoseRowsTableUpdateCompanionBuilder,
      (
        MedicationDoseRow,
        BaseReferences<
          _$AppDatabase,
          $MedicationDoseRowsTable,
          MedicationDoseRow
        >,
      ),
      MedicationDoseRow,
      PrefetchHooks Function()
    >;
typedef $$VitalRowsTableCreateCompanionBuilder =
    VitalRowsCompanion Function({
      Value<int> id,
      Value<double?> weightKg,
      Value<int?> edemaLevel,
      Value<int?> urineMl,
      Value<int?> systolic,
      Value<int?> diastolic,
      Value<int?> heartRate,
      Value<double?> temperatureC,
      Value<int?> spo2,
      Value<double?> glucoseMgDl,
      Value<String?> note,
      Value<String?> dialysisPhase,
      required DateTime measuredAt,
    });
typedef $$VitalRowsTableUpdateCompanionBuilder =
    VitalRowsCompanion Function({
      Value<int> id,
      Value<double?> weightKg,
      Value<int?> edemaLevel,
      Value<int?> urineMl,
      Value<int?> systolic,
      Value<int?> diastolic,
      Value<int?> heartRate,
      Value<double?> temperatureC,
      Value<int?> spo2,
      Value<double?> glucoseMgDl,
      Value<String?> note,
      Value<String?> dialysisPhase,
      Value<DateTime> measuredAt,
    });

class $$VitalRowsTableFilterComposer
    extends Composer<_$AppDatabase, $VitalRowsTable> {
  $$VitalRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get edemaLevel => $composableBuilder(
    column: $table.edemaLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get urineMl => $composableBuilder(
    column: $table.urineMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get systolic => $composableBuilder(
    column: $table.systolic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get diastolic => $composableBuilder(
    column: $table.diastolic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heartRate => $composableBuilder(
    column: $table.heartRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get spo2 => $composableBuilder(
    column: $table.spo2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get glucoseMgDl => $composableBuilder(
    column: $table.glucoseMgDl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dialysisPhase => $composableBuilder(
    column: $table.dialysisPhase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VitalRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $VitalRowsTable> {
  $$VitalRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get edemaLevel => $composableBuilder(
    column: $table.edemaLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get urineMl => $composableBuilder(
    column: $table.urineMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get systolic => $composableBuilder(
    column: $table.systolic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get diastolic => $composableBuilder(
    column: $table.diastolic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heartRate => $composableBuilder(
    column: $table.heartRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get spo2 => $composableBuilder(
    column: $table.spo2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get glucoseMgDl => $composableBuilder(
    column: $table.glucoseMgDl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dialysisPhase => $composableBuilder(
    column: $table.dialysisPhase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VitalRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VitalRowsTable> {
  $$VitalRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<int> get edemaLevel => $composableBuilder(
    column: $table.edemaLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get urineMl =>
      $composableBuilder(column: $table.urineMl, builder: (column) => column);

  GeneratedColumn<int> get systolic =>
      $composableBuilder(column: $table.systolic, builder: (column) => column);

  GeneratedColumn<int> get diastolic =>
      $composableBuilder(column: $table.diastolic, builder: (column) => column);

  GeneratedColumn<int> get heartRate =>
      $composableBuilder(column: $table.heartRate, builder: (column) => column);

  GeneratedColumn<double> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => column,
  );

  GeneratedColumn<int> get spo2 =>
      $composableBuilder(column: $table.spo2, builder: (column) => column);

  GeneratedColumn<double> get glucoseMgDl => $composableBuilder(
    column: $table.glucoseMgDl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get dialysisPhase => $composableBuilder(
    column: $table.dialysisPhase,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => column,
  );
}

class $$VitalRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VitalRowsTable,
          VitalRow,
          $$VitalRowsTableFilterComposer,
          $$VitalRowsTableOrderingComposer,
          $$VitalRowsTableAnnotationComposer,
          $$VitalRowsTableCreateCompanionBuilder,
          $$VitalRowsTableUpdateCompanionBuilder,
          (VitalRow, BaseReferences<_$AppDatabase, $VitalRowsTable, VitalRow>),
          VitalRow,
          PrefetchHooks Function()
        > {
  $$VitalRowsTableTableManager(_$AppDatabase db, $VitalRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VitalRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VitalRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VitalRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<int?> edemaLevel = const Value.absent(),
                Value<int?> urineMl = const Value.absent(),
                Value<int?> systolic = const Value.absent(),
                Value<int?> diastolic = const Value.absent(),
                Value<int?> heartRate = const Value.absent(),
                Value<double?> temperatureC = const Value.absent(),
                Value<int?> spo2 = const Value.absent(),
                Value<double?> glucoseMgDl = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> dialysisPhase = const Value.absent(),
                Value<DateTime> measuredAt = const Value.absent(),
              }) => VitalRowsCompanion(
                id: id,
                weightKg: weightKg,
                edemaLevel: edemaLevel,
                urineMl: urineMl,
                systolic: systolic,
                diastolic: diastolic,
                heartRate: heartRate,
                temperatureC: temperatureC,
                spo2: spo2,
                glucoseMgDl: glucoseMgDl,
                note: note,
                dialysisPhase: dialysisPhase,
                measuredAt: measuredAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<int?> edemaLevel = const Value.absent(),
                Value<int?> urineMl = const Value.absent(),
                Value<int?> systolic = const Value.absent(),
                Value<int?> diastolic = const Value.absent(),
                Value<int?> heartRate = const Value.absent(),
                Value<double?> temperatureC = const Value.absent(),
                Value<int?> spo2 = const Value.absent(),
                Value<double?> glucoseMgDl = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> dialysisPhase = const Value.absent(),
                required DateTime measuredAt,
              }) => VitalRowsCompanion.insert(
                id: id,
                weightKg: weightKg,
                edemaLevel: edemaLevel,
                urineMl: urineMl,
                systolic: systolic,
                diastolic: diastolic,
                heartRate: heartRate,
                temperatureC: temperatureC,
                spo2: spo2,
                glucoseMgDl: glucoseMgDl,
                note: note,
                dialysisPhase: dialysisPhase,
                measuredAt: measuredAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VitalRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VitalRowsTable,
      VitalRow,
      $$VitalRowsTableFilterComposer,
      $$VitalRowsTableOrderingComposer,
      $$VitalRowsTableAnnotationComposer,
      $$VitalRowsTableCreateCompanionBuilder,
      $$VitalRowsTableUpdateCompanionBuilder,
      (VitalRow, BaseReferences<_$AppDatabase, $VitalRowsTable, VitalRow>),
      VitalRow,
      PrefetchHooks Function()
    >;
typedef $$DietPlanRowsTableCreateCompanionBuilder =
    DietPlanRowsCompanion Function({
      Value<int> id,
      required String title,
      required String content,
      Value<bool> active,
      Value<DateTime> createdAt,
    });
typedef $$DietPlanRowsTableUpdateCompanionBuilder =
    DietPlanRowsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> content,
      Value<bool> active,
      Value<DateTime> createdAt,
    });

class $$DietPlanRowsTableFilterComposer
    extends Composer<_$AppDatabase, $DietPlanRowsTable> {
  $$DietPlanRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DietPlanRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $DietPlanRowsTable> {
  $$DietPlanRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DietPlanRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DietPlanRowsTable> {
  $$DietPlanRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DietPlanRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DietPlanRowsTable,
          DietPlanRow,
          $$DietPlanRowsTableFilterComposer,
          $$DietPlanRowsTableOrderingComposer,
          $$DietPlanRowsTableAnnotationComposer,
          $$DietPlanRowsTableCreateCompanionBuilder,
          $$DietPlanRowsTableUpdateCompanionBuilder,
          (
            DietPlanRow,
            BaseReferences<_$AppDatabase, $DietPlanRowsTable, DietPlanRow>,
          ),
          DietPlanRow,
          PrefetchHooks Function()
        > {
  $$DietPlanRowsTableTableManager(_$AppDatabase db, $DietPlanRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DietPlanRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DietPlanRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DietPlanRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DietPlanRowsCompanion(
                id: id,
                title: title,
                content: content,
                active: active,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String content,
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DietPlanRowsCompanion.insert(
                id: id,
                title: title,
                content: content,
                active: active,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DietPlanRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DietPlanRowsTable,
      DietPlanRow,
      $$DietPlanRowsTableFilterComposer,
      $$DietPlanRowsTableOrderingComposer,
      $$DietPlanRowsTableAnnotationComposer,
      $$DietPlanRowsTableCreateCompanionBuilder,
      $$DietPlanRowsTableUpdateCompanionBuilder,
      (
        DietPlanRow,
        BaseReferences<_$AppDatabase, $DietPlanRowsTable, DietPlanRow>,
      ),
      DietPlanRow,
      PrefetchHooks Function()
    >;
typedef $$DietAdherenceRowsTableCreateCompanionBuilder =
    DietAdherenceRowsCompanion Function({
      Value<int> id,
      required int planId,
      required DateTime day,
      required int percent,
      Value<String?> note,
    });
typedef $$DietAdherenceRowsTableUpdateCompanionBuilder =
    DietAdherenceRowsCompanion Function({
      Value<int> id,
      Value<int> planId,
      Value<DateTime> day,
      Value<int> percent,
      Value<String?> note,
    });

class $$DietAdherenceRowsTableFilterComposer
    extends Composer<_$AppDatabase, $DietAdherenceRowsTable> {
  $$DietAdherenceRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get percent => $composableBuilder(
    column: $table.percent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DietAdherenceRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $DietAdherenceRowsTable> {
  $$DietAdherenceRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get percent => $composableBuilder(
    column: $table.percent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DietAdherenceRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DietAdherenceRowsTable> {
  $$DietAdherenceRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get percent =>
      $composableBuilder(column: $table.percent, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$DietAdherenceRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DietAdherenceRowsTable,
          DietAdherenceRow,
          $$DietAdherenceRowsTableFilterComposer,
          $$DietAdherenceRowsTableOrderingComposer,
          $$DietAdherenceRowsTableAnnotationComposer,
          $$DietAdherenceRowsTableCreateCompanionBuilder,
          $$DietAdherenceRowsTableUpdateCompanionBuilder,
          (
            DietAdherenceRow,
            BaseReferences<
              _$AppDatabase,
              $DietAdherenceRowsTable,
              DietAdherenceRow
            >,
          ),
          DietAdherenceRow,
          PrefetchHooks Function()
        > {
  $$DietAdherenceRowsTableTableManager(
    _$AppDatabase db,
    $DietAdherenceRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DietAdherenceRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DietAdherenceRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DietAdherenceRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> planId = const Value.absent(),
                Value<DateTime> day = const Value.absent(),
                Value<int> percent = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => DietAdherenceRowsCompanion(
                id: id,
                planId: planId,
                day: day,
                percent: percent,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int planId,
                required DateTime day,
                required int percent,
                Value<String?> note = const Value.absent(),
              }) => DietAdherenceRowsCompanion.insert(
                id: id,
                planId: planId,
                day: day,
                percent: percent,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DietAdherenceRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DietAdherenceRowsTable,
      DietAdherenceRow,
      $$DietAdherenceRowsTableFilterComposer,
      $$DietAdherenceRowsTableOrderingComposer,
      $$DietAdherenceRowsTableAnnotationComposer,
      $$DietAdherenceRowsTableCreateCompanionBuilder,
      $$DietAdherenceRowsTableUpdateCompanionBuilder,
      (
        DietAdherenceRow,
        BaseReferences<
          _$AppDatabase,
          $DietAdherenceRowsTable,
          DietAdherenceRow
        >,
      ),
      DietAdherenceRow,
      PrefetchHooks Function()
    >;
typedef $$ChatMessageRowsTableCreateCompanionBuilder =
    ChatMessageRowsCompanion Function({
      Value<int> id,
      required String role,
      required String content,
      Value<String?> imagePath,
      Value<String?> model,
      Value<int?> inputTokens,
      Value<int?> outputTokens,
      Value<DateTime> createdAt,
    });
typedef $$ChatMessageRowsTableUpdateCompanionBuilder =
    ChatMessageRowsCompanion Function({
      Value<int> id,
      Value<String> role,
      Value<String> content,
      Value<String?> imagePath,
      Value<String?> model,
      Value<int?> inputTokens,
      Value<int?> outputTokens,
      Value<DateTime> createdAt,
    });

class $$ChatMessageRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ChatMessageRowsTable> {
  $$ChatMessageRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatMessageRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatMessageRowsTable> {
  $$ChatMessageRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatMessageRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatMessageRowsTable> {
  $$ChatMessageRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ChatMessageRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatMessageRowsTable,
          ChatMessageRow,
          $$ChatMessageRowsTableFilterComposer,
          $$ChatMessageRowsTableOrderingComposer,
          $$ChatMessageRowsTableAnnotationComposer,
          $$ChatMessageRowsTableCreateCompanionBuilder,
          $$ChatMessageRowsTableUpdateCompanionBuilder,
          (
            ChatMessageRow,
            BaseReferences<
              _$AppDatabase,
              $ChatMessageRowsTable,
              ChatMessageRow
            >,
          ),
          ChatMessageRow,
          PrefetchHooks Function()
        > {
  $$ChatMessageRowsTableTableManager(
    _$AppDatabase db,
    $ChatMessageRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatMessageRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatMessageRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatMessageRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<int?> inputTokens = const Value.absent(),
                Value<int?> outputTokens = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ChatMessageRowsCompanion(
                id: id,
                role: role,
                content: content,
                imagePath: imagePath,
                model: model,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String role,
                required String content,
                Value<String?> imagePath = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<int?> inputTokens = const Value.absent(),
                Value<int?> outputTokens = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ChatMessageRowsCompanion.insert(
                id: id,
                role: role,
                content: content,
                imagePath: imagePath,
                model: model,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatMessageRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatMessageRowsTable,
      ChatMessageRow,
      $$ChatMessageRowsTableFilterComposer,
      $$ChatMessageRowsTableOrderingComposer,
      $$ChatMessageRowsTableAnnotationComposer,
      $$ChatMessageRowsTableCreateCompanionBuilder,
      $$ChatMessageRowsTableUpdateCompanionBuilder,
      (
        ChatMessageRow,
        BaseReferences<_$AppDatabase, $ChatMessageRowsTable, ChatMessageRow>,
      ),
      ChatMessageRow,
      PrefetchHooks Function()
    >;
typedef $$TravelPlanRowsTableCreateCompanionBuilder =
    TravelPlanRowsCompanion Function({
      Value<int> id,
      required String destination,
      required DateTime startsAt,
      required int days,
      required String planMarkdown,
      Value<String?> options,
      Value<DateTime> createdAt,
    });
typedef $$TravelPlanRowsTableUpdateCompanionBuilder =
    TravelPlanRowsCompanion Function({
      Value<int> id,
      Value<String> destination,
      Value<DateTime> startsAt,
      Value<int> days,
      Value<String> planMarkdown,
      Value<String?> options,
      Value<DateTime> createdAt,
    });

class $$TravelPlanRowsTableFilterComposer
    extends Composer<_$AppDatabase, $TravelPlanRowsTable> {
  $$TravelPlanRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get days => $composableBuilder(
    column: $table.days,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planMarkdown => $composableBuilder(
    column: $table.planMarkdown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TravelPlanRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $TravelPlanRowsTable> {
  $$TravelPlanRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get days => $composableBuilder(
    column: $table.days,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planMarkdown => $composableBuilder(
    column: $table.planMarkdown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TravelPlanRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TravelPlanRowsTable> {
  $$TravelPlanRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startsAt =>
      $composableBuilder(column: $table.startsAt, builder: (column) => column);

  GeneratedColumn<int> get days =>
      $composableBuilder(column: $table.days, builder: (column) => column);

  GeneratedColumn<String> get planMarkdown => $composableBuilder(
    column: $table.planMarkdown,
    builder: (column) => column,
  );

  GeneratedColumn<String> get options =>
      $composableBuilder(column: $table.options, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TravelPlanRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TravelPlanRowsTable,
          TravelPlanRow,
          $$TravelPlanRowsTableFilterComposer,
          $$TravelPlanRowsTableOrderingComposer,
          $$TravelPlanRowsTableAnnotationComposer,
          $$TravelPlanRowsTableCreateCompanionBuilder,
          $$TravelPlanRowsTableUpdateCompanionBuilder,
          (
            TravelPlanRow,
            BaseReferences<_$AppDatabase, $TravelPlanRowsTable, TravelPlanRow>,
          ),
          TravelPlanRow,
          PrefetchHooks Function()
        > {
  $$TravelPlanRowsTableTableManager(
    _$AppDatabase db,
    $TravelPlanRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TravelPlanRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TravelPlanRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TravelPlanRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> destination = const Value.absent(),
                Value<DateTime> startsAt = const Value.absent(),
                Value<int> days = const Value.absent(),
                Value<String> planMarkdown = const Value.absent(),
                Value<String?> options = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TravelPlanRowsCompanion(
                id: id,
                destination: destination,
                startsAt: startsAt,
                days: days,
                planMarkdown: planMarkdown,
                options: options,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String destination,
                required DateTime startsAt,
                required int days,
                required String planMarkdown,
                Value<String?> options = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TravelPlanRowsCompanion.insert(
                id: id,
                destination: destination,
                startsAt: startsAt,
                days: days,
                planMarkdown: planMarkdown,
                options: options,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TravelPlanRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TravelPlanRowsTable,
      TravelPlanRow,
      $$TravelPlanRowsTableFilterComposer,
      $$TravelPlanRowsTableOrderingComposer,
      $$TravelPlanRowsTableAnnotationComposer,
      $$TravelPlanRowsTableCreateCompanionBuilder,
      $$TravelPlanRowsTableUpdateCompanionBuilder,
      (
        TravelPlanRow,
        BaseReferences<_$AppDatabase, $TravelPlanRowsTable, TravelPlanRow>,
      ),
      TravelPlanRow,
      PrefetchHooks Function()
    >;
typedef $$ArticleRowsTableCreateCompanionBuilder =
    ArticleRowsCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> summary,
      Value<String?> body,
      Value<String?> link,
      required String sourceName,
      required String origin,
      Value<DateTime?> publishedAt,
      Value<DateTime> fetchedAt,
      Value<bool> savedOffline,
    });
typedef $$ArticleRowsTableUpdateCompanionBuilder =
    ArticleRowsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> summary,
      Value<String?> body,
      Value<String?> link,
      Value<String> sourceName,
      Value<String> origin,
      Value<DateTime?> publishedAt,
      Value<DateTime> fetchedAt,
      Value<bool> savedOffline,
    });

class $$ArticleRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ArticleRowsTable> {
  $$ArticleRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get savedOffline => $composableBuilder(
    column: $table.savedOffline,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ArticleRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ArticleRowsTable> {
  $$ArticleRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get savedOffline => $composableBuilder(
    column: $table.savedOffline,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArticleRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArticleRowsTable> {
  $$ArticleRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get link =>
      $composableBuilder(column: $table.link, builder: (column) => column);

  GeneratedColumn<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<bool> get savedOffline => $composableBuilder(
    column: $table.savedOffline,
    builder: (column) => column,
  );
}

class $$ArticleRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArticleRowsTable,
          ArticleRow,
          $$ArticleRowsTableFilterComposer,
          $$ArticleRowsTableOrderingComposer,
          $$ArticleRowsTableAnnotationComposer,
          $$ArticleRowsTableCreateCompanionBuilder,
          $$ArticleRowsTableUpdateCompanionBuilder,
          (
            ArticleRow,
            BaseReferences<_$AppDatabase, $ArticleRowsTable, ArticleRow>,
          ),
          ArticleRow,
          PrefetchHooks Function()
        > {
  $$ArticleRowsTableTableManager(_$AppDatabase db, $ArticleRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArticleRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArticleRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArticleRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<String?> link = const Value.absent(),
                Value<String> sourceName = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<DateTime?> publishedAt = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<bool> savedOffline = const Value.absent(),
              }) => ArticleRowsCompanion(
                id: id,
                title: title,
                summary: summary,
                body: body,
                link: link,
                sourceName: sourceName,
                origin: origin,
                publishedAt: publishedAt,
                fetchedAt: fetchedAt,
                savedOffline: savedOffline,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> summary = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<String?> link = const Value.absent(),
                required String sourceName,
                required String origin,
                Value<DateTime?> publishedAt = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<bool> savedOffline = const Value.absent(),
              }) => ArticleRowsCompanion.insert(
                id: id,
                title: title,
                summary: summary,
                body: body,
                link: link,
                sourceName: sourceName,
                origin: origin,
                publishedAt: publishedAt,
                fetchedAt: fetchedAt,
                savedOffline: savedOffline,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ArticleRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArticleRowsTable,
      ArticleRow,
      $$ArticleRowsTableFilterComposer,
      $$ArticleRowsTableOrderingComposer,
      $$ArticleRowsTableAnnotationComposer,
      $$ArticleRowsTableCreateCompanionBuilder,
      $$ArticleRowsTableUpdateCompanionBuilder,
      (
        ArticleRow,
        BaseReferences<_$AppDatabase, $ArticleRowsTable, ArticleRow>,
      ),
      ArticleRow,
      PrefetchHooks Function()
    >;
typedef $$HttpCacheRowsTableCreateCompanionBuilder =
    HttpCacheRowsCompanion Function({
      required String cacheKey,
      required String body,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$HttpCacheRowsTableUpdateCompanionBuilder =
    HttpCacheRowsCompanion Function({
      Value<String> cacheKey,
      Value<String> body,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$HttpCacheRowsTableFilterComposer
    extends Composer<_$AppDatabase, $HttpCacheRowsTable> {
  $$HttpCacheRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HttpCacheRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $HttpCacheRowsTable> {
  $$HttpCacheRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HttpCacheRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HttpCacheRowsTable> {
  $$HttpCacheRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$HttpCacheRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HttpCacheRowsTable,
          HttpCacheRow,
          $$HttpCacheRowsTableFilterComposer,
          $$HttpCacheRowsTableOrderingComposer,
          $$HttpCacheRowsTableAnnotationComposer,
          $$HttpCacheRowsTableCreateCompanionBuilder,
          $$HttpCacheRowsTableUpdateCompanionBuilder,
          (
            HttpCacheRow,
            BaseReferences<_$AppDatabase, $HttpCacheRowsTable, HttpCacheRow>,
          ),
          HttpCacheRow,
          PrefetchHooks Function()
        > {
  $$HttpCacheRowsTableTableManager(_$AppDatabase db, $HttpCacheRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HttpCacheRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HttpCacheRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HttpCacheRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HttpCacheRowsCompanion(
                cacheKey: cacheKey,
                body: body,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String body,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => HttpCacheRowsCompanion.insert(
                cacheKey: cacheKey,
                body: body,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HttpCacheRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HttpCacheRowsTable,
      HttpCacheRow,
      $$HttpCacheRowsTableFilterComposer,
      $$HttpCacheRowsTableOrderingComposer,
      $$HttpCacheRowsTableAnnotationComposer,
      $$HttpCacheRowsTableCreateCompanionBuilder,
      $$HttpCacheRowsTableUpdateCompanionBuilder,
      (
        HttpCacheRow,
        BaseReferences<_$AppDatabase, $HttpCacheRowsTable, HttpCacheRow>,
      ),
      HttpCacheRow,
      PrefetchHooks Function()
    >;
typedef $$NotificationLogRowsTableCreateCompanionBuilder =
    NotificationLogRowsCompanion Function({
      Value<int> id,
      required String category,
      required String title,
      Value<String?> body,
      Value<DateTime> sentAt,
    });
typedef $$NotificationLogRowsTableUpdateCompanionBuilder =
    NotificationLogRowsCompanion Function({
      Value<int> id,
      Value<String> category,
      Value<String> title,
      Value<String?> body,
      Value<DateTime> sentAt,
    });

class $$NotificationLogRowsTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationLogRowsTable> {
  $$NotificationLogRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationLogRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationLogRowsTable> {
  $$NotificationLogRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationLogRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationLogRowsTable> {
  $$NotificationLogRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);
}

class $$NotificationLogRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationLogRowsTable,
          NotificationLogRow,
          $$NotificationLogRowsTableFilterComposer,
          $$NotificationLogRowsTableOrderingComposer,
          $$NotificationLogRowsTableAnnotationComposer,
          $$NotificationLogRowsTableCreateCompanionBuilder,
          $$NotificationLogRowsTableUpdateCompanionBuilder,
          (
            NotificationLogRow,
            BaseReferences<
              _$AppDatabase,
              $NotificationLogRowsTable,
              NotificationLogRow
            >,
          ),
          NotificationLogRow,
          PrefetchHooks Function()
        > {
  $$NotificationLogRowsTableTableManager(
    _$AppDatabase db,
    $NotificationLogRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationLogRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationLogRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$NotificationLogRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<DateTime> sentAt = const Value.absent(),
              }) => NotificationLogRowsCompanion(
                id: id,
                category: category,
                title: title,
                body: body,
                sentAt: sentAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String category,
                required String title,
                Value<String?> body = const Value.absent(),
                Value<DateTime> sentAt = const Value.absent(),
              }) => NotificationLogRowsCompanion.insert(
                id: id,
                category: category,
                title: title,
                body: body,
                sentAt: sentAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationLogRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationLogRowsTable,
      NotificationLogRow,
      $$NotificationLogRowsTableFilterComposer,
      $$NotificationLogRowsTableOrderingComposer,
      $$NotificationLogRowsTableAnnotationComposer,
      $$NotificationLogRowsTableCreateCompanionBuilder,
      $$NotificationLogRowsTableUpdateCompanionBuilder,
      (
        NotificationLogRow,
        BaseReferences<
          _$AppDatabase,
          $NotificationLogRowsTable,
          NotificationLogRow
        >,
      ),
      NotificationLogRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSettingsRowsTableTableManager get appSettingsRows =>
      $$AppSettingsRowsTableTableManager(_db, _db.appSettingsRows);
  $$ClinicalChangeRowsTableTableManager get clinicalChangeRows =>
      $$ClinicalChangeRowsTableTableManager(_db, _db.clinicalChangeRows);
  $$ProfileRowsTableTableManager get profileRows =>
      $$ProfileRowsTableTableManager(_db, _db.profileRows);
  $$EmergencyContactRowsTableTableManager get emergencyContactRows =>
      $$EmergencyContactRowsTableTableManager(_db, _db.emergencyContactRows);
  $$FoodItemRowsTableTableManager get foodItemRows =>
      $$FoodItemRowsTableTableManager(_db, _db.foodItemRows);
  $$FoodLogRowsTableTableManager get foodLogRows =>
      $$FoodLogRowsTableTableManager(_db, _db.foodLogRows);
  $$FluidLogRowsTableTableManager get fluidLogRows =>
      $$FluidLogRowsTableTableManager(_db, _db.fluidLogRows);
  $$LabResultRowsTableTableManager get labResultRows =>
      $$LabResultRowsTableTableManager(_db, _db.labResultRows);
  $$AppointmentRowsTableTableManager get appointmentRows =>
      $$AppointmentRowsTableTableManager(_db, _db.appointmentRows);
  $$MedicationRowsTableTableManager get medicationRows =>
      $$MedicationRowsTableTableManager(_db, _db.medicationRows);
  $$MedicationDoseRowsTableTableManager get medicationDoseRows =>
      $$MedicationDoseRowsTableTableManager(_db, _db.medicationDoseRows);
  $$VitalRowsTableTableManager get vitalRows =>
      $$VitalRowsTableTableManager(_db, _db.vitalRows);
  $$DietPlanRowsTableTableManager get dietPlanRows =>
      $$DietPlanRowsTableTableManager(_db, _db.dietPlanRows);
  $$DietAdherenceRowsTableTableManager get dietAdherenceRows =>
      $$DietAdherenceRowsTableTableManager(_db, _db.dietAdherenceRows);
  $$ChatMessageRowsTableTableManager get chatMessageRows =>
      $$ChatMessageRowsTableTableManager(_db, _db.chatMessageRows);
  $$TravelPlanRowsTableTableManager get travelPlanRows =>
      $$TravelPlanRowsTableTableManager(_db, _db.travelPlanRows);
  $$ArticleRowsTableTableManager get articleRows =>
      $$ArticleRowsTableTableManager(_db, _db.articleRows);
  $$HttpCacheRowsTableTableManager get httpCacheRows =>
      $$HttpCacheRowsTableTableManager(_db, _db.httpCacheRows);
  $$NotificationLogRowsTableTableManager get notificationLogRows =>
      $$NotificationLogRowsTableTableManager(_db, _db.notificationLogRows);
}
