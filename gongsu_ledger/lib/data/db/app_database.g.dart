// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WorkEntriesTable extends WorkEntries
    with TableInfo<$WorkEntriesTable, WorkEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _dateKeyMeta = const VerificationMeta(
    'dateKey',
  );
  @override
  late final GeneratedColumn<int> dateKey = GeneratedColumn<int>(
    'date_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _centiGongsuMeta = const VerificationMeta(
    'centiGongsu',
  );
  @override
  late final GeneratedColumn<int> centiGongsu = GeneratedColumn<int>(
    'centi_gongsu',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _presetIdMeta = const VerificationMeta(
    'presetId',
  );
  @override
  late final GeneratedColumn<int> presetId = GeneratedColumn<int>(
    'preset_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelSnapshotMeta = const VerificationMeta(
    'labelSnapshot',
  );
  @override
  late final GeneratedColumn<String> labelSnapshot = GeneratedColumn<String>(
    'label_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _colorIdSnapshotMeta = const VerificationMeta(
    'colorIdSnapshot',
  );
  @override
  late final GeneratedColumn<int> colorIdSnapshot = GeneratedColumn<int>(
    'color_id_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<int> siteId = GeneratedColumn<int>(
    'site_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitRateWonOverrideMeta =
      const VerificationMeta('unitRateWonOverride');
  @override
  late final GeneratedColumn<int> unitRateWonOverride = GeneratedColumn<int>(
    'unit_rate_won_override',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMillisMeta = const VerificationMeta(
    'createdAtMillis',
  );
  @override
  late final GeneratedColumn<int> createdAtMillis = GeneratedColumn<int>(
    'created_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMillisMeta = const VerificationMeta(
    'updatedAtMillis',
  );
  @override
  late final GeneratedColumn<int> updatedAtMillis = GeneratedColumn<int>(
    'updated_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMillisMeta = const VerificationMeta(
    'deletedAtMillis',
  );
  @override
  late final GeneratedColumn<int> deletedAtMillis = GeneratedColumn<int>(
    'deleted_at_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uid,
    dateKey,
    centiGongsu,
    presetId,
    labelSnapshot,
    colorIdSnapshot,
    siteId,
    unitRateWonOverride,
    createdAtMillis,
    updatedAtMillis,
    deletedAtMillis,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'work_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('date_key')) {
      context.handle(
        _dateKeyMeta,
        dateKey.isAcceptableOrUnknown(data['date_key']!, _dateKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dateKeyMeta);
    }
    if (data.containsKey('centi_gongsu')) {
      context.handle(
        _centiGongsuMeta,
        centiGongsu.isAcceptableOrUnknown(
          data['centi_gongsu']!,
          _centiGongsuMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_centiGongsuMeta);
    }
    if (data.containsKey('preset_id')) {
      context.handle(
        _presetIdMeta,
        presetId.isAcceptableOrUnknown(data['preset_id']!, _presetIdMeta),
      );
    }
    if (data.containsKey('label_snapshot')) {
      context.handle(
        _labelSnapshotMeta,
        labelSnapshot.isAcceptableOrUnknown(
          data['label_snapshot']!,
          _labelSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('color_id_snapshot')) {
      context.handle(
        _colorIdSnapshotMeta,
        colorIdSnapshot.isAcceptableOrUnknown(
          data['color_id_snapshot']!,
          _colorIdSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('site_id')) {
      context.handle(
        _siteIdMeta,
        siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta),
      );
    }
    if (data.containsKey('unit_rate_won_override')) {
      context.handle(
        _unitRateWonOverrideMeta,
        unitRateWonOverride.isAcceptableOrUnknown(
          data['unit_rate_won_override']!,
          _unitRateWonOverrideMeta,
        ),
      );
    }
    if (data.containsKey('created_at_millis')) {
      context.handle(
        _createdAtMillisMeta,
        createdAtMillis.isAcceptableOrUnknown(
          data['created_at_millis']!,
          _createdAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMillisMeta);
    }
    if (data.containsKey('updated_at_millis')) {
      context.handle(
        _updatedAtMillisMeta,
        updatedAtMillis.isAcceptableOrUnknown(
          data['updated_at_millis']!,
          _updatedAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMillisMeta);
    }
    if (data.containsKey('deleted_at_millis')) {
      context.handle(
        _deletedAtMillisMeta,
        deletedAtMillis.isAcceptableOrUnknown(
          data['deleted_at_millis']!,
          _deletedAtMillisMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      dateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_key'],
      )!,
      centiGongsu: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}centi_gongsu'],
      )!,
      presetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}preset_id'],
      ),
      labelSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_snapshot'],
      )!,
      colorIdSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_id_snapshot'],
      )!,
      siteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}site_id'],
      ),
      unitRateWonOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_rate_won_override'],
      ),
      createdAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_millis'],
      )!,
      updatedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_millis'],
      )!,
      deletedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_millis'],
      ),
    );
  }

  @override
  $WorkEntriesTable createAlias(String alias) {
    return $WorkEntriesTable(attachedDatabase, alias);
  }
}

class WorkEntry extends DataClass implements Insertable<WorkEntry> {
  final int id;

  /// 기기 간 병합/백업 재가져오기용 전역 키 (UUIDv4).
  final String uid;

  /// yyyyMMdd 정수. DateTime/타임존은 DB에 절대 들어가지 않는다.
  final int dateKey;

  /// centi-공수 (1공수 = 100). 0 = 휴무. double 경유 절대 금지.
  final int centiGongsu;

  /// 입력에 사용한 프리셋 id. NULL = 직접 입력.
  final int? presetId;

  /// 입력 시점 스냅샷 — 프리셋 이름. 직접 입력이면 빈 문자열.
  final String labelSnapshot;

  /// 입력 시점 스냅샷 — MarkerPalette id.
  final int colorIdSnapshot;

  /// M2 예약: 업체 id. NULL = 미지정.
  final int? siteId;

  /// M2 예약: 이 기록만 단가 오버라이드(원). NULL = 업체 단가 이력을 따름.
  final int? unitRateWonOverride;
  final int createdAtMillis;
  final int updatedAtMillis;

  /// soft delete. NULL = 살아있음. 같은 날 여러 건의 표시 순서는 id 오름차순.
  final int? deletedAtMillis;
  const WorkEntry({
    required this.id,
    required this.uid,
    required this.dateKey,
    required this.centiGongsu,
    this.presetId,
    required this.labelSnapshot,
    required this.colorIdSnapshot,
    this.siteId,
    this.unitRateWonOverride,
    required this.createdAtMillis,
    required this.updatedAtMillis,
    this.deletedAtMillis,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<String>(uid);
    map['date_key'] = Variable<int>(dateKey);
    map['centi_gongsu'] = Variable<int>(centiGongsu);
    if (!nullToAbsent || presetId != null) {
      map['preset_id'] = Variable<int>(presetId);
    }
    map['label_snapshot'] = Variable<String>(labelSnapshot);
    map['color_id_snapshot'] = Variable<int>(colorIdSnapshot);
    if (!nullToAbsent || siteId != null) {
      map['site_id'] = Variable<int>(siteId);
    }
    if (!nullToAbsent || unitRateWonOverride != null) {
      map['unit_rate_won_override'] = Variable<int>(unitRateWonOverride);
    }
    map['created_at_millis'] = Variable<int>(createdAtMillis);
    map['updated_at_millis'] = Variable<int>(updatedAtMillis);
    if (!nullToAbsent || deletedAtMillis != null) {
      map['deleted_at_millis'] = Variable<int>(deletedAtMillis);
    }
    return map;
  }

  WorkEntriesCompanion toCompanion(bool nullToAbsent) {
    return WorkEntriesCompanion(
      id: Value(id),
      uid: Value(uid),
      dateKey: Value(dateKey),
      centiGongsu: Value(centiGongsu),
      presetId: presetId == null && nullToAbsent
          ? const Value.absent()
          : Value(presetId),
      labelSnapshot: Value(labelSnapshot),
      colorIdSnapshot: Value(colorIdSnapshot),
      siteId: siteId == null && nullToAbsent
          ? const Value.absent()
          : Value(siteId),
      unitRateWonOverride: unitRateWonOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(unitRateWonOverride),
      createdAtMillis: Value(createdAtMillis),
      updatedAtMillis: Value(updatedAtMillis),
      deletedAtMillis: deletedAtMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtMillis),
    );
  }

  factory WorkEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkEntry(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      dateKey: serializer.fromJson<int>(json['dateKey']),
      centiGongsu: serializer.fromJson<int>(json['centiGongsu']),
      presetId: serializer.fromJson<int?>(json['presetId']),
      labelSnapshot: serializer.fromJson<String>(json['labelSnapshot']),
      colorIdSnapshot: serializer.fromJson<int>(json['colorIdSnapshot']),
      siteId: serializer.fromJson<int?>(json['siteId']),
      unitRateWonOverride: serializer.fromJson<int?>(
        json['unitRateWonOverride'],
      ),
      createdAtMillis: serializer.fromJson<int>(json['createdAtMillis']),
      updatedAtMillis: serializer.fromJson<int>(json['updatedAtMillis']),
      deletedAtMillis: serializer.fromJson<int?>(json['deletedAtMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'dateKey': serializer.toJson<int>(dateKey),
      'centiGongsu': serializer.toJson<int>(centiGongsu),
      'presetId': serializer.toJson<int?>(presetId),
      'labelSnapshot': serializer.toJson<String>(labelSnapshot),
      'colorIdSnapshot': serializer.toJson<int>(colorIdSnapshot),
      'siteId': serializer.toJson<int?>(siteId),
      'unitRateWonOverride': serializer.toJson<int?>(unitRateWonOverride),
      'createdAtMillis': serializer.toJson<int>(createdAtMillis),
      'updatedAtMillis': serializer.toJson<int>(updatedAtMillis),
      'deletedAtMillis': serializer.toJson<int?>(deletedAtMillis),
    };
  }

  WorkEntry copyWith({
    int? id,
    String? uid,
    int? dateKey,
    int? centiGongsu,
    Value<int?> presetId = const Value.absent(),
    String? labelSnapshot,
    int? colorIdSnapshot,
    Value<int?> siteId = const Value.absent(),
    Value<int?> unitRateWonOverride = const Value.absent(),
    int? createdAtMillis,
    int? updatedAtMillis,
    Value<int?> deletedAtMillis = const Value.absent(),
  }) => WorkEntry(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    dateKey: dateKey ?? this.dateKey,
    centiGongsu: centiGongsu ?? this.centiGongsu,
    presetId: presetId.present ? presetId.value : this.presetId,
    labelSnapshot: labelSnapshot ?? this.labelSnapshot,
    colorIdSnapshot: colorIdSnapshot ?? this.colorIdSnapshot,
    siteId: siteId.present ? siteId.value : this.siteId,
    unitRateWonOverride: unitRateWonOverride.present
        ? unitRateWonOverride.value
        : this.unitRateWonOverride,
    createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    deletedAtMillis: deletedAtMillis.present
        ? deletedAtMillis.value
        : this.deletedAtMillis,
  );
  WorkEntry copyWithCompanion(WorkEntriesCompanion data) {
    return WorkEntry(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      dateKey: data.dateKey.present ? data.dateKey.value : this.dateKey,
      centiGongsu: data.centiGongsu.present
          ? data.centiGongsu.value
          : this.centiGongsu,
      presetId: data.presetId.present ? data.presetId.value : this.presetId,
      labelSnapshot: data.labelSnapshot.present
          ? data.labelSnapshot.value
          : this.labelSnapshot,
      colorIdSnapshot: data.colorIdSnapshot.present
          ? data.colorIdSnapshot.value
          : this.colorIdSnapshot,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      unitRateWonOverride: data.unitRateWonOverride.present
          ? data.unitRateWonOverride.value
          : this.unitRateWonOverride,
      createdAtMillis: data.createdAtMillis.present
          ? data.createdAtMillis.value
          : this.createdAtMillis,
      updatedAtMillis: data.updatedAtMillis.present
          ? data.updatedAtMillis.value
          : this.updatedAtMillis,
      deletedAtMillis: data.deletedAtMillis.present
          ? data.deletedAtMillis.value
          : this.deletedAtMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkEntry(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('dateKey: $dateKey, ')
          ..write('centiGongsu: $centiGongsu, ')
          ..write('presetId: $presetId, ')
          ..write('labelSnapshot: $labelSnapshot, ')
          ..write('colorIdSnapshot: $colorIdSnapshot, ')
          ..write('siteId: $siteId, ')
          ..write('unitRateWonOverride: $unitRateWonOverride, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis, ')
          ..write('deletedAtMillis: $deletedAtMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    dateKey,
    centiGongsu,
    presetId,
    labelSnapshot,
    colorIdSnapshot,
    siteId,
    unitRateWonOverride,
    createdAtMillis,
    updatedAtMillis,
    deletedAtMillis,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkEntry &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.dateKey == this.dateKey &&
          other.centiGongsu == this.centiGongsu &&
          other.presetId == this.presetId &&
          other.labelSnapshot == this.labelSnapshot &&
          other.colorIdSnapshot == this.colorIdSnapshot &&
          other.siteId == this.siteId &&
          other.unitRateWonOverride == this.unitRateWonOverride &&
          other.createdAtMillis == this.createdAtMillis &&
          other.updatedAtMillis == this.updatedAtMillis &&
          other.deletedAtMillis == this.deletedAtMillis);
}

class WorkEntriesCompanion extends UpdateCompanion<WorkEntry> {
  final Value<int> id;
  final Value<String> uid;
  final Value<int> dateKey;
  final Value<int> centiGongsu;
  final Value<int?> presetId;
  final Value<String> labelSnapshot;
  final Value<int> colorIdSnapshot;
  final Value<int?> siteId;
  final Value<int?> unitRateWonOverride;
  final Value<int> createdAtMillis;
  final Value<int> updatedAtMillis;
  final Value<int?> deletedAtMillis;
  const WorkEntriesCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.dateKey = const Value.absent(),
    this.centiGongsu = const Value.absent(),
    this.presetId = const Value.absent(),
    this.labelSnapshot = const Value.absent(),
    this.colorIdSnapshot = const Value.absent(),
    this.siteId = const Value.absent(),
    this.unitRateWonOverride = const Value.absent(),
    this.createdAtMillis = const Value.absent(),
    this.updatedAtMillis = const Value.absent(),
    this.deletedAtMillis = const Value.absent(),
  });
  WorkEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String uid,
    required int dateKey,
    required int centiGongsu,
    this.presetId = const Value.absent(),
    this.labelSnapshot = const Value.absent(),
    this.colorIdSnapshot = const Value.absent(),
    this.siteId = const Value.absent(),
    this.unitRateWonOverride = const Value.absent(),
    required int createdAtMillis,
    required int updatedAtMillis,
    this.deletedAtMillis = const Value.absent(),
  }) : uid = Value(uid),
       dateKey = Value(dateKey),
       centiGongsu = Value(centiGongsu),
       createdAtMillis = Value(createdAtMillis),
       updatedAtMillis = Value(updatedAtMillis);
  static Insertable<WorkEntry> custom({
    Expression<int>? id,
    Expression<String>? uid,
    Expression<int>? dateKey,
    Expression<int>? centiGongsu,
    Expression<int>? presetId,
    Expression<String>? labelSnapshot,
    Expression<int>? colorIdSnapshot,
    Expression<int>? siteId,
    Expression<int>? unitRateWonOverride,
    Expression<int>? createdAtMillis,
    Expression<int>? updatedAtMillis,
    Expression<int>? deletedAtMillis,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (dateKey != null) 'date_key': dateKey,
      if (centiGongsu != null) 'centi_gongsu': centiGongsu,
      if (presetId != null) 'preset_id': presetId,
      if (labelSnapshot != null) 'label_snapshot': labelSnapshot,
      if (colorIdSnapshot != null) 'color_id_snapshot': colorIdSnapshot,
      if (siteId != null) 'site_id': siteId,
      if (unitRateWonOverride != null)
        'unit_rate_won_override': unitRateWonOverride,
      if (createdAtMillis != null) 'created_at_millis': createdAtMillis,
      if (updatedAtMillis != null) 'updated_at_millis': updatedAtMillis,
      if (deletedAtMillis != null) 'deleted_at_millis': deletedAtMillis,
    });
  }

  WorkEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? uid,
    Value<int>? dateKey,
    Value<int>? centiGongsu,
    Value<int?>? presetId,
    Value<String>? labelSnapshot,
    Value<int>? colorIdSnapshot,
    Value<int?>? siteId,
    Value<int?>? unitRateWonOverride,
    Value<int>? createdAtMillis,
    Value<int>? updatedAtMillis,
    Value<int?>? deletedAtMillis,
  }) {
    return WorkEntriesCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      dateKey: dateKey ?? this.dateKey,
      centiGongsu: centiGongsu ?? this.centiGongsu,
      presetId: presetId ?? this.presetId,
      labelSnapshot: labelSnapshot ?? this.labelSnapshot,
      colorIdSnapshot: colorIdSnapshot ?? this.colorIdSnapshot,
      siteId: siteId ?? this.siteId,
      unitRateWonOverride: unitRateWonOverride ?? this.unitRateWonOverride,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
      deletedAtMillis: deletedAtMillis ?? this.deletedAtMillis,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (dateKey.present) {
      map['date_key'] = Variable<int>(dateKey.value);
    }
    if (centiGongsu.present) {
      map['centi_gongsu'] = Variable<int>(centiGongsu.value);
    }
    if (presetId.present) {
      map['preset_id'] = Variable<int>(presetId.value);
    }
    if (labelSnapshot.present) {
      map['label_snapshot'] = Variable<String>(labelSnapshot.value);
    }
    if (colorIdSnapshot.present) {
      map['color_id_snapshot'] = Variable<int>(colorIdSnapshot.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<int>(siteId.value);
    }
    if (unitRateWonOverride.present) {
      map['unit_rate_won_override'] = Variable<int>(unitRateWonOverride.value);
    }
    if (createdAtMillis.present) {
      map['created_at_millis'] = Variable<int>(createdAtMillis.value);
    }
    if (updatedAtMillis.present) {
      map['updated_at_millis'] = Variable<int>(updatedAtMillis.value);
    }
    if (deletedAtMillis.present) {
      map['deleted_at_millis'] = Variable<int>(deletedAtMillis.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkEntriesCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('dateKey: $dateKey, ')
          ..write('centiGongsu: $centiGongsu, ')
          ..write('presetId: $presetId, ')
          ..write('labelSnapshot: $labelSnapshot, ')
          ..write('colorIdSnapshot: $colorIdSnapshot, ')
          ..write('siteId: $siteId, ')
          ..write('unitRateWonOverride: $unitRateWonOverride, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis, ')
          ..write('deletedAtMillis: $deletedAtMillis')
          ..write(')'))
        .toString();
  }
}

class $PresetsTable extends Presets with TableInfo<$PresetsTable, Preset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PresetsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _centiGongsuMeta = const VerificationMeta(
    'centiGongsu',
  );
  @override
  late final GeneratedColumn<int> centiGongsu = GeneratedColumn<int>(
    'centi_gongsu',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorIdMeta = const VerificationMeta(
    'colorId',
  );
  @override
  late final GeneratedColumn<int> colorId = GeneratedColumn<int>(
    'color_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMillisMeta = const VerificationMeta(
    'createdAtMillis',
  );
  @override
  late final GeneratedColumn<int> createdAtMillis = GeneratedColumn<int>(
    'created_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMillisMeta = const VerificationMeta(
    'updatedAtMillis',
  );
  @override
  late final GeneratedColumn<int> updatedAtMillis = GeneratedColumn<int>(
    'updated_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uid,
    name,
    centiGongsu,
    colorId,
    sortOrder,
    isArchived,
    createdAtMillis,
    updatedAtMillis,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'presets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Preset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('centi_gongsu')) {
      context.handle(
        _centiGongsuMeta,
        centiGongsu.isAcceptableOrUnknown(
          data['centi_gongsu']!,
          _centiGongsuMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_centiGongsuMeta);
    }
    if (data.containsKey('color_id')) {
      context.handle(
        _colorIdMeta,
        colorId.isAcceptableOrUnknown(data['color_id']!, _colorIdMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('created_at_millis')) {
      context.handle(
        _createdAtMillisMeta,
        createdAtMillis.isAcceptableOrUnknown(
          data['created_at_millis']!,
          _createdAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMillisMeta);
    }
    if (data.containsKey('updated_at_millis')) {
      context.handle(
        _updatedAtMillisMeta,
        updatedAtMillis.isAcceptableOrUnknown(
          data['updated_at_millis']!,
          _updatedAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMillisMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Preset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Preset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      centiGongsu: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}centi_gongsu'],
      )!,
      colorId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_millis'],
      )!,
      updatedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_millis'],
      )!,
    );
  }

  @override
  $PresetsTable createAlias(String alias) {
    return $PresetsTable(attachedDatabase, alias);
  }
}

class Preset extends DataClass implements Insertable<Preset> {
  final int id;
  final String uid;
  final String name;

  /// centi-공수. 0 = 휴무 프리셋.
  final int centiGongsu;

  /// MarkerPalette id. 색값(ARGB)이 아니라 팔레트 id를 저장 —
  /// 팔레트 색을 개선해도 데이터 마이그레이션이 필요 없다.
  final int colorId;
  final int sortOrder;

  /// 삭제 대신 보관. 과거 기록의 presetId가 이 행을 계속 가리킬 수 있다.
  final bool isArchived;
  final int createdAtMillis;
  final int updatedAtMillis;
  const Preset({
    required this.id,
    required this.uid,
    required this.name,
    required this.centiGongsu,
    required this.colorId,
    required this.sortOrder,
    required this.isArchived,
    required this.createdAtMillis,
    required this.updatedAtMillis,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<String>(uid);
    map['name'] = Variable<String>(name);
    map['centi_gongsu'] = Variable<int>(centiGongsu);
    map['color_id'] = Variable<int>(colorId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at_millis'] = Variable<int>(createdAtMillis);
    map['updated_at_millis'] = Variable<int>(updatedAtMillis);
    return map;
  }

  PresetsCompanion toCompanion(bool nullToAbsent) {
    return PresetsCompanion(
      id: Value(id),
      uid: Value(uid),
      name: Value(name),
      centiGongsu: Value(centiGongsu),
      colorId: Value(colorId),
      sortOrder: Value(sortOrder),
      isArchived: Value(isArchived),
      createdAtMillis: Value(createdAtMillis),
      updatedAtMillis: Value(updatedAtMillis),
    );
  }

  factory Preset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Preset(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      name: serializer.fromJson<String>(json['name']),
      centiGongsu: serializer.fromJson<int>(json['centiGongsu']),
      colorId: serializer.fromJson<int>(json['colorId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAtMillis: serializer.fromJson<int>(json['createdAtMillis']),
      updatedAtMillis: serializer.fromJson<int>(json['updatedAtMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'name': serializer.toJson<String>(name),
      'centiGongsu': serializer.toJson<int>(centiGongsu),
      'colorId': serializer.toJson<int>(colorId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAtMillis': serializer.toJson<int>(createdAtMillis),
      'updatedAtMillis': serializer.toJson<int>(updatedAtMillis),
    };
  }

  Preset copyWith({
    int? id,
    String? uid,
    String? name,
    int? centiGongsu,
    int? colorId,
    int? sortOrder,
    bool? isArchived,
    int? createdAtMillis,
    int? updatedAtMillis,
  }) => Preset(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    name: name ?? this.name,
    centiGongsu: centiGongsu ?? this.centiGongsu,
    colorId: colorId ?? this.colorId,
    sortOrder: sortOrder ?? this.sortOrder,
    isArchived: isArchived ?? this.isArchived,
    createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
  );
  Preset copyWithCompanion(PresetsCompanion data) {
    return Preset(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      name: data.name.present ? data.name.value : this.name,
      centiGongsu: data.centiGongsu.present
          ? data.centiGongsu.value
          : this.centiGongsu,
      colorId: data.colorId.present ? data.colorId.value : this.colorId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAtMillis: data.createdAtMillis.present
          ? data.createdAtMillis.value
          : this.createdAtMillis,
      updatedAtMillis: data.updatedAtMillis.present
          ? data.updatedAtMillis.value
          : this.updatedAtMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Preset(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('centiGongsu: $centiGongsu, ')
          ..write('colorId: $colorId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    name,
    centiGongsu,
    colorId,
    sortOrder,
    isArchived,
    createdAtMillis,
    updatedAtMillis,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Preset &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.name == this.name &&
          other.centiGongsu == this.centiGongsu &&
          other.colorId == this.colorId &&
          other.sortOrder == this.sortOrder &&
          other.isArchived == this.isArchived &&
          other.createdAtMillis == this.createdAtMillis &&
          other.updatedAtMillis == this.updatedAtMillis);
}

class PresetsCompanion extends UpdateCompanion<Preset> {
  final Value<int> id;
  final Value<String> uid;
  final Value<String> name;
  final Value<int> centiGongsu;
  final Value<int> colorId;
  final Value<int> sortOrder;
  final Value<bool> isArchived;
  final Value<int> createdAtMillis;
  final Value<int> updatedAtMillis;
  const PresetsCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.name = const Value.absent(),
    this.centiGongsu = const Value.absent(),
    this.colorId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAtMillis = const Value.absent(),
    this.updatedAtMillis = const Value.absent(),
  });
  PresetsCompanion.insert({
    this.id = const Value.absent(),
    required String uid,
    required String name,
    required int centiGongsu,
    this.colorId = const Value.absent(),
    required int sortOrder,
    this.isArchived = const Value.absent(),
    required int createdAtMillis,
    required int updatedAtMillis,
  }) : uid = Value(uid),
       name = Value(name),
       centiGongsu = Value(centiGongsu),
       sortOrder = Value(sortOrder),
       createdAtMillis = Value(createdAtMillis),
       updatedAtMillis = Value(updatedAtMillis);
  static Insertable<Preset> custom({
    Expression<int>? id,
    Expression<String>? uid,
    Expression<String>? name,
    Expression<int>? centiGongsu,
    Expression<int>? colorId,
    Expression<int>? sortOrder,
    Expression<bool>? isArchived,
    Expression<int>? createdAtMillis,
    Expression<int>? updatedAtMillis,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (name != null) 'name': name,
      if (centiGongsu != null) 'centi_gongsu': centiGongsu,
      if (colorId != null) 'color_id': colorId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAtMillis != null) 'created_at_millis': createdAtMillis,
      if (updatedAtMillis != null) 'updated_at_millis': updatedAtMillis,
    });
  }

  PresetsCompanion copyWith({
    Value<int>? id,
    Value<String>? uid,
    Value<String>? name,
    Value<int>? centiGongsu,
    Value<int>? colorId,
    Value<int>? sortOrder,
    Value<bool>? isArchived,
    Value<int>? createdAtMillis,
    Value<int>? updatedAtMillis,
  }) {
    return PresetsCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      centiGongsu: centiGongsu ?? this.centiGongsu,
      colorId: colorId ?? this.colorId,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (centiGongsu.present) {
      map['centi_gongsu'] = Variable<int>(centiGongsu.value);
    }
    if (colorId.present) {
      map['color_id'] = Variable<int>(colorId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAtMillis.present) {
      map['created_at_millis'] = Variable<int>(createdAtMillis.value);
    }
    if (updatedAtMillis.present) {
      map['updated_at_millis'] = Variable<int>(updatedAtMillis.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PresetsCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('centiGongsu: $centiGongsu, ')
          ..write('colorId: $colorId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis')
          ..write(')'))
        .toString();
  }
}

class $DayMemosTable extends DayMemos with TableInfo<$DayMemosTable, DayMemo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayMemosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateKeyMeta = const VerificationMeta(
    'dateKey',
  );
  @override
  late final GeneratedColumn<int> dateKey = GeneratedColumn<int>(
    'date_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _updatedAtMillisMeta = const VerificationMeta(
    'updatedAtMillis',
  );
  @override
  late final GeneratedColumn<int> updatedAtMillis = GeneratedColumn<int>(
    'updated_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [dateKey, body, updatedAtMillis];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_memos';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayMemo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date_key')) {
      context.handle(
        _dateKeyMeta,
        dateKey.isAcceptableOrUnknown(data['date_key']!, _dateKeyMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('updated_at_millis')) {
      context.handle(
        _updatedAtMillisMeta,
        updatedAtMillis.isAcceptableOrUnknown(
          data['updated_at_millis']!,
          _updatedAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMillisMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dateKey};
  @override
  DayMemo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayMemo(
      dateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_key'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      updatedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_millis'],
      )!,
    );
  }

  @override
  $DayMemosTable createAlias(String alias) {
    return $DayMemosTable(attachedDatabase, alias);
  }
}

class DayMemo extends DataClass implements Insertable<DayMemo> {
  final int dateKey;
  final String body;
  final int updatedAtMillis;
  const DayMemo({
    required this.dateKey,
    required this.body,
    required this.updatedAtMillis,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date_key'] = Variable<int>(dateKey);
    map['body'] = Variable<String>(body);
    map['updated_at_millis'] = Variable<int>(updatedAtMillis);
    return map;
  }

  DayMemosCompanion toCompanion(bool nullToAbsent) {
    return DayMemosCompanion(
      dateKey: Value(dateKey),
      body: Value(body),
      updatedAtMillis: Value(updatedAtMillis),
    );
  }

  factory DayMemo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayMemo(
      dateKey: serializer.fromJson<int>(json['dateKey']),
      body: serializer.fromJson<String>(json['body']),
      updatedAtMillis: serializer.fromJson<int>(json['updatedAtMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dateKey': serializer.toJson<int>(dateKey),
      'body': serializer.toJson<String>(body),
      'updatedAtMillis': serializer.toJson<int>(updatedAtMillis),
    };
  }

  DayMemo copyWith({int? dateKey, String? body, int? updatedAtMillis}) =>
      DayMemo(
        dateKey: dateKey ?? this.dateKey,
        body: body ?? this.body,
        updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
      );
  DayMemo copyWithCompanion(DayMemosCompanion data) {
    return DayMemo(
      dateKey: data.dateKey.present ? data.dateKey.value : this.dateKey,
      body: data.body.present ? data.body.value : this.body,
      updatedAtMillis: data.updatedAtMillis.present
          ? data.updatedAtMillis.value
          : this.updatedAtMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayMemo(')
          ..write('dateKey: $dateKey, ')
          ..write('body: $body, ')
          ..write('updatedAtMillis: $updatedAtMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(dateKey, body, updatedAtMillis);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayMemo &&
          other.dateKey == this.dateKey &&
          other.body == this.body &&
          other.updatedAtMillis == this.updatedAtMillis);
}

class DayMemosCompanion extends UpdateCompanion<DayMemo> {
  final Value<int> dateKey;
  final Value<String> body;
  final Value<int> updatedAtMillis;
  const DayMemosCompanion({
    this.dateKey = const Value.absent(),
    this.body = const Value.absent(),
    this.updatedAtMillis = const Value.absent(),
  });
  DayMemosCompanion.insert({
    this.dateKey = const Value.absent(),
    required String body,
    required int updatedAtMillis,
  }) : body = Value(body),
       updatedAtMillis = Value(updatedAtMillis);
  static Insertable<DayMemo> custom({
    Expression<int>? dateKey,
    Expression<String>? body,
    Expression<int>? updatedAtMillis,
  }) {
    return RawValuesInsertable({
      if (dateKey != null) 'date_key': dateKey,
      if (body != null) 'body': body,
      if (updatedAtMillis != null) 'updated_at_millis': updatedAtMillis,
    });
  }

  DayMemosCompanion copyWith({
    Value<int>? dateKey,
    Value<String>? body,
    Value<int>? updatedAtMillis,
  }) {
    return DayMemosCompanion(
      dateKey: dateKey ?? this.dateKey,
      body: body ?? this.body,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dateKey.present) {
      map['date_key'] = Variable<int>(dateKey.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (updatedAtMillis.present) {
      map['updated_at_millis'] = Variable<int>(updatedAtMillis.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayMemosCompanion(')
          ..write('dateKey: $dateKey, ')
          ..write('body: $body, ')
          ..write('updatedAtMillis: $updatedAtMillis')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
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
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SitesTable extends Sites with TableInfo<$SitesTable, Site> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SitesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 30,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorIdMeta = const VerificationMeta(
    'colorId',
  );
  @override
  late final GeneratedColumn<int> colorId = GeneratedColumn<int>(
    'color_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMillisMeta = const VerificationMeta(
    'createdAtMillis',
  );
  @override
  late final GeneratedColumn<int> createdAtMillis = GeneratedColumn<int>(
    'created_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMillisMeta = const VerificationMeta(
    'updatedAtMillis',
  );
  @override
  late final GeneratedColumn<int> updatedAtMillis = GeneratedColumn<int>(
    'updated_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxModeMeta = const VerificationMeta(
    'taxMode',
  );
  @override
  late final GeneratedColumn<String> taxMode = GeneratedColumn<String>(
    'tax_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _taxOptionsJsonMeta = const VerificationMeta(
    'taxOptionsJson',
  );
  @override
  late final GeneratedColumn<String> taxOptionsJson = GeneratedColumn<String>(
    'tax_options_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uid,
    name,
    colorId,
    sortOrder,
    isArchived,
    createdAtMillis,
    updatedAtMillis,
    taxMode,
    taxOptionsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Site> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_id')) {
      context.handle(
        _colorIdMeta,
        colorId.isAcceptableOrUnknown(data['color_id']!, _colorIdMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('created_at_millis')) {
      context.handle(
        _createdAtMillisMeta,
        createdAtMillis.isAcceptableOrUnknown(
          data['created_at_millis']!,
          _createdAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMillisMeta);
    }
    if (data.containsKey('updated_at_millis')) {
      context.handle(
        _updatedAtMillisMeta,
        updatedAtMillis.isAcceptableOrUnknown(
          data['updated_at_millis']!,
          _updatedAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMillisMeta);
    }
    if (data.containsKey('tax_mode')) {
      context.handle(
        _taxModeMeta,
        taxMode.isAcceptableOrUnknown(data['tax_mode']!, _taxModeMeta),
      );
    }
    if (data.containsKey('tax_options_json')) {
      context.handle(
        _taxOptionsJsonMeta,
        taxOptionsJson.isAcceptableOrUnknown(
          data['tax_options_json']!,
          _taxOptionsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Site map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Site(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_millis'],
      )!,
      updatedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_millis'],
      )!,
      taxMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_mode'],
      )!,
      taxOptionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_options_json'],
      ),
    );
  }

  @override
  $SitesTable createAlias(String alias) {
    return $SitesTable(attachedDatabase, alias);
  }
}

class Site extends DataClass implements Insertable<Site> {
  final int id;
  final String uid;
  final String name;

  /// MarkerPalette id.
  final int colorId;
  final int sortOrder;
  final bool isArchived;
  final int createdAtMillis;
  final int updatedAtMillis;

  /// M3 (schemaVersion 3, ADD COLUMN): 세금 방식 코드.
  /// 'none' | 'withholding33' | 'insurance4'. 기본 'none' — 잘못된 공제보다
  /// 공제 없음이 안전하다. 업체 편집 화면에서 고른다.
  final String taxMode;

  /// M3: 4대보험 세부 옵션 JSON (TaxOptions). NULL = 기본값.
  final String? taxOptionsJson;
  const Site({
    required this.id,
    required this.uid,
    required this.name,
    required this.colorId,
    required this.sortOrder,
    required this.isArchived,
    required this.createdAtMillis,
    required this.updatedAtMillis,
    required this.taxMode,
    this.taxOptionsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<String>(uid);
    map['name'] = Variable<String>(name);
    map['color_id'] = Variable<int>(colorId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at_millis'] = Variable<int>(createdAtMillis);
    map['updated_at_millis'] = Variable<int>(updatedAtMillis);
    map['tax_mode'] = Variable<String>(taxMode);
    if (!nullToAbsent || taxOptionsJson != null) {
      map['tax_options_json'] = Variable<String>(taxOptionsJson);
    }
    return map;
  }

  SitesCompanion toCompanion(bool nullToAbsent) {
    return SitesCompanion(
      id: Value(id),
      uid: Value(uid),
      name: Value(name),
      colorId: Value(colorId),
      sortOrder: Value(sortOrder),
      isArchived: Value(isArchived),
      createdAtMillis: Value(createdAtMillis),
      updatedAtMillis: Value(updatedAtMillis),
      taxMode: Value(taxMode),
      taxOptionsJson: taxOptionsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(taxOptionsJson),
    );
  }

  factory Site.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Site(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      name: serializer.fromJson<String>(json['name']),
      colorId: serializer.fromJson<int>(json['colorId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAtMillis: serializer.fromJson<int>(json['createdAtMillis']),
      updatedAtMillis: serializer.fromJson<int>(json['updatedAtMillis']),
      taxMode: serializer.fromJson<String>(json['taxMode']),
      taxOptionsJson: serializer.fromJson<String?>(json['taxOptionsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'name': serializer.toJson<String>(name),
      'colorId': serializer.toJson<int>(colorId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAtMillis': serializer.toJson<int>(createdAtMillis),
      'updatedAtMillis': serializer.toJson<int>(updatedAtMillis),
      'taxMode': serializer.toJson<String>(taxMode),
      'taxOptionsJson': serializer.toJson<String?>(taxOptionsJson),
    };
  }

  Site copyWith({
    int? id,
    String? uid,
    String? name,
    int? colorId,
    int? sortOrder,
    bool? isArchived,
    int? createdAtMillis,
    int? updatedAtMillis,
    String? taxMode,
    Value<String?> taxOptionsJson = const Value.absent(),
  }) => Site(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    name: name ?? this.name,
    colorId: colorId ?? this.colorId,
    sortOrder: sortOrder ?? this.sortOrder,
    isArchived: isArchived ?? this.isArchived,
    createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    taxMode: taxMode ?? this.taxMode,
    taxOptionsJson: taxOptionsJson.present
        ? taxOptionsJson.value
        : this.taxOptionsJson,
  );
  Site copyWithCompanion(SitesCompanion data) {
    return Site(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      name: data.name.present ? data.name.value : this.name,
      colorId: data.colorId.present ? data.colorId.value : this.colorId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAtMillis: data.createdAtMillis.present
          ? data.createdAtMillis.value
          : this.createdAtMillis,
      updatedAtMillis: data.updatedAtMillis.present
          ? data.updatedAtMillis.value
          : this.updatedAtMillis,
      taxMode: data.taxMode.present ? data.taxMode.value : this.taxMode,
      taxOptionsJson: data.taxOptionsJson.present
          ? data.taxOptionsJson.value
          : this.taxOptionsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Site(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('colorId: $colorId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis, ')
          ..write('taxMode: $taxMode, ')
          ..write('taxOptionsJson: $taxOptionsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    name,
    colorId,
    sortOrder,
    isArchived,
    createdAtMillis,
    updatedAtMillis,
    taxMode,
    taxOptionsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Site &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.name == this.name &&
          other.colorId == this.colorId &&
          other.sortOrder == this.sortOrder &&
          other.isArchived == this.isArchived &&
          other.createdAtMillis == this.createdAtMillis &&
          other.updatedAtMillis == this.updatedAtMillis &&
          other.taxMode == this.taxMode &&
          other.taxOptionsJson == this.taxOptionsJson);
}

class SitesCompanion extends UpdateCompanion<Site> {
  final Value<int> id;
  final Value<String> uid;
  final Value<String> name;
  final Value<int> colorId;
  final Value<int> sortOrder;
  final Value<bool> isArchived;
  final Value<int> createdAtMillis;
  final Value<int> updatedAtMillis;
  final Value<String> taxMode;
  final Value<String?> taxOptionsJson;
  const SitesCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.name = const Value.absent(),
    this.colorId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAtMillis = const Value.absent(),
    this.updatedAtMillis = const Value.absent(),
    this.taxMode = const Value.absent(),
    this.taxOptionsJson = const Value.absent(),
  });
  SitesCompanion.insert({
    this.id = const Value.absent(),
    required String uid,
    required String name,
    this.colorId = const Value.absent(),
    required int sortOrder,
    this.isArchived = const Value.absent(),
    required int createdAtMillis,
    required int updatedAtMillis,
    this.taxMode = const Value.absent(),
    this.taxOptionsJson = const Value.absent(),
  }) : uid = Value(uid),
       name = Value(name),
       sortOrder = Value(sortOrder),
       createdAtMillis = Value(createdAtMillis),
       updatedAtMillis = Value(updatedAtMillis);
  static Insertable<Site> custom({
    Expression<int>? id,
    Expression<String>? uid,
    Expression<String>? name,
    Expression<int>? colorId,
    Expression<int>? sortOrder,
    Expression<bool>? isArchived,
    Expression<int>? createdAtMillis,
    Expression<int>? updatedAtMillis,
    Expression<String>? taxMode,
    Expression<String>? taxOptionsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (name != null) 'name': name,
      if (colorId != null) 'color_id': colorId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAtMillis != null) 'created_at_millis': createdAtMillis,
      if (updatedAtMillis != null) 'updated_at_millis': updatedAtMillis,
      if (taxMode != null) 'tax_mode': taxMode,
      if (taxOptionsJson != null) 'tax_options_json': taxOptionsJson,
    });
  }

  SitesCompanion copyWith({
    Value<int>? id,
    Value<String>? uid,
    Value<String>? name,
    Value<int>? colorId,
    Value<int>? sortOrder,
    Value<bool>? isArchived,
    Value<int>? createdAtMillis,
    Value<int>? updatedAtMillis,
    Value<String>? taxMode,
    Value<String?>? taxOptionsJson,
  }) {
    return SitesCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      colorId: colorId ?? this.colorId,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
      taxMode: taxMode ?? this.taxMode,
      taxOptionsJson: taxOptionsJson ?? this.taxOptionsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorId.present) {
      map['color_id'] = Variable<int>(colorId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAtMillis.present) {
      map['created_at_millis'] = Variable<int>(createdAtMillis.value);
    }
    if (updatedAtMillis.present) {
      map['updated_at_millis'] = Variable<int>(updatedAtMillis.value);
    }
    if (taxMode.present) {
      map['tax_mode'] = Variable<String>(taxMode.value);
    }
    if (taxOptionsJson.present) {
      map['tax_options_json'] = Variable<String>(taxOptionsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SitesCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('colorId: $colorId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis, ')
          ..write('taxMode: $taxMode, ')
          ..write('taxOptionsJson: $taxOptionsJson')
          ..write(')'))
        .toString();
  }
}

class $SiteRateHistoriesTable extends SiteRateHistories
    with TableInfo<$SiteRateHistoriesTable, SiteRateHistory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SiteRateHistoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<int> siteId = GeneratedColumn<int>(
    'site_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _effectiveFromDateKeyMeta =
      const VerificationMeta('effectiveFromDateKey');
  @override
  late final GeneratedColumn<int> effectiveFromDateKey = GeneratedColumn<int>(
    'effective_from_date_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyRateWonMeta = const VerificationMeta(
    'dailyRateWon',
  );
  @override
  late final GeneratedColumn<int> dailyRateWon = GeneratedColumn<int>(
    'daily_rate_won',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMillisMeta = const VerificationMeta(
    'createdAtMillis',
  );
  @override
  late final GeneratedColumn<int> createdAtMillis = GeneratedColumn<int>(
    'created_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMillisMeta = const VerificationMeta(
    'updatedAtMillis',
  );
  @override
  late final GeneratedColumn<int> updatedAtMillis = GeneratedColumn<int>(
    'updated_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMillisMeta = const VerificationMeta(
    'deletedAtMillis',
  );
  @override
  late final GeneratedColumn<int> deletedAtMillis = GeneratedColumn<int>(
    'deleted_at_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uid,
    siteId,
    effectiveFromDateKey,
    dailyRateWon,
    createdAtMillis,
    updatedAtMillis,
    deletedAtMillis,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'site_rate_histories';
  @override
  VerificationContext validateIntegrity(
    Insertable<SiteRateHistory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('site_id')) {
      context.handle(
        _siteIdMeta,
        siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_siteIdMeta);
    }
    if (data.containsKey('effective_from_date_key')) {
      context.handle(
        _effectiveFromDateKeyMeta,
        effectiveFromDateKey.isAcceptableOrUnknown(
          data['effective_from_date_key']!,
          _effectiveFromDateKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveFromDateKeyMeta);
    }
    if (data.containsKey('daily_rate_won')) {
      context.handle(
        _dailyRateWonMeta,
        dailyRateWon.isAcceptableOrUnknown(
          data['daily_rate_won']!,
          _dailyRateWonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dailyRateWonMeta);
    }
    if (data.containsKey('created_at_millis')) {
      context.handle(
        _createdAtMillisMeta,
        createdAtMillis.isAcceptableOrUnknown(
          data['created_at_millis']!,
          _createdAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMillisMeta);
    }
    if (data.containsKey('updated_at_millis')) {
      context.handle(
        _updatedAtMillisMeta,
        updatedAtMillis.isAcceptableOrUnknown(
          data['updated_at_millis']!,
          _updatedAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMillisMeta);
    }
    if (data.containsKey('deleted_at_millis')) {
      context.handle(
        _deletedAtMillisMeta,
        deletedAtMillis.isAcceptableOrUnknown(
          data['deleted_at_millis']!,
          _deletedAtMillisMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SiteRateHistory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SiteRateHistory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      siteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}site_id'],
      )!,
      effectiveFromDateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}effective_from_date_key'],
      )!,
      dailyRateWon: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_rate_won'],
      )!,
      createdAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_millis'],
      )!,
      updatedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_millis'],
      )!,
      deletedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_millis'],
      ),
    );
  }

  @override
  $SiteRateHistoriesTable createAlias(String alias) {
    return $SiteRateHistoriesTable(attachedDatabase, alias);
  }
}

class SiteRateHistory extends DataClass implements Insertable<SiteRateHistory> {
  final int id;
  final String uid;
  final int siteId;

  /// yyyyMMdd. 이 날짜부터(포함) 적용.
  final int effectiveFromDateKey;

  /// 1.0공수당 원.
  final int dailyRateWon;
  final int createdAtMillis;
  final int updatedAtMillis;

  /// soft delete. 잘못 넣은 이력을 지울 때도 물리 삭제하지 않는다.
  final int? deletedAtMillis;
  const SiteRateHistory({
    required this.id,
    required this.uid,
    required this.siteId,
    required this.effectiveFromDateKey,
    required this.dailyRateWon,
    required this.createdAtMillis,
    required this.updatedAtMillis,
    this.deletedAtMillis,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<String>(uid);
    map['site_id'] = Variable<int>(siteId);
    map['effective_from_date_key'] = Variable<int>(effectiveFromDateKey);
    map['daily_rate_won'] = Variable<int>(dailyRateWon);
    map['created_at_millis'] = Variable<int>(createdAtMillis);
    map['updated_at_millis'] = Variable<int>(updatedAtMillis);
    if (!nullToAbsent || deletedAtMillis != null) {
      map['deleted_at_millis'] = Variable<int>(deletedAtMillis);
    }
    return map;
  }

  SiteRateHistoriesCompanion toCompanion(bool nullToAbsent) {
    return SiteRateHistoriesCompanion(
      id: Value(id),
      uid: Value(uid),
      siteId: Value(siteId),
      effectiveFromDateKey: Value(effectiveFromDateKey),
      dailyRateWon: Value(dailyRateWon),
      createdAtMillis: Value(createdAtMillis),
      updatedAtMillis: Value(updatedAtMillis),
      deletedAtMillis: deletedAtMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtMillis),
    );
  }

  factory SiteRateHistory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SiteRateHistory(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      siteId: serializer.fromJson<int>(json['siteId']),
      effectiveFromDateKey: serializer.fromJson<int>(
        json['effectiveFromDateKey'],
      ),
      dailyRateWon: serializer.fromJson<int>(json['dailyRateWon']),
      createdAtMillis: serializer.fromJson<int>(json['createdAtMillis']),
      updatedAtMillis: serializer.fromJson<int>(json['updatedAtMillis']),
      deletedAtMillis: serializer.fromJson<int?>(json['deletedAtMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'siteId': serializer.toJson<int>(siteId),
      'effectiveFromDateKey': serializer.toJson<int>(effectiveFromDateKey),
      'dailyRateWon': serializer.toJson<int>(dailyRateWon),
      'createdAtMillis': serializer.toJson<int>(createdAtMillis),
      'updatedAtMillis': serializer.toJson<int>(updatedAtMillis),
      'deletedAtMillis': serializer.toJson<int?>(deletedAtMillis),
    };
  }

  SiteRateHistory copyWith({
    int? id,
    String? uid,
    int? siteId,
    int? effectiveFromDateKey,
    int? dailyRateWon,
    int? createdAtMillis,
    int? updatedAtMillis,
    Value<int?> deletedAtMillis = const Value.absent(),
  }) => SiteRateHistory(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    siteId: siteId ?? this.siteId,
    effectiveFromDateKey: effectiveFromDateKey ?? this.effectiveFromDateKey,
    dailyRateWon: dailyRateWon ?? this.dailyRateWon,
    createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    deletedAtMillis: deletedAtMillis.present
        ? deletedAtMillis.value
        : this.deletedAtMillis,
  );
  SiteRateHistory copyWithCompanion(SiteRateHistoriesCompanion data) {
    return SiteRateHistory(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      effectiveFromDateKey: data.effectiveFromDateKey.present
          ? data.effectiveFromDateKey.value
          : this.effectiveFromDateKey,
      dailyRateWon: data.dailyRateWon.present
          ? data.dailyRateWon.value
          : this.dailyRateWon,
      createdAtMillis: data.createdAtMillis.present
          ? data.createdAtMillis.value
          : this.createdAtMillis,
      updatedAtMillis: data.updatedAtMillis.present
          ? data.updatedAtMillis.value
          : this.updatedAtMillis,
      deletedAtMillis: data.deletedAtMillis.present
          ? data.deletedAtMillis.value
          : this.deletedAtMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SiteRateHistory(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('siteId: $siteId, ')
          ..write('effectiveFromDateKey: $effectiveFromDateKey, ')
          ..write('dailyRateWon: $dailyRateWon, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis, ')
          ..write('deletedAtMillis: $deletedAtMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    siteId,
    effectiveFromDateKey,
    dailyRateWon,
    createdAtMillis,
    updatedAtMillis,
    deletedAtMillis,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SiteRateHistory &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.siteId == this.siteId &&
          other.effectiveFromDateKey == this.effectiveFromDateKey &&
          other.dailyRateWon == this.dailyRateWon &&
          other.createdAtMillis == this.createdAtMillis &&
          other.updatedAtMillis == this.updatedAtMillis &&
          other.deletedAtMillis == this.deletedAtMillis);
}

class SiteRateHistoriesCompanion extends UpdateCompanion<SiteRateHistory> {
  final Value<int> id;
  final Value<String> uid;
  final Value<int> siteId;
  final Value<int> effectiveFromDateKey;
  final Value<int> dailyRateWon;
  final Value<int> createdAtMillis;
  final Value<int> updatedAtMillis;
  final Value<int?> deletedAtMillis;
  const SiteRateHistoriesCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.siteId = const Value.absent(),
    this.effectiveFromDateKey = const Value.absent(),
    this.dailyRateWon = const Value.absent(),
    this.createdAtMillis = const Value.absent(),
    this.updatedAtMillis = const Value.absent(),
    this.deletedAtMillis = const Value.absent(),
  });
  SiteRateHistoriesCompanion.insert({
    this.id = const Value.absent(),
    required String uid,
    required int siteId,
    required int effectiveFromDateKey,
    required int dailyRateWon,
    required int createdAtMillis,
    required int updatedAtMillis,
    this.deletedAtMillis = const Value.absent(),
  }) : uid = Value(uid),
       siteId = Value(siteId),
       effectiveFromDateKey = Value(effectiveFromDateKey),
       dailyRateWon = Value(dailyRateWon),
       createdAtMillis = Value(createdAtMillis),
       updatedAtMillis = Value(updatedAtMillis);
  static Insertable<SiteRateHistory> custom({
    Expression<int>? id,
    Expression<String>? uid,
    Expression<int>? siteId,
    Expression<int>? effectiveFromDateKey,
    Expression<int>? dailyRateWon,
    Expression<int>? createdAtMillis,
    Expression<int>? updatedAtMillis,
    Expression<int>? deletedAtMillis,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (siteId != null) 'site_id': siteId,
      if (effectiveFromDateKey != null)
        'effective_from_date_key': effectiveFromDateKey,
      if (dailyRateWon != null) 'daily_rate_won': dailyRateWon,
      if (createdAtMillis != null) 'created_at_millis': createdAtMillis,
      if (updatedAtMillis != null) 'updated_at_millis': updatedAtMillis,
      if (deletedAtMillis != null) 'deleted_at_millis': deletedAtMillis,
    });
  }

  SiteRateHistoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? uid,
    Value<int>? siteId,
    Value<int>? effectiveFromDateKey,
    Value<int>? dailyRateWon,
    Value<int>? createdAtMillis,
    Value<int>? updatedAtMillis,
    Value<int?>? deletedAtMillis,
  }) {
    return SiteRateHistoriesCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      siteId: siteId ?? this.siteId,
      effectiveFromDateKey: effectiveFromDateKey ?? this.effectiveFromDateKey,
      dailyRateWon: dailyRateWon ?? this.dailyRateWon,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
      deletedAtMillis: deletedAtMillis ?? this.deletedAtMillis,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<int>(siteId.value);
    }
    if (effectiveFromDateKey.present) {
      map['effective_from_date_key'] = Variable<int>(
        effectiveFromDateKey.value,
      );
    }
    if (dailyRateWon.present) {
      map['daily_rate_won'] = Variable<int>(dailyRateWon.value);
    }
    if (createdAtMillis.present) {
      map['created_at_millis'] = Variable<int>(createdAtMillis.value);
    }
    if (updatedAtMillis.present) {
      map['updated_at_millis'] = Variable<int>(updatedAtMillis.value);
    }
    if (deletedAtMillis.present) {
      map['deleted_at_millis'] = Variable<int>(deletedAtMillis.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SiteRateHistoriesCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('siteId: $siteId, ')
          ..write('effectiveFromDateKey: $effectiveFromDateKey, ')
          ..write('dailyRateWon: $dailyRateWon, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis, ')
          ..write('deletedAtMillis: $deletedAtMillis')
          ..write(')'))
        .toString();
  }
}

class $DayExtraItemsTable extends DayExtraItems
    with TableInfo<$DayExtraItemsTable, DayExtraItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayExtraItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _dateKeyMeta = const VerificationMeta(
    'dateKey',
  );
  @override
  late final GeneratedColumn<int> dateKey = GeneratedColumn<int>(
    'date_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<int> siteId = GeneratedColumn<int>(
    'site_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountWonMeta = const VerificationMeta(
    'amountWon',
  );
  @override
  late final GeneratedColumn<int> amountWon = GeneratedColumn<int>(
    'amount_won',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isTaxableMeta = const VerificationMeta(
    'isTaxable',
  );
  @override
  late final GeneratedColumn<bool> isTaxable = GeneratedColumn<bool>(
    'is_taxable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_taxable" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMillisMeta = const VerificationMeta(
    'createdAtMillis',
  );
  @override
  late final GeneratedColumn<int> createdAtMillis = GeneratedColumn<int>(
    'created_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMillisMeta = const VerificationMeta(
    'updatedAtMillis',
  );
  @override
  late final GeneratedColumn<int> updatedAtMillis = GeneratedColumn<int>(
    'updated_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMillisMeta = const VerificationMeta(
    'deletedAtMillis',
  );
  @override
  late final GeneratedColumn<int> deletedAtMillis = GeneratedColumn<int>(
    'deleted_at_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uid,
    dateKey,
    siteId,
    kind,
    label,
    amountWon,
    isTaxable,
    createdAtMillis,
    updatedAtMillis,
    deletedAtMillis,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_extra_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayExtraItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('date_key')) {
      context.handle(
        _dateKeyMeta,
        dateKey.isAcceptableOrUnknown(data['date_key']!, _dateKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dateKeyMeta);
    }
    if (data.containsKey('site_id')) {
      context.handle(
        _siteIdMeta,
        siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('amount_won')) {
      context.handle(
        _amountWonMeta,
        amountWon.isAcceptableOrUnknown(data['amount_won']!, _amountWonMeta),
      );
    } else if (isInserting) {
      context.missing(_amountWonMeta);
    }
    if (data.containsKey('is_taxable')) {
      context.handle(
        _isTaxableMeta,
        isTaxable.isAcceptableOrUnknown(data['is_taxable']!, _isTaxableMeta),
      );
    }
    if (data.containsKey('created_at_millis')) {
      context.handle(
        _createdAtMillisMeta,
        createdAtMillis.isAcceptableOrUnknown(
          data['created_at_millis']!,
          _createdAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMillisMeta);
    }
    if (data.containsKey('updated_at_millis')) {
      context.handle(
        _updatedAtMillisMeta,
        updatedAtMillis.isAcceptableOrUnknown(
          data['updated_at_millis']!,
          _updatedAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMillisMeta);
    }
    if (data.containsKey('deleted_at_millis')) {
      context.handle(
        _deletedAtMillisMeta,
        deletedAtMillis.isAcceptableOrUnknown(
          data['deleted_at_millis']!,
          _deletedAtMillisMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DayExtraItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayExtraItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      dateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_key'],
      )!,
      siteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}site_id'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      amountWon: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_won'],
      )!,
      isTaxable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_taxable'],
      )!,
      createdAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_millis'],
      )!,
      updatedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_millis'],
      )!,
      deletedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_millis'],
      ),
    );
  }

  @override
  $DayExtraItemsTable createAlias(String alias) {
    return $DayExtraItemsTable(attachedDatabase, alias);
  }
}

class DayExtraItem extends DataClass implements Insertable<DayExtraItem> {
  final int id;
  final String uid;
  final int dateKey;

  /// 업체 귀속. NULL = 업체 무관.
  final int? siteId;

  /// 'allowance'(가산) | 'deduction'(차감). enum ordinal이 아닌 안정된 문자열.
  final String kind;
  final String label;
  final int amountWon;

  /// M3 예약: 세금 계산에 포함할지. 기본 false(일비/식비는 통상 비과세).
  final bool isTaxable;
  final int createdAtMillis;
  final int updatedAtMillis;
  final int? deletedAtMillis;
  const DayExtraItem({
    required this.id,
    required this.uid,
    required this.dateKey,
    this.siteId,
    required this.kind,
    required this.label,
    required this.amountWon,
    required this.isTaxable,
    required this.createdAtMillis,
    required this.updatedAtMillis,
    this.deletedAtMillis,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<String>(uid);
    map['date_key'] = Variable<int>(dateKey);
    if (!nullToAbsent || siteId != null) {
      map['site_id'] = Variable<int>(siteId);
    }
    map['kind'] = Variable<String>(kind);
    map['label'] = Variable<String>(label);
    map['amount_won'] = Variable<int>(amountWon);
    map['is_taxable'] = Variable<bool>(isTaxable);
    map['created_at_millis'] = Variable<int>(createdAtMillis);
    map['updated_at_millis'] = Variable<int>(updatedAtMillis);
    if (!nullToAbsent || deletedAtMillis != null) {
      map['deleted_at_millis'] = Variable<int>(deletedAtMillis);
    }
    return map;
  }

  DayExtraItemsCompanion toCompanion(bool nullToAbsent) {
    return DayExtraItemsCompanion(
      id: Value(id),
      uid: Value(uid),
      dateKey: Value(dateKey),
      siteId: siteId == null && nullToAbsent
          ? const Value.absent()
          : Value(siteId),
      kind: Value(kind),
      label: Value(label),
      amountWon: Value(amountWon),
      isTaxable: Value(isTaxable),
      createdAtMillis: Value(createdAtMillis),
      updatedAtMillis: Value(updatedAtMillis),
      deletedAtMillis: deletedAtMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtMillis),
    );
  }

  factory DayExtraItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayExtraItem(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      dateKey: serializer.fromJson<int>(json['dateKey']),
      siteId: serializer.fromJson<int?>(json['siteId']),
      kind: serializer.fromJson<String>(json['kind']),
      label: serializer.fromJson<String>(json['label']),
      amountWon: serializer.fromJson<int>(json['amountWon']),
      isTaxable: serializer.fromJson<bool>(json['isTaxable']),
      createdAtMillis: serializer.fromJson<int>(json['createdAtMillis']),
      updatedAtMillis: serializer.fromJson<int>(json['updatedAtMillis']),
      deletedAtMillis: serializer.fromJson<int?>(json['deletedAtMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'dateKey': serializer.toJson<int>(dateKey),
      'siteId': serializer.toJson<int?>(siteId),
      'kind': serializer.toJson<String>(kind),
      'label': serializer.toJson<String>(label),
      'amountWon': serializer.toJson<int>(amountWon),
      'isTaxable': serializer.toJson<bool>(isTaxable),
      'createdAtMillis': serializer.toJson<int>(createdAtMillis),
      'updatedAtMillis': serializer.toJson<int>(updatedAtMillis),
      'deletedAtMillis': serializer.toJson<int?>(deletedAtMillis),
    };
  }

  DayExtraItem copyWith({
    int? id,
    String? uid,
    int? dateKey,
    Value<int?> siteId = const Value.absent(),
    String? kind,
    String? label,
    int? amountWon,
    bool? isTaxable,
    int? createdAtMillis,
    int? updatedAtMillis,
    Value<int?> deletedAtMillis = const Value.absent(),
  }) => DayExtraItem(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    dateKey: dateKey ?? this.dateKey,
    siteId: siteId.present ? siteId.value : this.siteId,
    kind: kind ?? this.kind,
    label: label ?? this.label,
    amountWon: amountWon ?? this.amountWon,
    isTaxable: isTaxable ?? this.isTaxable,
    createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    deletedAtMillis: deletedAtMillis.present
        ? deletedAtMillis.value
        : this.deletedAtMillis,
  );
  DayExtraItem copyWithCompanion(DayExtraItemsCompanion data) {
    return DayExtraItem(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      dateKey: data.dateKey.present ? data.dateKey.value : this.dateKey,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      kind: data.kind.present ? data.kind.value : this.kind,
      label: data.label.present ? data.label.value : this.label,
      amountWon: data.amountWon.present ? data.amountWon.value : this.amountWon,
      isTaxable: data.isTaxable.present ? data.isTaxable.value : this.isTaxable,
      createdAtMillis: data.createdAtMillis.present
          ? data.createdAtMillis.value
          : this.createdAtMillis,
      updatedAtMillis: data.updatedAtMillis.present
          ? data.updatedAtMillis.value
          : this.updatedAtMillis,
      deletedAtMillis: data.deletedAtMillis.present
          ? data.deletedAtMillis.value
          : this.deletedAtMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayExtraItem(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('dateKey: $dateKey, ')
          ..write('siteId: $siteId, ')
          ..write('kind: $kind, ')
          ..write('label: $label, ')
          ..write('amountWon: $amountWon, ')
          ..write('isTaxable: $isTaxable, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis, ')
          ..write('deletedAtMillis: $deletedAtMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    dateKey,
    siteId,
    kind,
    label,
    amountWon,
    isTaxable,
    createdAtMillis,
    updatedAtMillis,
    deletedAtMillis,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayExtraItem &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.dateKey == this.dateKey &&
          other.siteId == this.siteId &&
          other.kind == this.kind &&
          other.label == this.label &&
          other.amountWon == this.amountWon &&
          other.isTaxable == this.isTaxable &&
          other.createdAtMillis == this.createdAtMillis &&
          other.updatedAtMillis == this.updatedAtMillis &&
          other.deletedAtMillis == this.deletedAtMillis);
}

class DayExtraItemsCompanion extends UpdateCompanion<DayExtraItem> {
  final Value<int> id;
  final Value<String> uid;
  final Value<int> dateKey;
  final Value<int?> siteId;
  final Value<String> kind;
  final Value<String> label;
  final Value<int> amountWon;
  final Value<bool> isTaxable;
  final Value<int> createdAtMillis;
  final Value<int> updatedAtMillis;
  final Value<int?> deletedAtMillis;
  const DayExtraItemsCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.dateKey = const Value.absent(),
    this.siteId = const Value.absent(),
    this.kind = const Value.absent(),
    this.label = const Value.absent(),
    this.amountWon = const Value.absent(),
    this.isTaxable = const Value.absent(),
    this.createdAtMillis = const Value.absent(),
    this.updatedAtMillis = const Value.absent(),
    this.deletedAtMillis = const Value.absent(),
  });
  DayExtraItemsCompanion.insert({
    this.id = const Value.absent(),
    required String uid,
    required int dateKey,
    this.siteId = const Value.absent(),
    required String kind,
    required String label,
    required int amountWon,
    this.isTaxable = const Value.absent(),
    required int createdAtMillis,
    required int updatedAtMillis,
    this.deletedAtMillis = const Value.absent(),
  }) : uid = Value(uid),
       dateKey = Value(dateKey),
       kind = Value(kind),
       label = Value(label),
       amountWon = Value(amountWon),
       createdAtMillis = Value(createdAtMillis),
       updatedAtMillis = Value(updatedAtMillis);
  static Insertable<DayExtraItem> custom({
    Expression<int>? id,
    Expression<String>? uid,
    Expression<int>? dateKey,
    Expression<int>? siteId,
    Expression<String>? kind,
    Expression<String>? label,
    Expression<int>? amountWon,
    Expression<bool>? isTaxable,
    Expression<int>? createdAtMillis,
    Expression<int>? updatedAtMillis,
    Expression<int>? deletedAtMillis,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (dateKey != null) 'date_key': dateKey,
      if (siteId != null) 'site_id': siteId,
      if (kind != null) 'kind': kind,
      if (label != null) 'label': label,
      if (amountWon != null) 'amount_won': amountWon,
      if (isTaxable != null) 'is_taxable': isTaxable,
      if (createdAtMillis != null) 'created_at_millis': createdAtMillis,
      if (updatedAtMillis != null) 'updated_at_millis': updatedAtMillis,
      if (deletedAtMillis != null) 'deleted_at_millis': deletedAtMillis,
    });
  }

  DayExtraItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? uid,
    Value<int>? dateKey,
    Value<int?>? siteId,
    Value<String>? kind,
    Value<String>? label,
    Value<int>? amountWon,
    Value<bool>? isTaxable,
    Value<int>? createdAtMillis,
    Value<int>? updatedAtMillis,
    Value<int?>? deletedAtMillis,
  }) {
    return DayExtraItemsCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      dateKey: dateKey ?? this.dateKey,
      siteId: siteId ?? this.siteId,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      amountWon: amountWon ?? this.amountWon,
      isTaxable: isTaxable ?? this.isTaxable,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
      deletedAtMillis: deletedAtMillis ?? this.deletedAtMillis,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (dateKey.present) {
      map['date_key'] = Variable<int>(dateKey.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<int>(siteId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (amountWon.present) {
      map['amount_won'] = Variable<int>(amountWon.value);
    }
    if (isTaxable.present) {
      map['is_taxable'] = Variable<bool>(isTaxable.value);
    }
    if (createdAtMillis.present) {
      map['created_at_millis'] = Variable<int>(createdAtMillis.value);
    }
    if (updatedAtMillis.present) {
      map['updated_at_millis'] = Variable<int>(updatedAtMillis.value);
    }
    if (deletedAtMillis.present) {
      map['deleted_at_millis'] = Variable<int>(deletedAtMillis.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayExtraItemsCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('dateKey: $dateKey, ')
          ..write('siteId: $siteId, ')
          ..write('kind: $kind, ')
          ..write('label: $label, ')
          ..write('amountWon: $amountWon, ')
          ..write('isTaxable: $isTaxable, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis, ')
          ..write('deletedAtMillis: $deletedAtMillis')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WorkEntriesTable workEntries = $WorkEntriesTable(this);
  late final $PresetsTable presets = $PresetsTable(this);
  late final $DayMemosTable dayMemos = $DayMemosTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $SitesTable sites = $SitesTable(this);
  late final $SiteRateHistoriesTable siteRateHistories =
      $SiteRateHistoriesTable(this);
  late final $DayExtraItemsTable dayExtraItems = $DayExtraItemsTable(this);
  late final Index idxWorkEntriesDate = Index(
    'idx_work_entries_date',
    'CREATE INDEX idx_work_entries_date ON work_entries (date_key)',
  );
  late final Index idxSiteRatesSiteFrom = Index(
    'idx_site_rates_site_from',
    'CREATE INDEX idx_site_rates_site_from ON site_rate_histories (site_id, effective_from_date_key)',
  );
  late final Index idxDayExtraItemsDate = Index(
    'idx_day_extra_items_date',
    'CREATE INDEX idx_day_extra_items_date ON day_extra_items (date_key)',
  );
  late final WorkEntryDao workEntryDao = WorkEntryDao(this as AppDatabase);
  late final PresetDao presetDao = PresetDao(this as AppDatabase);
  late final MemoDao memoDao = MemoDao(this as AppDatabase);
  late final SiteDao siteDao = SiteDao(this as AppDatabase);
  late final DayItemDao dayItemDao = DayItemDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    workEntries,
    presets,
    dayMemos,
    appSettings,
    sites,
    siteRateHistories,
    dayExtraItems,
    idxWorkEntriesDate,
    idxSiteRatesSiteFrom,
    idxDayExtraItemsDate,
  ];
}

typedef $$WorkEntriesTableCreateCompanionBuilder =
    WorkEntriesCompanion Function({
      Value<int> id,
      required String uid,
      required int dateKey,
      required int centiGongsu,
      Value<int?> presetId,
      Value<String> labelSnapshot,
      Value<int> colorIdSnapshot,
      Value<int?> siteId,
      Value<int?> unitRateWonOverride,
      required int createdAtMillis,
      required int updatedAtMillis,
      Value<int?> deletedAtMillis,
    });
typedef $$WorkEntriesTableUpdateCompanionBuilder =
    WorkEntriesCompanion Function({
      Value<int> id,
      Value<String> uid,
      Value<int> dateKey,
      Value<int> centiGongsu,
      Value<int?> presetId,
      Value<String> labelSnapshot,
      Value<int> colorIdSnapshot,
      Value<int?> siteId,
      Value<int?> unitRateWonOverride,
      Value<int> createdAtMillis,
      Value<int> updatedAtMillis,
      Value<int?> deletedAtMillis,
    });

class $$WorkEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkEntriesTable> {
  $$WorkEntriesTableFilterComposer({
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

  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get centiGongsu => $composableBuilder(
    column: $table.centiGongsu,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get presetId => $composableBuilder(
    column: $table.presetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labelSnapshot => $composableBuilder(
    column: $table.labelSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorIdSnapshot => $composableBuilder(
    column: $table.colorIdSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitRateWonOverride => $composableBuilder(
    column: $table.unitRateWonOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtMillis => $composableBuilder(
    column: $table.deletedAtMillis,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkEntriesTable> {
  $$WorkEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get centiGongsu => $composableBuilder(
    column: $table.centiGongsu,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get presetId => $composableBuilder(
    column: $table.presetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labelSnapshot => $composableBuilder(
    column: $table.labelSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorIdSnapshot => $composableBuilder(
    column: $table.colorIdSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitRateWonOverride => $composableBuilder(
    column: $table.unitRateWonOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtMillis => $composableBuilder(
    column: $table.deletedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkEntriesTable> {
  $$WorkEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<int> get dateKey =>
      $composableBuilder(column: $table.dateKey, builder: (column) => column);

  GeneratedColumn<int> get centiGongsu => $composableBuilder(
    column: $table.centiGongsu,
    builder: (column) => column,
  );

  GeneratedColumn<int> get presetId =>
      $composableBuilder(column: $table.presetId, builder: (column) => column);

  GeneratedColumn<String> get labelSnapshot => $composableBuilder(
    column: $table.labelSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get colorIdSnapshot => $composableBuilder(
    column: $table.colorIdSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get siteId =>
      $composableBuilder(column: $table.siteId, builder: (column) => column);

  GeneratedColumn<int> get unitRateWonOverride => $composableBuilder(
    column: $table.unitRateWonOverride,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAtMillis => $composableBuilder(
    column: $table.deletedAtMillis,
    builder: (column) => column,
  );
}

class $$WorkEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkEntriesTable,
          WorkEntry,
          $$WorkEntriesTableFilterComposer,
          $$WorkEntriesTableOrderingComposer,
          $$WorkEntriesTableAnnotationComposer,
          $$WorkEntriesTableCreateCompanionBuilder,
          $$WorkEntriesTableUpdateCompanionBuilder,
          (
            WorkEntry,
            BaseReferences<_$AppDatabase, $WorkEntriesTable, WorkEntry>,
          ),
          WorkEntry,
          PrefetchHooks Function()
        > {
  $$WorkEntriesTableTableManager(_$AppDatabase db, $WorkEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<int> dateKey = const Value.absent(),
                Value<int> centiGongsu = const Value.absent(),
                Value<int?> presetId = const Value.absent(),
                Value<String> labelSnapshot = const Value.absent(),
                Value<int> colorIdSnapshot = const Value.absent(),
                Value<int?> siteId = const Value.absent(),
                Value<int?> unitRateWonOverride = const Value.absent(),
                Value<int> createdAtMillis = const Value.absent(),
                Value<int> updatedAtMillis = const Value.absent(),
                Value<int?> deletedAtMillis = const Value.absent(),
              }) => WorkEntriesCompanion(
                id: id,
                uid: uid,
                dateKey: dateKey,
                centiGongsu: centiGongsu,
                presetId: presetId,
                labelSnapshot: labelSnapshot,
                colorIdSnapshot: colorIdSnapshot,
                siteId: siteId,
                unitRateWonOverride: unitRateWonOverride,
                createdAtMillis: createdAtMillis,
                updatedAtMillis: updatedAtMillis,
                deletedAtMillis: deletedAtMillis,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uid,
                required int dateKey,
                required int centiGongsu,
                Value<int?> presetId = const Value.absent(),
                Value<String> labelSnapshot = const Value.absent(),
                Value<int> colorIdSnapshot = const Value.absent(),
                Value<int?> siteId = const Value.absent(),
                Value<int?> unitRateWonOverride = const Value.absent(),
                required int createdAtMillis,
                required int updatedAtMillis,
                Value<int?> deletedAtMillis = const Value.absent(),
              }) => WorkEntriesCompanion.insert(
                id: id,
                uid: uid,
                dateKey: dateKey,
                centiGongsu: centiGongsu,
                presetId: presetId,
                labelSnapshot: labelSnapshot,
                colorIdSnapshot: colorIdSnapshot,
                siteId: siteId,
                unitRateWonOverride: unitRateWonOverride,
                createdAtMillis: createdAtMillis,
                updatedAtMillis: updatedAtMillis,
                deletedAtMillis: deletedAtMillis,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkEntriesTable,
      WorkEntry,
      $$WorkEntriesTableFilterComposer,
      $$WorkEntriesTableOrderingComposer,
      $$WorkEntriesTableAnnotationComposer,
      $$WorkEntriesTableCreateCompanionBuilder,
      $$WorkEntriesTableUpdateCompanionBuilder,
      (WorkEntry, BaseReferences<_$AppDatabase, $WorkEntriesTable, WorkEntry>),
      WorkEntry,
      PrefetchHooks Function()
    >;
typedef $$PresetsTableCreateCompanionBuilder = PresetsCompanion Function({
  Value<int> id,
  required String uid,
  required String name,
  required int centiGongsu,
  Value<int> colorId,
  required int sortOrder,
  Value<bool> isArchived,
  required int createdAtMillis,
  required int updatedAtMillis,
});
typedef $$PresetsTableUpdateCompanionBuilder = PresetsCompanion Function({
  Value<int> id,
  Value<String> uid,
  Value<String> name,
  Value<int> centiGongsu,
  Value<int> colorId,
  Value<int> sortOrder,
  Value<bool> isArchived,
  Value<int> createdAtMillis,
  Value<int> updatedAtMillis,
});

class $$PresetsTableFilterComposer
    extends Composer<_$AppDatabase, $PresetsTable> {
  $$PresetsTableFilterComposer({
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

  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get centiGongsu => $composableBuilder(
    column: $table.centiGongsu,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorId => $composableBuilder(
    column: $table.colorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PresetsTableOrderingComposer
    extends Composer<_$AppDatabase, $PresetsTable> {
  $$PresetsTableOrderingComposer({
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

  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get centiGongsu => $composableBuilder(
    column: $table.centiGongsu,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorId => $composableBuilder(
    column: $table.colorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PresetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PresetsTable> {
  $$PresetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get centiGongsu => $composableBuilder(
    column: $table.centiGongsu,
    builder: (column) => column,
  );

  GeneratedColumn<int> get colorId =>
      $composableBuilder(column: $table.colorId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => column,
  );
}

class $$PresetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PresetsTable,
          Preset,
          $$PresetsTableFilterComposer,
          $$PresetsTableOrderingComposer,
          $$PresetsTableAnnotationComposer,
          $$PresetsTableCreateCompanionBuilder,
          $$PresetsTableUpdateCompanionBuilder,
          (Preset, BaseReferences<_$AppDatabase, $PresetsTable, Preset>),
          Preset,
          PrefetchHooks Function()
        > {
  $$PresetsTableTableManager(_$AppDatabase db, $PresetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PresetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PresetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PresetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> centiGongsu = const Value.absent(),
                Value<int> colorId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> createdAtMillis = const Value.absent(),
                Value<int> updatedAtMillis = const Value.absent(),
              }) => PresetsCompanion(
                id: id,
                uid: uid,
                name: name,
                centiGongsu: centiGongsu,
                colorId: colorId,
                sortOrder: sortOrder,
                isArchived: isArchived,
                createdAtMillis: createdAtMillis,
                updatedAtMillis: updatedAtMillis,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uid,
                required String name,
                required int centiGongsu,
                Value<int> colorId = const Value.absent(),
                required int sortOrder,
                Value<bool> isArchived = const Value.absent(),
                required int createdAtMillis,
                required int updatedAtMillis,
              }) => PresetsCompanion.insert(
                id: id,
                uid: uid,
                name: name,
                centiGongsu: centiGongsu,
                colorId: colorId,
                sortOrder: sortOrder,
                isArchived: isArchived,
                createdAtMillis: createdAtMillis,
                updatedAtMillis: updatedAtMillis,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PresetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PresetsTable,
      Preset,
      $$PresetsTableFilterComposer,
      $$PresetsTableOrderingComposer,
      $$PresetsTableAnnotationComposer,
      $$PresetsTableCreateCompanionBuilder,
      $$PresetsTableUpdateCompanionBuilder,
      (Preset, BaseReferences<_$AppDatabase, $PresetsTable, Preset>),
      Preset,
      PrefetchHooks Function()
    >;
typedef $$DayMemosTableCreateCompanionBuilder = DayMemosCompanion Function({
  Value<int> dateKey,
  required String body,
  required int updatedAtMillis,
});
typedef $$DayMemosTableUpdateCompanionBuilder = DayMemosCompanion Function({
  Value<int> dateKey,
  Value<String> body,
  Value<int> updatedAtMillis,
});

class $$DayMemosTableFilterComposer
    extends Composer<_$AppDatabase, $DayMemosTable> {
  $$DayMemosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayMemosTableOrderingComposer
    extends Composer<_$AppDatabase, $DayMemosTable> {
  $$DayMemosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayMemosTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayMemosTable> {
  $$DayMemosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get dateKey =>
      $composableBuilder(column: $table.dateKey, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => column,
  );
}

class $$DayMemosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayMemosTable,
          DayMemo,
          $$DayMemosTableFilterComposer,
          $$DayMemosTableOrderingComposer,
          $$DayMemosTableAnnotationComposer,
          $$DayMemosTableCreateCompanionBuilder,
          $$DayMemosTableUpdateCompanionBuilder,
          (DayMemo, BaseReferences<_$AppDatabase, $DayMemosTable, DayMemo>),
          DayMemo,
          PrefetchHooks Function()
        > {
  $$DayMemosTableTableManager(_$AppDatabase db, $DayMemosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayMemosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayMemosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayMemosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> dateKey = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> updatedAtMillis = const Value.absent(),
              }) => DayMemosCompanion(
                dateKey: dateKey,
                body: body,
                updatedAtMillis: updatedAtMillis,
              ),
          createCompanionCallback:
              ({
                Value<int> dateKey = const Value.absent(),
                required String body,
                required int updatedAtMillis,
              }) => DayMemosCompanion.insert(
                dateKey: dateKey,
                body: body,
                updatedAtMillis: updatedAtMillis,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayMemosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayMemosTable,
      DayMemo,
      $$DayMemosTableFilterComposer,
      $$DayMemosTableOrderingComposer,
      $$DayMemosTableAnnotationComposer,
      $$DayMemosTableCreateCompanionBuilder,
      $$DayMemosTableUpdateCompanionBuilder,
      (DayMemo, BaseReferences<_$AppDatabase, $DayMemosTable, DayMemo>),
      DayMemo,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
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
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
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
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
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
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$SitesTableCreateCompanionBuilder = SitesCompanion Function({
  Value<int> id,
  required String uid,
  required String name,
  Value<int> colorId,
  required int sortOrder,
  Value<bool> isArchived,
  required int createdAtMillis,
  required int updatedAtMillis,
  Value<String> taxMode,
  Value<String?> taxOptionsJson,
});
typedef $$SitesTableUpdateCompanionBuilder = SitesCompanion Function({
  Value<int> id,
  Value<String> uid,
  Value<String> name,
  Value<int> colorId,
  Value<int> sortOrder,
  Value<bool> isArchived,
  Value<int> createdAtMillis,
  Value<int> updatedAtMillis,
  Value<String> taxMode,
  Value<String?> taxOptionsJson,
});

class $$SitesTableFilterComposer extends Composer<_$AppDatabase, $SitesTable> {
  $$SitesTableFilterComposer({
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

  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorId => $composableBuilder(
    column: $table.colorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxMode => $composableBuilder(
    column: $table.taxMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxOptionsJson => $composableBuilder(
    column: $table.taxOptionsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SitesTableOrderingComposer
    extends Composer<_$AppDatabase, $SitesTable> {
  $$SitesTableOrderingComposer({
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

  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorId => $composableBuilder(
    column: $table.colorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxMode => $composableBuilder(
    column: $table.taxMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxOptionsJson => $composableBuilder(
    column: $table.taxOptionsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SitesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SitesTable> {
  $$SitesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get colorId =>
      $composableBuilder(column: $table.colorId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taxMode =>
      $composableBuilder(column: $table.taxMode, builder: (column) => column);

  GeneratedColumn<String> get taxOptionsJson => $composableBuilder(
    column: $table.taxOptionsJson,
    builder: (column) => column,
  );
}

class $$SitesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SitesTable,
          Site,
          $$SitesTableFilterComposer,
          $$SitesTableOrderingComposer,
          $$SitesTableAnnotationComposer,
          $$SitesTableCreateCompanionBuilder,
          $$SitesTableUpdateCompanionBuilder,
          (Site, BaseReferences<_$AppDatabase, $SitesTable, Site>),
          Site,
          PrefetchHooks Function()
        > {
  $$SitesTableTableManager(_$AppDatabase db, $SitesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SitesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SitesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SitesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> colorId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> createdAtMillis = const Value.absent(),
                Value<int> updatedAtMillis = const Value.absent(),
                Value<String> taxMode = const Value.absent(),
                Value<String?> taxOptionsJson = const Value.absent(),
              }) => SitesCompanion(
                id: id,
                uid: uid,
                name: name,
                colorId: colorId,
                sortOrder: sortOrder,
                isArchived: isArchived,
                createdAtMillis: createdAtMillis,
                updatedAtMillis: updatedAtMillis,
                taxMode: taxMode,
                taxOptionsJson: taxOptionsJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uid,
                required String name,
                Value<int> colorId = const Value.absent(),
                required int sortOrder,
                Value<bool> isArchived = const Value.absent(),
                required int createdAtMillis,
                required int updatedAtMillis,
                Value<String> taxMode = const Value.absent(),
                Value<String?> taxOptionsJson = const Value.absent(),
              }) => SitesCompanion.insert(
                id: id,
                uid: uid,
                name: name,
                colorId: colorId,
                sortOrder: sortOrder,
                isArchived: isArchived,
                createdAtMillis: createdAtMillis,
                updatedAtMillis: updatedAtMillis,
                taxMode: taxMode,
                taxOptionsJson: taxOptionsJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SitesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SitesTable,
      Site,
      $$SitesTableFilterComposer,
      $$SitesTableOrderingComposer,
      $$SitesTableAnnotationComposer,
      $$SitesTableCreateCompanionBuilder,
      $$SitesTableUpdateCompanionBuilder,
      (Site, BaseReferences<_$AppDatabase, $SitesTable, Site>),
      Site,
      PrefetchHooks Function()
    >;
typedef $$SiteRateHistoriesTableCreateCompanionBuilder =
    SiteRateHistoriesCompanion Function({
      Value<int> id,
      required String uid,
      required int siteId,
      required int effectiveFromDateKey,
      required int dailyRateWon,
      required int createdAtMillis,
      required int updatedAtMillis,
      Value<int?> deletedAtMillis,
    });
typedef $$SiteRateHistoriesTableUpdateCompanionBuilder =
    SiteRateHistoriesCompanion Function({
      Value<int> id,
      Value<String> uid,
      Value<int> siteId,
      Value<int> effectiveFromDateKey,
      Value<int> dailyRateWon,
      Value<int> createdAtMillis,
      Value<int> updatedAtMillis,
      Value<int?> deletedAtMillis,
    });

class $$SiteRateHistoriesTableFilterComposer
    extends Composer<_$AppDatabase, $SiteRateHistoriesTable> {
  $$SiteRateHistoriesTableFilterComposer({
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

  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get effectiveFromDateKey => $composableBuilder(
    column: $table.effectiveFromDateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyRateWon => $composableBuilder(
    column: $table.dailyRateWon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtMillis => $composableBuilder(
    column: $table.deletedAtMillis,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SiteRateHistoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SiteRateHistoriesTable> {
  $$SiteRateHistoriesTableOrderingComposer({
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

  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get effectiveFromDateKey => $composableBuilder(
    column: $table.effectiveFromDateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyRateWon => $composableBuilder(
    column: $table.dailyRateWon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtMillis => $composableBuilder(
    column: $table.deletedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SiteRateHistoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SiteRateHistoriesTable> {
  $$SiteRateHistoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<int> get siteId =>
      $composableBuilder(column: $table.siteId, builder: (column) => column);

  GeneratedColumn<int> get effectiveFromDateKey => $composableBuilder(
    column: $table.effectiveFromDateKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyRateWon => $composableBuilder(
    column: $table.dailyRateWon,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAtMillis => $composableBuilder(
    column: $table.deletedAtMillis,
    builder: (column) => column,
  );
}

class $$SiteRateHistoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SiteRateHistoriesTable,
          SiteRateHistory,
          $$SiteRateHistoriesTableFilterComposer,
          $$SiteRateHistoriesTableOrderingComposer,
          $$SiteRateHistoriesTableAnnotationComposer,
          $$SiteRateHistoriesTableCreateCompanionBuilder,
          $$SiteRateHistoriesTableUpdateCompanionBuilder,
          (
            SiteRateHistory,
            BaseReferences<
              _$AppDatabase,
              $SiteRateHistoriesTable,
              SiteRateHistory
            >,
          ),
          SiteRateHistory,
          PrefetchHooks Function()
        > {
  $$SiteRateHistoriesTableTableManager(
    _$AppDatabase db,
    $SiteRateHistoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SiteRateHistoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SiteRateHistoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SiteRateHistoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<int> siteId = const Value.absent(),
                Value<int> effectiveFromDateKey = const Value.absent(),
                Value<int> dailyRateWon = const Value.absent(),
                Value<int> createdAtMillis = const Value.absent(),
                Value<int> updatedAtMillis = const Value.absent(),
                Value<int?> deletedAtMillis = const Value.absent(),
              }) => SiteRateHistoriesCompanion(
                id: id,
                uid: uid,
                siteId: siteId,
                effectiveFromDateKey: effectiveFromDateKey,
                dailyRateWon: dailyRateWon,
                createdAtMillis: createdAtMillis,
                updatedAtMillis: updatedAtMillis,
                deletedAtMillis: deletedAtMillis,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uid,
                required int siteId,
                required int effectiveFromDateKey,
                required int dailyRateWon,
                required int createdAtMillis,
                required int updatedAtMillis,
                Value<int?> deletedAtMillis = const Value.absent(),
              }) => SiteRateHistoriesCompanion.insert(
                id: id,
                uid: uid,
                siteId: siteId,
                effectiveFromDateKey: effectiveFromDateKey,
                dailyRateWon: dailyRateWon,
                createdAtMillis: createdAtMillis,
                updatedAtMillis: updatedAtMillis,
                deletedAtMillis: deletedAtMillis,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SiteRateHistoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SiteRateHistoriesTable,
      SiteRateHistory,
      $$SiteRateHistoriesTableFilterComposer,
      $$SiteRateHistoriesTableOrderingComposer,
      $$SiteRateHistoriesTableAnnotationComposer,
      $$SiteRateHistoriesTableCreateCompanionBuilder,
      $$SiteRateHistoriesTableUpdateCompanionBuilder,
      (
        SiteRateHistory,
        BaseReferences<_$AppDatabase, $SiteRateHistoriesTable, SiteRateHistory>,
      ),
      SiteRateHistory,
      PrefetchHooks Function()
    >;
typedef $$DayExtraItemsTableCreateCompanionBuilder =
    DayExtraItemsCompanion Function({
      Value<int> id,
      required String uid,
      required int dateKey,
      Value<int?> siteId,
      required String kind,
      required String label,
      required int amountWon,
      Value<bool> isTaxable,
      required int createdAtMillis,
      required int updatedAtMillis,
      Value<int?> deletedAtMillis,
    });
typedef $$DayExtraItemsTableUpdateCompanionBuilder =
    DayExtraItemsCompanion Function({
      Value<int> id,
      Value<String> uid,
      Value<int> dateKey,
      Value<int?> siteId,
      Value<String> kind,
      Value<String> label,
      Value<int> amountWon,
      Value<bool> isTaxable,
      Value<int> createdAtMillis,
      Value<int> updatedAtMillis,
      Value<int?> deletedAtMillis,
    });

class $$DayExtraItemsTableFilterComposer
    extends Composer<_$AppDatabase, $DayExtraItemsTable> {
  $$DayExtraItemsTableFilterComposer({
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

  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountWon => $composableBuilder(
    column: $table.amountWon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTaxable => $composableBuilder(
    column: $table.isTaxable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtMillis => $composableBuilder(
    column: $table.deletedAtMillis,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayExtraItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $DayExtraItemsTable> {
  $$DayExtraItemsTableOrderingComposer({
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

  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountWon => $composableBuilder(
    column: $table.amountWon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTaxable => $composableBuilder(
    column: $table.isTaxable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtMillis => $composableBuilder(
    column: $table.deletedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayExtraItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayExtraItemsTable> {
  $$DayExtraItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<int> get dateKey =>
      $composableBuilder(column: $table.dateKey, builder: (column) => column);

  GeneratedColumn<int> get siteId =>
      $composableBuilder(column: $table.siteId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get amountWon =>
      $composableBuilder(column: $table.amountWon, builder: (column) => column);

  GeneratedColumn<bool> get isTaxable =>
      $composableBuilder(column: $table.isTaxable, builder: (column) => column);

  GeneratedColumn<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAtMillis => $composableBuilder(
    column: $table.deletedAtMillis,
    builder: (column) => column,
  );
}

class $$DayExtraItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayExtraItemsTable,
          DayExtraItem,
          $$DayExtraItemsTableFilterComposer,
          $$DayExtraItemsTableOrderingComposer,
          $$DayExtraItemsTableAnnotationComposer,
          $$DayExtraItemsTableCreateCompanionBuilder,
          $$DayExtraItemsTableUpdateCompanionBuilder,
          (
            DayExtraItem,
            BaseReferences<_$AppDatabase, $DayExtraItemsTable, DayExtraItem>,
          ),
          DayExtraItem,
          PrefetchHooks Function()
        > {
  $$DayExtraItemsTableTableManager(_$AppDatabase db, $DayExtraItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayExtraItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayExtraItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayExtraItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<int> dateKey = const Value.absent(),
                Value<int?> siteId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> amountWon = const Value.absent(),
                Value<bool> isTaxable = const Value.absent(),
                Value<int> createdAtMillis = const Value.absent(),
                Value<int> updatedAtMillis = const Value.absent(),
                Value<int?> deletedAtMillis = const Value.absent(),
              }) => DayExtraItemsCompanion(
                id: id,
                uid: uid,
                dateKey: dateKey,
                siteId: siteId,
                kind: kind,
                label: label,
                amountWon: amountWon,
                isTaxable: isTaxable,
                createdAtMillis: createdAtMillis,
                updatedAtMillis: updatedAtMillis,
                deletedAtMillis: deletedAtMillis,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uid,
                required int dateKey,
                Value<int?> siteId = const Value.absent(),
                required String kind,
                required String label,
                required int amountWon,
                Value<bool> isTaxable = const Value.absent(),
                required int createdAtMillis,
                required int updatedAtMillis,
                Value<int?> deletedAtMillis = const Value.absent(),
              }) => DayExtraItemsCompanion.insert(
                id: id,
                uid: uid,
                dateKey: dateKey,
                siteId: siteId,
                kind: kind,
                label: label,
                amountWon: amountWon,
                isTaxable: isTaxable,
                createdAtMillis: createdAtMillis,
                updatedAtMillis: updatedAtMillis,
                deletedAtMillis: deletedAtMillis,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayExtraItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayExtraItemsTable,
      DayExtraItem,
      $$DayExtraItemsTableFilterComposer,
      $$DayExtraItemsTableOrderingComposer,
      $$DayExtraItemsTableAnnotationComposer,
      $$DayExtraItemsTableCreateCompanionBuilder,
      $$DayExtraItemsTableUpdateCompanionBuilder,
      (
        DayExtraItem,
        BaseReferences<_$AppDatabase, $DayExtraItemsTable, DayExtraItem>,
      ),
      DayExtraItem,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WorkEntriesTableTableManager get workEntries =>
      $$WorkEntriesTableTableManager(_db, _db.workEntries);
  $$PresetsTableTableManager get presets =>
      $$PresetsTableTableManager(_db, _db.presets);
  $$DayMemosTableTableManager get dayMemos =>
      $$DayMemosTableTableManager(_db, _db.dayMemos);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db, _db.sites);
  $$SiteRateHistoriesTableTableManager get siteRateHistories =>
      $$SiteRateHistoriesTableTableManager(_db, _db.siteRateHistories);
  $$DayExtraItemsTableTableManager get dayExtraItems =>
      $$DayExtraItemsTableTableManager(_db, _db.dayExtraItems);
}
